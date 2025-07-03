package insotu;

import inet.common.scenario.ScenarioManager;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.inet.WirelessHost; // 無線ホストを追加 [1]
import inet.node.wireless.AccessPoint; // アクセスポイントを追加 [2]

// 無線通信のための追加インポート
// inet.physicallayer.wireless.common.radio.packetlevel.Radio; // 抽象的なRadioモジュール。具体的な実装は以下
import inet.physicallayer.wireless.ieee80211.packetlevel.Ieee80211Radio; // IEEE 802.11ラジオの具体的な実装 [3]
import inet.physicallayer.wireless.ieee80211.packetlevel.Ieee80211RadioMedium; // IEEE 802.11無線媒体 [3]

import inet.physicallayer.wireless.common.antenna.IsotropicAntenna; // 等方性アンテナ [4]
import inet.mobility.single.RandomWaypointMobility; // モビリティモデル [5]
import inet.physicallayer.wireless.common.pathloss.FreeSpacePathLoss; // パスロスモデル [6]
// import inet.physicallayer.wireless.common.error.StochasticErrorModel; // 汎用エラーモデル（チャネルのコメントで言及）[7]

// QoS関連の追加インポート (ルーター内部で利用されることを想定)
// これらのモジュールは通常、ルーターやホストの内部サブモジュールとして構成されます。
import inet.queueing.queue.PriorityQueue; // 優先度キュー [8]
import inet.networklayer.diffserv.BehaviorAggregateClassifier; // DSCP分類器 [9]
import inet.networklayer.diffserv.DscpMarker; // DSCPマーカー [10]
import inet.queueing.shaper.TimeAwareShaper; // タイムアウェアシェーパー [11]
import inet.queueing.filter.RedDropper; // REDキュー (輻輳制御) [12]

// 既存のインポート
import ned.IdealChannel;
import inet.node.ethernet.Eth10M;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.Eth40G;
import ned.DatarateChannel;
import inet.common.misc.ThruputMeteringChannel; // スループット計測チャネル [13]


