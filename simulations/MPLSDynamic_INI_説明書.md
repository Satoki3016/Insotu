# MPLSDynamic.ini 使用説明書

## 概要
このファイルは、MPLS-TE（Traffic Engineering）とRSVP-TEを使用した動的ルーティングシミュレーションの設定ファイルです。リンク障害検出、輻輳回避、動的経路切り替え機能を実装しています。

---

## ファイル構成

### 1. 設定セクション（Config）の階層構造

```
[Config MPLSCommon]           # MPLS共通設定（抽象）
    ↓
[Config ApplicationsCommon]   # アプリケーション共通設定（抽象）
    ↓
[Config MPLSDynamicBase]      # MPLSDynamicネットワーク基本設定（抽象）
    ↓
[Config MPLSDynamic_Test1]           # 具体的なテストケース1
[Config MPLSDynamic_Congestion]      # 輻輳テスト
[Config MPLSDynamic_MultipleFailures]# 多重障害テスト
```

---

## 主要設定セクションの説明

### [Config MPLSCommon]（9-66行目）
**用途**: MPLS関連の基本設定を定義する抽象設定

#### 重要なパラメータ

##### MPLS基本設定
```ini
**.ipv4.configurator.networkConfiguratorModule = ""
```
- NetworkConfiguratorを無効化（手動ルーティングを使用）

##### トラフィック分類（DiffServ）
```ini
**.ppp[*].ingressTC.typename = "TC1"
**.ingressTC.numClasses = 3
**.ingressTC.classifier.filters = xmldoc("MPLSDynamic_filters.xml")
**.ingressTC.marker.dscps = "EF AF41 AF42"
```
- **TC1**: トラフィック分類器のタイプ
- **numClasses**: 3つの優先度クラス（高・中・低）
- **filters**: パケット分類ルール（XMLファイル）
- **dscps**: DiffServコードポイント
  - **EF (Expedited Forwarding)**: 高優先度
  - **AF41 (Assured Forwarding 41)**: 中優先度
  - **AF42 (Assured Forwarding 42)**: 低優先度

##### キュー設定
```ini
**.LER*.ppp[*].queue.typename = "DSQueue1"
**.CoreRouter*.ppp[*].queue.typename = "DSQueue1"
**.LER*.ppp[*].queue.packetCapacity = -1
**.LER*.ppp[*].queue.wrr.weights = "5 4 3 2 1"
```
- **DSQueue1**: DiffServ対応キュー
- **packetCapacity = -1**: 無制限（バイト制限のみ）
- **wrr.weights**: Weighted Round Robin重み（優先度順）

##### RSVP-TE設定
```ini
**.LER*.rsvp.typename = "insotu.RsvpTeScriptable"
**.CoreRouter*.rsvp.typename = "insotu.RsvpTeScriptable"
**.LER*.classifier.typename = "insotu.RsvpClassifierScriptable"
```
- カスタムRSVP-TE実装を使用（動的経路切り替え対応）

##### 高速障害検出
```ini
**.LER*.rsvp.helloInterval = 0.1s
**.LER*.rsvp.helloTimeout = 0.4s
```
- **helloInterval**: Hello メッセージ送信間隔（0.1秒）
- **helloTimeout**: タイムアウト時間（0.4秒）
- 障害検出時間: 最大0.4秒

##### 統計記録
```ini
**.app[*].packetSent:vector.result-recording-modes = -
**.app[*].packetReceived:vector.result-recording-modes = -
**.app[*].throughput:vector.result-recording-modes = +vector
**.app[*].rcvdPkLifetime:vector.result-recording-modes = +vector
```
- パケットオブジェクトの記録は無効（型変換エラー回避）
- スループットとパケット寿命のみベクトル記録

---

### [Config ApplicationsCommon]（70-109行目）
**用途**: アプリケーション層の設定

#### トラフィックパターン

##### Tx1 → Rx1（高優先度トラフィック）
```ini
**.Tx1.app[0].typename = "UdpBasicApp"
**.Tx1.app[0].localPort = 1000
**.Tx1.app[0].destPort = 1000
**.Tx1.app[0].messageLength = 1400 bytes
**.Tx1.app[0].sendInterval = 2ms
**.Tx1.app[0].destAddresses = "10.2.1.2"
**.Tx1.app[0].packetName = "HighPriority"
```
- **帯域幅**: 1400 bytes × (1/0.002s) = 700 KB/s = 5.6 Mbps
- **ポート**: 1000（高優先度識別用）
- **宛先**: Rx1 (10.2.1.2)

