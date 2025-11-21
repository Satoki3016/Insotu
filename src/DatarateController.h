#ifndef __INSOTU_DATARATECONTROLLER_H
#define __INSOTU_DATARATECONTROLLER_H

#include <omnetpp.h>
#include "inet/common/INETDefs.h"
#include "inet/networklayer/common/NetworkInterface.h"
#include "inet/linklayer/ppp/PppInterface.h"

namespace insotu {

using namespace omnetpp;

/**
 * Controls the effective datarate of a link by monitoring and potentially
 * throttling packets. This allows dynamic datarate changes during simulation.
 */
class DatarateController : public cSimpleModule
{
  protected:
    double normalDatarate = 0;
    double currentDatarate = 0;
    inet::NetworkInterface *networkInterface = nullptr;

    simsignal_t datarateChangedSignal;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void handleParameterChange(const char *parname) override;

    void updateDatarate(double newDatarate);

  public:
    virtual ~DatarateController() = default;

    double getCurrentDatarate() const { return currentDatarate; }
    void setDatarate(double datarate);
};

} // namespace insotu

#endif
