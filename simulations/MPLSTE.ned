package insotu.simulations;

import inet.node.ethernet.Eth10G;
import inet.networklayer.configurator.ipv4.Ipv4FlatNetworkConfigurator;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.WirelessHost;
import inet.node.wireless.AccessPoint;
import insotu.QueueCongestionMonitor;
import insotu.RsvpMplsRouterScriptable;
import insotu.RsvpTeScriptable;
import insotu.simulations.wireless;
import insotu.simulations.wired;
import inet.common.scenario.ScenarioManager;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.mpls.RsvpMplsRouter;
import ned.IdealChannel;
import inet.node.ethernet.Eth10M;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.Eth40G;
import inet.node.contract.INetworkNode;
import inet.physicallayer.wireless.common.contract.packetlevel.IRadioMedium;
import inet.visualizer.contract.IIntegratedVisualizer;

network MPLSTE
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "";
//        @figure[rcvdPkText](type=indicatorText; pos=380,20; anchor=w; font=,18; textFormat="packets received: %g"; initialValue=0);
//        @statistic[packetReceived](source=hostB.app[0].packetReceived; record=figure(count); targetFigure=rcvdPkText);

        @display("bgb=3164,1570");
    submodules:
        visualizer: <default(firstAvailableOrEmpty("IntegratedCanvasVisualizer"))> like IIntegratedVisualizer if typename != "" {
            @display("p=1821,93;is=s");
        }
        LER1: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4";
                @display("p=1065,709");
            gates:
                pppg[5];

        }
        scenarioManager: ScenarioManager {
            parameters:
                @display("p=2287,95;is=s");
        }
        highCongestion: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER1.ppp[3].queue";
                rsvpModule = "^.LER1.rsvp";
                tunnelId = 1;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=982,1299;is=s");
        }
        midCongestion: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER1.ppp[4].queue";
                rsvpModule = "^.LER1.rsvp";
                tunnelId = 2;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=1624,1422;is=s");
        }
//        lowCongestion: QueueCongestionMonitor {
//            parameters:
//                queueModule = "^.LER1.ppp[2].queue";
//                rsvpModule = "^.LER1.rsvp";
//                tunnelId = 3;
//                highWatermark = 30;
//                lowWatermark = 8;
//                checkInterval = 0.05s;
//                @display("p=2218,1299;is=s");
//        }
        Wired: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1624,436");
            gates:
                pppg[2];
        }
        LER2: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4";
                @display("p=2218,709");
            gates:
                pppg[5];
        }
        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=1236,115;is=s");
        }
        MidTx: StandardHost {
            @display("p=317,709");
        }
        MidRx: StandardHost {
            @display("p=2784,709");
        }
        Wireless: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1624,1077");
            gates:
                pppg[2];
        }
        HighTx: StandardHost {
            @display("p=471,297");
        }
        LowTx: StandardHost {
            @display("p=467,1144");
        }
        HighRx: StandardHost {
            @display("p=2677,313");
        }
        LowRx: StandardHost {
            @display("p=2701,1148");
        }
    connections:
        LER1.pppg[3] <--> wired { @display("ls=,2"); } <--> Wired.pppg[0];
        LER2.pppg[3] <--> wired { @display("ls=,2"); } <--> Wired.pppg[1];
        LER1.pppg[4] <--> wireless { @display("ls=,2"); } <--> Wireless.pppg[0];
        Wireless.pppg[1] <--> wireless { @display("ls=,2"); } <--> LER2.pppg[4];
        HighTx.pppg++ <--> Eth10G <--> LER1.pppg[0];
        MidTx.pppg++ <--> Eth10G <--> LER1.pppg[1];
        LowTx.pppg++ <--> Eth10G <--> LER1.pppg[2];
        LER2.pppg[0] <--> Eth10G <--> HighRx.pppg++;
        LER2.pppg[1] <--> Eth10G <--> MidRx.pppg++;
        LER2.pppg[2] <--> Eth10G <--> LowRx.pppg++;
}