##### Tx2 → Rx2（中優先度トラフィック）
```ini
**.Tx2.app[0].messageLength = 1000 bytes
**.Tx2.app[0].sendInterval = 5ms
**.Tx2.app[0].destAddresses = "10.2.2.2"
```
- **帯域幅**: 1000 bytes × (1/0.005s) = 200 KB/s = 1.6 Mbps
- **ポート**: 2000（中優先度識別用）
- **宛先**: Rx2 (10.2.2.2)

##### Tx3 → Rx3（低優先度トラフィック）
```ini
**.Tx3.app[0].messageLength = 800 bytes
**.Tx3.app[0].sendInterval = 10ms
**.Tx3.app[0].destAddresses = "10.2.3.2"
```
- **帯域幅**: 800 bytes × (1/0.01s) = 80 KB/s = 0.64 Mbps
- **ポート**: 3000（低優先度識別用）
- **宛先**: Rx3 (10.2.3.2)

---

### [Config MPLSDynamicBase]（114-173行目）
**用途**: MPLSDynamicネットワークの基本設定

#### ネットワーク設定
```ini
network = insotu.simulations.MPLSDynamic
sim-time-limit = 60s
```
- シミュレーション時間: 60秒

#### NetworkConfigurator完全無効化
```ini
*.ipv4NetworkConfigurator.config = xmldoc("empty.xml")
*.ipv4NetworkConfigurator.addStaticRoutes = false
*.ipv4NetworkConfigurator.addDefaultRoutes = false
*.ipv4NetworkConfigurator.addSubnetRoutes = false
*.ipv4NetworkConfigurator.optimizeRoutes = false
```
- **重要**: 全ての自動設定を無効化
- 手動設定（.rtファイル）を使用

#### RouterID設定（重要）
```ini
*.LER_Ingress.routerId = "10.1.3.1"
*.LER_Egress.routerId = "10.2.10.1"
*.CoreRouter1.routerId = "10.1.3.2"
*.CoreRouter2.routerId = "10.1.4.2"
*.CoreRouter3.routerId = "10.1.5.2"
```
**注意事項**:
- **routerIDは必ずそのルータの実際のインターフェースアドレスの1つと一致させる必要があります**
- これはRSVP-TEがrouterIDを使ってネットワークインターフェースを特定するためです
- 例: LER_IngressのrouterID `10.1.3.1`は、ppp[3]のアドレスと同じ

#### RSVP-TE Peers設定
```ini
**.LER_Ingress.peers = "ppp3 ppp4 ppp5"
**.CoreRouter1.peers = "ppp0 ppp1"
**.CoreRouter2.peers = "ppp0 ppp1"
**.CoreRouter3.peers = "ppp0 ppp1"
**.LER_Egress.peers = "ppp3 ppp4 ppp5"
```
- **peers**: RSVP対応ルータに接続されているインターフェースのみを指定
- ホストに接続されているインターフェース（例: LER_Ingressのppp0-2）は含めない

#### RSVP-TE設定ファイル
```ini
**.LER_Ingress.rsvp.traffic = xmldoc("LER_Ingress_traffic.xml")
**.LER_Ingress.classifier.config = xmldoc("LER_Ingress_fec.xml")
```
- **traffic**: LSPトンネル定義
  - 各トンネルに複数のパス（プライマリ + バックアップ）を定義
  - `permanent="true"`を設定することで、全てのパスが起動時に確立される
  - これにより障害時に即座にフェイルオーバー可能
- **classifier**: FEC（Forwarding Equivalence Class）マッピング
  - 宛先IPアドレスとトンネルIDの対応を定義

#### トンネルとパスの構成

各トンネルは3つのLSPパスを持ちます：

**Tunnel 1（高優先度）**:
- LSP 100（プライマリ）: CoreRouter1経由
- LSP 101（バックアップ1）: CoreRouter2経由
- LSP 102（バックアップ2）: CoreRouter3経由

**Tunnel 2（中優先度）**:
- LSP 200（プライマリ）: CoreRouter2経由
- LSP 201（バックアップ1）: CoreRouter1経由
- LSP 202（バックアップ2）: CoreRouter3経由

