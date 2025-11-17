#include "EnhancedLinkMonitor.h"
#include "RsvpTeScriptable.h"
#include "inet/queueing/contract/IPacketQueue.h"
#include "inet/networklayer/common/NetworkInterface.h"
#include <omnetpp.h>
#include <algorithm>
#include <numeric>

namespace insotu {

using namespace omnetpp;
using inet::queueing::IPacketQueue;
using inet::NetworkInterface;

Define_Module(EnhancedLinkMonitor);

void EnhancedLinkMonitor::initialize(int stage)
{
    cSimpleModule::initialize(stage);

    if (stage == inet::INITSTAGE_LOCAL) {
        // Read parameters
        enabled = par("enabled").boolValue();
        if (!enabled) {
            EV_INFO << "EnhancedLinkMonitor is disabled" << std::endl;
            return;
        }

        tunnelId = par("tunnelId").intValue();
        highWatermark = par("highWatermark").intValue();
        lowWatermark = par("lowWatermark").intValue();
        checkInterval = par("checkInterval").doubleValue();

        // Optional parameters
        if (hasPar("lossRateThreshold"))
            lossRateThreshold = par("lossRateThreshold").doubleValue();
        if (hasPar("latencyThreshold"))
            latencyThreshold = par("latencyThreshold").doubleValue();
        if (hasPar("utilizationThreshold"))
            utilizationThreshold = par("utilizationThreshold").doubleValue();
        if (hasPar("monitorWindowSize"))
            monitorWindowSize = par("monitorWindowSize").intValue();
        if (hasPar("historySize"))
            historySize = par("historySize").intValue();

        // Validate parameters
        if (highWatermark <= lowWatermark)
            throw cRuntimeError("highWatermark must be greater than lowWatermark");

        // Get module references
        const char *queuePath = par("queueModule").stringValue();
        const char *rsvpPath = par("rsvpModule").stringValue();

        cModule *queueModule = queuePath && *queuePath ? getModuleByPath(queuePath) : nullptr;
        queue = queueModule ? dynamic_cast<IPacketQueue *>(queueModule) : nullptr;
        if (!queue)
            throw cRuntimeError("Queue module '%s' is not an IPacketQueue", queuePath ? queuePath : "<null>");

        cModule *rsvpModule = rsvpPath && *rsvpPath ? getModuleByPath(rsvpPath) : nullptr;
        rsvp = rsvpModule ? dynamic_cast<insotu::RsvpTeScriptable *>(rsvpModule) : nullptr;
        if (!rsvp)
            throw cRuntimeError("RSVP module '%s' is not an insotu::RsvpTeScriptable", rsvpPath ? rsvpPath : "<null>");

        // Optional interface module for link status monitoring
        // Note: NetworkInterface is not a cModule, so this feature is currently disabled
        // To enable, you would need to access the interface through InterfaceTable
        if (hasPar("interfaceModule")) {
            const char *ifacePath = par("interfaceModule").stringValue();
            if (ifacePath && *ifacePath) {
                // TODO: Implement interface lookup via InterfaceTable
                EV_WARN << "Interface monitoring via interfaceModule parameter is not yet implemented" << std::endl;
                EV_WARN << "To monitor link status, use queue-based monitoring instead" << std::endl;
            }
        }

        // Initialize timer
        pollTimer = new cMessage("pollTimer");

        // Initialize statistics
        lastCheckTime = simTime();

        // Watch variables
        WATCH(congested);
        WATCH(linkFailed);
        WATCH(highLoss);
        WATCH(highLatency);
        WATCH(highUtilization);
        WATCH(packetsSent);
        WATCH(packetsDropped);

        EV_INFO << "EnhancedLinkMonitor initialized for tunnel " << tunnelId << std::endl;
    }
    else if (stage == inet::INITSTAGE_LAST) {
        if (enabled && pollTimer)
            scheduleAt(simTime() + checkInterval, pollTimer);
    }
}

void EnhancedLinkMonitor::handleMessage(cMessage *msg)
{
    if (msg == pollTimer) {
        performChecks();
        scheduleAt(simTime() + checkInterval, pollTimer);
    }
    else {
        delete msg;
    }
}

void EnhancedLinkMonitor::finish()
{
    cancelAndDelete(pollTimer);
    pollTimer = nullptr;

    // Record final statistics
    if (enabled) {
        recordScalar("finalPacketsSent", packetsSent);
        recordScalar("finalPacketsDropped", packetsDropped);
        if (packetsSent > 0) {
            double lossRate = (double)packetsDropped / (double)packetsSent;
            recordScalar("finalPacketLossRate", lossRate);
        }
    }
}

void EnhancedLinkMonitor::performChecks()
{
    if (!enabled || !queue || !rsvp)
        return;

    EV_DEBUG << "Performing link checks at t=" << simTime() << std::endl;

    // Perform all monitoring checks
    checkQueueCongestion();
    checkLinkStatus();
    checkPacketLoss();
    checkLatency();
    checkUtilization();

    lastCheckTime = simTime();
}

void EnhancedLinkMonitor::checkQueueCongestion()
{
    int queueLength = queue->getNumPackets();

    // Update history
    queueLengthHistory.push_back(queueLength);
    if ((int)queueLengthHistory.size() > historySize)
        queueLengthHistory.erase(queueLengthHistory.begin());

    double avgQueueLength = calculateAverageQueueLength();

    bool wasCongested = congested;

    if (!congested && avgQueueLength >= highWatermark) {
        congested = true;
        EV_WARN << "Queue congestion detected! Avg queue length: " << avgQueueLength
                << " >= " << highWatermark << std::endl;
        notifyRsvp("Queue congestion detected", true);
    }
    else if (congested && avgQueueLength <= lowWatermark) {
        congested = false;
        EV_INFO << "Queue congestion cleared. Avg queue length: " << avgQueueLength
                << " <= " << lowWatermark << std::endl;
        notifyRsvp("Queue congestion cleared", false);
    }

    if (congested != wasCongested) {
        emit(registerSignal("congestionState"), congested ? 1 : 0);
    }
}

void EnhancedLinkMonitor::checkLinkStatus()
{
    if (!interface)
        return;

    // Check if interface is up
    bool isUp = interface->isUp();
    bool wasLinkFailed = linkFailed;

    if (isUp && linkFailed) {
        linkFailed = false;
        EV_INFO << "Link recovered" << std::endl;
        notifyRsvp("Link recovered", false);
    }
    else if (!isUp && !linkFailed) {
        linkFailed = true;
        EV_WARN << "Link failure detected!" << std::endl;
        notifyRsvp("Link failure detected", true);
    }

    if (linkFailed != wasLinkFailed) {
        emit(registerSignal("linkFailureState"), linkFailed ? 1 : 0);
    }
}

void EnhancedLinkMonitor::checkPacketLoss()
{
    double lossRate = calculatePacketLossRate();
    bool wasHighLoss = highLoss;

    if (!highLoss && lossRate >= lossRateThreshold) {
        highLoss = true;
        EV_WARN << "High packet loss detected! Loss rate: " << (lossRate * 100)
                << "% >= " << (lossRateThreshold * 100) << "%" << std::endl;
        notifyRsvp("High packet loss detected", true);
    }
    else if (highLoss && lossRate < lossRateThreshold * 0.5) {
        highLoss = false;
        EV_INFO << "Packet loss returned to normal. Loss rate: " << (lossRate * 100) << "%" << std::endl;
        notifyRsvp("Packet loss normalized", false);
    }

    if (highLoss != wasHighLoss) {
        emit(registerSignal("packetLossState"), highLoss ? 1 : 0);
    }

    recordScalar("currentPacketLossRate", lossRate);
}

void EnhancedLinkMonitor::checkLatency()
{
    if (latencySamples.empty())
        return;

    double avgLatency = calculateAverageLatency();
    bool wasHighLatency = highLatency;

    if (!highLatency && avgLatency >= latencyThreshold.dbl()) {
        highLatency = true;
        EV_WARN << "High latency detected! Avg latency: " << avgLatency
                << "s >= " << latencyThreshold << std::endl;
        notifyRsvp("High latency detected", false);
    }
    else if (highLatency && avgLatency < latencyThreshold.dbl() * 0.7) {
        highLatency = false;
        EV_INFO << "Latency returned to normal. Avg latency: " << avgLatency << "s" << std::endl;
        notifyRsvp("Latency normalized", false);
    }

    if (highLatency != wasHighLatency) {
        emit(registerSignal("latencyState"), highLatency ? 1 : 0);
    }
}

void EnhancedLinkMonitor::checkUtilization()
{
    double utilization = calculateUtilization();
    bool wasHighUtilization = highUtilization;

    if (!highUtilization && utilization >= utilizationThreshold) {
        highUtilization = true;
        EV_WARN << "High link utilization detected! Utilization: " << (utilization * 100)
                << "% >= " << (utilizationThreshold * 100) << "%" << std::endl;
        notifyRsvp("High utilization detected", false);
    }
    else if (highUtilization && utilization < utilizationThreshold * 0.7) {
        highUtilization = false;
        EV_INFO << "Link utilization returned to normal. Utilization: " << (utilization * 100) << "%" << std::endl;
        notifyRsvp("Utilization normalized", false);
    }

    if (highUtilization != wasHighUtilization) {
        emit(registerSignal("utilizationState"), highUtilization ? 1 : 0);
    }

    recordScalar("currentUtilization", utilization);
}

double EnhancedLinkMonitor::calculateAverageQueueLength()
{
    if (queueLengthHistory.empty())
        return 0.0;

    double sum = std::accumulate(queueLengthHistory.begin(), queueLengthHistory.end(), 0.0);
    return sum / queueLengthHistory.size();
}

double EnhancedLinkMonitor::calculatePacketLossRate()
{
    if (packetsSent == 0)
        return 0.0;

    return (double)packetsDropped / (double)packetsSent;
}

double EnhancedLinkMonitor::calculateAverageLatency()
{
    if (latencySamples.empty())
        return 0.0;

    double sum = 0.0;
    for (const auto &sample : latencySamples)
        sum += sample.dbl();

    return sum / latencySamples.size();
}

double EnhancedLinkMonitor::calculateUtilization()
{
    // Simple utilization based on queue occupancy
    if (!queue)
        return 0.0;

    int maxCapacity = queue->getMaxNumPackets();
    if (maxCapacity <= 0)
        return 0.0;

    int currentOccupancy = queue->getNumPackets();
    return (double)currentOccupancy / (double)maxCapacity;
}

void EnhancedLinkMonitor::notifyRsvp(const char *reason, bool critical)
{
    if (!rsvp)
        return;

    EV_INFO << "Notifying RSVP-TE: " << reason << " (critical=" << critical << ")" << std::endl;

    // Notify RSVP-TE about congestion state
    rsvp->handleCongestionNotification(tunnelId, critical, reason);
}

// Public interface for external notifications

void EnhancedLinkMonitor::reportPacketDrop()
{
    packetsDropped++;
}

void EnhancedLinkMonitor::reportPacketSent()
{
    packetsSent++;
}

void EnhancedLinkMonitor::reportLatency(simtime_t latency)
{
    latencySamples.push_back(latency);

    // Keep only recent samples
    if ((int)latencySamples.size() > monitorWindowSize)
        latencySamples.erase(latencySamples.begin());
}

} // namespace insotu