network MPLSTE1
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "";
//        @figure[rcvdPkText](type=indicatorText; pos=380,20; anchor=w; font=,18; textFormat="packets received: %g"; initialValue=0);
//        @statistic[packetReceived](source=hostB.app[0].packetReceived; record=figure(count); targetFigure=rcvdPkText);

        @display("bgb=3164,1570");
    submodules:
        visualizer: <default(firstAvailableOrEmpty("IntegratedCanvasVisualizer"))> like IIntegratedVisualizer if typename != "" {
            @display("p=1821,93;is=s");
        }
        LER1: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4";
                @display("p=1065,709");
            gates:
                pppg[5];
        }
        scenarioManager: ScenarioManager {
            parameters:
                @display("p=2287,95;is=s");
        }
        Wired: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1624,436");
            gates:
                pppg[2];
        }
        LER2: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4";
                @display("p=2218,709");
            gates:
                pppg[5];
        }
        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=1236,115;is=s");
        }
        MidTx: StandardHost {
            @display("p=317,709");
        }
        MidRx: StandardHost {
            @display("p=2784,709");
        }
        Wireless: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1624,1077");
            gates:
                pppg[2];
        }
        HighTx: StandardHost {
            @display("p=471,297");
        }
        LowTx: StandardHost {
            @display("p=467,1144");
        }
        HighRx: StandardHost {
            @display("p=2677,313");
        }
        LowRx: StandardHost {
            @display("p=2701,1148");
        }
        highCongestion: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER1.ppp[3].queue";
                rsvpModule = "^.LER1.rsvp";
                tunnelId = 1;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=982,1299;is=s");
        }
        midCongestion: QueueCongestionMonitor {
            parameters:
                queueModule = "^.LER1.ppp[4].queue";
                rsvpModule = "^.LER1.rsvp";
                tunnelId = 2;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=1624,1422;is=s");
        }
    connections:
        LER1.pppg[3] <--> wired { @display("ls=,2"); } <--> Wired.pppg[0];
        LER2.pppg[3] <--> wired { @display("ls=,2"); } <--> Wired.pppg[1];
        LER1.pppg[4] <--> wireless { @display("ls=,2"); } <--> Wireless.pppg[0];
        Wireless.pppg[1] <--> wireless { @display("ls=,2"); } <--> LER2.pppg[4];
        HighTx.pppg++ <--> Eth10G <--> LER1.pppg[0];
        MidTx.pppg++ <--> Eth10G <--> LER1.pppg[1];
        LowTx.pppg++ <--> Eth10G <--> LER1.pppg[2];
        LER2.pppg[0] <--> Eth10G <--> HighRx.pppg++;
        LER2.pppg[1] <--> Eth10G <--> MidRx.pppg++;
        LER2.pppg[2] <--> Eth10G <--> LowRx.pppg++;
}

network Normal
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "ipv4NetworkConfigurator";
//        @figure[rcvdPkText](type=indicatorText; pos=380,20; anchor=w; font=,18; textFormat="packets received: %g"; initialValue=0);
//        @statistic[packetReceived](source=hostB.app[0].packetReceived; record=figure(count); targetFigure=rcvdPkText);

        @display("bgb=3164,1570");
    submodules:
        visualizer: <default(firstAvailableOrEmpty("IntegratedCanvasVisualizer"))> like IIntegratedVisualizer if typename != "" {
            @display("p=1821,93;is=s");
        }
        LER1: Router {
            parameters:
                @display("p=1065,709");
            gates:
                pppg[5];

        }
        scenarioManager: ScenarioManager {
            parameters:
                @display("p=2287,95;is=s");
        }
        Wired: Router {
            parameters:
                @display("p=1624,436");
            gates:
                pppg[2];
        }
        LER2: Router {
            parameters:
                @display("p=2218,709");
            gates:
                pppg[5];
        }
        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=1236,115;is=s");
        }
        MidTx: StandardHost {
            @display("p=317,709");
        }
        MidRx: StandardHost {
            @display("p=2784,709");
        }
        Wireless: Router {
            parameters:
                @display("p=1624,1077");
            gates:
                pppg[2];
        }
        HighTx: StandardHost {
            @display("p=471,297");
        }
        LowTx: StandardHost {
            @display("p=467,1144");
        }
        HighRx: StandardHost {
            @display("p=2677,313");
        }
        LowRx: StandardHost {
            @display("p=2701,1148");
        }
    connections:
        LER1.pppg[3] <--> wired { @display("ls=,2"); } <--> Wired.pppg[0];
        LER2.pppg[3] <--> wired { @display("ls=,2"); } <--> Wired.pppg[1];
        LER1.pppg[4] <--> wireless { @display("ls=,2"); } <--> Wireless.pppg[0];
        Wireless.pppg[1] <--> wireless { @display("ls=,2"); } <--> LER2.pppg[4];
        HighTx.pppg++ <--> Eth10G <--> LER1.pppg[0];
        MidTx.pppg++ <--> Eth10G <--> LER1.pppg[1];
        LowTx.pppg++ <--> Eth10G <--> LER1.pppg[2];
        LER2.pppg[0] <--> Eth10G <--> HighRx.pppg++;
        LER2.pppg[1] <--> Eth10G <--> MidRx.pppg++;
        LER2.pppg[2] <--> Eth10G <--> LowRx.pppg++;
}