**Tunnel 3（低優先度）**:
- LSP 300（プライマリ）: CoreRouter3経由
- LSP 301（バックアップ1）: CoreRouter1経由
- LSP 302（バックアップ2）: CoreRouter2経由

全てのパスが`permanent="true"`で起動時に確立されるため、障害発生時に即座に代替パスへ切り替わります。

#### ルーティングテーブルファイル
```ini
**.LER_Ingress.ipv4.routingTable.routingFile = "LER_Ingress.rt"
**.Tx1.ipv4.routingTable.routingFile = "Tx1.rt"
# ... 他のノードも同様
```
- 各ノードに対応する.rtファイルを指定

#### シナリオ設定
```ini
**.scenarioManager.script = xmldoc("MPLSDynamic_scenario.xml")
```
- リンク障害イベント等のシナリオ定義

---

### [General]（178-320行目）
**用途**: デフォルト実行設定

この設定は`omnetpp`コマンドでConfigを指定せずに実行した際に使用されます。
MPLSDynamicBaseの内容を展開して記述しています。

**注意**:
- 276-299行目のIPアドレス設定は古い記述です
- 実際のIPアドレスは.rtファイルのifconfigセクションで設定されます
- この部分は無視されます（.rtファイルが優先）

---

### [Config MPLSDynamic_Test1]（321-323行目）
**用途**: 基本的なリンク障害テスト

```ini
extends = MPLSDynamicBase
description = "Test with link failure on primary path at t=20s"
```
- MPLSDynamicBaseを継承
- t=20秒でリンク障害発生（MPLSDynamic_scenario.xmlで定義）

**実行方法**:
```bash
omnetpp -u Cmdenv -c MPLSDynamic_Test1 MPLSDynamic.ini
```

---

### [Config MPLSDynamic_Congestion]（325-332行目）
**用途**: 輻輳時の動的経路切り替えテスト

```ini
extends = MPLSDynamicBase
**.Tx1.app[0].sendInterval = 0.5ms  # トラフィック量を大幅増加
**.Tx2.app[0].sendInterval = 1ms
**.Tx3.app[0].sendInterval = 2ms
```
- トラフィック量を増やして輻輳を発生させる
- Tx1の帯域幅: 1400 bytes × (1/0.0005s) = 2.8 MB/s = 22.4 Mbps

**実行方法**:
```bash
omnetpp -u Cmdenv -c MPLSDynamic_Congestion MPLSDynamic.ini
```

---

### [Config MPLSDynamic_MultipleFailures]（334-338行目）
**用途**: 複数のリンク障害が発生する場合のテスト

```ini
extends = MPLSDynamicBase
sim-time-limit = 70s
**.Tx*.app[0].stopTime = 119s
```
- シミュレーション時間を70秒に延長
- 複数の障害イベントをテスト

**実行方法**:
```bash
omnetpp -u Cmdenv -c MPLSDynamic_MultipleFailures MPLSDynamic.ini
```

---

### [Config MPLSMesh_Config]（344-370行目）
**用途**: メッシュトポロジーネットワークの設定

```ini
network = insotu.simulations.MPLSMesh
*.CoreRouter4.routerId = "10.3.4.1"
**.scenarioManager.script = xmldoc("MPLSMesh_scenario.xml")
```
- MPLSMeshネットワークを使用（CoreRouter4を含む）
- 別のシナリオファイルを使用

**実行方法**:
```bash
omnetpp -u Cmdenv -c MPLSMesh_Config MPLSDynamic.ini
```

---

## IPアドレス体系

### ネットワーク設計

#### 送信側ネットワーク（10.0.x.x）
- **Tx1 ↔ LER_Ingress.ppp[0]**: 10.0.1.0/30
  - Tx1: 10.0.1.2
  - LER_Ingress.ppp[0]: 10.0.1.1
- **Tx2 ↔ LER_Ingress.ppp[1]**: 10.0.2.0/30
  - Tx2: 10.0.2.2
  - LER_Ingress.ppp[1]: 10.0.2.1
- **Tx3 ↔ LER_Ingress.ppp[2]**: 10.0.3.0/30
  - Tx3: 10.0.3.2
  - LER_Ingress.ppp[2]: 10.0.3.1

