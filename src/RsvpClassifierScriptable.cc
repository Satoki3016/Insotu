#include "RsvpClassifierScriptable.h"
#include <omnetpp.h>

namespace insotu {

using namespace omnetpp;

Define_Module(RsvpClassifierScriptable);

void RsvpClassifierScriptable::bind(const inet::SessionObj& session, const inet::SenderTemplateObj& sender, int inLabel)
{
    if (allowAutomaticBinding) {
        // During initialization or when explicitly allowed
        EV_INFO << "RsvpClassifierScriptable::bind() ALLOWED for tunnel " << session.Tunnel_Id
                << " LSP " << sender.Lsp_Id << " label " << inLabel << inet::endl;
        inet::RsvpClassifier::bind(session, sender, inLabel);
    } else {
        // Prevent automatic FEC binding during LSP restoration
        EV_DETAIL << "RsvpClassifierScriptable::bind() BLOCKED for tunnel " << session.Tunnel_Id
                  << " LSP " << sender.Lsp_Id << " (automatic binding disabled)" << inet::endl;
    }
}

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
