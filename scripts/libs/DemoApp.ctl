//*****************************************************************************
// Control function library for the PVSS_DemoApplication **********************
//*****************************************************************************
// File:		scripts/libs/DemoApp.ctl									  *
// Purpose:		library functions for framework, base-layout etc.			  *
// Author:		MS										  					  *
// Creation:	2001-04-01                                                    *
// Copyright:	(c)2001	ETM Aktiengesellschaft                                *
//																			  *
// Functions																  *
// Returntype:	Name:					Purpose:							  *
// void			da_onClick()  			functions after mouseclick      	  *
//                                                                            *  
// Last modified:	Author:		Changes:                                      *	
// 2001-04-01		MS			baseversion									  *
// YYYY-MM-DD		You			please describe modifications
// 2007-07-17            mholz                 Web Server to Port 81				  *
// 														 					  *
//*****************************************************************************

//*****************************************************************************
// da_alwaysOnTop()	                                                          *
// Purpose: Start panel with new module and the "alwaysOnTop attribute        *
//*****************************************************************************
da_alwaysOnTop(string panel, string module, string dollar1 = "", string dollar2 = "", string dollar3 = "")
{
  dyn_string parameter;
  
  if (dollar1 != "")
    dynAppend(parameter, dollar1);  // "$name:" + "string"
  if (dollar2 != "")
    dynAppend(parameter, dollar2);
  if (dollar3 != "")
    dynAppend(parameter, dollar3);

  if (isModuleOpen (module) == FALSE)
  {
    ModuleOnWithPanel(module, 
                      -1, -1, 0, 0, 1, 1, 
                      "None", 
                      panel, //"vision/dpe_monitor.pnl",
                      panel, //"vision/dpe_monitor.pnl",
                      parameter);
    stayOnTop(TRUE, module);
  }
}

//*****************************************************************************
// bool da_excelReport()	                                                    *
// Purpose: Start excel report                                                *
//*****************************************************************************
da_excelReport()
{
  string xlsFile=DATA_PATH+"xls_report/Report.xls";
  strreplace(xlsFile,"/","\\");
  system("CMD /c start excel.exe " + xlsFile);
}

//*****************************************************************************
// bool da_quit()	                                                          *
// Purpose: Quit demo application                                             *
//*****************************************************************************
da_quit()
{
  bool       stopSndEnabled, SoundOn;
  string     soundfile;
  dyn_float  fanswer;
  dyn_string sanswer;
  
  ChildPanelOnCentralModalReturn("vision/MessageWarning2",getCatStr("sc","attention"),
                      
  makeDynString("$1:"+getCatStr("DemoApp","reallyClose"),
                "$2:"+getCatStr("general","OK"), 
                "$3:"+getCatStr("general","cancel")), 
                fanswer, sanswer);  
                    
  if(fanswer[1] != 0)
  {
    dpGet("ApplicationProperties.sound.onStop:_online.._value",soundfile,
          "ApplicationProperties.sound.onStopEnabled:_online.._value",stopSndEnabled,
          "ApplicationProperties.sound.on:_online.._value", SoundOn);
          
    if (stopSndEnabled == 1 && SoundOn == 1)
    {  
      delay(1,200);
      da_startSound(soundfile,FALSE);
      delay(3);
    }
    
    STD_LogoutCurrentUser();
    STD_CloseUis();
  }
}

//*****************************************************************************
// bool da_webServer()	                                                      *
// Purpose: Start web server                                                  *
//*****************************************************************************
da_webServer()
{
  system("cmd /c start IEXPLORE.EXE http://localhost:81");
}

//*****************************************************************************
// bool da_wapClient()	                                                      *
// Purpose: Start WAP client                                                  *
//*****************************************************************************
da_wapClient()
{
  //system("\"C:/Programme/Yourwap/Wireless Companion/wapsim.exe localhost/wap\"");
  //system("cmd /c start \"C:/Programme/Yourwap/Wireless Companion/wapsim.exe localhost/wap\"");
  //system("start \"C:/Programme/Yourwap/Wireless Companion/wapsim.exe\" localhost/wap");
  //system("cmd /c cd /d \"C:/Programme/Yourwap/Wireless Companion\" start wapsim.exe");
  //system("cmd /c start startWapSim.bat");
  system("start cmd /c \"C:\\Programme\\YOURWAP\\Wireless Companion\\wapsim.exe\"");
}

//*****************************************************************************
// bool da_startSimulation ()	                                              *
// Purpose: Start PVSS_DemoApplication simulation                             *
//*****************************************************************************
bool da_startSimulation()
{
  dpSet("ApplicationProperties.simulation.on:_original.._value",TRUE, 
        "ApplicationProperties.simulation.values.on:_original.._value",TRUE);
}

//*****************************************************************************
// bool da_stopSimulation ()	                                              *
// Purpose: Start PVSS_DemoApplication simulation                             *
//*****************************************************************************
bool da_stopSimulation()
{
  dpSet("ApplicationProperties.simulation.on:_original.._value",FALSE);
}

