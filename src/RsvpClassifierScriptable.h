#ifndef __INSOTU_RSVPCLASSIFIERSCRIPTABLE_H
#define __INSOTU_RSVPCLASSIFIERSCRIPTABLE_H

#include "inet/networklayer/rsvpte/RsvpClassifier.h"
#include "inet/networklayer/rsvpte/RsvpTe.h"

namespace insotu {

class RsvpClassifierScriptable : public inet::RsvpClassifier
{
  public:
    RsvpClassifierScriptable() = default;

    const std::vector<FecEntry>& getFecEntries() const { return bindings; }

    void rebindFec(int fecId, const inet::SessionObj& session, const inet::SenderTemplateObj& sender, int inLabel);
};

} // namespace insotu

#endif