#### コアネットワーク（10.1.x.x）
- **LER_Ingress.ppp[3] ↔ CoreRouter1.ppp[0]**: 10.1.3.0/30
  - LER_Ingress.ppp[3]: 10.1.3.1 ← **routerID**
  - CoreRouter1.ppp[0]: 10.1.3.2 ← **routerID**
- **LER_Ingress.ppp[4] ↔ CoreRouter2.ppp[0]**: 10.1.4.0/30
  - LER_Ingress.ppp[4]: 10.1.4.1
  - CoreRouter2.ppp[0]: 10.1.4.2 ← **routerID**
- **LER_Ingress.ppp[5] ↔ CoreRouter3.ppp[0]**: 10.1.5.0/30
  - LER_Ingress.ppp[5]: 10.1.5.1
  - CoreRouter3.ppp[0]: 10.1.5.2 ← **routerID**

#### 受信側ネットワーク（10.2.x.x）
- **LER_Egress.ppp[0] ↔ Rx1**: 10.2.1.0/30
  - LER_Egress.ppp[0]: 10.2.1.1
  - Rx1: 10.2.1.2
- **LER_Egress.ppp[1] ↔ Rx2**: 10.2.2.0/30
  - LER_Egress.ppp[1]: 10.2.2.1
  - Rx2: 10.2.2.2
- **LER_Egress.ppp[2] ↔ Rx3**: 10.2.3.0/30
  - LER_Egress.ppp[2]: 10.2.3.1
  - Rx3: 10.2.3.2
- **CoreRouter1.ppp[1] ↔ LER_Egress.ppp[3]**: 10.2.10.0/30
  - CoreRouter1.ppp[1]: 10.2.10.2
  - LER_Egress.ppp[3]: 10.2.10.1 ← **routerID**
- **CoreRouter2.ppp[1] ↔ LER_Egress.ppp[4]**: 10.2.11.0/30
  - CoreRouter2.ppp[1]: 10.2.11.2
  - LER_Egress.ppp[4]: 10.2.11.1
- **CoreRouter3.ppp[1] ↔ LER_Egress.ppp[5]**: 10.2.12.0/30
  - CoreRouter3.ppp[1]: 10.2.12.2
  - LER_Egress.ppp[5]: 10.2.12.1

---

## 関連設定ファイル

### XMLファイル
1. **LER_Ingress_traffic.xml**: RSVP-TE LSPトンネル定義
2. **LER_Ingress_fec.xml**: FECマッピング（宛先→トンネルID）
3. **MPLSDynamic_scenario.xml**: リンク障害シナリオ
4. **MPLSMesh_scenario.xml**: メッシュネットワーク用シナリオ
5. **MPLSDynamic_filters.xml**: トラフィック分類フィルタ
6. **empty.xml**: NetworkConfigurator無効化用の空ファイル

### ルーティングテーブルファイル（.rt）
1. **Tx1.rt, Tx2.rt, Tx3.rt**: 送信ホスト
2. **Rx1.rt, Rx2.rt, Rx3.rt**: 受信ホスト
3. **LER_Ingress.rt**: Ingressエッジルータ
4. **LER_Egress.rt**: Egressエッジルータ
5. **CoreRouter1.rt, CoreRouter2.rt, CoreRouter3.rt**: コアルータ

---

## 実行方法

### GUIモード（Qtenv）
```bash
cd /c/ICHIKAWA/Insotu/simulations
omnetpp -u Qtenv MPLSDynamic.ini
```
起動後、Configセレクタで以下を選択:
- MPLSDynamic_Test1
- MPLSDynamic_Congestion
- MPLSDynamic_MultipleFailures
- MPLSMesh_Config

### コマンドラインモード（Cmdenv）
```bash
# デフォルト設定で実行
omnetpp -u Cmdenv MPLSDynamic.ini

# 特定のConfigで実行
omnetpp -u Cmdenv -c MPLSDynamic_Test1 MPLSDynamic.ini
omnetpp -u Cmdenv -c MPLSDynamic_Congestion MPLSDynamic.ini
omnetpp -u Cmdenv -c MPLSDynamic_MultipleFailures MPLSDynamic.ini
```

---

## トラブルシューティング

### よくあるエラーと対処法

