using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Graphics as Gfx;


class BatteryAnalyzerInitDelegate extends Ui.InputDelegate{
	
	function initialize(){
        InputDelegate.initialize();
	}
	
	function goBack(){
		return false;
    }

    function onSelect(){
	 //Sys.println("onSelect");
		analyzeAndStoreData(getData());
        Ui.requestUpdate();
        return true;    
    }
	
    function onTap(evt) {
		onSelect();
		return true;
    }
    
    
    function onMenu(){
	 //Sys.println("onMenu");
    	
        var dialog = new Ui.Confirmation("Erase history");
        Ui.pushView(dialog, new ConfirmationDialogDelegate(), Ui.SLIDE_IMMEDIATE);
        return true;
    }
    
    function onKey(evt) {
    	if (evt.getKey() == Ui.KEY_ENTER){
			onSelect();
			return true;
    	}
    	
    	if (evt.getKey() == Ui.KEY_MENU){
    		return onMenu();
    	}
    	
		return false;
    }
    
}


class ConfirmationDialogDelegate extends Ui.ConfirmationDelegate {
    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(value) {
        if (value == 0) {
			//Keep
        }
        else {
            //Erase
            objectStoreErase(HISTORY_KEY);
            objectStoreErase(LAST_HISTORY_KEY);
            objectStoreErase(COUNT);
        }
    }
}


class BatteryAnalyzerView extends Ui.View {

	var ctrX, ctrY;

    function initialize() {
    	////Sys.println("View/initialize");
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    	////Sys.println("View/onLayout");
    	ctrX = dc.getWidth()/2;
    	ctrY = dc.getHeight()/2; 
    	
    	// add data to ensure most recent data is shown and no time delay on the graph.
		analyzeAndStoreData(getData());
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	////Sys.println("View/onShow");
    }

    // Update the view
    function onUpdate(dc) {
    	////Sys.println("View/onUpdate");
        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
        dc.setColor(0x000000, 0x000000);		
        dc.clear();
        
       	dc.setColor(0xFFFFFF, Gfx.COLOR_TRANSPARENT);	
        
        if (!ableBackground){
    		////Sys.println("  View/onUpdate/!ableBackground");	
			dc.drawText(ctrX, ctrY, Gfx.FONT_MEDIUM, "Device does not\nsupport background\nprocesses", Gfx.TEXT_JUSTIFY_CENTER |  Gfx.TEXT_JUSTIFY_VCENTER);
        } else {
    		////Sys.println("  View/onUpdate/ableBackground");
        	var app = App.getApp();
        	var history = app.getProperty(HISTORY_KEY);
       		var battery = Sys.getSystemStats().battery;
        	if (!(history instanceof Toybox.Lang.Array)){
    			////Sys.println("  View/onUpdate/ableBackground/!Array");
        		dc.drawText(ctrX, ctrY, Gfx.FONT_MEDIUM, "No data has yet\nbeen recorded\n\nBattery = " + battery.toNumber() + "%", Gfx.TEXT_JUSTIFY_CENTER |  Gfx.TEXT_JUSTIFY_VCENTER);
        	} else { //there is an array
    			////Sys.println("  View/onUpdate/ableBackground/Array");
        		drawChart2(dc,[10,ctrX*2-10,ctrY-50,ctrY+50],history,0x5555AA,0xAAAAAA,0xFFAAAA);
       			dc.setColor(0xFFFFFF, Gfx.COLOR_TRANSPARENT);	
        		dc.drawText(ctrX, 15, Gfx.FONT_MEDIUM, battery.toNumber() + "%", Gfx.TEXT_JUSTIFY_CENTER |  Gfx.TEXT_JUSTIFY_VCENTER);
        	}
        }
    }
    
    
    
