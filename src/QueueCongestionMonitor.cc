#include "QueueCongestionMonitor.h"

#include "RsvpTeScriptable.h"
#include "inet/queueing/contract/IPacketQueue.h"
#include <omnetpp.h>

namespace insotu {

using namespace omnetpp;
using inet::queueing::IPacketQueue;

Define_Module(QueueCongestionMonitor);

void QueueCongestionMonitor::initialize(int stage)
{
    cSimpleModule::initialize(stage);

    if (stage == inet::INITSTAGE_LOCAL) {
        enabled = par("enabled");
        if (!enabled)
            return;

        tunnelId = par("tunnelId");
        highWatermark = par("highWatermark");
        lowWatermark = par("lowWatermark");
        interval = par("checkInterval");

        if (highWatermark <= lowWatermark)
            throw cRuntimeError("highWatermark must be greater than lowWatermark");

        const char *queuePath = par("queueModule");
        const char *rsvpPath = par("rsvpModule");

        cModule *queueModule = queuePath && *queuePath ? getModuleByPath(queuePath) : nullptr;
        queue = queueModule ? dynamic_cast<IPacketQueue *>(queueModule) : nullptr;
        if (!queue)
            throw cRuntimeError("Queue module '%s' is not an IPacketQueue", queuePath ? queuePath : "<null>");

        cModule *rsvpModule = rsvpPath && *rsvpPath ? getModuleByPath(rsvpPath) : nullptr;
        rsvp = rsvpModule ? dynamic_cast<insotu::RsvpTeScriptable *>(rsvpModule) : nullptr;
        if (!rsvp)
            throw cRuntimeError("RSVP module '%s' is not an insotu RsvpTeScriptable", rsvpPath ? rsvpPath : "<null>");

        timer = new cMessage("poll");
        WATCH(congested);
    }
    else if (stage == inet::INITSTAGE_LAST) {
        if (enabled && timer)
            scheduleAt(simTime(), timer);
    }
}

void QueueCongestionMonitor::handleMessage(cMessage *msg)
{
    if (msg == timer) {
        poll();
        scheduleAt(simTime() + interval, timer);
    }
    else {
        delete msg;
    }
}

void QueueCongestionMonitor::finish()
{
    cancelAndDelete(timer);
    timer = nullptr;
}

void QueueCongestionMonitor::poll()
{
    if (!enabled || !queue || !rsvp)
        return;

    int depth = queue->getNumPackets();

    if (!congested && depth >= highWatermark) {
        congested = true;
        rsvp->handleCongestionNotification(tunnelId, true, getFullPath().c_str());
    }
    else if (congested && depth <= lowWatermark) {
        congested = false;
        rsvp->handleCongestionNotification(tunnelId, false, getFullPath().c_str());
    }
}

} // namespace insotu