#### 1. "not a local peer: x.x.x.x" エラー
**原因**: routerIDがインターフェースアドレスと一致していない

**対処**:
```ini
# routerIDは必ずいずれかのインターフェースアドレスと同じにする
*.LER_Ingress.routerId = "10.1.3.1"  # ppp[3]のアドレスと同じ
```

#### 2. "UNROUTABLE" エラー
**原因**: ルーティングテーブルファイルが正しく設定されていない

**対処**:
- .rtファイルにifconfigセクションがあるか確認
- gateway アドレスが正しいか確認
- インターフェース名（ppp0, ppp1等）が正しいか確認

#### 3. "Cannot convert cObject * to double" エラー
**原因**: パケットオブジェクトをベクトル記録しようとしている

**対処**:
```ini
# 既に設定済み（57-64行目）
**.app[*].packetSent:vector.result-recording-modes = -
**.app[*].packetReceived:vector.result-recording-modes = -
```

#### 4. XMLファイルが見つからない
**原因**: XMLファイルのパスが正しくない

**対処**:
- シミュレーションディレクトリにXMLファイルが存在するか確認
- ファイル名のスペルミスがないか確認

---

## リンク使用率監視機能（LinkUtilizationMonitor）

### 概要
LinkUtilizationMonitorは、リンクの帯域幅使用率を定期的に計算し、設定された閾値と比較してパケット送信パスを動的に切り替える機能を提供します。

従来のQueueCongestionMonitor（キュー深度ベース）に加えて、帯域幅使用率ベースの監視が可能になります。

### 仕組み

1. **測定**: キューから送出されるパケットのバイト数を累積的に記録
2. **使用率計算**: 測定窓幅（measurementWindow）内のデータから帯域幅使用率を計算
3. **閾値判定**:
   - 使用率が `utilizationThreshold` を超えると代替パスへ切り替え
   - 使用率が `lowThreshold` 以下に回復するとプライマリパスへ復帰

### パラメータ

#### linkCapacity (bps)
```ini
linkCapacity = 1Gbps
```
- リンクの最大容量（ビット/秒）
- この値で実際の使用率を割って使用率を計算

#### utilizationThreshold (0.0-1.0)
```ini
utilizationThreshold = 0.8  # 80%
```
- パスを切り替える閾値
- 0.8 = 80%の帯域幅使用率を超えると代替パスへ切り替え

#### lowThreshold (0.0-1.0)
```ini
lowThreshold = 0.5  # 50%
```
- プライマリパスへ復帰する閾値
- 0.5 = 50%以下に使用率が下がるとプライマリパスへ戻る

#### checkInterval (秒)
```ini
checkInterval = 1s
```
- 使用率をチェックする間隔
- 1秒ごとに測定・判定を実行

#### measurementWindow (秒)
```ini
measurementWindow = 5s
```
- 使用率計算用の測定窓幅
- 過去5秒間のデータから平均使用率を計算

#### queueModule (パス)
```ini
queueModule = "^.LER_Ingress.ppp[3].queue"
```
- 監視対象のキューモジュールへのパス
- このキューからパケットが送出された際にバイト数を記録

#### interfaceModule (パス, オプション)
```ini
interfaceModule = "^.LER_Ingress.ppp[3]"
```
- 監視対象のインターフェースモジュールへのパス（現在は未使用）

#### rsvpModule (パス)
```ini
rsvpModule = "^.LER_Ingress.rsvp"
```
- RSVP-TEモジュールへのパス
- 閾値超過時にこのモジュールへ通知

#### tunnelId (整数)
```ini
tunnelId = 1
```
- 監視対象のトンネルID
- 閾値超過時に通知するトンネルを特定

#### enabled (真偽値)
```ini
enabled = true
```
- 監視機能の有効/無効

### MPLSDynamic.nedでの設定例

```ned
linkUtilMonitor1: LinkUtilizationMonitor {
    parameters:
        queueModule = "^.LER_Ingress.ppp[3].queue";
        interfaceModule = "^.LER_Ingress.ppp[3]";
        rsvpModule = "^.LER_Ingress.rsvp";
        tunnelId = 1;
        linkCapacity = 1Gbps;
        utilizationThreshold = 0.8;  // 80%
        lowThreshold = 0.5;          // 50%
        checkInterval = 1s;
        measurementWindow = 5s;
        enabled = true;
        @display("p=700,1700;is=s");
}
```

