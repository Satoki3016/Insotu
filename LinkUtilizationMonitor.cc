#include "LinkUtilizationMonitor.h"
#include "RsvpTeScriptable.h"
#include "inet/common/ModuleAccess.h"
#include "inet/common/packet/Packet.h"
#include <omnetpp.h>

namespace insotu {

using namespace omnetpp;
using namespace inet;

Define_Module(LinkUtilizationMonitor);

void LinkUtilizationMonitor::initialize(int stage)
{
    cSimpleModule::initialize(stage);

    if (stage == inet::INITSTAGE_LOCAL) {
        enabled = par("enabled").boolValue();
        if (!enabled)
            return;

        linkCapacity = par("linkCapacity").doubleValue();
        utilizationThreshold = par("utilizationThreshold").doubleValue();
        lowThreshold = par("lowThreshold").doubleValue();
        checkInterval = par("checkInterval").doubleValue();
        measurementWindow = par("measurementWindow").doubleValue();
        tunnelId = par("tunnelId").intValue();

        // パラメータ検証
        if (utilizationThreshold <= lowThreshold)
            throw cRuntimeError("utilizationThreshold must be greater than lowThreshold");
        if (utilizationThreshold < 0.0 || utilizationThreshold > 1.0)
            throw cRuntimeError("utilizationThreshold must be between 0.0 and 1.0");
        if (lowThreshold < 0.0 || lowThreshold > 1.0)
            throw cRuntimeError("lowThreshold must be between 0.0 and 1.0");

        // RSVPモジュール参照
        const char *rsvpPath = par("rsvpModule");
        cModule *rsvpModule = rsvpPath && *rsvpPath ? getModuleByPath(rsvpPath) : nullptr;
        rsvp = rsvpModule ? dynamic_cast<insotu::RsvpTeScriptable *>(rsvpModule) : nullptr;
        if (!rsvp)
            throw cRuntimeError("RSVP module '%s' is not an insotu RsvpTeScriptable", rsvpPath ? rsvpPath : "<null>");

        // タイマー作成
        timer = new cMessage("measureUtilization");

        // 統計シグナル登録
        utilizationSignal = registerSignal("linkUtilization");
        utilizationVector.setName("Link Utilization");

        WATCH(currentUtilization);
        WATCH(overThreshold);
        WATCH(totalBytesTransmitted);
    }
    else if (stage == inet::INITSTAGE_LAST) {
        if (enabled && timer) {
            // キューシグナルをサブスクライブ
            subscribeToQueueSignals();

            // 初期測定
            scheduleAt(simTime() + checkInterval, timer);
        }
    }
}

void LinkUtilizationMonitor::subscribeToQueueSignals()
{
    // キューモジュールからパケット出力シグナルをリスニング
    const char *queuePath = par("queueModule");
    cModule *queueModule = queuePath && *queuePath ? getModuleByPath(queuePath) : nullptr;

    if (!queueModule) {
        EV_WARN << "Queue module not found: " << queuePath << ", cannot monitor link utilization" << endl;
        return;
    }

    // "popPacket" シグナルをサブスクライブ
    popPacketSignal = queueModule->registerSignal("popPacket");
    queueModule->subscribe(popPacketSignal, this);

    EV_INFO << "Subscribed to popPacket signal from " << queueModule->getFullPath() << endl;
}

void LinkUtilizationMonitor::receiveSignal(cComponent *source, simsignal_t signalID, cObject *obj, cObject *details)
{
    // パケットがキューから出た（送信された）
    if (signalID == popPacketSignal) {
        Packet *packet = dynamic_cast<Packet *>(obj);
        if (packet) {
            int64_t packetBytes = packet->getByteLength();
            totalBytesTransmitted += packetBytes;

            EV_DEBUG << "Packet popped from queue: " << packetBytes
                     << " bytes, total: " << totalBytesTransmitted << " bytes" << endl;
        }
    }
}

void LinkUtilizationMonitor::handleMessage(cMessage *msg)
{
    if (msg == timer) {
        measureUtilization();
        scheduleAt(simTime() + checkInterval, timer);
    }
    else {
        delete msg;
    }
}

void LinkUtilizationMonitor::finish()
{
    // シグナルサブスクリプションを解除
    if (popPacketSignal != -1) {
        const char *queuePath = par("queueModule");
        cModule *queueModule = queuePath && *queuePath ? getModuleByPath(queuePath) : nullptr;
        if (queueModule) {
            queueModule->unsubscribe(popPacketSignal, this);
        }
    }

    cancelAndDelete(timer);
    timer = nullptr;
}

void LinkUtilizationMonitor::measureUtilization()
{
    if (!enabled || !rsvp)
        return;

    // 使用率を計算
    currentUtilization = calculateUtilization();

    // 統計記録
    emit(utilizationSignal, currentUtilization);
    utilizationVector.record(currentUtilization);

    EV_INFO << "Link utilization: " << (currentUtilization * 100.0) << "%" << endl;

    // 閾値判定
    if (!overThreshold && currentUtilization >= utilizationThreshold) {
        // 閾値超過 → 代替パスへ切り替え
        overThreshold = true;
        EV_WARN << "Link utilization exceeded threshold ("
                << (currentUtilization * 100.0) << "% >= "
                << (utilizationThreshold * 100.0) << "%), switching to backup path for tunnel "
                << tunnelId << endl;

        rsvp->handleCongestionNotification(tunnelId, true, getFullPath().c_str());
    }
    else if (overThreshold && currentUtilization <= lowThreshold) {
        // 閾値以下に回復 → プライマリパスへ復帰可能
        overThreshold = false;
        EV_INFO << "Link utilization recovered ("
                << (currentUtilization * 100.0) << "% <= "
                << (lowThreshold * 100.0) << "%), can restore primary path for tunnel "
                << tunnelId << endl;

        rsvp->handleCongestionNotification(tunnelId, false, getFullPath().c_str());
    }
}

double LinkUtilizationMonitor::calculateUtilization()
{
    // 現在の送信バイト数を取得
    int64_t currentBytes = getBytesTransmitted();
    simtime_t now = simTime();

    // 測定ポイント追加
    measurements.push_back({now, currentBytes});

    // 古い測定データをクリーンアップ
    cleanOldMeasurements();

    // 測定窓内のデータが不足している場合
    if (measurements.size() < 2) {
        return 0.0;
    }

    // 窓の開始と終了の測定ポイント
    const auto& oldest = measurements.front();
    const auto& newest = measurements.back();

    // 時間差
    simtime_t timeDiff = newest.timestamp - oldest.timestamp;
    if (timeDiff <= 0) {
        return 0.0;
    }

    // バイト差
    int64_t bytesDiff = newest.bytesTransmitted - oldest.bytesTransmitted;
    if (bytesDiff < 0) {
        // カウンターがリセットされた場合
        bytesDiff = newest.bytesTransmitted;
    }

    // 使用率計算: (転送ビット数 / 時間) / リンク容量
    double bitsPerSecond = (bytesDiff * 8.0) / timeDiff.dbl();
    double utilization = bitsPerSecond / linkCapacity;

    // 1.0を超えることがある（バースト）ので上限を設定
    if (utilization > 1.0) {
        utilization = 1.0;
    }

    return utilization;
}

int64_t LinkUtilizationMonitor::getBytesTransmitted()
{
    // receiveSignal()で累積している送信バイト数を返す
    return totalBytesTransmitted;
}

void LinkUtilizationMonitor::cleanOldMeasurements()
{
    simtime_t cutoff = simTime() - measurementWindow;

    // cutoffより古い測定データを削除
    while (!measurements.empty() && measurements.front().timestamp < cutoff) {
        measurements.erase(measurements.begin());
    }
}

} // namespace insotu
