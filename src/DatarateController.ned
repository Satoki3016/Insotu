package insotu;

//
// Controls the effective datarate of a link by introducing delays
// Simulates datarate reduction without modifying channel parameters
//
simple DatarateController
{
    parameters:
        string interfaceModule;          // Path to the interface (e.g., "^.ppp[0]")
        double normalDatarate @unit(bps) = default(10Mbps);
        double currentDatarate @unit(bps) = default(10Mbps);
        @display("i=block/control");
        @signal[datarateChanged](type=double);
        @statistic[datarate](source=datarateChanged; record=vector,last);
}
