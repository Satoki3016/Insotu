package sotuken.simulations.MPLS;


import inet.networklayer.configurator.ipv4.Ipv4FlatNetworkConfigurator;
import inet.common.scenario.ScenarioManager;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.mpls.RsvpMplsRouter;
import ned.IdealChannel;
import inet.node.ethernet.Eth10M;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.Eth40G;


network RSVPTEori
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "";


        @display("bgb=1549,571");
    submodules:
        LSR1: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ";
                @display("p=360,220");
            gates:
                pppg[5];
        }
        LSR2: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=543,369");
            gates:
                pppg[3];
        }
        LSR3: RsvpMplsRouter {
            peers = "ppp0 ppp1 ppp2";
            @display("p=475,105");
            gates:
                pppg[3];
        }
        LSR4: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=621,224");
            gates:
                pppg[3];
        }
        LSR5: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2 ppp3 ppp4";
                @display("p=874,224");
            gates:
                pppg[5];
        }
        LSR6: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=704,381");
            gates:
                pppg[2];
        }
        LSR7: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=719,106");
            gates:
                pppg[2];
        }
        HighClient: StandardHost { // client
            parameters:
                @display("p=71,121;i=device/pc2");
        }
        MidClient: StandardHost { // client
            parameters:
                @display("p=58,221;i=device/pc2");
        }
        HighServer: StandardHost { // server
            parameters:
                @display("p=1340,90;i=device/server");
        }
        LowServer: StandardHost { // server
            parameters:
                @display("p=1373,445;i=device/server");
        }
        LowClient: StandardHost { // client
            parameters:
                @display("p=58,321;i=device/pc2");
        }
        scenarioManager: ScenarioManager {
            parameters:
                @display("p=99,30;is=s");
        }
        MidServer: StandardHost {
            @display("p=1411,266;i=device/server");
        }
        WiredRouter: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=962,115");
            gates:
                pppg[2];
        }
        ServerRouter: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1205,225");
            gates:
                pppg[5];
        }
        WirelessRouter: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=998,351");
            gates:
                pppg[2];
        }
    connections:
        LSR1.pppg[0] <--> wired <--> LSR2.pppg[0];
        LSR1.pppg[1] <--> wired <--> LSR3.pppg[0];
        MidClient.pppg++ <--> wired <--> LSR1.pppg[2];
        HighClient.pppg++ <--> wired <--> LSR1.pppg[3];
        LSR2.pppg[1] <--> wired <--> LSR4.pppg[0];
        LSR3.pppg[1] <--> wired <--> LSR4.pppg[2];
        LSR4.pppg[1] <--> wired <--> LSR5.pppg[0];
        LSR2.pppg[2] <--> wired <--> LSR6.pppg[0];

        LSR5.pppg[1] <--> wired <--> WiredRouter.pppg[0];
        LSR5.pppg[2] <--> wireless <--> WirelessRouter.pppg[0];

        LSR5.pppg[3] <--> wired <--> LSR6.pppg[1];
        LSR3.pppg[2] <--> wired <--> LSR7.pppg[0];
        LSR5.pppg[4] <--> wired <--> LSR7.pppg[1];
        LowClient.pppg++ <--> wired <--> LSR1.pppg[4];

        ServerRouter.pppg[0] <--> wired <--> WiredRouter.pppg[1];
        ServerRouter.pppg[1] <--> wireless <--> WirelessRouter.pppg[1];
        ServerRouter.pppg[2] <--> wired <--> HighServer.pppg++;
        ServerRouter.pppg[3] <--> wired <--> MidServer.pppg++;
        ServerRouter.pppg[4] <--> wired <--> LowServer.pppg++;

}



