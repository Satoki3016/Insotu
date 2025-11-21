#include "RsvpTeScriptable.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <omnetpp.h>

#include "RsvpClassifierScriptable.h"
#include "inet/common/INETDefs.h"
#include "inet/common/Simsignals.h"
#include "inet/common/Protocol.h"
#include "inet/common/ProtocolTag_m.h"
#include "inet/common/packet/Packet.h"
#include "inet/networklayer/ipv4/IcmpHeader_m.h"
#include "inet/networklayer/rsvpte/RsvpPacket_m.h"
#include "inet/networklayer/rsvpte/SignallingMsg_m.h"

namespace insotu {

using namespace omnetpp;
using inet::PathNotifyMsg;
using inet::SessionObj;
using inet::SenderTemplateObj;
using std::endl;

Define_Module(RsvpTeScriptable);

void RsvpTeScriptable::initialize(int stage)
{
    inet::RsvpTe::initialize(stage);

    if (stage == inet::INITSTAGE_LOCAL) {
        autoRestorePrimary = par("autoRestorePrimary").boolValue();
        restorationDelay = par("restorationDelay");
        restorationCheckTimer = new cMessage("restorationCheck");
        classifierExt = dynamic_cast<insotu::RsvpClassifierScriptable *>(rpct.get());
        if (!classifierExt)
            throw cRuntimeError("RsvpTeScriptable requires insotu::RsvpClassifierScriptable as classifier module");
    }
    else if (stage == inet::INITSTAGE_ROUTING_PROTOCOLS) {
        buildTunnelPlan();
        syncActiveIndices();

        for (auto& session : traffic) {
            for (auto& path : session.paths) {
                if (path.permanent) {

                    bool hasPsb = findPSB(session.sobj, path.sender);
                    if (!hasPsb) {
                        EV_INFO << "Pre-establishing backup LSP " << path.sender.Lsp_Id
                                << " for tunnel " << session.sobj.Tunnel_Id << endl;
                        createPath(session.sobj, path.sender);
                    }
                }
            }
        }

        // After initial LSP setup, disable automatic FEC binding
        // Only explicit rebinding via switchToIndex() will update FECs
        EV_INFO << "Initial LSP setup complete, disabling automatic FEC binding" << endl;
        classifierExt->setAllowAutomaticBinding(false);
    }
}

void RsvpTeScriptable::handleMessageWhenUp(cMessage *msg)
{
    // Handle restoration check timer
    if (msg == restorationCheckTimer) {
        checkPendingRestorations();
        return;
    }

    // Filter out non-RSVP packets (e.g., ICMP messages)
    if (auto packet = dynamic_cast<inet::Packet *>(msg)) {
        // Check if packet contains ICMP header
        if (packet->findTag<inet::PacketProtocolTag>()) {
            auto protocolTag = packet->getTag<inet::PacketProtocolTag>();
            if (protocolTag->getProtocol() == &inet::Protocol::icmpv4 ||
                protocolTag->getProtocol() == &inet::Protocol::icmpv6) {
                EV_WARN << "Received ICMP packet, discarding (not an RSVP message)" << endl;
                delete msg;
                return;
            }
        }

        // Check if packet actually contains RSVP message
        try {
            auto chunk = packet->peekAtFront<inet::Chunk>();
            if (!dynamicPtrCast<const inet::RsvpMessage>(chunk)) {
                EV_WARN << "Received non-RSVP packet with protocol tag, discarding" << endl;
                delete msg;
                return;
            }
        }
        catch (const std::exception& e) {
            EV_WARN << "Exception while checking packet type: " << e.what() << ", discarding" << endl;
            delete msg;
            return;
        }
    }

    // Pass valid RSVP messages to base class
    inet::RsvpTe::handleMessageWhenUp(msg);
}

void RsvpTeScriptable::processCommand(const cXMLElement& node)
{
    const char *name = node.getAttribute("name");
    if (!name)
        throw cRuntimeError("Script command missing 'name' attribute");

    if (!strcmp(name, "reroute")) {
        const char *args = node.getAttribute("args");
        if (!args)
            throw cRuntimeError("reroute command requires args (tunnelId[=<id>] [action=restore])");

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
            throw cRuntimeError("reroute command requires tunnelId argument");

        EV_INFO << "Scenario command: reroute tunnelId=" << tunnelId
                << (restore ? " action=restore" : " action=failover") << endl;

        if (restore)
            requestRestore(tunnelId, "scenario command", false);
        else
            requestFailover(tunnelId, "scenario command", false);
    }
    else {
        throw cRuntimeError("Unknown ScenarioManager command: %s", name);
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

    bool hasPsb = findPSB(session->sobj, path->sender);
    if (!hasPsb) {
        int existingPending = tunnelPendingIndex.count(tunnelId) ? tunnelPendingIndex[tunnelId] : -1;
        if (existingPending != targetIndex) {
            EV_INFO << "Triggering path setup for tunnel " << tunnelId << " lspId " << lspId << endl;
            createPath(session->sobj, path->sender);
            tunnelPendingIndex[tunnelId] = targetIndex;
        }
        else {
            EV_DEBUG << "Still waiting for PATH setup for tunnel " << tunnelId << " lspId " << lspId << endl;
        }
        return;
    }

    int inLabel = getInLabel(session->sobj, path->sender);

    if (inLabel < 0) {
        tunnelPendingIndex[tunnelId] = targetIndex;
        EV_INFO << "Pending switch of tunnel " << tunnelId << " to LSP " << lspId
                << " (index " << targetIndex << ") until RESV installs a label" << endl;
        return;
    }

    bool rebound = false;
    for (const auto& fec : classifierExt->getFecEntries()) {
        if (fec.session.Tunnel_Id != tunnelId)
            continue;

        classifierExt->rebindFec(fec.id, session->sobj, path->sender, inLabel);
        rebound = true;
    }

    if (rebound) {
        tunnelActiveIndex[tunnelId] = targetIndex;
        tunnelPendingIndex.erase(tunnelId);
        EV_WARN << "**SWITCH** Tunnel " << tunnelId << " from index " << currentIndex
                << " to index " << targetIndex << " (LSP " << lspId << ", label " << inLabel
                << ") - Reason: " << reason << " at t=" << simTime() << endl;
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
    auto pendingIt = tunnelPendingIndex.find(tunnelId);
    if (pendingIt != tunnelPendingIndex.end())
        currentIndex = pendingIt->second;

    traffic_session_t *session = findSessionByTunnel(tunnelId);
    if (!session)
        return;


    int candidate = -1;
    for (int idx = currentIndex + 1; idx < (int)orderIt->second.size(); ++idx) {
        int lspId = orderIt->second[idx];
        traffic_path_t *path = findPathByLsp(session, lspId);
        if (!path)
            continue;


        bool hasPsb = findPSB(session->sobj, path->sender);
        if (hasPsb) {
            int inLabel = getInLabel(session->sobj, path->sender);
            if (inLabel >= 0) {

                candidate = idx;
                EV_INFO << "Found immediately available backup path at index " << idx << " (LSP " << lspId << ")" << endl;
                break;
            }
        }


        if (candidate < 0) {
            candidate = idx;
            EV_INFO << "Found backup path at index " << idx << " (LSP " << lspId << "), will attempt setup" << endl;
        }
    }

    if (candidate >= 0) {
        switchToIndex(tunnelId, candidate, reason);
        return;
    }

    int primaryIndex = getPrimaryIndex(tunnelId);
    if (currentIndex != primaryIndex && primaryUnavailable.count(tunnelId) == 0) {
        EV_INFO << "No forward backup available, attempting to restore primary path" << endl;
        switchToIndex(tunnelId, primaryIndex, reason);
        return;
    }

    // 最後の手段：全てのパスをチェック（currentIndexより前も含む）
    for (int idx = 0; idx < (int)orderIt->second.size(); ++idx) {
        if (idx == currentIndex)
            continue;

        int lspId = orderIt->second[idx];
        traffic_path_t *path = findPathByLsp(session, lspId);
        if (!path)
            continue;

        bool hasPsb = findPSB(session->sobj, path->sender);
        if (hasPsb) {
            int inLabel = getInLabel(session->sobj, path->sender);
            if (inLabel >= 0) {
                EV_INFO << "Found alternative available path at index " << idx << " (LSP " << lspId << ")" << endl;
                switchToIndex(tunnelId, idx, reason);
                return;
            }
        }
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

    // Verify primary path is fully operational before restoring
    traffic_session_t *session = findSessionByTunnel(tunnelId);
    if (!session)
        return;

    int primaryLspId = orderIt->second[primaryIndex];
    traffic_path_t *path = findPathByLsp(session, primaryLspId);
    if (!path)
        return;

    bool hasPsb = findPSB(session->sobj, path->sender);
    if (!hasPsb) {
        EV_DETAIL << "Cannot restore to primary LSP " << primaryLspId << " - no PSB yet" << endl;
        return;
    }

    int inLabel = getInLabel(session->sobj, path->sender);
    if (inLabel < 0) {
        EV_DETAIL << "Cannot restore to primary LSP " << primaryLspId << " - no valid label yet" << endl;
        return;
    }

    EV_INFO << "Restoring tunnel " << tunnelId << " to primary path (LSP " << primaryLspId
            << ", label " << inLabel << "): " << reason << endl;
    switchToIndex(tunnelId, primaryIndex, reason);
}

void RsvpTeScriptable::handlePathFailure(int tunnelId, int lspId, const char *reason)
{
    int index = findPathIndex(tunnelId, lspId);
    if (index < 0)
        return;

    bool wasPending = false;
    auto pendingIt = tunnelPendingIndex.find(tunnelId);
    if (pendingIt != tunnelPendingIndex.end() && pendingIt->second == index) {
        wasPending = true;
        tunnelPendingIndex.erase(pendingIt);
    }

    int currentIndex = tunnelActiveIndex.count(tunnelId) ? tunnelActiveIndex[tunnelId] : getPrimaryIndex(tunnelId);
    auto remainingPending = tunnelPendingIndex.find(tunnelId);
    if (remainingPending != tunnelPendingIndex.end())
        currentIndex = remainingPending->second;


    if (index == getPrimaryIndex(tunnelId))
        primaryUnavailable.insert(tunnelId);

    if (wasPending && index != currentIndex) {
        EV_INFO << "Pending LSP " << lspId << " for tunnel " << tunnelId
                << " failed to establish (" << reason << "), waiting for RSVP retry" << endl;

        return;
    }

    if (!wasPending && index != currentIndex) {

        EV_INFO << "Non-active LSP " << lspId << " for tunnel " << tunnelId
                << " failed (" << reason << "), but tunnel is using different path (index " << currentIndex << ")" << endl;
        return;
    }


    EV_WARN << "Active LSP " << lspId << " (index " << index << ") for tunnel " << tunnelId
            << " has failed (" << reason << "), triggering immediate failover" << endl;

    requestFailover(tunnelId, reason, false);
}

void RsvpTeScriptable::handlePathRestored(int tunnelId, int lspId, const char *reason)
{
    int index = findPathIndex(tunnelId, lspId);
    if (index < 0)
        return;

    traffic_session_t *session = findSessionByTunnel(tunnelId);
    if (!session)
        return;

    traffic_path_t *path = findPathByLsp(session, lspId);
    if (!path)
        return;

    // Verify LSP is fully operational before considering it restored
    bool hasPsb = findPSB(session->sobj, path->sender);
    if (!hasPsb) {
        EV_DETAIL << "LSP " << lspId << " restored notification but PSB not found, waiting for full establishment" << endl;
        return;
    }

    int inLabel = getInLabel(session->sobj, path->sender);
    if (inLabel < 0) {
        EV_DETAIL << "LSP " << lspId << " has PSB but no valid label yet, waiting for label installation" << endl;
        return;
    }

    EV_INFO << "LSP " << lspId << " for tunnel " << tunnelId << " has PSB and label " << inLabel << endl;

    // For delayed restoration, schedule timer on first detection
    if (restorationDelay > 0) {
        auto key = std::make_pair(tunnelId, lspId);
        auto it = pathRestoredTime.find(key);

        if (it == pathRestoredTime.end()) {
            // First time - record time and schedule timer
            pathRestoredTime[key] = simTime();
            EV_INFO << "Path restoration detected, scheduling delayed restoration in "
                    << restorationDelay << "s" << endl;

            if (!restorationCheckTimer->isScheduled()) {
                scheduleAt(simTime() + restorationDelay, restorationCheckTimer);
            }
            return; // Don't restore yet
        }
    }

    // Immediate restoration (restorationDelay == 0) or called from timer
    auto pendingIt = tunnelPendingIndex.find(tunnelId);
    if (pendingIt != tunnelPendingIndex.end() && pendingIt->second == index) {
        switchToIndex(tunnelId, index, reason);
        return;
    }

    if (index == getPrimaryIndex(tunnelId)) {
        primaryUnavailable.erase(tunnelId);
        if (autoRestorePrimary) {
            EV_INFO << "Primary path (LSP " << lspId << ") ready for restoration" << endl;
            requestRestore(tunnelId, reason, false);
        }
    }
}

void RsvpTeScriptable::checkPendingRestorations()
{
    EV_INFO << "Checking pending restorations at t=" << simTime() << endl;

    // Collect paths that are ready for restoration
    std::vector<std::pair<int, int>> readyPaths;

    for (auto& entry : pathRestoredTime) {
        int tunnelId = entry.first.first;
        int lspId = entry.first.second;
        simtime_t restoredTime = entry.second;
        simtime_t elapsed = simTime() - restoredTime;

        if (elapsed >= restorationDelay) {
            EV_INFO << "Path tunnel=" << tunnelId << " lsp=" << lspId
                    << " is ready for restoration (elapsed=" << elapsed << "s)" << endl;
            readyPaths.push_back(entry.first);
        }
    }

    // Process ready paths - perform restoration directly
    for (auto& key : readyPaths) {
        int tunnelId = key.first;
        int lspId = key.second;

        // Remove from tracking
        pathRestoredTime.erase(key);

        // Perform restoration
        int index = findPathIndex(tunnelId, lspId);
        if (index < 0)
            continue;

        traffic_session_t *session = findSessionByTunnel(tunnelId);
        if (!session)
            continue;

        traffic_path_t *path = findPathByLsp(session, lspId);
        if (!path)
            continue;

        // Verify still has PSB and label
        bool hasPsb = findPSB(session->sobj, path->sender);
        int inLabel = hasPsb ? getInLabel(session->sobj, path->sender) : -1;

        if (!hasPsb || inLabel < 0) {
            EV_WARN << "Path tunnel=" << tunnelId << " lsp=" << lspId
                    << " lost PSB/label during delay period, skipping restoration" << endl;
            continue;
        }

        EV_INFO << "Restoring path tunnel=" << tunnelId << " lsp=" << lspId
                << " with label=" << inLabel << " after delay" << endl;

        // Check if this is primary and should be restored
        if (index == getPrimaryIndex(tunnelId)) {
            primaryUnavailable.erase(tunnelId);
            if (autoRestorePrimary) {
                requestRestore(tunnelId, "delayed_restoration", false);
            }
        }
    }

    // Reschedule if there are still pending restorations
    if (!pathRestoredTime.empty()) {
        scheduleAt(simTime() + restorationDelay, restorationCheckTimer);
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
