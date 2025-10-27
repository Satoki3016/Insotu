#include "RsvpTeScriptable.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>

#include "RsvpClassifierScriptable.h"
#include "inet/common/INETDefs.h"
#include "inet/common/Simsignals.h"
#include "inet/networklayer/rsvpte/SignallingMsg_m.h"
#include "omnetpp/cstringtokenizer.h"

namespace insotu {

using omnetpp::cStringTokenizer;
using omnetpp::cXMLElement;
using inet::PathNotifyMsg;
using inet::SessionObj;
using inet::SenderTemplateObj;
using std::endl;

Define_Module(RsvpTeScriptable);

void RsvpTeScriptable::initialize(int stage)
{
    inet::RsvpTe::initialize(stage);

    if (stage == inet::INITSTAGE_LOCAL) {
        classifierExt = dynamic_cast<insotu::RsvpClassifierScriptable *>(rpct.get());
        if (!classifierExt)
            throw inet::cRuntimeError("RsvpTeScriptable requires insotu::RsvpClassifierScriptable as classifier module");
    }
    else if (stage == inet::INITSTAGE_ROUTING_PROTOCOLS) {
        buildTunnelPlan();
        syncActiveIndices();
    }
}

void RsvpTeScriptable::processCommand(const cXMLElement& node)
{
    const char *name = node.getAttribute("name");
    if (!name)
        throw inet::cRuntimeError("Script command missing 'name' attribute");

    if (!strcmp(name, "reroute")) {
        const char *args = node.getAttribute("args");
        if (!args)
            throw inet::cRuntimeError("reroute command requires args (tunnelId[=<id>] [action=restore])");

        int tunnelId = -1;
        bool restore = false;

        cStringTokenizer tokenizer(args, " ");
        while (const char *token = tokenizer.nextToken()) {
            if (!strncmp(token, "tunnelId=", 9))
                tunnelId = atoi(token + 9);
            else if (!strcmp(token, "restore=true") || !strcmp(token, "action=restore"))
                restore = true;
        }

        if (tunnelId < 0)
            throw inet::cRuntimeError("reroute command requires tunnelId argument");

        EV_INFO << "Scenario command: reroute tunnelId=" << tunnelId
                << (restore ? " action=restore" : " action=failover") << endl;

        if (restore)
            requestRestore(tunnelId, "scenario command", false);
        else
            requestFailover(tunnelId, "scenario command", false);
    }
    else {
        throw inet::cRuntimeError("Unknown ScenarioManager command: %s", name);
    }
}

void RsvpTeScriptable::processPATH_NOTIFY(PathNotifyMsg *msg)
{
    int status = msg->getStatus();
    SessionObj session = msg->getSession();
    SenderTemplateObj sender = msg->getSender();

    inet::RsvpTe::processPATH_NOTIFY(msg);

    switch (status) {
        case inet::PATH_FAILED:
        case inet::PATH_UNFEASIBLE:
        case inet::PATH_PREEMPTED:
            handlePathFailure(session.Tunnel_Id, sender.Lsp_Id, "PATH_NOTIFY");
            break;
        case inet::PATH_CREATED:
            handlePathRestored(session.Tunnel_Id, sender.Lsp_Id, "PATH_NOTIFY");
            break;
        default:
            break;
    }
}

void RsvpTeScriptable::buildTunnelPlan()
{
    tunnelLspOrder.clear();
    tunnelLspIndex.clear();

    for (auto& session : traffic) {
        int tunnelId = session.sobj.Tunnel_Id;
        auto& order = tunnelLspOrder[tunnelId];
        auto& indexMap = tunnelLspIndex[tunnelId];
        order.clear();
        indexMap.clear();

        for (size_t i = 0; i < session.paths.size(); ++i) {
            int lspId = session.paths[i].sender.Lsp_Id;
            order.push_back(lspId);
            indexMap[lspId] = static_cast<int>(i);
        }
    }
}

RsvpTeScriptable::traffic_session_t *RsvpTeScriptable::findSessionByTunnel(int tunnelId)
{
    for (auto& session : traffic) {
        if (session.sobj.Tunnel_Id == tunnelId)
            return &session;
    }
    return nullptr;
}

RsvpTeScriptable::traffic_path_t *RsvpTeScriptable::findPathByLsp(traffic_session_t *session, int lspId)
{
    if (!session)
        return nullptr;
    for (auto& path : session->paths) {
        if (path.sender.Lsp_Id == lspId)
            return &path;
    }
    return nullptr;
}

int RsvpTeScriptable::findPathIndex(int tunnelId, int lspId) const
{
    auto it = tunnelLspIndex.find(tunnelId);
    if (it == tunnelLspIndex.end())
        return -1;
    auto jt = it->second.find(lspId);
    if (jt == it->second.end())
        return -1;
    return jt->second;
}

void RsvpTeScriptable::syncActiveIndices()
{
    tunnelActiveIndex.clear();
    for (const auto& pair : tunnelLspOrder)
        tunnelActiveIndex[pair.first] = getPrimaryIndex(pair.first);

    if (!classifierExt)
        return;

    for (const auto& fec : classifierExt->getFecEntries()) {
        int tunnelId = fec.session.Tunnel_Id;
        int idx = findPathIndex(tunnelId, fec.sender.Lsp_Id);
        if (idx >= 0)
            tunnelActiveIndex[tunnelId] = idx;
    }
}

void RsvpTeScriptable::switchToIndex(int tunnelId, int targetIndex, const char *reason)
{
    auto orderIt = tunnelLspOrder.find(tunnelId);
    if (orderIt == tunnelLspOrder.end())
        return;

    if (targetIndex < 0 || targetIndex >= (int)orderIt->second.size())
        return;

    int currentIndex = tunnelActiveIndex[tunnelId];
    if (currentIndex == targetIndex)
        return;

    traffic_session_t *session = findSessionByTunnel(tunnelId);
    if (!session)
        return;

    int lspId = orderIt->second[targetIndex];
    traffic_path_t *path = findPathByLsp(session, lspId);
    if (!path) {
        EV_WARN << "Requested LSP " << lspId << " not defined for tunnel " << tunnelId << endl;
        return;
    }

    if (!findPSB(session->sobj, path->sender)) {
        EV_INFO << "Triggering path setup for tunnel " << tunnelId << " lspId " << lspId << endl;
        createPath(session->sobj, path->sender);
    }

    int inLabel = getInLabel(session->sobj, path->sender);

    bool rebound = false;
    for (const auto& fec : classifierExt->getFecEntries()) {
        if (fec.session.Tunnel_Id != tunnelId)
            continue;

        classifierExt->rebindFec(fec.id, session->sobj, path->sender, inLabel);
        rebound = true;
    }

    if (rebound) {
        tunnelActiveIndex[tunnelId] = targetIndex;
        EV_INFO << "Switched tunnel " << tunnelId << " to LSP " << lspId
                << " (index " << targetIndex << ") due to " << reason << endl;
    }
    else {
        EV_WARN << "No FEC entries found for tunnel " << tunnelId << " while attempting to switch paths" << endl;
    }
}

void RsvpTeScriptable::requestFailover(int tunnelId, const char *reason, bool)
{
    auto orderIt = tunnelLspOrder.find(tunnelId);
    if (orderIt == tunnelLspOrder.end())
        return;

    int currentIndex = tunnelActiveIndex[tunnelId];
    int candidate = -1;
    for (int idx = currentIndex + 1; idx < (int)orderIt->second.size(); ++idx) {
        candidate = idx;
        break;
    }

    if (candidate >= 0) {
        switchToIndex(tunnelId, candidate, reason);
        return;
    }

    int primaryIndex = getPrimaryIndex(tunnelId);
    if (currentIndex != primaryIndex && primaryUnavailable.count(tunnelId) == 0) {
        switchToIndex(tunnelId, primaryIndex, reason);
        return;
    }

    EV_WARN << "No alternate path available for tunnel " << tunnelId << " when handling " << reason << endl;
}

void RsvpTeScriptable::requestRestore(int tunnelId, const char *reason, bool dueToCongestion)
{
    auto orderIt = tunnelLspOrder.find(tunnelId);
    if (orderIt == tunnelLspOrder.end())
        return;

    int primaryIndex = getPrimaryIndex(tunnelId);
    if (tunnelActiveIndex[tunnelId] == primaryIndex)
        return;

    if (!dueToCongestion && congestionForced.count(tunnelId))
        return;

    if (primaryUnavailable.count(tunnelId))
        return;

    switchToIndex(tunnelId, primaryIndex, reason);
}

void RsvpTeScriptable::handlePathFailure(int tunnelId, int lspId, const char *reason)
{
    int index = findPathIndex(tunnelId, lspId);
    if (index < 0)
        return;

    if (index == getPrimaryIndex(tunnelId))
        primaryUnavailable.insert(tunnelId);

    requestFailover(tunnelId, reason, false);
}

void RsvpTeScriptable::handlePathRestored(int tunnelId, int lspId, const char *reason)
{
    int index = findPathIndex(tunnelId, lspId);
    if (index < 0)
        return;

    if (index == getPrimaryIndex(tunnelId)) {
        primaryUnavailable.erase(tunnelId);
        requestRestore(tunnelId, reason, false);
    }
}

void RsvpTeScriptable::handleCongestionNotification(int tunnelId, bool congested, const char *source)
{
    if (congested) {
        bool inserted = congestionForced.insert(tunnelId).second;
        if (inserted)
            EV_INFO << "Congestion detected for tunnel " << tunnelId << " by " << source << endl;
        requestFailover(tunnelId, source, true);
    }
    else {
        bool erased = congestionForced.erase(tunnelId) > 0;
        if (erased)
            EV_INFO << "Congestion cleared for tunnel " << tunnelId << " by " << source << endl;
        requestRestore(tunnelId, source, true);
    }
}

} // namespace insotu
