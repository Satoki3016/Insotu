#include "RsvpClassifierScriptable.h"
#include <omnetpp.h>

namespace insotu {

using namespace omnetpp;

Define_Module(RsvpClassifierScriptable);

void RsvpClassifierScriptable::rebindFec(int fecId, const inet::SessionObj& session, const inet::SenderTemplateObj& sender, int inLabel)
{
    auto it = findFEC(fecId);
    if (it == bindings.end())
        throw cRuntimeError("FEC entry %d not found when attempting to rebind", fecId);

    it->session = session;
    it->sender = sender;
    it->dest = session.DestAddress;
    it->src = sender.SrcAddress;
    it->inLabel = inLabel;

    EV_INFO << "Rebound FEC " << fecId << " to tunnel " << session.Tunnel_Id
            << " lspId " << sender.Lsp_Id << " with label " << inLabel << inet::endl;
}

} // namespace insotu
