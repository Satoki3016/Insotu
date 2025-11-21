//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

package insotu.simulations;

import inet.common.scenario.ScenarioManager;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.mpls.LdpMplsRouter;
import ned.IdealChannel;
import inet.node.ethernet.Eth10M;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.Eth40G;
import ned.DatarateChannel;
import sotuken.CustomUdpApp;
import inet.common.misc.ThruputMeteringChannel;
//
// TODO auto-generated type
//
network Insotu
{
    types:
        channel wired extends ThruputMeteringChannel
        {
            double length @unit(km) = 100km;  // 距離 100km
            delay = (length * 10^3) * (3/2)/ 299792458m * 1s;  // 光ファイバーの遅延計算
            datarate = 100Gbps;  // データレート 
            @display("ls=blue"); // 表示設定（青線）
            thruputDisplayFormat = "#N";
        }
        //channel wireless extends DynamicChannel
        channel wireless extends ThruputMeteringChannel
        {
            double length @unit(km) = 1km;  // 距離 1km
            delay = (length * 10^3) / 299792458m * 1s;  // 遅延計算
            datarate = 100Mbps;//ned.DatarateChannel時に使用
            @display("ls=red"); // 表示設定（赤線）
            thruputDisplayFormat = "#N";
        }

    submodules:
        MidServer: StandardHost {
            @display("p=610,203");
        }
        HighServer: StandardHost {
            @display("p=604,85");
        }
        LowServer: StandardHost {
            @display("p=610,307");
        }
        HighClient: StandardHost {
            @display("p=101,85");
        }
        MidClient: StandardHost {
            @display("p=101,203");
        }
        LowClient: StandardHost {
            @display("p=101,307");
        }
        WiredRouter: LdpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=351,114");
            gates:
                pppg[2];
        }
        WirelessRouter: LdpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=351,295");
            gates:
                pppg[2];
        }
        ClientRouter: LdpMplsRouter {
            parameters:
                peers = "ppp0 ppp1";
                @display("p=243,203");
            gates:
                pppg[5];
        }
        ServerRouter: LdpMplsRouter {
            parameters:
                peers = "ppp1 ppp2";
                @display("p=460,203");
            gates:
                pppg[5];
        }
        ipv4NetworkConfigurator: Ipv4NetworkConfigurator {
            @display("p=382,40");
        }
        scenarioManager: ScenarioManager {
            @display("p=527,36");
        }

    connections:
        HighServer.pppg++ <--> Eth10M <--> ServerRouter.pppg[0];
        WiredRouter.pppg[0] <--> wired <--> ServerRouter.pppg[1];
        WirelessRouter.pppg[0] <--> wireless <--> ServerRouter.pppg[2];
        MidServer.pppg++ <--> Eth10M <--> ServerRouter.pppg[3];
        LowServer.pppg++ <--> Eth10M <--> ServerRouter.pppg[4];
        WiredRouter.pppg[1] <--> wired <--> ClientRouter.pppg[0];
        WirelessRouter.pppg[1] <--> wireless <--> ClientRouter.pppg[1];
        HighClient.pppg++ <--> Eth10M <--> ClientRouter.pppg[2];
        MidClient.pppg++ <--> Eth10M <--> ClientRouter.pppg[3];
        LowClient.pppg++ <--> Eth10M <--> ClientRouter.pppg[4];
}