	function drawChart2(dc,xy,chartDataNormalOrder,colorChart,colorDataNormal, colorDataImportant){
    	var X1 = xy[0], X2 = xy[1], Y1 = xy[2], Y2 = xy[3];
    	var chartData = chartDataNormalOrder.reverse();
    	
    	//! pixels available in chart frame
    	var Yframe = Y2 - Y1;// pixels available for level
    	var Xframe = X2 - X1;// pixels available for time
    	var Xnow = Xframe * 2 / 3; // position of now, equivalent to: pixels available for left part of chart, with history only (right part is future prediction)
    	
    	//! evaluate scale of graph y-axis
    	var Ymax = 100; //max value for battery
    	
    	//! draw y gridlines
    	dc.setPenWidth(1);
    	var yGridSteps = 0.1;
    	for (var i = 0; i <= 1.05; i += yGridSteps){
	    	if (i == 0 or i == 0.5 or i.toNumber() == 1){
	    		dc.setColor(0xAAAAAA,Gfx.COLOR_TRANSPARENT);
	    	} else {
	    		dc.setColor(0x555555,Gfx.COLOR_TRANSPARENT);
	    	}
	    	dc.drawLine(X1 - 10,Y2 - (i*Ymax),X2 + 10,Y2 - (i*Ymax));
    	}
    	
    	//! draw x and y axis
    	dc.setColor(0xFFFFFF,Gfx.COLOR_TRANSPARENT);
    	dc.setPenWidth(2);
    	//dc.drawLine(X1,Y1+3,X1,Y2-1);
    	//dc.drawLine(X1,Y2-1,X2,Y2-1);
    	
    	
    	//! y-legend
    	/*
    	yGridSteps = 0.5;
    	dc.setColor(0xAAAAAA,Gfx.COLOR_TRANSPARENT);
    	for (var i = 0; i <= 1.05; i += yGridSteps){
	    	dc.drawText(X1-2, Y2-2 - (i*Ymax), Gfx.FONT_XTINY, (i*100).toNumber(), Gfx.TEXT_JUSTIFY_RIGHT |  Gfx.TEXT_JUSTIFY_VCENTER);
        }
        */
        
    	////Sys.println(App.getApp().getProperty(LAST_HISTORY_KEY));
    	//! draw data
    	var charDataSize = 0;
    	var downSlopeSec = null;
    	if (chartData instanceof Array){ if (chartData[0] != null){
    		charDataSize = chartData.size();
    		var totalMemory = Sys.getSystemStats().totalMemory;
    		downSlopeSec = downSlope(chartData);
    	
    	
    		//! calculate down slope
	    	var downSlopeStr = "";
	    	var timeLeftSecUNIX = null;
		    dc.setColor(0xFFFFFF,Gfx.COLOR_TRANSPARENT);
		    if (downSlopeSec != null){
	    		var downSlopeHours = (downSlopeSec * 60 * 60);
	    		if (downSlopeHours * 24 <= 100){
	    			downSlopeStr = (downSlopeHours*24).toNumber() + "%/day";
	    		} else {
	    			downSlopeStr = (downSlopeHours).toNumber() + "%/hour";
	    		}	
	    		//downSlopeStr = " (" + downSlopeStr + ")";
	    		downSlopeStr = "Discharge " + downSlopeStr;
	    		
				var timeLeftSec = -(chartData[0][BATTERY] / (downSlopeSec));
				timeLeftSecUNIX = timeLeftSec + chartData[0][TIMESTAMP_END];
				var timeLeftStr = minToStr(timeLeftSec / 60);
				dc.setColor(0xFFFFFF,Gfx.COLOR_TRANSPARENT);
				dc.drawText(ctrX, 33, Gfx.FONT_TINY, downSlopeStr, Gfx.TEXT_JUSTIFY_CENTER);
		    } else {
				dc.setColor(0xAAAAAA,Gfx.COLOR_TRANSPARENT);
				dc.drawText(ctrX, 33, Gfx.FONT_XTINY, "More time needed...", Gfx.TEXT_JUSTIFY_CENTER);		    	
		    }
    		
	    	//! evaluate scale of graph x-axis
	    	var timeMostRecentPoint = chartData[0][TIMESTAMP_END];
	    	var timeMostFuturePoint = timeMostRecentPoint;
	    	if (timeLeftSecUNIX != null){
	    		timeMostFuturePoint = timeLeftSecUNIX;
	    	}
	    	var timeLeastRecentPoint = timeLastFullCharge(chartData);
	    	////Sys.println("time distance in minutes="+(timeMostRecentPoint - timeLeastRecentPoint)/60);
	    	var xHistoryInMin = (0.0 + timeMostRecentPoint - timeLeastRecentPoint)/60;// max value for time in minutes
	    	xHistoryInMin = MIN(MAX(xHistoryInMin,60),60*25*30);
	    	var xFutureInMin = (0.0 + timeMostFuturePoint - timeMostRecentPoint)/60;// max value for time in minutes
	    	xFutureInMin = MIN(MAX(xFutureInMin,60),60*25*30);
	    	var XmaxInMin = xHistoryInMin + xFutureInMin;// max value for time in minutes
	    	
	    	var XscaleMinPerPxl = (0.0 + XmaxInMin) / Xframe;// in minutes per pixel
    	    Xnow = xHistoryInMin / XscaleMinPerPxl;
    	    
	    	//! draw now axis
	    	dc.setPenWidth(2);
	    	dc.drawLine(X1 + Xnow,Y1+1,X1 + Xnow,Y2);
	    	
	    	//! draw graduation
	    	dc.setPenWidth(1);
	    	dc.drawLine(X1 + Xnow,Y1+1,X1 + Xnow,Y2);
	    	
	    		
	    		
	    	//! draw future estimation
    		dc.setPenWidth(3);
	    	if (downSlopeSec != null){
			    
		    	var pixelsAvail = Xframe - Xnow;
		    	var timeDistanceMin = pixelsAvail * XscaleMinPerPxl;
		    	var xStart = X1 + Xnow;
		    	var xEnd = xStart + pixelsAvail;
		    	var valueStart = chartData[0][BATTERY];
		    	var valueEnd = chartData[0][BATTERY] + downSlopeSec * 60 * timeDistanceMin;
		    	if (valueEnd < 0){
		    		timeDistanceMin = - chartData[0][BATTERY] / (downSlopeSec * 60);
		    		valueEnd = 0;
		    		xEnd = xStart + timeDistanceMin / XscaleMinPerPxl;
		    	}
		    	var yStart = Y2 - (valueStart * Yframe) / Ymax;
		    	var yEnd = Y2 - (valueEnd * Yframe) / Ymax;
			
    			dc.setColor(0xFFAAFF,Gfx.COLOR_TRANSPARENT);
				dc.drawLine(xStart,yStart,xEnd,yEnd);
	    	}
	    	
	    	
	    	//! draw history data	
	    	dc.setPenWidth(3);
	    	var timeInSecs = 0;
	    	var lastPoint = null;
	    	//////Sys.println("chartData.size = " + chartData.size());
	    	for (var i = 0; i < chartData.size(); i++){
	    		////Sys.println(i + " " + chartData[i]);
	    		// End (closer to now)
	    		var timeEnd = chartData[i][TIMESTAMP_END];
	    		var dataTimeDistanceInMinEnd = ((timeMostRecentPoint - timeEnd)/60).toNumber();
	    		
	    		if (dataTimeDistanceInMinEnd > xHistoryInMin){
	    			continue;
	    		} else {
	    			var dataHeightBat = (chartData[i][BATTERY] * Yframe) / Ymax;
	    			var yBat = Y2 - dataHeightBat;
	    		//	var dataHeightMem = ((100 - (chartData[i][FREEMEMORY] * 100 / totalMemory)) * Yframe) / Ymax;
	    		//	var yMem = Y2 - dataHeightMem;
	    			var dataTimeDistanceInPxl = dataTimeDistanceInMinEnd / XscaleMinPerPxl;
	    			var x = X1 + Xnow - dataTimeDistanceInPxl;
	    			//////Sys.println(dataTimeDistanceInMinEnd + " (" + dataTimeDistanceInPxl + ") " + chartData[i][BATTERY] + " (" + dataHeight + ")");
	    			if (i > 0){ 
	    		//		dc.setColor(COLOR_MEM,Gfx.COLOR_TRANSPARENT);
				//		dc.drawLine(x,yMem,lastPoint[0],lastPoint[2]);
	    				dc.setColor(COLOR_BAT,Gfx.COLOR_TRANSPARENT);
						dc.drawLine(x,yBat,lastPoint[0],lastPoint[1]);
					}
			    	lastPoint = [x,yBat];//,yMem];
			    }
	    		
	    		// Start (further to now)
	    		var timeStart = chartData[i][TIMESTAMP_START];
	    		var dataTimeDistanceInMinStart = ((timeMostRecentPoint - timeStart)/60).toNumber();
	    		
	    		if (dataTimeDistanceInMinStart > xHistoryInMin){
	    			continue;
	    		} else {
	    			var dataTimeDistanceInPxl = dataTimeDistanceInMinStart / XscaleMinPerPxl;
	    			var x = X1 + Xnow - dataTimeDistanceInPxl;
	    			//////Sys.println(dataTimeDistanceInMinStart + " (" + dataTimeDistanceInPxl + ") ");
	    		//	dc.setColor(COLOR_MEM,Gfx.COLOR_TRANSPARENT);
				//	dc.drawLine(x,lastPoint[2],lastPoint[0],lastPoint[2]);
	    			dc.setColor(COLOR_BAT,Gfx.COLOR_TRANSPARENT);
					dc.drawLine(x,lastPoint[1],lastPoint[0],lastPoint[1]);
			    	lastPoint = [x,lastPoint[1]];//,lastPoint[2]];
			    }
		    }
		    
	        //! x-legend
	    	dc.setColor(0xFFFFFF,Gfx.COLOR_TRANSPARENT);
	    	var timeStr = minToStr(xHistoryInMin);
	        dc.drawText(27, Y2 +1, Gfx.FONT_TINY,  "<-" + timeStr, Gfx.TEXT_JUSTIFY_LEFT);
	        
	    	timeStr = minToStr(xFutureInMin);
	        dc.drawText(ctrX*2 - 27, Y2 +1, Gfx.FONT_TINY, timeStr + "->", Gfx.TEXT_JUSTIFY_RIGHT);
	        
	        if (downSlopeSec != null){
	        	var timeLeftMin = -(100 / (downSlopeSec * 60));
		    	timeStr = minToStr(timeLeftMin);
	    		dc.setColor(0xFFFFFF,Gfx.COLOR_TRANSPARENT);
		        dc.drawText(ctrX, ctrY*2 - 43, Gfx.FONT_SMALL, "100% = " + timeStr, Gfx.TEXT_JUSTIFY_CENTER);
        	}	
	    	//timeStr = minToStr((Time.now().value() - timeMostRecentPoint)/60);
	        //dc.drawText(X1+Xnow, Y2 +1, Gfx.FONT_TINY, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
        	
        
    	}}
			
		//DEBUG
	    //dc.setColor(0x555555,Gfx.COLOR_TRANSPARENT);
    	//dc.drawText(ctrX, Y2 +1, Gfx.FONT_TINY, charDataSize, Gfx.TEXT_JUSTIFY_CENTER);
    	
    	
    }
    function timeLastCharge(data){
		for (var i = 0; i < data.size() - 1; i++){
			if (data[i][BATTERY] > data[i+1][BATTERY]){
				return data[i][TIMESTAMP_END];
			}
		}
    	return data[data.size()-1][TIMESTAMP_START];
    }
    
