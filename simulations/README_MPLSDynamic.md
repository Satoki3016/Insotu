# MPLSDynamic - Dynamic MPLS Network Simulation

## 概要

このシミュレーションは、OMNeT++とINET 4.5を使用して、動的なMPLSネットワークの障害検知と経路切り替えをシミュレートします。

## 機能

### 1. ネットワーク構成
- **送信ホスト**: 3台 (Tx1, Tx2, Tx3)
- **受信ホスト**: 3台 (Rx1, Rx2, Rx3)
- **エッジルーター**: 2台 (LER_Ingress, LER_Egress)
- **コアルーター**: 3台以上（可変）(CoreRouter1, CoreRouter2, CoreRouter3)

### 2. MPLSルーティング
- RSVP-TEによるトラフィックエンジニアリング
- 複数のLSP（Label Switched Path）トンネル
- プライマリパスとバックアップパスの自動切り替え

### 3. リンク監視機能
- **輻輳検知**: キュー長の監視
- **障害検知**: リンクダウンの検出
- **パケットロス監視**: パケット損失率の計算
- **レイテンシ監視**: 遅延の測定
- **帯域利用率監視**: リンク使用率の追跡

### 4. 障害・輻輳シミュレーション
- ScenarioManagerによる時間指定でのリンク障害発生
- 複数リンクの同時障害シミュレーション
- 輻輳状態の動的生成

## ファイル構成

### ネットワーク定義ファイル
- `MPLSDynamic.ned` - 基本的なMPLSネットワークトポロジー
- `MPLSMesh.ned` - メッシュトポロジーの拡張版

### 設定ファイル
- `MPLSDynamic.ini` - シミュレーション設定
- `MPLSDynamic_scenario.xml` - 障害シナリオ定義
- `MPLSDynamic_filters.xml` - DiffServトラフィック分類
- `LER_Ingress_traffic.xml` - RSVP-TEトンネル設定
- `LER_Ingress_fec.xml` - FEC（転送等価クラス）マッピング

### ルーティングテーブル
- `LER_Ingress.rt`, `LER_Egress.rt` - エッジルーターのルーティング
- `CoreRouter1.rt`, `CoreRouter2.rt`, `CoreRouter3.rt` - コアルーターのルーティング
- `Tx1.rt`, `Tx2.rt`, `Tx3.rt` - 送信ホストのルーティング
- `Rx1.rt`, `Rx2.rt`, `Rx3.rt` - 受信ホストのルーティング

### C++モジュール
- `EnhancedLinkMonitor.h/cc` - 拡張リンク監視モジュール
- `QueueCongestionMonitor.h/cc` - キュー輻輳監視モジュール
- `RsvpTeScriptable.h/cc` - RSVP-TE拡張モジュール
- `RsvpClassifierScriptable.h/cc` - RSVP分類器

## 使用方法

### 1. ビルド

```bash
cd C:\ICHIKAWA\Insotu\src
make clean
make MODE=release
```

または、OMNeT++ IDEからプロジェクトをビルド

### 2. シミュレーション実行

#### コマンドライン実行
```bash
cd C:\ICHIKAWA\Insotu\simulations
..\src\Insotu.exe -u Cmdenv -c MPLSDynamic_Test1 -n .;../src;../../inet4.5/src MPLSDynamic.ini
```

#### GUI実行（OMNeT++ IDE）
1. OMNeT++でプロジェクトを開く
2. `simulations/MPLSDynamic.ini`を右クリック
3. "Run As" → "OMNeT++ Simulation"を選択
4. 設定から実行したいコンフィグを選択（例: MPLSDynamic_Test1）

### 3. 利用可能な設定

#### [MPLSDynamic_Test1]
- 基本的な障害テスト
- t=20s にプライマリパス（CoreRouter1）で障害発生
- t=40s に復旧

#### [MPLSDynamic_Congestion]
- 輻輳テスト
- トラフィック量を増やして輻輳状態を発生させる

#### [MPLSDynamic_MultipleFailures]
- 複数障害テスト
- 複数のリンクで連続的に障害を発生させる

#### [MPLSMesh_Config]
- メッシュトポロジー
- 冗長パスを持つより複雑なネットワーク

## カスタマイズ方法

### 1. ルーター数を変更する

`MPLSDynamic.ned`の`numCoreRouters`パラメータを変更し、必要に応じてサブモジュールと接続を追加します。

```ned
parameters:
    int numCoreRouters = default(5); // ルーター数を5に変更
```

### 2. 障害シナリオのカスタマイズ

