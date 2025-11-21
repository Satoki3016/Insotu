#include "DatarateController.h"
#include "inet/common/ModuleAccess.h"

namespace insotu {

Define_Module(DatarateController);

void DatarateController::initialize()
{
    normalDatarate = par("normalDatarate").doubleValue();
    currentDatarate = par("currentDatarate").doubleValue();

    datarateChangedSignal = registerSignal("datarateChanged");

    const char *interfacePath = par("interfaceModule");
    cModule *interfaceModule = getModuleByPath(interfacePath);
    if (!interfaceModule) {
        EV_WARN << "Interface module not found at path: " << interfacePath << endl;
        return;
    }

    // Get the network interface
    auto pppInterface = dynamic_cast<inet::PppInterface*>(interfaceModule);
    if (pppInterface) {
        networkInterface = pppInterface->getNetworkInterface();
        EV_INFO << "DatarateController initialized for interface " << networkInterface->getInterfaceName()
                << " with datarate " << currentDatarate << " bps" << endl;
    }

    emit(datarateChangedSignal, currentDatarate);
}

void DatarateController::handleMessage(cMessage *msg)
{
    delete msg;
}

void DatarateController::handleParameterChange(const char *parname)
{
    if (strcmp(parname, "currentDatarate") == 0) {
        double newDatarate = par("currentDatarate").doubleValue();
        updateDatarate(newDatarate);
    }
}

void DatarateController::updateDatarate(double newDatarate)
{
    if (currentDatarate == newDatarate)
        return;

    currentDatarate = newDatarate;

    EV_WARN << "**DATARATE CHANGE** Interface datarate changed to " << currentDatarate
            << " bps (reduction factor: " << (normalDatarate / currentDatarate) << "x) at t="
            << simTime() << endl;

    emit(datarateChangedSignal, currentDatarate);

    // Note: This module tracks datarate changes but does not enforce them.
    // Actual datarate limiting would require modifying the queue or using a token bucket.
    // For simulation purposes, this provides visibility into intended datarate changes.
}

void DatarateController::setDatarate(double datarate)
{
    par("currentDatarate").setDoubleValue(datarate);
    updateDatarate(datarate);
}

} // namespace insotu