    function timeLastFullCharge(data){
		for (var i = 0; i < data.size(); i++){
			if (data[i][BATTERY] == 100){
				return data[i][TIMESTAMP_END];
			}
		}
    	return data[data.size()-1][TIMESTAMP_START];
    }
    
    function downSlope(data){//data is history data as array / return a slope in percentage point per second
    	//Sys.println("in downSlope()");
    	if (data.size() <= 2){
    		return null;
    	}
    	//Sys.println("data.size " + data.size());
    	
    	var slopes = new [0];
	    var i = 0, j = 0;
	    
	    var timeMostRecent = data[0][TIMESTAMP_END], timeLeastRecent, valueMostRecent = data[0][BATTERY], valueLeastRecent;
	    for (; i < data.size()-1; i++){
	    // goal is to store X1 X2 Y1 Y2 for each downslope (actually up-slope because reversed array) and store all slopes in array to later do array average.
	    	//Sys.println("data[" + i + "]=" + data[i]);
    	
	    	if (data[i][BATTERY] <= data[i+1][BATTERY] and i < data.size()-2 and ((data[0][TIMESTAMP_END] - data[i][TIMESTAMP_END]) /60 /60 /24 < 10)){ //Normal case, battery going down or staying level, less than 10 days ago
	    		// do nothing, keep progressing in data
	    		//Sys.println("progressing... " + i);
    	
	    	} else { //battery charged or ran out of data
	    		//Sys.println("action... " + i);
	    		timeLeastRecent = data[i][TIMESTAMP_START];
    			valueLeastRecent = data[i][BATTERY];
    			timeMostRecent = data[j+1][TIMESTAMP_END];
    			valueMostRecent = data[j+1][BATTERY];
    			//Sys.println(timeLeastRecent + " " + timeMostRecent + " " + valueLeastRecent + " " + valueMostRecent);
	    		if (timeMostRecent - timeLeastRecent < 1 * 60 * 60) {//if less than 1 hours data
	    			//Sys.println("discard... " + i);
	    			//discard
	    		} else { //save
	    			//Sys.println("save... " + i);
	    			var slope = (0.0 + valueLeastRecent - valueMostRecent) / (timeLeastRecent - timeMostRecent);
	    			if (slope < 0){
	    				slopes.add(slope);
	    			}
	    			//Sys.println("slopes " + slopes);
	    		}
	    		j = i;
	    	}
    	}
    	if (slopes.size() == 0){
    		return null;
    	} else {
    		var sumSlopes = 0;
    		for (var i = 0; i < slopes.size(); i++){
    			sumSlopes += slopes[i];
    			//Sys.println("sumSlopes " + sumSlopes);
    		}
    		var avgSlope = sumSlopes/slopes.size();
    		//Sys.println("avgSlope " + avgSlope);
    		return (avgSlope);
    	}
    }
    
