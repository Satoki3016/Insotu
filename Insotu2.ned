
package insotu;

import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import ned.IdealChannel;
import inet.common.misc.ThruputMeteringChannel;
import simu5g.nodes.Ue;
import simu5g.nodes.NR.gNodeB;
import simu5g.apps.cbr.CbrSender;
import simu5g.apps.cbr.CbrReceiver;


//
// TODO auto-generated type
//
network Insotu2
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
        WiredRouter: Router {
            @display("p=364,118");
        }
        WirelessRouter: Router {
            @display("p=364,285");
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
        ServerRouter: Router {
            @display("p=472,203");
        }
        ClientRouter: Router {
            @display("p=257,203");
        }
        gnb: gNodeB {
            @display("p=241,365");
        }

        ue: Ue {
            @display("p=326,365");
        }


    connections:
        HighServer.ethg++ <--> IdealChannel <--> ServerRouter.ethg++;
        MidServer.ethg++ <--> IdealChannel <--> ServerRouter.ethg++;
        LowServer.ethg++ <--> IdealChannel <--> ServerRouter.ethg++;
        ServerRouter.ethg++ <--> wired <--> WiredRouter.ethg++;
        WiredRouter.ethg++ <--> wired <--> ClientRouter.ethg++;
        ClientRouter.ethg++ <--> IdealChannel <--> HighClient.ethg++;
        ClientRouter.ethg++ <--> IdealChannel <--> MidClient.ethg++;
        ClientRouter.ethg++ <--> IdealChannel <--> LowClient.ethg++;
        ServerRouter.ethg++ <--> wireless <--> WirelessRouter.ethg++;
        WirelessRouter.ethg++ <--> wireless <--> ClientRouter.ethg++;
}
