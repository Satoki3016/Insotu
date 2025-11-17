#ifndef __INSOTU_LINKUTILIZATIONMONITOR_H
#define __INSOTU_LINKUTILIZATIONMONITOR_H

#include <omnetpp.h>
#include "inet/common/InitStages.h"

using namespace omnetpp;

namespace inet {
namespace queueing {
class IPacketQueue;
}
namespace common {
class PacketEventTag;
}
} // namespace inet

namespace insotu {

class RsvpTeScriptable;

/**
 * リンク使用率監視モジュール
 *
 * 機能:
 * - リンクの帯域幅使用率を定期的に計算
 * - 設定された閾値と比較
 * - 閾値を超えた場合、RSVP-TEに通知して代替パスへ切り替え
 *
 * パラメータ:
 * - linkCapacity: リンク容量（bps）
 * - utilizationThreshold: 使用率閾値（0.0-1.0、例: 0.8 = 80%）
 * - lowThreshold: 復帰閾値（0.0-1.0、例: 0.5 = 50%）
 * - checkInterval: チェック間隔（秒）
 * - measurementWindow: 測定窓幅（秒）
 */
class LinkUtilizationMonitor : public cSimpleModule, public cListener
{
  protected:
    // 設定パラメータ
    double linkCapacity = 0;          // bps
    double utilizationThreshold = 0;  // 0.0-1.0
    double lowThreshold = 0;          // 0.0-1.0
    simtime_t checkInterval = 0;
    simtime_t measurementWindow = 0;
    int tunnelId = -1;
    bool enabled = true;

    // 参照
    insotu::RsvpTeScriptable *rsvp = nullptr;
    cMessage *timer = nullptr;

    // 測定データ
    struct MeasurementPoint {
        simtime_t timestamp;
        int64_t bytesTransmitted;
    };
    std::vector<MeasurementPoint> measurements;

    // 累積送信バイト数
    int64_t totalBytesTransmitted = 0;

    // 状態
    bool overThreshold = false;
    double currentUtilization = 0.0;

    // 統計
    cOutVector utilizationVector;
    simsignal_t utilizationSignal;

  protected:
    virtual int numInitStages() const override { return inet::NUM_INIT_STAGES; }
    virtual void initialize(int stage) override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
    virtual void receiveSignal(cComponent *source, simsignal_t signalID, cObject *obj, cObject *details) override;

    void measureUtilization();
    double calculateUtilization();
    int64_t getBytesTransmitted();
    void cleanOldMeasurements();
    void subscribeToQueueSignals();

  private:
    simsignal_t popPacketSignal = -1;
};

} // namespace insotu

#endif