    function minToStr(min){
    	//////Sys.println("min : " + min);
    	var str;
    	if (min < 1){
    		str = "Now";
    	} else if (min < 60){
    		str = min.toNumber() + "m";
    	} else if (min < 60 * 2){
    		var hours = Math.floor(min/60);
    		var mins = min - hours * 60;
    		str = hours.toNumber() + "h" + mins.format("%02d");
    	} else if (min < 60 * 24){
    		var hours = Math.floor(min/60);
    		var mins = min - hours * 60;
    		str = hours.toNumber() + "h" + mins.format("%02d");
    	} else {
    		var days = Math.floor(min/60/24);
    		var hours = Math.floor((min / 60) - days * 24);
    		//var mins = (min - hours * 60 - days * 24 * 60).toNumber();
    		str = days.toNumber() + "d " + hours.toNumber() + "h";//  + mins.format("%02d") + "m";
    	}
    	//////Sys.println("str = " + str);
    	return str;
    }
    
	function MAX (val1, val2){
		if (val1 > val2){
			return val1;
		} else {
			return val2;
		}
	}
	function MIN (val1, val2){
		if (val1 < val2){
			return val1;
		} else {
			return val2;
		}
	}
	    
	
    /*
    
	function drawChart(dc,xy,chartData1,colorChart,colorDataNormal, colorDataImportant){
    	var X1 = xy[0], X2 = xy[1], Y1 = xy[2], Y2 = xy[3];
    	var chartData = chartData1.reverse();
    	
    	//! evaluate scale of graph y-axis
    	var Ymax = 100; //max value for battery
    	var Xmax = X2 - X1 - 5;//2 pixels for chart axis and space
    	
    	//! draw data bars
    	dc.setColor(colorDataNormal,Gfx.COLOR_TRANSPARENT);
    	dc.setPenWidth(1);
    	var timeEnd = 1, timeStart = 0, valueEnd = 1, valueStart = 0;
    	for (var i = 0; i < MIN(Xmax,chartData.size()); i++){
    		dc.setColor(colorDataNormal,Gfx.COLOR_TRANSPARENT);
    	//	TIMESTAMP_START,BATTERY,FREEMEMORY
    		var j = MIN(Xmax,chartData.size()) - i;
    		var dataHeight = (chartData[i][BATTERY] * (Y2 - Y1 - 4)) / Ymax; 
    		if (i == 0){
    			//dc.setColor(colorDataImportant,Gfx.COLOR_TRANSPARENT);
    			timeEnd = chartData[i][TIMESTAMP_START];
    			valueEnd = chartData[i][BATTERY];
    			var now = Time.now().value();
    			var hoursFromMomentStr = ((now - chartData[i][TIMESTAMP_START]) / 3600).format("%01d") + "h";
    			dc.drawText(X1+2 + j + 4, Y2 - dataHeight, Gfx.FONT_SMALL, chartData[i][BATTERY] + "%", Gfx.TEXT_JUSTIFY_LEFT |  Gfx.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(X1+2 + j, Y2 +1, Gfx.FONT_SMALL, hoursFromMomentStr, Gfx.TEXT_JUSTIFY_CENTER);
        	}
        	if (i == MIN(Xmax,chartData.size())-1){
    			dc.drawText(X1+2 + j - 6, Y2 - dataHeight, Gfx.FONT_SMALL, chartData[i][BATTERY] + "%", Gfx.TEXT_JUSTIFY_RIGHT |  Gfx.TEXT_JUSTIFY_VCENTER);
        		if(i > 20){
        			timeStart = chartData[i][TIMESTAMP_START];
    				valueStart = chartData[i][BATTERY];
    				var now = Time.now().value();
    				var hoursFromMomentStr = ((now - chartData[i][TIMESTAMP_START]) / 3600).format("%01d") + "h";
        			dc.drawText(X1+2 + j, Y2 +1, Gfx.FONT_SMALL, hoursFromMomentStr, Gfx.TEXT_JUSTIFY_CENTER);
        		}
        	}
    		dc.drawLine(X1+2 + j, Y2-4, X1+2 + j, Y2 - dataHeight);
    	}
    	
    	////Sys.println(timeEnd + " " + timeStart + " " + valueEnd + " " + valueStart);
    	//! draw trend 
    	var j = MIN(Xmax,chartData.size());
    	if (j > 24){
	    	var dataHeight = (chartData[0][BATTERY] * (Y2 - Y1 - 4)) / Ymax; 
	    	var slope = 0.0;
	    	////Sys.println(slope);
	    	slope = slope + (valueEnd - valueStart);
	    	////Sys.println(slope);
	    	//slope = slope * 60 * INTERVAL_MIN;
	    	//////Sys.println(slope);
	    	slope = slope / (j);
	    	////Sys.println(slope);
	    	////Sys.println("j " + j);
	    	var xDelta = Xmax - j;
	    	var yDelta = xDelta * slope;
	    	var xAtyZero = dataHeight / slope;
	    	var timexAtyZero = (0.0 + timeEnd - timeStart) * xAtyZero / 60 / INTERVAL_MIN / j;// 60 = in mins of history duration
	    	var timeStr = timexAtyZero.format("%01d") + "h";
	    	////Sys.println(xDelta + " " + yDelta);
	    	dc.drawLine(X1+2 + j,Y2 - dataHeight,(X1+2 + j) + xDelta,(Y2 - dataHeight) - yDelta);
	    	dc.drawText((X1+2 + j) - xAtyZero,Y2 + 1, Gfx.FONT_SMALL, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
	    }	
    	
    	//! draw x and y axis
    	dc.setColor(colorChart,Gfx.COLOR_TRANSPARENT);
    	dc.setPenWidth(2);
    	dc.drawLine(X1+1,Y1,X1+1,Y2-1);
    	dc.drawLine(X1+1,Y2-1,X2-1,Y2-1);
    	
    	//! draw max value
    	
    	dc.setColor(colorChart,colorBackground);
	    dc.drawText(X1 - 4, Y1, Gfx.FONT_XTINY, Ymax.toNumber().toString(), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
   		
    }*/    
	    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    	////Sys.println("View/onHide");
    }

}


