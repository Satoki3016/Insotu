package insotu;

//
// リンク使用率監視モジュール
//
// リンクの帯域幅使用率を定期的に計算し、設定された閾値と比較します。
// 閾値を超えた場合、RSVP-TEに通知して代替パスへ切り替えを行います。
//
// パラメータ:
// - linkCapacity: リンク容量（bps）
// - utilizationThreshold: 使用率閾値（0.0-1.0）、これを超えると代替パスへ切り替え
// - lowThreshold: 復帰閾値（0.0-1.0）、これ以下になるとプライマリパスへ復帰可能
// - checkInterval: 使用率チェック間隔
// - measurementWindow: 使用率計算用の測定窓幅
// - queueModule: 監視対象キューモジュールへのパス
// - interfaceModule: 監視対象インターフェースモジュールへのパス（オプション）
// - rsvpModule: RSVP-TEモジュールへのパス
// - tunnelId: この監視が対象とするトンネルID
// - enabled: モニタリング有効/無効
//
simple LinkUtilizationMonitor
{
    parameters:
        double linkCapacity @unit(bps) = default(1Mbps);
        double utilizationThreshold = default(0.8);  // 80%
        double lowThreshold = default(0.5);          // 50%
        double checkInterval @unit(s) = default(1s);
        double measurementWindow @unit(s) = default(5s);
        string queueModule;
        string interfaceModule = default("");
        string rsvpModule = default("^.rsvp");
        int tunnelId;
        bool enabled = default(true);

        @class(insotu::LinkUtilizationMonitor);
        @display("i=block/process");

        @signal[linkUtilization](type=double);
        @statistic[linkUtilization](title="Link Utilization"; record=vector,stats; interpolationmode=sample-hold);
}