network DualLinkMPLS
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "ipv4NetworkConfigurator";
        @display("bgb=2200,1200");
    submodules:
        visualizer: <default(firstAvailableOrEmpty("IntegratedCanvasVisualizer"))> like IIntegratedVisualizer if typename != "" {
            @display("p=1800,100;is=s");
        }
        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=1550,100;is=s");
        }
        scenarioManager: ScenarioManager {
            @display("p=2000,100;is=s");
        }
        TxRouter: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4";
                @display("p=800,680");
            gates:
                pppg[5];
        }
        RxRouter: RsvpMplsRouterScriptable {
            parameters:
                peers = "ppp3 ppp4";
                @display("p=1400,680");
            gates:
                pppg[5];
        }
        highCongestion: QueueCongestionMonitor {
            parameters:
                queueModule = "^.TxRouter.ppp[3].queue";
                rsvpModule = "^.TxRouter.rsvp";
                tunnelId = 1;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=650,980;is=s");
        }
        midCongestion: QueueCongestionMonitor {
            parameters:
                queueModule = "^.TxRouter.ppp[3].queue";
                rsvpModule = "^.TxRouter.rsvp";
                tunnelId = 2;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=800,1030;is=s");
        }
        lowCongestion: QueueCongestionMonitor {
            parameters:
                queueModule = "^.TxRouter.ppp[3].queue";
                rsvpModule = "^.TxRouter.rsvp";
                tunnelId = 3;
                highWatermark = 200;
                lowWatermark = 120;
                checkInterval = 0.05s;
                @display("p=950,1080;is=s");
        }
        HighTx: StandardHost {
            @display("p=200,500");
        }
        MidTx: StandardHost {
            @display("p=200,680");
        }
        LowTx: StandardHost {
            @display("p=200,860");
        }
        HighRx: StandardHost {
            @display("p=2000,500");
        }
        MidRx: StandardHost {
            @display("p=2000,680");
        }
        LowRx: StandardHost {
            @display("p=2000,860");
        }
    connections:
        TxRouter.pppg[3] <--> wired { @display("ls=,2"); } <--> RxRouter.pppg[3];
        TxRouter.pppg[4] <--> wireless { @display("ls=,2"); } <--> RxRouter.pppg[4];
        HighTx.pppg++ <--> Eth10G <--> TxRouter.pppg[0];
        MidTx.pppg++ <--> Eth10G <--> TxRouter.pppg[1];
        LowTx.pppg++ <--> Eth10G <--> TxRouter.pppg[2];
        RxRouter.pppg[0] <--> Eth10G <--> HighRx.pppg++;
        RxRouter.pppg[1] <--> Eth10G <--> MidRx.pppg++;
        RxRouter.pppg[2] <--> Eth10G <--> LowRx.pppg++;
}
