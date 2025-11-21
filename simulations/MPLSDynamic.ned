package insotu.simulations;

import inet.node.ethernet.Eth10G;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.Eth1G;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.StandardHost;
import inet.common.scenario.ScenarioManager;
import inet.visualizer.contract.IIntegratedVisualizer;
import insotu.QueueCongestionMonitor;
import insotu.LinkUtilizationMonitor;
import insotu.RsvpMplsRouterScriptable;

//
// Custom channel definitions for MPLS network
//
channel HighSpeedLink extends ned.DatarateChannel
{
    datarate = 10Mbps;
    delay = 1ms;
}

channel MediumSpeedLink extends ned.DatarateChannel
{
    datarate = 5Mbps;
    delay = 2ms;
}

channel LowSpeedLink extends ned.DatarateChannel
{
    datarate = 1Mbps;
    delay = 5ms;
}

//
// Dynamic MPLS Network with Resilient Routing
//
// This network demonstrates:
// - MPLS-TE (Traffic Engineering) with RSVP
// - Multiple redundant paths for fault tolerance
// - Dynamic path switching based on link conditions
// - Congestion monitoring and avoidance
// - Link failure detection and recovery
//
// Architecture:
//   Tx hosts -> LER_Ingress -> Core Routers -> LER_Egress -> Rx hosts
//
// Features:
// - 3 sender hosts (Tx1, Tx2, Tx3)
// - 3 receiver hosts (Rx1, Rx2, Rx3)
// - MPLS routing with RSVP-TE
// - Link failure and congestion simulation
// - Dynamic path switching based on congestion/failure detection
// - Configurable number of core routers
//
network MPLSDynamic
{
    parameters:
        int numCoreRouters = default(3); // Variable number of core routers
        **.ipv4.configurator.networkConfiguratorModule = "ipv4NetworkConfigurator";
        @display("bgb=2500,1800");

    submodules:
        //
        // Management and Visualization Modules
        //
        visualizer: <default(firstAvailableOrEmpty("IntegratedCanvasVisualizer"))> like IIntegratedVisualizer if typename != "" {
            @display("p=100,100;is=s");
        }

        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=300,100;is=s");
        }

        scenarioManager: ScenarioManager {
            @display("p=500,100;is=s");
        }

        //
        // MPLS Edge Routers (Label Edge Routers)
        //
        LER_Ingress: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4 ppp5";
                @display("p=700,900;i=abstract/router");
            gates:
                pppg[6]; // 0-2: hosts, 3-5: core routers
        }

        LER_Egress: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4 ppp5";
                @display("p=1800,900;i=abstract/router");
            gates:
                pppg[6]; // 0-2: hosts, 3-5: core routers
        }

        //
        // MPLS Core Routers (Label Switching Routers)
        // Each provides an alternate path for redundancy
        //
        CoreRouter1: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1250,500;i=abstract/router2");
            gates:
                pppg[2]; // 0: ingress, 1: egress
        }

        CoreRouter2: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1250,900;i=abstract/router2");
            gates:
                pppg[2];
        }

        CoreRouter3: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1250,1300;i=abstract/router2");
            gates:
                pppg[2];
        }

        //
        // Sender Hosts (Traffic Sources)
        //
        Tx1: StandardHost {
            @display("p=200,500;i=device/pc");
        }

        Tx2: StandardHost {
            @display("p=200,900;i=device/pc");
        }

        Tx3: StandardHost {
            @display("p=200,1300;i=device/pc");
        }

        //
        // Receiver Hosts (Traffic Sinks)
        //
        Rx1: StandardHost {
            @display("p=2300,500;i=device/pc");
        }

        Rx2: StandardHost {
            @display("p=2300,900;i=device/pc");
        }

        Rx3: StandardHost {
            @display("p=2300,1300;i=device/pc");
        }

        //
        // Congestion Monitors for Dynamic Path Switching
        // Monitor queue depth and trigger path changes
        //
        congestionMonitor1: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[3].queue";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 1;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=700,1600;is=s");
        }

        congestionMonitor2: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[4].queue";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 2;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=1000,1600;is=s");
        }

        congestionMonitor3: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[5].queue";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 3;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=1300,1600;is=s");
        }

        //
        // Link Utilization Monitors for Bandwidth-based Path Switching
        // Monitor link bandwidth utilization and trigger path changes
        //
        linkUtilMonitor1: LinkUtilizationMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[3].queue";
                interfaceModule = "^.LER_Ingress.ppp[3]";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 1;
                linkCapacity = 1Gbps;
                utilizationThreshold = 0.8;  // 80%
                lowThreshold = 0.5;          // 50%
                checkInterval = 1s;
                measurementWindow = 5s;
                enabled = true;
                @display("p=700,1700;is=s");
        }

        linkUtilMonitor2: LinkUtilizationMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[4].queue";
                interfaceModule = "^.LER_Ingress.ppp[4]";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 2;
                linkCapacity = 100Mbps;
                utilizationThreshold = 0.8;
                lowThreshold = 0.5;
                checkInterval = 1s;
                measurementWindow = 5s;
                enabled = true;
                @display("p=1000,1700;is=s");
        }

        linkUtilMonitor3: LinkUtilizationMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[5].queue";
                interfaceModule = "^.LER_Ingress.ppp[5]";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 3;
                linkCapacity = 1Gbps;
                utilizationThreshold = 0.8;
                lowThreshold = 0.5;
                checkInterval = 1s;
                measurementWindow = 5s;
                enabled = true;
                @display("p=1300,1700;is=s");
        }

    connections:
        //
        // Host to Edge Router Connections (Access Links)
        //
        Tx1.pppg++ <--> Eth10G <--> LER_Ingress.pppg[0];
        Tx2.pppg++ <--> Eth10G <--> LER_Ingress.pppg[1];
        Tx3.pppg++ <--> Eth10G <--> LER_Ingress.pppg[2];

        Rx1.pppg++ <--> Eth10G <--> LER_Egress.pppg[0];
        Rx2.pppg++ <--> Eth10G <--> LER_Egress.pppg[1];
        Rx3.pppg++ <--> Eth10G <--> LER_Egress.pppg[2];

        //
        // Core Network Connections (Multiple Paths for Redundancy)
        // Path 1: via CoreRouter1 (Primary, high-speed)
        // Path 2: via CoreRouter2 (Backup, medium-speed)
        // Path 3: via CoreRouter3 (Backup, high-speed)
        //
        LER_Ingress.pppg[3] <--> HighSpeedLink <--> CoreRouter1.pppg[0];
        CoreRouter1.pppg[1] <--> HighSpeedLink <--> LER_Egress.pppg[3];

        LER_Ingress.pppg[4] <--> MediumSpeedLink <--> CoreRouter2.pppg[0];
        CoreRouter2.pppg[1] <--> MediumSpeedLink <--> LER_Egress.pppg[4];

        LER_Ingress.pppg[5] <--> LowSpeedLink <--> CoreRouter3.pppg[0];
        CoreRouter3.pppg[1] <--> LowSpeedLink <--> LER_Egress.pppg[5];
}

