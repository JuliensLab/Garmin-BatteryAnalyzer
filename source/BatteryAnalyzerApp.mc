using Toybox.Application as App;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

//! App constants
const HISTORY_MAX = 500; // 5000 points = 5 times a full discharge
const INTERVAL_MIN = 60;//temporal event in minutes

//! Object store keys
const HISTORY_KEY = 2;
const LAST_HISTORY_KEY = 3;
const COUNT = 1;

const COLOR_BAT = 0x55FF55;
const COLOR_MEM = 0xFF5555;

//! History Array data type
enum{
	TIMESTAMP_START,
	TIMESTAMP_END,
	BATTERY,
	FREEMEMORY
}

var ableBackground=false;

(:background)
class BatteryAnalyzerApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    	//objectStorePut(HISTORY_KEY,null);
    	
	    //App.getApp().deleteProperty(0);
	    //App.getApp().deleteProperty(1);
	    //App.getApp().deleteProperty(2);
	    //App.getApp().deleteProperty(3);
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {	
    	//Sys.println("App/getInitialView");
    	//register for temporal events if they are supported
    	if(Toybox.System has :ServiceDelegate) {
    		ableBackground=true;
    		Background.registerForTemporalEvent(new Time.Duration(INTERVAL_MIN * 60));//x mins - total in seconds
    	}
        return [ new BatteryAnalyzerView() , new BatteryAnalyzerInitDelegate() ];
    }
    
    function onBackgroundData(data) {
    	//Sys.println("App/onBackgroundData");
    	//Sys.println("data received " + data);
		analyzeAndStoreData(data);    	
        Ui.requestUpdate();
    }    

    function getServiceDelegate(){
    	//Sys.println("App/getServiceDelegate");
        return [new BatteryAnalyzerServiceDelegate()];
    }

}

function analyzeAndStoreData(data){
    //Sys.println("analyzeAndStoreData");
	var lastHistory = App.getApp().getProperty(LAST_HISTORY_KEY);
	if (lastHistory == null){ // no data yet
		objectStoreAdd(HISTORY_KEY, data);
	} else { //data already exists
		if (lastHistory[BATTERY] == data[BATTERY]){
			var history = App.getApp().getProperty(HISTORY_KEY);
			history[history.size()-1][TIMESTAMP_END] = data[TIMESTAMP_END];
			App.getApp().setProperty(HISTORY_KEY, history);
		} else {
			objectStoreAdd(HISTORY_KEY, data);
		}
	}
	App.getApp().setProperty(LAST_HISTORY_KEY, data);
	App.getApp().setProperty(COUNT, objectStoreGet(COUNT,0)+1);
}

// Global method for getting a key from the object store
// with a specified default. If the value is not in the
// store, the default will be saved and returned.
function objectStoreAdd(key, newValue) {
    //Sys.println("objectStoreAdd");
	var app = App.getApp();
    var existingArray = app.getProperty(key);
    if(newValue != null) {
    	if(!(existingArray instanceof Toybox.Lang.Array)) {//if not array (incl is null), then create first item of array
	        app.setProperty(key, [newValue]);
	    } else {//existing value is an array -> append data to array end
			if(existingArray.size() > HISTORY_MAX){
				app.setProperty(key,existingArray.slice(1, HISTORY_MAX-1).add(newValue));
			} else {
				if(existingArray.size() < HISTORY_MAX){
		        	app.setProperty(key, existingArray.add(newValue));
				} else {
					app.setProperty(key,existingArray.slice(1, existingArray.size()).add(newValue));
				}
			}
	    }
	}
}

// Global method for getting a key from the object store
// with a specified default. If the value is not in the
// store, the default will be saved and returned.
function objectStoreGet(key, defaultValue) {
    //Sys.println("objectStoreGet");
    var value = App.getApp().getProperty(key);
    if((value == null) && (defaultValue != null)) {
        value = defaultValue;
        App.getApp().setProperty(key, value);
        }
    return value;
}

// Global method for putting a key value pair into the
// object store. This method doesn't do anything that
// setProperty doesn't do, but provides a matching function
// to the objectStoreGet method above.
function objectStorePut(key, value) {
    //Sys.println("objectStorePut");
    App.getApp().setProperty(key, value);
}
function objectStoreErase(key) {
    //Sys.println("objectStorePut");
    App.getApp().deleteProperty(key);
}