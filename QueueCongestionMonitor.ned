package insotu;

simple QueueCongestionMonitor
{
    parameters:
        string queueModule;
        string rsvpModule = default("^.rsvp");
        int tunnelId;
        int highWatermark = default(20);
        int lowWatermark = default(5);
        double checkInterval @unit(s) = default(0.1s);
        bool enabled = default(true);
        @class(insotu::QueueCongestionMonitor);
        @display("i=block/process");
}
