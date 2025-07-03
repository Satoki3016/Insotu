package insotu;

import inet.common.scenario.ScenarioManager;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.ospfv2.OspfRouter;
import ned.IdealChannel;
import inet.node.ethernet.Eth10M;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.Eth40G;
import ned.DatarateChannel;
import inet.common.misc.ThruputMeteringChannel;

//
// TODO auto-generated type
simple DatarateController
{
}

network Insotu
{
    types:
        channel C extends ThruputMeteringChannel
        {
            datarate = 40Gbps;
            thruputDisplayFormat = "#N";
        }
        channel wired extends ThruputMeteringChannel
        {
            double length @unit(km) = 100km; // 距離 100km
            delay = (length * 10^3) * (3/2)/ 299792458m * 1s; // 光ファイバーの遅延計算
            datarate = 1Gbps; // データレート
            @display("ls=blue"); // 表示設定（青線）
            thruputDisplayFormat = "#N";
        }
        //channel wireless extends DynamicChannel
        channel wireless extends ThruputMeteringChannel
        {
            double length @unit(km) = 1km; // 距離 1km
            delay = (length * 10^3) / 299792458m * 1s; // 遅延計算
            datarate = 100Mbps;//ned.DatarateChannel時に使用
            @display("ls=red"); // 表示設定（赤線）
            thruputDisplayFormat = "#N";
        }

    submodules:
        configurator: Ipv4NetworkConfigurator {
            @display("p=64,76");
        }
        VideoClient: StandardHost {
            @display("p=195,274");
        }
        VideoServer: StandardHost {
            @display("p=625,274");
        }
        WiredDummyClient: StandardHost {
            @display("p=170,165");
        }
        WiredDummyServer: StandardHost {
            @display("p=645,165");
        }
        ClientRouter: Router {
            @display("p=311,165");
        }
        ServerRouter: Router {
            @display("p=490,165");
        }
        WiredRouter: Router {
            @display("p=410,76");
        }
        WirelessRouter: Router {
            @display("p=407,239");
        }
        WirelessDummyServer: StandardHost {
            @display("p=625,37");
        }
        WirelessDummyClient: StandardHost {
            @display("p=195,37");
        }
        scenarioManager: ScenarioManager {
            @display("p=53,217");
        }
    connections:
        VideoClient.ethg++ <--> C <--> ClientRouter.ethg++;
        VideoServer.ethg++ <--> C <--> ServerRouter.ethg++;
        WiredDummyClient.ethg++ <--> wired <--> ClientRouter.ethg++;
        WiredDummyServer.ethg++ <--> wired <--> ServerRouter.ethg++;
        ClientRouter.ethg++ <--> wired <--> WiredRouter.ethg++;
        ServerRouter.ethg++ <--> wired <--> WiredRouter.ethg++;
        ServerRouter.ethg++ <--> wireless <--> WirelessRouter.ethg++;
        WirelessDummyClient.ethg++ <--> C <--> WirelessRouter.ethg++;
}

