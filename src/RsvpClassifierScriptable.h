#ifndef __INSOTU_RSVPCLASSIFIERSCRIPTABLE_H
#define __INSOTU_RSVPCLASSIFIERSCRIPTABLE_H

#include "inet/networklayer/rsvpte/RsvpClassifier.h"
#include "inet/networklayer/rsvpte/RsvpTe.h"

namespace insotu {

class RsvpClassifierScriptable : public inet::RsvpClassifier
{
  protected:
    // Override bind to prevent automatic FEC updates during LSP restoration
    virtual void bind(const inet::SessionObj& session, const inet::SenderTemplateObj& sender, int inLabel) override;

    bool allowAutomaticBinding = true; // Allow binding during initialization

  public:
    RsvpClassifierScriptable() = default;

    const std::vector<FecEntry>& getFecEntries() const { return bindings; }

    void rebindFec(int fecId, const inet::SessionObj& session, const inet::SenderTemplateObj& sender, int inLabel);

    // Control automatic binding
    void setAllowAutomaticBinding(bool allow) { allowAutomaticBinding = allow; }
};

} // namespace insotu

#endif