network Insotu1
{
    parameters:
        // 無線通信のための環境設定
        @display("bgb=1000,1000,white; bgt=Enhanced Network Simulation"); // 背景とタイトルを設定 [14]
    types:
        // 有線チャネルのプロパティ (既存の定義を維持)
        channel WirelessLink extends DatarateChannel
        {
            parameters:
                datarate = 100Mbps; // データレートを設定 [15]
                delay = 100ms; // 遅延を設定 [15]
                @display("ls=blue,3"); // 表示設定（青線、太さ3） [14]
                // 概念的なビットエラー率の追加。 [14]
                // DatarateChannel自体は通常完璧なチャネルであるため、このパラメータは示唆的です。 [14]
                // 実際にエラーを発生させるには、通常ノードの物理層モジュールで [14]
                // StochasticErrorModelなどのエラーモデルを設定するか、 [14]
                // より複雑なCompoundChannelを定義する必要があります。 [14]
                double bitErrorRate = default(1e-9); // 例: 10億分の1のビットエラー率 [14]
        }
        channel OpticalLikeWiredChannel extends DatarateChannel
        {
            parameters:
                delay = 1us; // 光ファイバーのような低遅延 [16]
                datarate = 100Gbps; // 超高速データレート [16]
                ber = default(1e-12); // 非常に低いビットエラー率 [16]
                @display("ls=orange,2"); // 表示設定（オレンジ色の線、太さ2）
        }

    submodules:
        scenarioManager: ScenarioManager;
        configurator: Ipv4NetworkConfigurator;
        // 無線通信のための無線媒体モジュール
        // 既存の`channel wireless`の代わりに、共有媒体としてネットワーク内に配置されます。
        radioMedium: Ieee80211RadioMedium { // IEEE 802.11に特化した媒体モデル [3, 14]
            parameters:
                @display("p=500,500;i=misc/cloud;r=200"); // 媒体のアイコンと範囲表示 [17, 18]
                
                backgroundNoise.power = -100dBm; // 背景ノイズの電力 [18, 19]
                pathLoss.typename = "FreeSpacePathLoss"; // 自由空間パスロスモデル [6, 18]
                // より詳細なモデル:
                // shadowing.typename = "LogNormalShadowing"; // シャドウイング効果を有効化 [6, 18]
                // fading.typename = "RayleighFading"; // レイリーフェージング効果を有効化 [18, 20]
        }

        // ノードの定義 (既存のルーターとホスト)
        ClientRouter: Router {
            parameters:
                @display("p=200,500;i=abstract/router"); // ルーターアイコン [18, 21]
                // QoS機能の設定例（通常は.iniファイルで詳細設定、またはカスタムルーターモジュールで定義）： [22]
                // 各インターフェースのキューイング規律を変更する例。 [22]
                // 例: ethgのMAC層の送信キューをPriorityQueueに設定
                // eth.mac.queue.typename = "inet.queueing.queue.PriorityQueue"; [8, 22]
                // eth.mac.queue.numQueues = 4; // 優先度キューの数 [22]
                // eth.mac.classifier.typename = "inet.networklayer.diffserv.BehaviorAggregateClassifier"; [9, 22]
                // eth.mac.classifier.dscpToQueueMap = "0-7:0; 8-15:1; 16-23:2; 24-63:3"; // DSCPとキューのマッピング [22]
                // eth.mac.marker.typename = "inet.networklayer.diffserv.DscpMarker"; [10, 22] // パケットをDSCPでマーク
        }

        ServerRouter: Router {
            parameters:
                @display("p=800,500;i=abstract/router"); // ルーターアイコン [21, 22]
        }

        // 高速有線接続用ホスト (変更なし)
        HighClient: StandardHost {
            parameters:
                @display("p=100,200;i=device/laptop"); // ノートPCアイコン [23, 24]
        }

        HighSever: StandardHost {
            parameters:
                @display("p=900,200;i=device/server"); // サーバーアイコン [24, 25]
        }

        // 無線LANアクセスポイント (元々のWirelessRouterの役割を代替)
        // AccessPointは、無線クライアントと有線ネットワーク間の接続点となります。
        WirelessAP: AccessPoint {
            parameters:
                @display("p=500,800;i=device/accesspoint"); // アクセスポイントアイコン [24, 26]
                wlan.radio.antenna.typename = "IsotropicAntenna"; // 等方性アンテナを使用 [4, 24]
                wlan.radio.typename = "inet.physicallayer.wireless.ieee80211.packetlevel.Ieee80211Radio"; // IEEE 802.11ラジオ [3, 24]
                // 無線MAC層でのQoS (IEEE 802.11e EDCAなど) の設定例:
                // wlan.mac.channelAccess.typename = "inet.linklayer.ieee80211.mac.channelaccess.Edca"; [27, 28]
        }

        // 無線クライアントホスト (モビリティ機能付き)
        WirelessClientHost: WirelessHost {
            parameters:
                @display("p=500,200;i=device/cellphone"); // 携帯電話アイコン [28, 29]
                // モビリティの追加 [5, 28]
                mobility.typename = "RandomWaypointMobility"; // ランダムウェイポイントモビリティ [5, 28]
                mobility.initialX = 400m;
                mobility.initialY = 400m;
                mobility.initialZ = 0m;
                mobility.maxX = 600m;
                mobility.maxY = 600m;
                mobility.maxSpeed = 5mps; // 移動速度 [28]
        }

    connections:
        // 既存の有線接続
        HighClient.ethg++ <--> Eth100M <--> ClientRouter.ethg++; // [30]
        HighSever.ethg++ <--> Eth100M <--> ServerRouter.ethg++; // [30]

        // 既存の`wired`チャネルの代わりに`OpticalLikeWiredChannel`を使用し、
        // より詳細な物理層特性（遅延、データレート、概念的なビットエラー率）を考慮 [16]
        ClientRouter.ethg++ <--> OpticalLikeWiredChannel {  datarate = 1Gbps; ber = 1e-8; } <--> ServerRouter.ethg++;

        // 無線通信リンク
        // AccessPointとWirelessClientHostの間の通信は、直接チャネルではなく、
        // 共有の`radioMedium`を介して行われます。
        // 各ノードの`wlan.radio`モジュールの送受信ゲートを無線媒体の適切なゲートに接続します。
        // radioMediumにはinoutのベクターゲート radioIn[] と radioOut[] が存在します。 [31]
        // ++ 演算子を使用すると、自動的に新しいインデックスが割り当てられます。

        //radioMedium.radioOut++ --> WirelessClientHost.radioIn; // 無線信号の受信 [31, 32]
        //WirelessClientHost.wlan.radio.radioOut --> radioMedium.radioIn++;
       
       // radioMedium.radioOut++ --> WirelessAP.radioIn; // 無線信号の受信 [31, 32]
        //WirelessAP.wlan.radio.radioOut --> radioMedium.radioIn++;

        // アクセスポイントを既存の有線ネットワークに接続
        // WirelessAP.ethg はベクターゲートなので、インデックスが必要です。通常は ethg を使用します。
        // ClientRouter.ethg もベクターゲートです。既存の使用状況 (ethgとethg[1]は別の接続で使用) を考慮し、
        // 次の利用可能なゲートとして ethg[2] を使用します。
        WirelessAP.ethg++ <--> Eth100M <--> ClientRouter.ethg++; // Eth100Mチャネルを使用 [16, 30]

}