network Insotu22
{
    types:
        channel line extends ThruputMeteringChannel
        {
            delay = 0s;
            datarate = 0bps;
        }
        //channel wireless extends DynamicChannel
        channel wireless extends ThruputMeteringChannel
        {
            double length @unit(km) = 1km; // 距離 1km
            delay = (length * 10^3) / 299792458m * 1s; // 遅延計算
            datarate = 10Mbps;//ned.DatarateChannel時に使用
            @display("ls=red"); // 表示設定（赤線）
            thruputDisplayFormat = "#N";
        }
        channel wired extends ThruputMeteringChannel
        {
            double length @unit(km) = 100km; // 距離 100km
            delay = (length * 10^3) * (3/2)/ 299792458m * 1s; // 光ファイバーの遅延計算
            datarate = 1Gbps; // データレート
            @display("ls=blue"); // 表示設定（青線）
            thruputDisplayFormat = "#N";
        }

    submodules:
        configurator: Ipv4NetworkConfigurator {
            @display("p=64,76");
        }
        VideoClient: StandardHost {
            @display("p=195,274");
        }
        VideoServer: StandardHost {
            @display("p=625,274");
        }
        WiredDummyClient: StandardHost {
            @display("p=170,165");
        }
        WiredDummyServer: StandardHost {
            @display("p=645,165");
        }
        ClientRouter: OspfRouter {
            @display("p=311,165");
        }
        ServerRouter: OspfRouter {
            @display("p=490,165");
        }
        WiredRouter: OspfRouter {
            @display("p=410,76");
        }
        WirelessRouter: OspfRouter {
            @display("p=407,239");
        }
        WirelessDummyServer: StandardHost {
            @display("p=625,37");
        }
        WirelessDummyClient: StandardHost {
            @display("p=195,37");
        }
        scenarioManager: ScenarioManager {
            @display("p=53,217");
        }
    connections:
        VideoClient.ethg++ <--> Eth40G <--> ClientRouter.ethg++;
        VideoServer.ethg++ <--> Eth40G <--> ServerRouter.ethg++;
        WiredDummyClient.ethg++ <--> wired <--> ClientRouter.ethg++;
        WiredDummyServer.ethg++ <--> wired <--> ServerRouter.ethg++;
        ClientRouter.ethg++ <--> wired <--> WiredRouter.ethg++;
        ServerRouter.ethg++ <--> wired <--> WiredRouter.ethg++;
        ClientRouter.ethg++ <--> wireless <--> WirelessRouter.ethg++;
        ServerRouter.ethg++ <--> wireless <--> WirelessRouter.ethg++;
        WirelessDummyClient.ethg++ <--> Eth40G <--> ClientRouter.ethg++;
}

network Insotu3
{
    parameters:
        @display("bgb=748,320");
    types:
        channel C extends ThruputMeteringChannel
        {
            datarate = 40Gbps;
            thruputDisplayFormat = "#N";
        }
        channel wired extends ned.DatarateChannel
        {
            double length @unit(km) = 100km; // 距離 100km
            delay = (length * 10^3) * (3/2)/ 299792458m * 1s; // 光ファイバーの遅延計算
            datarate = 100Mbps; // データレート
            @display("ls=blue"); // 表示設定（青線）
        }
        //channel wireless extends DynamicChannel
        channel wireless extends ned.DatarateChannel
        {
            double length @unit(km) = 1km; // 距離 1km
            delay = (length * 10^3) / 299792458m * 1s; // 遅延計算
            datarate = 10Mbps;//ned.DatarateChannel時に使用
            @display("ls=red"); // 表示設定（赤線）
        }

    submodules:
        configurator: Ipv4NetworkConfigurator {
            @display("p=64,76");
        }
        VideoClient: StandardHost {
            @display("p=195,274");
        }
        VideoServer: StandardHost {
            @display("p=625,274");
        }
        WiredDummyClient: StandardHost {
            @display("p=170,165");
        }
        WiredDummyServer: StandardHost {
            @display("p=645,165");
        }
        ClientRouter: Router {
            @display("p=311,165");
        }
        ServerRouter: Router {
            @display("p=490,165");
        }
        WiredRouter: Router {
            @display("p=410,76");
        }
        WirelessRouter: Router {
            @display("p=407,239");
        }
        WirelessDummyServer: StandardHost {
            @display("p=625,37");
        }
        WirelessDummyClient: StandardHost {
            @display("p=195,37");
        }
        scenarioManager: ScenarioManager {
            @display("p=41,222");
        }
    connections:
        VideoClient.ethg++ <--> C <--> ClientRouter.ethg++;
        VideoServer.ethg++ <--> C <--> ServerRouter.ethg++;
        WiredDummyClient.ethg++ <--> C <--> ClientRouter.ethg++;
        WiredDummyServer.ethg++ <--> C <--> ServerRouter.ethg++;
        ClientRouter.ethg++ <--> WiredRouter.ethg++;
        ServerRouter.ethg++ <--> WiredRouter.ethg++;
        ServerRouter.ethg++ <--> WirelessRouter.ethg++;
        WirelessDummyClient.ethg++ <--> C <--> WirelessRouter.ethg++;
}