`MPLSDynamic_scenario.xml`を編集して、障害発生時刻や対象を変更します。

```xml
<at t="30.0">
    <tell module="scenarioManager" target="CoreRouter2" operation="shutdown"/>
</at>
```

### 3. トラフィックパターンの変更

`MPLSDynamic.ini`のアプリケーション設定を編集します。

```ini
**.Tx1.app[0].sendInterval = 1ms  # 送信間隔を変更
**.Tx1.app[0].messageLength = 2000 bytes  # パケットサイズを変更
```

### 4. 監視パラメータの調整

輻輳検知の閾値や監視間隔を調整します。

```ini
*.congestionMonitor1.highWatermark = 300  # 輻輳判定閾値
*.congestionMonitor1.lowWatermark = 150   # 回復判定閾値
*.congestionMonitor1.checkInterval = 0.1s # チェック間隔
```

### 5. EnhancedLinkMonitorの使用

より高度な監視機能を使用する場合、INIファイルで設定します。

```ini
*.enhancedMonitor.typename = "insotu.EnhancedLinkMonitor"
*.enhancedMonitor.queueModule = "^.LER_Ingress.ppp[3].queue"
*.enhancedMonitor.rsvpModule = "^.LER_Ingress.rsvp"
*.enhancedMonitor.tunnelId = 1
*.enhancedMonitor.lossRateThreshold = 0.05  # 5%のロス率
*.enhancedMonitor.latencyThreshold = 0.1s   # 100msの遅延
*.enhancedMonitor.utilizationThreshold = 0.9 # 90%の利用率
```

## トポロジーの説明

### 基本トポロジー（MPLSDynamic）

```
Tx1 ---\                    /--- Rx1
        \                  /
Tx2 --- LER_Ingress --- CoreRouter1 --- LER_Egress --- Rx2
        /              /    |    \              \
Tx3 ---/         CoreRouter2|CoreRouter3        \--- Rx3
                              (Multiple paths)
```

### 特徴
- 3つの送信ホストから3つの受信ホストへのトラフィック
- コアルーター間に複数の経路（冗長性確保）
- MPLS-TEによる動的経路切り替え

## シミュレーション結果の確認

### 1. ベクトルファイル (.vec)
- キュー長の時系列変化
- パケット送受信統計
- 遅延変動

### 2. スカラーファイル (.sca)
- 総パケット数
- 平均遅延
- パケット損失率

### 3. ログファイル
- 経路切り替えイベント
- 輻輳検知イベント
- リンク障害/復旧イベント

## トラブルシューティング

### ビルドエラー
- INET 4.5のパスが正しく設定されているか確認
- Makefileの`INET4_5_PROJ`変数を確認

### リンク障害が機能しない
- `*.*.hasStatus = true`が設定されているか確認
- ScenarioManagerのモジュールパスが正しいか確認

### RSVP-TEトンネルが確立されない
- ルーティングテーブルが正しいか確認
- traffic.xmlのノードIDが正しいか確認
- RouterIDが各ノードで重複していないか確認

## 参考資料

