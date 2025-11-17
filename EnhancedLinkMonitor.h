#ifndef __INSOTU_ENHANCEDLINKMONITOR_H
#define __INSOTU_ENHANCEDLINKMONITOR_H

#include <omnetpp.h>
#include "inet/common/InitStages.h"
#include <vector>
#include <map>

using namespace omnetpp;

namespace inet {
namespace queueing {
class IPacketQueue;
}
class NetworkInterface;
} // namespace inet

namespace insotu {

class RsvpTeScriptable;

/**
 * Enhanced Link Monitor
 *
 * This module monitors multiple aspects of network links:
 * - Queue congestion levels
 * - Link failures (interface status)
 * - Packet loss rate
 * - Link utilization
 * - Latency variations
 *
 * When issues are detected, it notifies the RSVP-TE module
 * to trigger path switching to alternate routes.
 */
class EnhancedLinkMonitor : public cSimpleModule
{
  protected:
    // Configuration parameters
    int tunnelId = -1;
    int highWatermark = 0;
    int lowWatermark = 0;
    simtime_t checkInterval = 0;
    bool enabled = true;

    // Loss rate monitoring
    double lossRateThreshold = 0.05;  // 5% packet loss threshold
    int monitorWindowSize = 100;      // Monitor last N packets

    // Latency monitoring
    simtime_t latencyThreshold = 0.1;  // 100ms threshold

    // Bandwidth utilization monitoring
    double utilizationThreshold = 0.9;  // 90% utilization threshold

    // Module references
    inet::queueing::IPacketQueue *queue = nullptr;
    insotu::RsvpTeScriptable *rsvp = nullptr;
    inet::NetworkInterface *interface = nullptr;

    // Timer
    cMessage *pollTimer = nullptr;

    // State tracking
    bool congested = false;
    bool linkFailed = false;
    bool highLoss = false;
    bool highLatency = false;
    bool highUtilization = false;

    // Statistics
    long packetsSent = 0;
    long packetsDropped = 0;
    long bytesTransmitted = 0;
    simtime_t lastCheckTime = 0;
    std::vector<simtime_t> latencySamples;

    // History for moving average
    std::vector<int> queueLengthHistory;
    int historySize = 10;

  protected:
    virtual int numInitStages() const override { return inet::NUM_INIT_STAGES; }
    virtual void initialize(int stage) override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;

    // Monitoring functions
    void performChecks();
    void checkQueueCongestion();
    void checkLinkStatus();
    void checkPacketLoss();
    void checkLatency();
    void checkUtilization();

    // Helper functions
    double calculateAverageQueueLength();
    double calculatePacketLossRate();
    double calculateAverageLatency();
    double calculateUtilization();
    void notifyRsvp(const char *reason, bool critical);

  public:
    // Public interface for external notifications
    void reportPacketDrop();
    void reportPacketSent();
    void reportLatency(simtime_t latency);
};

} // namespace insotu

#endif
