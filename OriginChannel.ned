package sotuken.simulations.MPLS;
import inet.node.ethernet.EthernetLink;
import inet.common.misc.ThruputMeteringChannel;

channel Eth10M extends EthernetLink
{
     datarate = 10Mbps;
}

channel C extends ThruputMeteringChannel
{
    datarate = 40Gbps;
    thruputDisplayFormat = "#N";
}
channel wired extends ThruputMeteringChannel
{
    double length @unit(km) = 1km;  // 距離 100km
    delay = (length * 10^3) * (3/2)/ 299792458m * 1s;  // 光ファイバーの遅延計算
    datarate = 100Mbps;  // データレート 
    @display("ls=red"); // 表示設定（青線）
    thruputDisplayFormat = "#N";
}
//channel wireless extends DynamicChannel
channel wireless extends ThruputMeteringChannel
{
    double length @unit(km) = 1m;  // 距離 1km
    delay = (length * 10^3) / 299792458m * 1s;  // 遅延計算
    datarate = 1Mbps;//ned.DatarateChannel時に使用 
    @display("ls=blue"); // 表示設定（赤線）
    thruputDisplayFormat = "#N";
}
