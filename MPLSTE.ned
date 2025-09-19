package insotu.simulations;

import inet.node.ethernet.Eth10G;
import inet.networklayer.configurator.ipv4.Ipv4FlatNetworkConfigurator;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.WirelessHost;
import inet.node.wireless.AccessPoint;
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
        LER1: RsvpMplsRouter {
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
        Wired: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1624,436");
            gates:
                pppg[2];
        }
        LER2: RsvpMplsRouter {
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
        Wireless: RsvpMplsRouter {
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

