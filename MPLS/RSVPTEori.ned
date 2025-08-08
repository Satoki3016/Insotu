package insotu.simulations.MPLS;

import inet.networklayer.configurator.ipv4.Ipv4FlatNetworkConfigurator;
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

//
// Example network to demonstrate Rsvp-TE.
//
// See the README file in the model directory for scenario description.
//
network RSVPTEori
{
    parameters:
        **.ipv4.configurator.networkConfiguratorModule = "";


        @display("bgb=1088,419");
    submodules:
        LSR1: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=182,221");
            gates:
                pppg[5];
        }
        LSR2: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=282,321");
            gates:
                pppg[3];
        }
        LSR3: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=282,121");
            gates:
                pppg[3];
        }
        LSR4: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1 ppp2";
                @display("p=382,221");
            gates:
                pppg[3];
        }
        LSR5: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp3 ppp4";
                @display("p=582,221");
            gates:
                pppg[5];
        }
        LSR6: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=482,351");
            gates:
                pppg[2];
        }
        LSR7: RsvpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=482,91");
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
                @display("p=1028,47;i=device/server");
        }
        LowServer: StandardHost { // server
            parameters:
                @display("p=1028,351;i=device/server");
        }
        LowClient: StandardHost { // client
            parameters:
                @display("p=58,321;i=device/pc2");
        }
        scenarioManager: ScenarioManager {
            parameters:
                @display("p=99,30;is=s");
        }
        WiredRouter: Router {
            @display("p=704,106");
        }
        WirelessRouter: Router {
            @display("p=710,321");
        }
        ServerRouter: Router {
            @display("p=813,210");
        }
        MidServer: StandardHost {
            @display("p=1028,207;i=device/server");
        }
        ipv4FlatNetworkConfigurator: Ipv4FlatNetworkConfigurator {
            @display("p=652,28");
        }
    connections:
        LSR1.pppg[0] <--> {  delay = 15ms; datarate = 600kbps; } <--> LSR2.pppg[0];
        LSR1.pppg[1] <--> {  delay = 5ms; datarate = 600kbps; } <--> LSR3.pppg[0];
        MidClient.pppg++ <--> {  delay = 10ms; datarate = 600kbps; } <--> LSR1.pppg[2];
        HighClient.pppg++ <--> {  delay = 10ms; datarate = 600kbps; } <--> LSR1.pppg[3];
        LSR2.pppg[1] <--> {  delay = 5ms; datarate = 600kbps; } <--> LSR4.pppg[0];
        LSR3.pppg[1] <--> {  delay = 5ms; datarate = 600kbps; } <--> LSR4.pppg[2];
        LSR4.pppg[1] <--> {  delay = 5ms; datarate = 600kbps; } <--> LSR5.pppg[0];
        LSR5.pppg[1] <--> wired <--> WiredRouter.pppg++;
        LSR5.pppg[2] <--> wireless <--> WirelessRouter.pppg++;
        LSR2.pppg[2] <--> {  delay = 10ms; datarate = 600kbps; } <--> LSR6.pppg[0];
        LSR5.pppg[3] <--> {  delay = 10ms; datarate = 600kbps; } <--> LSR6.pppg[1];
        LSR3.pppg[2] <--> {  delay = 10ms; datarate = 600kbps; } <--> LSR7.pppg[0];
        LSR5.pppg[4] <--> {  delay = 10ms; datarate = 600kbps; } <--> LSR7.pppg[1];
        LowClient.pppg++ <--> {  delay = 10ms; datarate = 600kbps; } <--> LSR1.pppg[4];
        WiredRouter.pppg++ <--> wired <--> ServerRouter.pppg++;
        WirelessRouter.pppg++ <--> wireless <--> ServerRouter.pppg++;
        ServerRouter.pppg++ <--> Eth10M <--> HighServer.pppg++;
        ServerRouter.pppg++ <--> Eth10M <--> MidServer.pppg++;
        ServerRouter.pppg++ <--> Eth10M <--> LowServer.pppg++;
}