//
// Extended MPLS Network with Mesh Topology
//
// This network adds:
// - Additional core router for more redundancy
// - Mesh connections between core routers
// - More complex failover scenarios
//
network MPLSMesh
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "ipv4NetworkConfigurator";
        @display("bgb=2800,2000");

    submodules:
        //
        // Management and Visualization
        //
        visualizer: <default(firstAvailableOrEmpty("IntegratedCanvasVisualizer"))> like IIntegratedVisualizer if typename != "" {
            @display("p=100,100;is=s");
        }

        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=300,100;is=s");
        }

        scenarioManager: ScenarioManager {
            @display("p=500,100;is=s");
        }

        //
        // Edge Routers
        //
        LER_Ingress: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4 ppp5 ppp6";
                @display("p=700,1000;i=abstract/router");
            gates:
                pppg[7]; // 0-2: hosts, 3-6: core routers
        }

        LER_Egress: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4 ppp5 ppp6";
                @display("p=2100,1000;i=abstract/router");
            gates:
                pppg[7];
        }

        //
        // Core Routers with Mesh Connectivity
        //
        CoreRouter1: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=1400,600;i=abstract/router2");
            gates:
                pppg[3]; // 0: ingress, 1: egress, 2: mesh
        }

        CoreRouter2: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=1400,1000;i=abstract/router2");
            gates:
                pppg[3];
        }

        CoreRouter3: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=1400,1400;i=abstract/router2");
            gates:
                pppg[3];
        }

        CoreRouter4: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1400,1700;i=abstract/router2");
            gates:
                pppg[2];
        }

        //
        // Hosts
        //
        Tx1: StandardHost {
            @display("p=200,600;i=device/pc");
        }

        Tx2: StandardHost {
            @display("p=200,1000;i=device/pc");
        }

        Tx3: StandardHost {
            @display("p=200,1400;i=device/pc");
        }

        Rx1: StandardHost {
            @display("p=2600,600;i=device/pc");
        }

        Rx2: StandardHost {
            @display("p=2600,1000;i=device/pc");
        }

        Rx3: StandardHost {
            @display("p=2600,1400;i=device/pc");
        }

        //
        // Congestion Monitors
        //
        congestionMonitor1: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[3].queue";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 1;
                highWatermark = 150;
                lowWatermark = 100;
                checkInterval = 0.05s;
                @display("p=700,1800;is=s");
        }

        congestionMonitor2: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[4].queue";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 2;
                highWatermark = 150;
                lowWatermark = 100;
                checkInterval = 0.05s;
                @display("p=1000,1800;is=s");
        }

        congestionMonitor3: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER_Ingress.ppp[5].queue";
                rsvpModule = "^.LER_Ingress.rsvp";
                tunnelId = 3;
                highWatermark = 150;
                lowWatermark = 100;
                checkInterval = 0.05s;
                @display("p=1300,1800;is=s");
        }

    connections:
        //
        // Host Connections
        //
        Tx1.pppg++ <--> Eth10G <--> LER_Ingress.pppg[0];
        Tx2.pppg++ <--> Eth10G <--> LER_Ingress.pppg[1];
        Tx3.pppg++ <--> Eth10G <--> LER_Ingress.pppg[2];

        Rx1.pppg++ <--> Eth10G <--> LER_Egress.pppg[0];
        Rx2.pppg++ <--> Eth10G <--> LER_Egress.pppg[1];
        Rx3.pppg++ <--> Eth10G <--> LER_Egress.pppg[2];

        //
        // Primary Paths
        //
        LER_Ingress.pppg[3] <--> HighSpeedLink <--> CoreRouter1.pppg[0];
        CoreRouter1.pppg[1] <--> HighSpeedLink <--> LER_Egress.pppg[3];

        LER_Ingress.pppg[4] <--> HighSpeedLink <--> CoreRouter2.pppg[0];
        CoreRouter2.pppg[1] <--> HighSpeedLink <--> LER_Egress.pppg[4];

        LER_Ingress.pppg[5] <--> HighSpeedLink <--> CoreRouter3.pppg[0];
        CoreRouter3.pppg[1] <--> HighSpeedLink <--> LER_Egress.pppg[5];

        LER_Ingress.pppg[6] <--> MediumSpeedLink <--> CoreRouter4.pppg[0];
        CoreRouter4.pppg[1] <--> MediumSpeedLink <--> LER_Egress.pppg[6];

        //
        // Mesh Connections Between Core Routers (for additional redundancy)
        //
        CoreRouter1.pppg[2] <--> HighSpeedLink <--> CoreRouter2.pppg[2];
}
