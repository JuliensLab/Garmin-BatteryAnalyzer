using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Time;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system. This indicates a set timer has expired, and
// we should attempt to notify the user.
(:background)
class BatteryAnalyzerServiceDelegate extends Sys.ServiceDelegate {
    function initialize() {
    	//Sys.println("Background/initialize");
        ServiceDelegate.initialize();
    }

    // If our timer expires, it means the application timer ran out,
    // and the main application is not open. Prompt the user to let them
    // know the timer expired.
    function onTemporalEvent() {
    	//Sys.println("Background/onTemporalEvent");
        //Background.requestApplicationWake("Your timer has expired!");
        var stats = Sys.getSystemStats();
	    var battery = stats.battery.toNumber();// out of 100
	    var freeMemory = stats.freeMemory;// in bytes
	    var now = Time.now().value(); //in seconds from UNIX epoch in UTC
        Background.exit([now,now,battery,freeMemory]);
    }
}

function getData(){
    //! get data
    //Sys.println("getData");    
    var stats = Sys.getSystemStats();
    var battery = stats.battery.toNumber();// out of 100
    var freeMemory = stats.freeMemory;// in bytes
    var now = Time.now().value(); //in seconds from UNIX epoch in UTC
    return [now,now,battery,freeMemory];
}
