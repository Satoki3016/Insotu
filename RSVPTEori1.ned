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


network RSVPTEori1
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "";


        @display("bgb=2824,1224");
    submodules:
        LSR1: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ";
                @display("p=761,629");
            gates:
                pppg[3];
        }
        LSR2: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=936,900");
            gates:
                pppg[3];
        }
        LSR3: RsvpMplsRouter {
            peers = "ppp0 ppp1 ppp2";
            @display("p=936,443");
            gates:
                pppg[3];
        }
        LSR4: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=1130,637");
            gates:
                pppg[3];
        }
        LSR5: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2 ppp3 ppp4";
                @display("p=1658,636");
            gates:
                pppg[5];
        }
        LSR6: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1373,900");
            gates:
                pppg[2];
        }
        LSR7: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1357,443");
            gates:
                pppg[2];
        }
        HighClient: StandardHost { // client
            parameters:
                @display("p=205,296;i=device/pc2");
        }
        MidClient: StandardHost { // client
            parameters:
                @display("p=183,629;i=device/pc2");
        }
        HighServer: StandardHost { // server
            parameters:
                @display("p=2486,385;i=device/server");
        }
        LowServer: StandardHost { // server
            parameters:
                @display("p=2489,994;i=device/server");
        }
        LowClient: StandardHost { // client
            parameters:
                @display("p=183,994;i=device/pc2");
        }
        scenarioManager: ScenarioManager {
            parameters:
                @display("p=764,163;is=s");
        }
        MidServer: StandardHost {
            @display("p=2486,631;i=device/server");
        }
        WiredRouter: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1880,335");
            gates:
                pppg[2];
        }
        ServerRouter: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=2101,629");
            gates:
                pppg[5];
        }
        WirelessRouter: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=1877,898");
            gates:
                pppg[2];
        }
        ClientRouter: Router {
            @display("p=498,629");
            gates:
                pppg[4];
        }
    connections:
        LSR1.pppg[0] <--> wired { @display("ls=,2"); } <--> LSR2.pppg[0];
        LSR1.pppg[1] <--> wired { @display("ls=,2"); } <--> LSR3.pppg[0];
        LSR2.pppg[1] <--> wired { @display("ls=,2"); } <--> LSR4.pppg[0];
        LSR3.pppg[1] <--> wired { @display("ls=,2"); } <--> LSR4.pppg[2];
        LSR4.pppg[1] <--> wired { @display("ls=,2"); } <--> LSR5.pppg[0];
        LSR2.pppg[2] <--> wired { @display("ls=,2"); } <--> LSR6.pppg[0];

        LSR5.pppg[1] <--> wired { @display("ls=,2"); } <--> WiredRouter.pppg[0];
        LSR5.pppg[2] <--> wireless { @display("ls=,2"); } <--> WirelessRouter.pppg[0];

        LSR5.pppg[3] <--> wired { @display("ls=,2"); } <--> LSR6.pppg[1];
        LSR3.pppg[2] <--> wired { @display("ls=,2"); } <--> LSR7.pppg[0];
        LSR5.pppg[4] <--> wired { @display("ls=,2"); } <--> LSR7.pppg[1];
        ServerRouter.pppg[0] <--> wired { @display("ls=,2"); } <--> WiredRouter.pppg[1];
        ServerRouter.pppg[1] <--> wireless { @display("ls=,2"); } <--> WirelessRouter.pppg[1];
        ServerRouter.pppg[2] <--> wireless { @display("ls=,2"); } <--> HighServer.pppg++;
        ServerRouter.pppg[3] <--> wireless { @display("ls=,2"); } <--> MidServer.pppg++;
        ServerRouter.pppg[4] <--> wireless { @display("ls=,2"); } <--> LowServer.pppg++;

        MidClient.pppg++ <--> wireless { @display("ls=,2"); } <--> ClientRouter.pppg[0];
        HighClient.pppg++ <--> wireless { @display("ls=,2"); } <--> ClientRouter.pppg[1];
        LowClient.pppg++ <--> wireless { @display("ls=,2"); } <--> ClientRouter.pppg[2];
        ClientRouter.pppg[3] <--> wired { @display("ls=,2"); } <--> LSR1.pppg[2];
}



