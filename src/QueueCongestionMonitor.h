#ifndef __INSOTU_QUEUECONGESTIONMONITOR_H
#define __INSOTU_QUEUECONGESTIONMONITOR_H

#include <omnetpp.h>
#include "inet/common/InitStages.h"

using namespace omnetpp;

namespace inet {
namespace queueing {
class IPacketQueue;
}
} // namespace inet

namespace insotu {

class RsvpTeScriptable;

class QueueCongestionMonitor : public cSimpleModule
{
  protected:
    inet::queueing::IPacketQueue *queue = nullptr;
    insotu::RsvpTeScriptable *rsvp = nullptr;
    cMessage *timer = nullptr;
    int tunnelId = -1;
    int highWatermark = 0;
    int lowWatermark = 0;
    bool congested = false;
    simtime_t interval = 0;
    bool enabled = true;

  protected:
    virtual int numInitStages() const override { return inet::NUM_INIT_STAGES; }
    virtual void initialize(int stage) override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;

    void poll();
};

} // namespace insotu

#endif
