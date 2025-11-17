#ifndef __INET_RSVPTESCRIPTABLE_H
#define __INET_RSVPTESCRIPTABLE_H

#include <map>
#include <set>
#include <vector>
#include <omnetpp.h>

#include "inet/common/scenario/IScriptable.h"
#include "inet/networklayer/rsvpte/RsvpTe.h"
#include "inet/networklayer/rsvpte/SignallingMsg_m.h"

using namespace omnetpp;

namespace insotu {
class RsvpClassifierScriptable;

class RsvpTeScriptable : public inet::RsvpTe
{
  protected:
    using traffic_session_t = inet::RsvpTe::traffic_session_t;
    using traffic_path_t = inet::RsvpTe::traffic_path_t;

    insotu::RsvpClassifierScriptable *classifierExt = nullptr;

    std::map<int, std::vector<int>> tunnelLspOrder;
    std::map<int, std::map<int, int>> tunnelLspIndex;
    std::map<int, int> tunnelActiveIndex;
    std::map<int, int> tunnelPendingIndex;
    std::set<int> congestionForced;
    std::set<int> primaryUnavailable;
    bool autoRestorePrimary = true;

    // Delayed restoration: track when paths were restored
    std::map<std::pair<int, int>, simtime_t> pathRestoredTime;
    simtime_t restorationDelay = 0;
    cMessage *restorationCheckTimer = nullptr;

  protected:
    virtual void initialize(int stage) override;
    virtual void handleMessageWhenUp(cMessage *msg) override;
    virtual void processCommand(const cXMLElement& node) override;
    virtual void processPATH_NOTIFY(inet::PathNotifyMsg *msg) override;

    void buildTunnelPlan();
    traffic_session_t *findSessionByTunnel(int tunnelId);
    traffic_path_t *findPathByLsp(traffic_session_t *session, int lspId);
    int getPrimaryIndex(int tunnelId) const { return 0; }
    int findPathIndex(int tunnelId, int lspId) const;
    void syncActiveIndices();
    void switchToIndex(int tunnelId, int targetIndex, const char *reason);
    void requestFailover(int tunnelId, const char *reason, bool dueToCongestion);
    void requestRestore(int tunnelId, const char *reason, bool dueToCongestion);
    void handlePathFailure(int tunnelId, int lspId, const char *reason);
    void handlePathRestored(int tunnelId, int lspId, const char *reason);
    void checkPendingRestorations();

  public:
    void handleCongestionNotification(int tunnelId, bool congested, const char *source);
};

} // namespace insotu

#endif