### MPLSDynamic.iniでの統計記録設定

```ini
# Link utilization monitoring statistics
**.linkUtilMonitor*.linkUtilization:vector.result-recording-modes = +vector
**.linkUtilMonitor*.linkUtilization:stats.result-recording-modes = +stats
```

これにより、リンク使用率が時系列データとして記録されます。

### QueueCongestionMonitorとの違い

| 項目 | QueueCongestionMonitor | LinkUtilizationMonitor |
|------|------------------------|------------------------|
| 監視対象 | キュー内のパケット数 | リンクの帯域幅使用率 |
| チェック間隔 | 0.05s（高頻度） | 1s（低頻度） |
| 閾値 | パケット数（200個等） | 使用率（0.0-1.0） |
| 反応速度 | 速い（バースト検出） | 遅い（平均使用率） |
| 適用場面 | 瞬間的な輻輳検出 | 持続的な高負荷検出 |

### 使い分けの推奨

- **QueueCongestionMonitor**: バーストトラフィックによる瞬間的な輻輳を検出したい場合
- **LinkUtilizationMonitor**: リンクの平均的な使用率に基づいて長期的な負荷分散を行いたい場合
- **両方使用**: 短期・長期両方の輻輳検出を行いたい場合

### カスタマイズ例

#### 高感度設定（早めに切り替え）
```ini
*.linkUtilMonitor1.utilizationThreshold = 0.6  # 60%で切り替え
*.linkUtilMonitor1.lowThreshold = 0.3          # 30%で復帰
*.linkUtilMonitor1.checkInterval = 0.5s        # 0.5秒ごとにチェック
*.linkUtilMonitor1.measurementWindow = 3s      # 3秒の窓幅
```

#### 低感度設定（ほぼ飽和時のみ切り替え）
```ini
*.linkUtilMonitor1.utilizationThreshold = 0.95  # 95%で切り替え
*.linkUtilMonitor1.lowThreshold = 0.7           # 70%で復帰
*.linkUtilMonitor1.checkInterval = 2s           # 2秒ごとにチェック
*.linkUtilMonitor1.measurementWindow = 10s      # 10秒の窓幅
```

#### 一時的に無効化
```ini
*.linkUtilMonitor*.enabled = false
```

---

## カスタマイズ方法

### トラフィック量の変更
```ini
# 高優先度トラフィックを増やす
**.Tx1.app[0].sendInterval = 1ms  # 2ms から 1ms に変更
```

### シミュレーション時間の変更
```ini
sim-time-limit = 120s  # 60s から 120s に変更
**.Tx*.app[0].stopTime = 119s
```

### 新しいテストConfigの追加
```ini
[Config MyCustomTest]
extends = MPLSDynamicBase
description = "My custom test scenario"

# カスタム設定を追加
**.Tx1.app[0].sendInterval = 1ms
**.scenarioManager.script = xmldoc("my_scenario.xml")
```

---

## パラメータ記号の意味

- `*`: 任意の1つの要素に一致
- `**`: 任意の階層の要素に一致
- `[n]`: 配列のn番目の要素
- `[*]`: 配列の全ての要素

例:
- `**.Tx*.app[0]`: 全てのTxで始まるノードの最初のアプリケーション
- `*.LER_Ingress.ppp[3]`: トップレベルのLER_IngressのPPPインターフェース3番

---

## 参考情報

### DiffServコードポイント
- **EF (46)**: Expedited Forwarding - 最高優先度
- **AF41 (34)**: Assured Forwarding Class 4, Low Drop - 高優先度
- **AF42 (36)**: Assured Forwarding Class 4, Medium Drop - 中優先度
- **BE (0)**: Best Effort - デフォルト

### RSVP-TE優先度
- **setup_pri**: LSP確立時の優先度（0-7、7が最高）
- **holding_pri**: LSP保持時の優先度（0-7、7が最高）

### OMNeT++/INET 4.5ドキュメント
- INET Framework: https://inet.omnetpp.org/
- RSVP-TE実装: `inet/networklayer/rsvpte/`
- MPLS実装: `inet/networklayer/mpls/`

---

作成日: 2025年
対象バージョン: OMNeT++ 6.1, INET 4.5