//*****************************************************************************
// bool da_startSound ( string wavFileName, bool loopSound);	              *
// Parameters:	Exactly like in the orig. function 'startSound' - OnlineHelp  *
// Purpose:		Check if sound is generally switched on - ApplicationProps... *
//*****************************************************************************
bool da_startSound(string wavFileName, bool loopSound)
{
  bool   soundOn, successful = FALSE;
  string SoundFile;

  dpGet("ApplicationProperties.sound.on:_online.._value",soundOn);
  if (soundOn && (wavFileName != ""))
  {
    SoundFile = getPath(DATA_REL_PATH,"sounds/"+wavFileName);
    successful = startSound(SoundFile,loopSound);
    return successful;
  }
}
// end of da_onClick() ********************************************************

//*****************************************************************************
// bool da_LayerOnPanelInModule (int layerNumber, string PanelName,           *
//								 string ModulName)                            *
// Parameters:	selfexplaning											      *
// Purpose:		switch a layer (layerNumber) in a given panel and module      *
//				to visible											          *
//*****************************************************************************
da_LayerOnPanelInModule(int layerNumber ,string PanelName, string ModulName)
{
  string dp;

  dpSet(myUiDpName()+".LayerOn.ModuleName:_original.._value", ModulName,
        myUiDpName()+".LayerOn.Layer:_original.._value", layerNumber,
        myUiDpName()+".LayerOn.PanelName:_original.._value", PanelName);

}
// end of da_LayerOnPanelInModule()********************************************

//*****************************************************************************
// bool da_LayerOffPanelInModule (int layerNumber, string PanelName,          *
//                                string ModulName)                           *
// Parameters:	selfexplaning											      *
// Purpose:		switch a layer (layerNumber) in a given panel and module      *
//				to invisible											      *
//*****************************************************************************
da_LayerOffPanelInModule(int layerNumber ,string PanelName, string ModulName)
{
  string dp;

  dpSet(myUiDpName()+".LayerOff.ModuleName:_original.._value", ModulName,
        myUiDpName()+".LayerOff.Layer:_original.._value", layerNumber,
        myUiDpName()+".LayerOff.PanelName:_original.._value", PanelName);

}
// end of da_LayerOffPanelInModule()*******************************************

//*****************************************************************************
// int da_CalcBarStatistics                                                   *
//                                                                            *
// Parameters:	see at declaration header   							      *
// Purpose:		calculates bar trend statistics                               *
//*****************************************************************************
int da_CalcBarStatistics(//Inputs
                         time       tend,            //time of end
                         time       tstart,          // time of begin
                         int        numberOfClasses, //number of classes
                         dyn_float  values,          //the set of values to be evaluated
                         dyn_time   times,           //the set of timestamps of values
                         float      minVal,          //minimum
                         float      maxVal,          //maximum
                         int        slope,
                         //Outputs
                         dyn_float  &classRange_min, //the lower limit of each class
                         dyn_float  &classRange_max, //the upper limit of each class
                         dyn_float  &classFrequency, //percentage of classSum
                         dyn_time   &classSum        //the total time summation of each class
                         )
{
  int        i,k,maxValues;
  time       totalTime;
  dyn_time	 durations;

  for (i = 1; i <= numberOfClasses; i++)
  {
    classRange_min[i] = minVal + (i-1)*(maxVal-minVal) / numberOfClasses;
    classRange_max[i] = minVal + (i)  *(maxVal-minVal) / numberOfClasses;
    classFrequency[i] = 0.0;
    setPeriod(classSum[i],0);
  }

  maxValues = dynlen(values);
  if((maxValues == 0) || (dynlen(times) == 0))
    return -1;	//nothing to do
    
  // values are only valid in the evaluated period,
  // earlier or later values are used for calculation
  // with the timestamps of start and end;

  if (times[1] < tstart)
    times[1] = tstart;
  if (times[maxValues] > tstart)
    times[maxValues] = tend;

  totalTime = times[maxValues] - times[1];
  
  durations[1]     = 0;

  if(slope == 0) //timestamps are not equidistant
  {
    for (k = 2; k <= maxValues; k++)
    {
      durations[k-1]     = times[k] - times[k-1];

      for (i = 1; i <= numberOfClasses; i++)
      {
        if ((values[k-1] >= classRange_min[i]) && (values[k-1] < classRange_max[i]))
        {
          classSum[i] = classSum[i] + durations[k-1];
          classFrequency[i] = 100.0 * period(classSum[i]) / period(totalTime);
          //leave inner loop at bottom
          break;
        }    
      }
    }
  }
  else //AC Types with equidistant timestamps
  {
    i = 1;
    dynSortAsc(values); //sort ascending
    totalTime = slope * (maxValues - 1);

    for (k = 2; k <= maxValues; k++)
    {
      while(TRUE) //endless loop left via break statement
      {
        if ((values[k-1] >= classRange_min[i]) && (values[k-1] < classRange_max[i]))
        {
          classSum[i] = classSum[i] + slope;
          classFrequency[i] = 100.0 * period(classSum[i]) / period(totalTime);
          break; //break while statement
        }
        else
          i++; //because of values sorted ascending, values[k-1] must be a member of following classes
        if(i > numberOfClasses)
          return 0;
      }
    }
  }
  return 0;

}

// end of da_CalcBarStatistics                                                   *


//if ( dynlen(getLastError()) )
//{ 
//  dyn_errClass err = getLastError();
//  errorDialog(err);
//  return;
//}
