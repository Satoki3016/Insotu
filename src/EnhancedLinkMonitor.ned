package insotu;

//
// Enhanced Link Monitor Module
//
// This module provides comprehensive monitoring of network links including:
// - Queue congestion detection with moving average
// - Link failure detection
// - Packet loss rate monitoring
// - Latency monitoring
// - Link utilization monitoring
//
// When problems are detected, it notifies the RSVP-TE module to trigger
// automatic path switching to alternate routes.
//
simple EnhancedLinkMonitor
{
    parameters:
        @display("i=block/control");
        @class(insotu::EnhancedLinkMonitor);

        // Enable/disable monitoring
        bool enabled = default(true);

        // Tunnel identification
        int tunnelId;

        // Queue congestion thresholds
        int highWatermark = default(200);  // High water mark for congestion
        int lowWatermark = default(100);   // Low water mark for recovery

        // Monitoring interval
        double checkInterval @unit(s) = default(0.1s);

        // Module paths
        string queueModule;                // Path to queue module to monitor
        string rsvpModule;                 // Path to RSVP-TE module
        string interfaceModule = default(""); // Optional: path to network interface

        // Packet loss monitoring
        double lossRateThreshold = default(0.05);  // 5% loss rate threshold
        int monitorWindowSize = default(100);      // Number of packets to monitor

        // Latency monitoring
        double latencyThreshold @unit(s) = default(0.1s);  // 100ms latency threshold

        // Utilization monitoring
        double utilizationThreshold = default(0.9);  // 90% utilization threshold

        // History size for moving average
        int historySize = default(10);  // Number of samples for averaging

        // Statistics
        @signal[congestionState](type=long);
        @signal[linkFailureState](type=long);
        @signal[packetLossState](type=long);
        @signal[latencyState](type=long);
        @signal[utilizationState](type=long);

        @statistic[congestionState](title="Congestion State"; record=vector; interpolationmode=sample-hold);
        @statistic[linkFailureState](title="Link Failure State"; record=vector; interpolationmode=sample-hold);
        @statistic[packetLossState](title="Packet Loss State"; record=vector; interpolationmode=sample-hold);
        @statistic[latencyState](title="Latency State"; record=vector; interpolationmode=sample-hold);
        @statistic[utilizationState](title="Utilization State"; record=vector; interpolationmode=sample-hold);
}