- [OMNeT++ マニュアル](https://doc.omnetpp.org/)
- [INET Framework ドキュメント](https://inet.omnetpp.org/docs/)
- [RSVP-TE RFC 3209](https://datatracker.ietf.org/doc/html/rfc3209)
- [MPLS アーキテクチャ RFC 3031](https://datatracker.ietf.org/doc/html/rfc3031)

## ライセンス

このシミュレーションコードは、INET Frameworkのライセンスに従います。

## 作成者情報

作成日: 2025
プロジェクト: Insotu MPLS Dynamic Routing Simulation

## 重要な修正事項（2025-01-07）

### 1. XMLフィルター設定の修正

**問題**: `MultiFieldClassifier の out[3] が存在しない`エラー

**原因**: INI設定で`numClasses = 3`（ゲート0,1,2のみ）なのに、XMLで`gate="3"`を指定

**修正内容**: `MPLSDynamic_filters.xml`を修正
```xml
<!-- 修正前: gate="3" を使用 -->
<filter gate="3">
    <pattern>*</pattern>
</filter>

<!-- 修正後: デフォルトフィルターを削除 -->
<!-- gate="2"で低優先度とデフォルトを統合 -->
```

### 2. INI設定のリファクタリング

**改善点**:
- 継承構造の導入（`MPLSCommon`, `ApplicationsCommon`）
- 重複設定の削減
- 保守性の向上

**主な変更**:
```ini
[Config MPLSCommon]
abstract-config = true
# 全MPLS設定に共通する設定

[Config ApplicationsCommon]
abstract-config = true
# アプリケーション設定の共通化

[Config MPLSDynamicBase]
extends = MPLSCommon, ApplicationsCommon
# 基本設定の組み合わせ
```

### 3. NED定義の改善

**追加機能**:
- カスタムチャネル定義（HighSpeedLink, MediumSpeedLink, LowSpeedLink）
- 詳細なコメント追加
- アイコン指定による視覚的改善

**チャネル定義**:
```ned
channel HighSpeedLink extends ned.DatarateChannel {
    datarate = 1Gbps;
    delay = 1ms;
}
```

## クイックスタートガイド

### 1分で試す

```bash
# ビルド
cd C:\ICHIKAWA\Insotu\src && make MODE=release

# 実行
cd ..\simulations
..\src\Insotu.exe -u Cmdenv -c General -n .;../src;../../inet4.5/src MPLSDynamic.ini
```

### よくある質問 (FAQ)

**Q: ビルドエラー "EnhancedLinkMonitor.o not found" が出る**
A: Makefileを確認してください。以下が含まれているはずです:
```makefile
OBJS = ... $O/EnhancedLinkMonitor.o
```

**Q: シミュレーション実行時に "Gate index 3 out of range" エラー**
A: `MPLSDynamic_filters.xml`が修正済みか確認してください。gate="3"は使用しません。

**Q: RSVP-TEトンネルが確立されない**
A: 以下を確認:
1. ルーティングテーブルファイルが存在するか
2. Router IDが重複していないか
3. peers パラメータが正しいか

**Q: ルーター数を増やしたい**
A: 以下の手順:
1. NEDファイルでCoreRouter4を追加
2. ゲート数を調整
3. 接続を追加
4. ルーティングテーブルファイルを作成
5. INI設定でRouterIDを設定

## 性能最適化のヒント

### シミュレーション高速化
```ini
# ベクトル記録を選択的に
**.queue.queueLength.result-recording-modes = +vector
**.app[*].*.result-recording-modes = +stats  # vectorを無効化

# 不要なモジュールの無効化
**.visualizer.typename = ""
```

### メモリ使用量削減
```ini
# 記録を最小限に
**.scalar-recording = false
**.vector-recording = false

# 必要な統計のみ有効化
**.queue.queueLength.result-recording-modes = +stats
```

## まとめ

このシミュレーションは、MPLSネットワークにおける以下を実証します:

1. ✅ **障害検知と回復**: リンク障害の即座検知と自動経路切替
2. ✅ **輻輳管理**: キュー監視による輻輳回避
3. ✅ **QoS制御**: DiffServによる優先度制御
4. ✅ **冗長性**: 複数経路による高可用性
5. ✅ **拡張性**: 可変ルーター数対応

リファクタリングにより、設定の保守性が大幅に向上し、カスタマイズが容易になりました。

---

**更新日**: 2025-01-07  
**バージョン**: 2.0  
**ステータス**: Production Ready

## 追加修正（インクルードエラー対応）

### EnhancedLinkMonitor のインクルード修正

**問題**: `Unresolved inclusion: "inet/networklayer/contract/INetworkInterface.h"`

**原因**: INET 4.5では`INetworkInterface`インターフェースは存在せず、`NetworkInterface`クラスが直接使用される

**修正内容**:

#### EnhancedLinkMonitor.h
```cpp
// 修正前
namespace inet {
namespace networklayer {
namespace contract {
class INetworkInterface;
}
}
}

// 修正後
namespace inet {
namespace queueing {
class IPacketQueue;
}
class NetworkInterface;  // 直接inet名前空間に配置
}
```

#### EnhancedLinkMonitor.cc
```cpp
// 修正前
#include "inet/networklayer/contract/INetworkInterface.h"
using inet::networklayer::contract::INetworkInterface;

// 修正後
#include "inet/networklayer/common/NetworkInterface.h"
using inet::NetworkInterface;
```

### NetworkInterface監視機能の制限

**注意**: 現在の実装では、`NetworkInterface`オブジェクトはcModuleではないため、モジュールパスから直接取得できません。

**対応**:
- インターフェース監視機能は現在無効化されています
- 代わりにキューベースの監視を使用してください
- 将来的には`InterfaceTable`経由でのアクセスを実装予定

**使用例**:
```cpp
// 現在は機能しません
*.enhancedMonitor.interfaceModule = "^.ppp[0]"

// 代わりにキュー監視を使用
*.enhancedMonitor.queueModule = "^.ppp[0].queue"
```

---

**最終更新**: 2025-01-07  
**ステータス**: ビルド可能、基本機能動作確認済み
