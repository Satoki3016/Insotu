package insotu;

import inet.networklayer.rsvpte.RsvpTe;

//
// Extended RSVP-TE module with scriptable path management
//
// Extends the base RsvpTe module with:
// - Dynamic path switching based on congestion/failure detection
// - Multiple backup paths per tunnel
// - Delayed restoration to ensure label stability
// - Integration with QueueCongestionMonitor and LinkUtilizationMonitor
//
simple RsvpTeScriptable extends RsvpTe
{
    parameters:
        @class(insotu::RsvpTeScriptable);

        // Auto-restore to primary path when it becomes available
        bool autoRestorePrimary = default(true);

        // Delay before restoring to a path after it becomes available
        // This ensures labels are fully installed in intermediate routers
        double restorationDelay @unit(s) = default(2s);
}
