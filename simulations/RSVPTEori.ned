package insotu.simulations;


import inet.networklayer.configurator.ipv4.Ipv4FlatNetworkConfigurator;
import inet.common.scenario.ScenarioManager;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import ned.IdealChannel;
import inet.node.ethernet.Eth10M;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.Eth40G;


network RSVPTEori
{
    @display("bgb=1088,419");
    submodules:
        LSR1: Router {
            @display("p=188,220");
            gates:
                pppg[5];
        }
        LSR2: Router {
            @display("p=272,351");
            gates:
                pppg[3];
        }
        LSR3: Router {
            @display("p=272,120");
            gates:
                pppg[3];
        }
        LSR4: Router {
            @display("p=397,220");
            gates:
                pppg[3];
        }
        LSR5: Router {
            @display("p=568,220");
            gates:
                pppg[5];
        }
        LSR6: Router {
            @display("p=482,359");
            gates:
                pppg[2];
        }
        LSR7: Router {
            @display("p=482,100");
            gates:
                pppg[2];
        }
        HighClient: StandardHost { // client
            parameters:
                @display("p=71,105;i=device/pc2");
        }
        MidClient: StandardHost { // client
            parameters:
                @display("p=48,220;i=device/pc2");
        }
        HighServer: StandardHost { // server
            parameters:
                @display("p=1028,53;i=device/server");
        }
        LowServer: StandardHost { // server
            parameters:
                @display("p=1028,333;i=device/server");
        }
        LowClient: StandardHost { // client
            parameters:
                @display("p=48,332;i=device/pc2");
        }
        scenarioManager: ScenarioManager {
            parameters:
                @display("p=99,30;is=s");
        }
        MidServer: StandardHost {
            @display("p=1028,205;i=device/server");
        }
        WiredRouter: Router {
            @display("p=721,143");
            gates:
                pppg[2];
        }
        ServerRouter: Router {
            @display("p=861,205");
            gates:
                pppg[5];
        }
        WirelessRouter: Router {
            @display("p=721,308");
            gates:
                pppg[2];
        }
        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=829,46");
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



