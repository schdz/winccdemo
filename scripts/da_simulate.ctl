//*****************************************************************************
// Runtime simulation script for the PVSS_DemoApplication *********************
//*****************************************************************************
// File:		scripts/da_simulate.ctl							  		      *
// Purpose:		simulation of status signals reacting to commands,            *
//				measurement values and partially also an interaction of both  *
// Author:		MS										  					  *
// Creation:	2001-04-30                                                    *
// Copyright:	(c)2001	ETM Aktiengesellschaft                                *
//																			  *
// Note:		For each type of status signals depending on commands, there  *
// 				is an own callback function. Measurements are generated       *
//				normally artificially, process simulation is only done for	  *
//				the 'water_supply' scenery. 								  *
//                                                                            *  
// Last modified:	Author:		Changes:                                      *	
// 2001-04-30		MK			baseversion									  *
// YYYY-MM-DD		You			please describe modifications				  *
// 														 					  *
//*****************************************************************************

// ************************* GLOBAL VARIABLES *********************************

//*****************************************************************************
// These global variables are used to perform the value- and process simulation
// for water supply, building automation, traffic control and weather station*
// Building_automation:                                                       //
  float fCooler,     fCoolerMax,                                              //
        fPreHeater,  fPreHeaterMax,                                           //
        fReHeater,   fReHeaterMax,                                            //
        fReHeater2,  fReHeaterMax2,                                           //
        fReHeater3,  fReHeaterMax3,                                           //
        fEvaporator, fEvaporatorMax;                                          //
                                                                              //
  bool  bCoolerState, bPreHeaterState, bReHeaterState, bReHeaterState2,       //
        bReHeaterState3, bEvaporatorState;                                    //
// Water_simulation                                                           //
  float fInflow1,      fInflow2,      fInMax1,      fInMax2,                  //
        fOutMax1,      fOutMax2,      fOutflow1,    fOutflow2,                //
        fInPosition1, fInPosition2,   fOutPosition1, fOutPosition2,           //
        fLevel1,      fLevel2,        fLevelMax1,    fLevelMax2;              //
                                                                              //
  bool  bInValve1Auto, bInValve2Auto, bOutValve1Auto, bOutValve2Auto;         //
// Traffic control                                                            //
  int   iLight1, iLight2, iLight3, iLight4,                                   //
        iTrafficTime;                                                         //
                                                                              //
  bool  bLight1Off,    bLight2Off,    bLight3Off,    bLight4Off,              //
        bLight1Manual, bLight2Manual, bLight3Manual, bLight4Manual;           //
                                                                              //
  dyn_bool bRed, bRedYellow, bGreen, bFlashingGreen, bYellow;                 //
// Weather station                                                            //
  int   iWeatherTime, iWeatherCountMS;                                        //
//*****************************************************************************        

main()
{ 
  int 		 i;
  dyn_string slide_valve2,
             asDp;
  addGlobal("GboSimOn",BOOL_VAR);
  addGlobal("GboSimValueOn",BOOL_VAR);
  addGlobal("GboSimCheckBackOn",BOOL_VAR);
  addGlobal("GboSimProcessOn",BOOL_VAR);
  addGlobal("GfDelayCheckBack",INT_VAR);
  addGlobal("GiSpeedSimValue",INT_VAR);

  GboSimOn=0;
  GboSimCheckBackOn=0;
  GboSimValueOn=0;

  dpConnect("simulation_CB","ApplicationProperties.simulation.on:_online.._value",
                            "ApplicationProperties.simulation.values.on:_online.._value",                            
                            "ApplicationProperties.simulation.values.speed:_online.._value",
                            "ApplicationProperties.simulation.checkback.on:_online.._value",                            
                            "ApplicationProperties.simulation.checkback.delay:_online.._value",
                            "ApplicationProperties.simulation.process.on:_online.._value");  


  //****************************************************************************
  //*********Simulation for the 'traffic_control' scenery*******************
  //****************************************************************************
  
  //Simulation for all the Datapoints with the DpType TC_TRAFFIC_SIGN
  asDp = dpNames("*","TC_TRAFFIC_SIGN");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("traffic_sign_CB",0,asDp[i]+".cmd.value:_online.._value",
                                      asDp[i]+".cmd.off:_online.._value",
                                      asDp[i]+".cmd.manual:_online.._value");
    }
  }
 
  //Simulation for all the Datapoints with the DpType TC_TRAFFIC_ALERT  
  asDp = dpNames("*","TC_TRAFFIC_ALERT");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("traffic_alert_CB",0,asDp[i]+".cmd.alert:_online.._value",
                                       asDp[i]+".cmd.off:_online.._value",
                                       asDp[i]+".cmd.manual:_online.._value");
    }
  }

  //Simulation for all the Datapoint with the DpType TC_TRAFFIC_LIGHTS
  asDp = dpNames("*","TC_TRAFFIC_LIGHTS");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("traffic_Light_CB",0,asDp[i]+".cmd.manual:_online.._value"
                                      ,asDp[i]+".cmd.off:_online.._value"
                                      ,asDp[i]+".cmd.red:_online.._value"
                                      ,asDp[i]+".cmd.red-yellow:_online.._value"
                                      ,asDp[i]+".cmd.yellow:_online.._value"
                                      ,asDp[i]+".cmd.flashing_yellow:_online.._value"
                                      ,asDp[i]+".cmd.green:_online.._value"
                                      ,asDp[i]+".cmd.flashing_green:_online.._value");
    } 
  } 

  //****************************************************************************
  //*********Simulation for the 'building_automation' scenery*******************
  //****************************************************************************
  
  //Simulation for all the Datapoint with the DpType 'HVAC_DEVICESWITCH'
  asDp = dpNames("*","HVAC_DEVICESWITCH");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("HVAC_deviceswitch_CB",0,asDp[i]+".cmd.auto:_online.._value",
                                           asDp[i]+".cmd.off:_online.._value",
                                           asDp[i]+".cmd.manual:_online.._value");
    }
  }

  //Simulation for all the Datapoint with the DpType 'HVAC_FAN'
  asDp = dpNames("*","HVAC_FAN");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("HVAC_fan_CB",0,asDp[i]+".cmd.n1:_online.._value",
                                  asDp[i]+".cmd.n2:_online.._value",
                                  asDp[i]+".cmd.off:_online.._value",
                                  asDp[i]+".cmd.manual:_online.._value");
    }
  }

  //Simulation for all the Datapoint with the DpType 'HVAC_FLAP' 
  asDp = dpNames("*","HVAC_FLAP");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("HVAC_flap_CB",0,asDp[i]+".cmd.open:_online.._value",
                                   asDp[i]+".cmd.close:_online.._value");
    }
  }

  //Simulation for all the Datapoint with the DpType 'HVAC_PREHEATER'
  asDp = dpNames("*","HVAC_PREHEATER");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
      {
        dpConnect("HVAC_preheaterPump_CB",0,asDp[i]+".pump.cmd.on:_online.._value",
                                            asDp[i]+".pump.cmd.off:_online.._value",
                                            asDp[i]+".pump.cmd.manual:_online.._value");

        dpConnect("HVAC_preheaterValve_CB",0,asDp[i]+".valve.cmd.open:_online.._value",
                                             asDp[i]+".valve.cmd.close:_online.._value",
                                             asDp[i]+".valve.cmd.manual:_online.._value",
                                             asDp[i]+".valve.cmd.setpoint:_online.._value");
      }
    }
  }

  //Simulation for all the Datapoint with the DpType 'HVAC_VALVE'
  asDp = dpNames("*","HVAC_VALVE");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("HVAC_valve_CB",0,asDp[i]+".cmd.open:_online.._value",
                                    asDp[i]+".cmd.close:_online.._value",
                                    asDp[i]+".cmd.manual:_online.._value",
                                    asDp[i]+".cmd.setpoint:_online.._value");
    }
  }

  //Simulation for all the Datapoint with the DpType 'HVAC_pump'  
  asDp = dpNames("*","HVAC_PUMP");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("HVAC_pump_CB",0,asDp[i]+".cmd.on:_online.._value",
                                   asDp[i]+".cmd.off:_online.._value",
                                   asDp[i]+".cmd.manual:_online.._value");
    }
  }

  //****************************************************************************
  //*********Simulation for the 'water_supply' scenery**************************
  //****************************************************************************

  //Simulation for the DPT SLIDE_VALVE2 used for reservoir_1(2)_inflow(_outflow)
  asDp = dpNames("*","SLIDE_VALVE2");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        if(strpos(asDp[i],"Reservoir_") >= 0)
          dpConnect("WATER_Reservoir_valve_CB",0,asDp[i]+".cmd.open:_online.._value",
                                                 asDp[i]+".cmd.mode.auto:_online.._value",
                                                 asDp[i]+".para.position:_online.._value");
    }
  }

  //Simulation for the DPT PUMP2 used for Source_2_pump and Well_2_pump
  asDp = dpNames("*","PUMP2");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
        dpConnect("WATER_Pump2_CB",0,asDp[i]+".cmd.on:_online.._value",
                                               asDp[i]+".cmd.mode.auto:_online.._value",
                                               asDp[i]+".para.speed:_online.._value");
    }
  }

  //****************************************************************************
  //*********Simulation for the 'color_plant' scenery**************************
  //****************************************************************************

  //Simulation for the CP_DRIVE datapoint type used for mixer and pump
  asDp = dpNames("*","CP_DRIVE");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
          dpConnect("CP_DRIVE_CB",0,asDp[i]+".cmd.on:_online.._value",
                                    asDp[i]+".alert.runDry:_online.._value");
    }
  }



  //*************************************************************************************
  //Simulation of values + process for water supply, building automation, traffic control
  //and weather station ****************************************************************
  startThread("All_simulations");
  //*************************************************************************************  
}

//*****************************************************************************
// simulation_CB(...)												  		  *	
//*****************************************************************************
simulation_CB(string dp1, bool  boSimOn,
              string dp2, bool  boSimValuesOn,
              string dp3, int   iSpeedSimValue,
              string dp4, bool  boSimCheckBackOn,
              string dp5, float fDelayCheckBack,
              string dp6, int   boProcessOn)
{

  GboSimOn = boSimOn;
  GboSimValueOn = boSimValuesOn;
  GiSpeedSimValue = iSpeedSimValue;
  GboSimCheckBackOn = boSimCheckBackOn;
  GfDelayCheckBack = fDelayCheckBack;
  GboSimProcessOn  = boProcessOn;

//DebugTN("simulation_CB"); //DebugTN("GboSimOn", GboSimOn); //DebugTN("GboSimValueOn", GboSimValueOn); //DebugTN("GiSpeedSimValue", GiSpeedSimValue);
//DebugTN("GboSimCheckBackOn", GboSimCheckBackOn); //DebugTN("GfDelayCheckBack", GfDelayCheckBack); //DebugTN("GboSimProcessOn", GboSimProcessOn);

}
// end of simulation_CB(...)*************************************************

//*****************************************************************************
// traffic_sign_CB(...)												  		  *	
//*****************************************************************************
traffic_sign_CB(string dp1 , int  iValue,
                string dp2 , bool booff,
                string dp3 , bool boManual)
{

//DebugTN("traffic_sign_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );

    dpSet(dpe+".state.value:_original.._value",iValue,
          dpe+".state.off:_original.._value",booff,
          dpe+".state.manual:_original.._value",boManual);
  }
}
// end of traffic_sign_CB(...)*************************************************

//*****************************************************************************
// traffic_alert_CB(...)												  		  *	
//*****************************************************************************
traffic_alert_CB(string dp1 , bool boAlert,
                 string dp2 , bool booff,
                 string dp3 , bool boManual)
{

//DebugTN("traffic_alert_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    
    dpSet(dpe+".state.alert:_original.._value",boAlert,
        dpe+".state.off:_original.._value",booff,
        dpe+".state.manual:_original.._value",boManual);
  }
}
// end of traffic_alert_CB(..) *************************************************

//*****************************************************************************
// traffic_Light_CB(...)												  		  *	
//*****************************************************************************
traffic_Light_CB(string dp1,bool boManual,
                 string dp2,bool boOff,
                 string dp3,bool boRed,
                 string dp4,bool boRedYellow,
                 string dp5,bool boYellow,
                 string dp6,bool boYellowFlash,
                 string dp7,bool boGreen,
                 string dp8,bool boGreenFlash)
{

//DebugTN("traffic_Light_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    
    dpSet(dpe+".state.manual:_original.._value",boManual
         ,dpe+".state.off:_original.._value",boOff
         ,dpe+".state.red:_original.._value",boRed
         ,dpe+".state.red-yellow:_original.._value" ,boRedYellow
         ,dpe+".state.yellow:_original.._value",boYellow
         ,dpe+".state.flashing_yellow:_original.._value",boYellowFlash
         ,dpe+".state.green:_original.._value",boGreen
         ,dpe+".state.flashing_green:_original.._value",boGreenFlash);
  }
}
// end of traffic_Light_CB(...) ***********************************************

//*****************************************************************************
// HVAC_fan_CB(...)												  		  *	
//*****************************************************************************
HVAC_fan_CB(string dp1 , bool bon1,
            string dp2 , bool bon2,
            string dp3 , bool boOff,
            string dp4 , bool boManual)
{

//DebugTN("HVAC_fan_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );

    dpSet(dpe+".state.n1:_original.._value",bon1,
          dpe+".state.n2:_original.._value",bon2,
          dpe+".state.off:_original.._value",boOff,
          dpe+".state.manual:_original.._value",boManual);
  }
}
// end of HVAC_fan_CB(...)*************************************************

//*****************************************************************************
// HVAC_flap_CB(...)												  		  *	
//*****************************************************************************
HVAC_flap_CB(string dp1 , float fOpen,
             string dp2 , float fClose)
{

//DebugTN("HVAC_flap_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    dpSet(dpe+".state.open:_original.._value",fOpen,
          dpe+".state.closed:_original.._value",fClose);
  }
}
// end of HVAC_flap_CB(...)*************************************************

//*****************************************************************************
// HVAC_preheaterPump_CB(...)												  		  *	
//*****************************************************************************
HVAC_preheaterPump_CB(string dp1 , bool boPumpOn,
                      string dp2 , bool boPumpOff,
                      string dp3 , bool boPumpManual)
{

//DebugTN("HVAC_preheaterPump_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
   
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
 
    dpSet(dpe+".pump.state.on:_original.._value",boPumpOn,
          dpe+".pump.state.off:_original.._value",boPumpOff,
          dpe+".pump.state.manual:_original.._value",boPumpManual);
   }
}
// end of HVAC_preheaterPump_CB(...)*******************************************

//*****************************************************************************
// HVAC_preheaterValve_CB(...)												  		  *	
//*****************************************************************************
HVAC_preheaterValve_CB(string dp1 , bool boValveOpen,
                       string dp2 , bool boValveClose,
                       string dp3 , bool boValveManual,
                       string dp4 , float fValveSetpoint)
{

//DebugTN("HVAC_preheaterValve_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
   
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );

    dpSet(dpe+".valve.state.open:_original.._value",boValveOpen,
          dpe+".valve.state.closed:_original.._value",boValveClose,
          dpe+".valve.state.manual:_original.._value",boValveManual,
          dpe+".valve.value.position:_original.._value",fValveSetpoint);
   }
}
// end of HVAC_preheaterValve_CB(...)******************************************


//*****************************************************************************
// HVAC_valve_CB(...)												  		  *	
//*****************************************************************************
HVAC_valve_CB(string dp1 , bool boValveOpen,
              string dp2 , bool boValveClose,
              string dp3 , bool boValveManual,
              string dp4 , float fValveSetpoint)
{

//DebugTN("HVAC_valve_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );

    dpSet(dpe+".state.open:_original.._value",boValveOpen,
          dpe+".state.closed:_original.._value",boValveClose,
          dpe+".state.manual:_original.._value",boValveManual,
          dpe+".value.position:_original.._value",fValveSetpoint);
  }  
}
// end of HVAC_valve_CB(...)*************************************************

//*****************************************************************************
// HVAC_pump_CB(...)												  		  *	
//*****************************************************************************
HVAC_pump_CB(string dp1 , bool boOn,
             string dp2 , bool booff,
             string dp3 , bool boManual)
{

//DebugTN("HVAC_pump_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );

    dpSet(dpe+".state.on:_original.._value",boOn,
          dpe+".state.off:_original.._value",booff,
          dpe+".state.manual:_original.._value",boManual);
  }
}
// end of HVAC_pump_CB(...)*************************************************

//*****************************************************************************
// HVAC_deviceswitch_CB(...)												  		  *	
//*****************************************************************************
HVAC_deviceswitch_CB(string dp1 , bool boAuto,
                     string dp2 , bool booff,
                     string dp3 , bool boManual)
{

//DebugTN("HVAC_deviceswitch_CB");

  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
    dyn_string asDp;
    float fPosition;
    int i;
    
    if(booff) fPosition=0;
    else      fPosition=100;
  
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );

    dpSet(dpe+".state.auto:_original.._value",boAuto,
          dpe+".state.off:_original.._value",booff,
          dpe+".state.manual:_original.._value",boManual);
    
    //change the state of all the Datapoint with the DpType 'HVAC_FAN'
    asDp = dpNames("*","HVAC_FAN");
    if (dynlen(asDp) >= 1)
    {
      for (i = 1; i<= dynlen(asDp); i++)
      {
        if (strpos(asDp[i],"_mp_") < 0)
        {
          if(boManual)
            dpSet(asDp[i]+".cmd.n1:_original.._value",1,
                  asDp[i]+".cmd.n2:_original.._value",0,
                  asDp[i]+".cmd.off:_original.._value",booff,
                  asDp[i]+".cmd.manual:_original.._value",boManual);
          else if(booff)
            dpSet(asDp[i]+".cmd.n1:_original.._value",0,
                  asDp[i]+".cmd.n2:_original.._value",0,
                  asDp[i]+".cmd.off:_original.._value",booff,
                  asDp[i]+".cmd.manual:_original.._value",1);
          else
            dpSet(asDp[i]+".cmd.n1:_original.._value",0,
                  asDp[i]+".cmd.n2:_original.._value",0,
                  asDp[i]+".cmd.off:_original.._value",0,
                  asDp[i]+".cmd.manual:_original.._value",0);
        }
      }
    }

    //change the state of all the Datapoint with the DpType 'HVAC_PREHEATER'
    asDp = dpNames("*","HVAC_PREHEATER");
    if (dynlen(asDp) >= 1)
    {
      for (i = 1; i<= dynlen(asDp); i++)
      {
        if (strpos(asDp[i],"_mp_") < 0)
        {
          if(boManual)
          {
            dpSet(asDp[i]+".pump.cmd.on:_original.._value",!booff,
                  asDp[i]+".pump.cmd.off:_original.._value",booff,
                  asDp[i]+".pump.cmd.manual:_original.._value",boManual,
                  asDp[i]+".valve.cmd.open:_original.._value",!booff,
                  asDp[i]+".valve.cmd.close:_original.._value",booff,
                  asDp[i]+".valve.cmd.manual:_original.._value",boManual,
                  asDp[i]+".valve.cmd.setpoint:_original.._value",fPosition);
          }
          else if(booff)
          {
            dpSet(asDp[i]+".pump.cmd.on:_original.._value",!booff,
                  asDp[i]+".pump.cmd.off:_original.._value",booff,
                  asDp[i]+".pump.cmd.manual:_original.._value",1,
                  asDp[i]+".valve.cmd.open:_original.._value",!booff,
                  asDp[i]+".valve.cmd.close:_original.._value",booff,
                  asDp[i]+".valve.cmd.manual:_original.._value",1,
                  asDp[i]+".valve.cmd.setpoint:_original.._value",fPosition);
          }
          else
            dpSet(asDp[i]+".pump.cmd.on:_original.._value",0,
                  asDp[i]+".pump.cmd.off:_original.._value",0,
                  asDp[i]+".pump.cmd.manual:_original.._value",0,
                  asDp[i]+".valve.cmd.open:_original.._value",0,
                  asDp[i]+".valve.cmd.close:_original.._value",0,
                  asDp[i]+".valve.cmd.manual:_original.._value",0,
                  asDp[i]+".valve.cmd.setpoint:_original.._value",50);
        }
      }
    }

    //change the state of all the Datapoint with the DpType 'HVAC_VALVE'
    asDp = dpNames("*","HVAC_VALVE");
    if (dynlen(asDp) >= 1)
    {
      for (i = 1; i<= dynlen(asDp); i++)
      {
        if (strpos(asDp[i],"_mp_") < 0)
        {
          if(boManual)
          {
            dpSet(asDp[i]+".cmd.open:_original.._value",!booff,
                  asDp[i]+".cmd.close:_original.._value",booff,
                  asDp[i]+".cmd.manual:_original.._value",boManual,
                  asDp[i]+".cmd.setpoint:_original.._value",fPosition);
          }
          else if(booff)
            dpSet(asDp[i]+".cmd.open:_original.._value",!booff,
                  asDp[i]+".cmd.close:_original.._value",booff,
                  asDp[i]+".cmd.manual:_original.._value",1,
                  asDp[i]+".cmd.setpoint:_original.._value",fPosition);
          else
            dpSet(asDp[i]+".cmd.open:_original.._value",0,
                  asDp[i]+".cmd.close:_original.._value",0,
                  asDp[i]+".cmd.manual:_original.._value",0,
                  asDp[i]+".cmd.setpoint:_original.._value",50);
        } 
      }
    }

    //change the state of all the Datapoint with the DpType 'HVAC_pump'  
    asDp = dpNames("*","HVAC_PUMP");
    if (dynlen(asDp) >= 1)
    {
      for (i = 1; i<= dynlen(asDp); i++)
      {
        if (strpos(asDp[i],"_mp_") < 0)
        {
          if(boManual)
            dpSet(asDp[i]+".cmd.on:_original.._value",!booff,
                  asDp[i]+".cmd.off:_original.._value",booff,
                  asDp[i]+".cmd.manual:_original.._value",boManual);
          else if(booff)
            dpSet(asDp[i]+".cmd.on:_original.._value",!booff,
                  asDp[i]+".cmd.off:_original.._value",booff,
                  asDp[i]+".cmd.manual:_original.._value",1);
          else
            dpSet(asDp[i]+".cmd.on:_original.._value",0,
                  asDp[i]+".cmd.off:_original.._value",0,
                  asDp[i]+".cmd.manual:_original.._value",0);
      
        }
      }
    }
 
  //change the state of all the Datapoint with the DpType 'HVAC_FLAP' 
  asDp = dpNames("*","HVAC_FLAP");
  if (dynlen(asDp) >= 1)
  {
    for (i = 1; i<= dynlen(asDp); i++)
    {
      if (strpos(asDp[i],"_mp_") < 0)
      {
        if(booff)
          dpSet(asDp[i]+".cmd.open:_original.._value",0,
                asDp[i]+".cmd.close:_original.._value",100);
        else
          dpSet(asDp[i]+".cmd.open:_original.._value",50,
                asDp[i]+".cmd.close:_original.._value",50);
      }
    }
  }
  }
}
// end of HVAC_deviceswitch_CB(...)********************************************

//*****************************************************************************
// WATER_Reservoir_valve_CB											  		  *	
//*****************************************************************************
WATER_Reservoir_valve_CB(string dp1, int   iOpen, //.cmd.open
                         string dp2, int   iAuto, //.cmd.mode.auto
                         string dp3, float fPosition) //.para.position
{
  bool bIsOpen, bIsClosed, bIsAuto, bIsManual;

//DebugTN("WATER_Reservoir_valve_CB");
//DebugTN("WATER_Reservoir_valve_CB",iOpen, iAuto, fPosition);
//DebugTN("WATER_Reservoir_valve_CB: GboSimOn, GboSimCheckBackOn", GboSimOn, GboSimCheckBackOn);    
  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
    
    if(iOpen == 2) //open cmd
      bIsOpen = TRUE;
    else
      if(iOpen == 4) //close cmd
        bIsOpen = FALSE;

    if(iOpen != 1) //stop command    
      bIsClosed = !bIsOpen;
    
    dpSet(dpe+".state.opening:_original.._value",bIsOpen,
          dpe+".state.closing:_original.._value",bIsClosed);

//DebugTN("WATER_Reservoir_valve_CB: GfDelayCheckBack", GfDelayCheckBack); 

        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    
    if(iAuto == 1)
      bIsAuto = TRUE;
    else
      bIsAuto = FALSE;
      
    bIsManual = !bIsAuto;
    if(bIsManual)
    {
      if(bIsClosed)
        fPosition = 0.0;  //In manual mode and closed the position is zero
      if(fPosition == 0.0)//Setpoint zero -> closed
      {
        bIsClosed = TRUE;
        bIsOpen   = FALSE;
      }
      if(fPosition == 100.0)//Setpoint 100 -> opened
      {
        bIsClosed = FALSE;
        bIsOpen   = TRUE;
      }
    }
      
    if(bIsAuto) //automatic mode - do not modify position
    {
//DebugTN("WATER_Reservoir_valve_CB: bIsAuto, fPosition", bIsAuto, fPosition);  
      dpSet(dpe+".state.open:_original.._value",0,  //a position between full open or closed state
            dpe+".state.close:_original.._value",0,
            dpe+".state.mode.auto:_original.._value",bIsAuto,
            dpe+".state.mode.man:_original.._value",bIsManual,
            dpe+".state.opening:_original.._value",0,
            dpe+".state.closing:_original.._value",0);    
    }
    else        //manual mode 
    {
//DebugTN("WATER_Reservoir_valve_CB: fPosition",fPosition);  
      dpSet(dpe+".state.open:_original.._value",bIsOpen,
            dpe+".state.close:_original.._value",bIsClosed,
            dpe+".state.mode.auto:_original.._value",bIsAuto,
            dpe+".state.mode.man:_original.._value",bIsManual,
            dpe+".value.position:_original.._value",fPosition,
            dpe+".state.opening:_original.._value",0,
            dpe+".state.closing:_original.._value",0);    
    }
  }      
}
                         
// end of WATER_Reservoir_valve_CB(...)****************************************		

//*****************************************************************************
// WATER_PUMP2_CB											  		          *	
//*****************************************************************************
WATER_Pump2_CB(string dp1, int   iOn,    //.cmd.on
               string dp2, int   iAuto,  //.cmd.mode.auto
               string dp3, float fSpeed) //.para.speed
{
  bool bIsOn, bIsOff, bIsAuto, bIsManual;
  
//DebugTN("WATER_Pump2_CB");
    
  if(GboSimOn && GboSimCheckBackOn)
  {
    string dpe=substr(dp1,0,strpos(dp1,"."));
    
    bIsOn = FALSE;
    if(iOn > 1)
      bIsOn = TRUE;
    
    bIsOff = !bIsOn;
    
        delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    
    if(iAuto == 1)
      bIsAuto = TRUE;
    else
      bIsAuto = FALSE;
      
    bIsManual = !bIsAuto;
    if(bIsManual && bIsOff)
      fSpeed = 0.0; 
      
    if(bIsAuto) //automatic mode do not modify speed
      dpSet(dpe+".state.on:_original.._value",bIsOn,
            dpe+".state.off:_original.._value",bIsOff,
            dpe+".state.mode.auto:_original.._value",bIsAuto,
            dpe+".state.mode.man:_original.._value",bIsManual);
    else        //manual mode 
      dpSet(dpe+".state.on:_original.._value",bIsOn,
            dpe+".state.off:_original.._value",bIsOff,
            dpe+".state.mode.auto:_original.._value",bIsAuto,
            dpe+".state.mode.man:_original.._value",bIsManual,
            dpe+".value.speed:_original.._value",fSpeed);
  }      
}
                         
// end of WATER_PUMP2_CB(...)*****************************************************

//********************************************************************************
//Simulation of values + process for water supply, building automation, 
//traffic control and weather station, designed as own thread with an endless loop 
//********************************************************************************

All_simulations()
{
  float fValue,
        fCount1 = 0.0,
        fCount2 = 0.0,
        fCount3 = 1.42;
  int   iSimulationSpeed;

//DebugTN("All_simulations");

  //Setup the callback to get the actual values for building automation       
  dpConnect("BuildingCB",                                                     
        //Cooler                                                                    
        "Cooler.valve.value.position:_online.._value",                
        "Cooler.valve.value.position:_pv_range.._max",                
        "Cooler.valve.state.manual:_online.._value",                  
        //Preheater                                                               
        "PreHeater.valve.value.position:_online.._value",             
        "PreHeater.valve.value.position:_pv_range.._max",             
        "PreHeater.valve.state.manual:_online.._value",               
        //Reheaters                                                               
        "ReHeater.valve.value.position:_online.._value",              
        "ReHeater.valve.value.position:_pv_range.._max",              
        "ReHeater.valve.state.manual:_online.._value",                
        "ReHeater_2.valve.value.position:_online.._value",            
        "ReHeater_2.valve.value.position:_pv_range.._max",            
        "ReHeater_2.valve.state.manual:_online.._value",              
        "ReHeater_3.valve.value.position:_online.._value",            
        "ReHeater_3.valve.value.position:_pv_range.._max",            
        "ReHeater_3.valve.state.manual:_online.._value",              
         //Evaporator                                                              
        "Evaporator.value.position:_online.._value",                  
        "Evaporator.value.position:_pv_range.._max",                  
        "Evaporator.state.manual:_online.._value");                   

  //Setup the callbacks to get the actual values for water simulation         //
  dpConnect("WaterCB",                                                        //
    //zone 1+2 inflow                                                         //
          "Reservoir_1_inflow_valve.value.position:_online.._value",  //
          "Sources_1_flow.value:_pv_range.._max",                     //
          "Reservoir_2_inflow_valve.value.position:_online.._value",  //
          "Sources_2_flow.value:_pv_range.._max",                     //
    //zone 1+2 outflow                                                        //
          "Reservoir_1_outflow_valve.value.position:_online.._value", //
          "Zone_1_flow.value:_pv_range.._max",                        //
          "Reservoir_2_outflow_valve.value.position:_online.._value", //
          "Zone_2_flow.value:_pv_range.._max",                        //
    //zone 1+2 levelmax                                                       //
          "Reservoir_1_level.value:_pv_range.._max",                  //
          "Reservoir_2_level.value:_pv_range.._max",
    //valve mode                                                              //
          "Reservoir_1_inflow_valve.state.mode.auto:_online.._value", //
          "Reservoir_2_inflow_valve.state.mode.auto:_online.._value", //
          "Reservoir_1_outflow_valve.state.mode.auto:_online.._value",//
          "Reservoir_2_outflow_valve.state.mode.auto:_online.._value");//
  dpGet(                                                                      //
    //zone 1+2 level initial value                                            //
          "Reservoir_1_level.value:_online.._value",fLevel1,          //
          "Reservoir_2_level.value:_online.._value",fLevel2);         //

  //Setup the sequences for the traffic light control                         //
  //                           RD --------------------------------,RD+YE, GN -------------------,FL GN -----, YE    //
  //                             1     2     3     4     5     6     7     8     9     10    11    12    13    14   //
  bRed           = makeDynBool(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);//
  bRedYellow     = makeDynBool(FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE, FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);//
  bGreen         = makeDynBool(FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE, TRUE, TRUE, TRUE, FALSE,FALSE,FALSE);//
  bFlashingGreen = makeDynBool(FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE, TRUE, FALSE);//
  bYellow        = makeDynBool(FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE );//
  iLight1        = 0;                                                         //************************************//
  iLight2        = 7;                                                         //
  iLight3        = 0;                                                         //
  iLight4        = 7;                                                         //
  iTrafficTime   = 0;                                                         //
  dpConnect("TrafficCB",                                                      //
    //Light 1                                                                 //
    "TC_traffic_light_1.state.manual:_online.._value",                //
    "TC_traffic_light_1.state.off:_online.._value",                   //
    //Light 2                                                                 //
    "TC_traffic_light_2.state.manual:_online.._value",                //
    "TC_traffic_light_2.state.off:_online.._value",                   //
    //Light 3                                                                 //
    "TC_traffic_light_3.state.manual:_online.._value",                //
    "TC_traffic_light_3.state.off:_online.._value",                   //
    //Light 4                                                                 //
    "TC_traffic_light_4.state.manual:_online.._value",                //
    "TC_traffic_light_4.state.off:_online.._value");                  //
  //***************************************************************************

  //***************************************************************************
  //Setup the time counter for the weather station triggers                   //
  iWeatherTime    = 1;
  iWeatherCountMS = 0; 
  
  while(TRUE) //forever loop
  {
    //Do nothing if simulation mode is off
    if(!GboSimOn)
    {
      delay(5,0); //wait for 5 sec
      continue;   //continue while loop at top
    }
   
    if(GboSimValueOn) //simulate values
    {
      //********** make a value simulation for building automation panel *********************************
      Building_automation(fCount2);
      //********** Perform the simulation for water supply scenery ***************************************
      Water_simulation(fCount1,fCount3);
      //********** Simulate the traffic lights ***********************************************************
      Traffic_Light_simulation();
      //********** Simulate some weather measurements ****************************************************
      Weather_simulation();
      //**************************************************************************************************
    }

    iSimulationSpeed = (GiSpeedSimValue >= 100) ? GiSpeedSimValue : 100;//to prevent div by zero in next line
    fCount2 = (fCount2 > 6.28) ? 0.0 : (fCount2 + (2 * 3.141592 * (1.0 / iSimulationSpeed))); 
    
    //delay loop
    delay((GiSpeedSimValue / 1000),(GiSpeedSimValue % 1000)); //delay x.y sec before next loop
  }
}
//End of All-simulations

//*********************************************************************
//Water_simulation is called by forever loop of All_simulations       *
//*********************************************************************
Water_simulation(float &fCount1, float &fCount3)
{
  float fValue, fTrend1, fTrend2;
  int   i = 1,
        iSimulationSpeed;

  dyn_string  dpName;
  dyn_anytype values;
  
//DebugTN("Water_simulation");
    
  fInflow1 = fInMax1 * fInPosition1 / 100.0;
  fInflow2 = fInMax2 * fInPosition2 / 100.0;      

  if(bOutValve1Auto && (fOutPosition1 == 0))
    fOutflow1 = fOutMax1 * 0.5;
  else
    fOutflow1 = fOutMax1 * fOutPosition1 / 100.0;      

  if(bOutValve2Auto && (fOutPosition2 == 0))
    fOutflow2 = fOutMax2 * 0.5;
  else
    fOutflow2 = fOutMax2 * fOutPosition2 / 100.0;      

  iSimulationSpeed = (GiSpeedSimValue >= 100) ? GiSpeedSimValue : 100;//to prevent div by zero
  do
  {
    fValue = fOutflow1;
    //simulate a sinus wave outflow value
    fCount1 = (fCount1 > 6.28) ? 0.0 : (fCount1 + (2 * 3.141592 * (1.0 / iSimulationSpeed)));
    if(sin(fCount1) < 0)
      fValue = -1 * sin(fCount1) * fValue;
    else
      fValue = sin(fCount1) * fValue;
  }
  while((fValue > fOutMax1) || (fValue < (fOutflow1 * 0.25)));
  //modify outflow only in automativ mode of aoutflow valve
  if(bOutValve1Auto)
    fOutflow1 = fValue;
      
  do
  {
    fValue = fOutflow2;
    //simulate a sinus wave outflow value
    fCount3 = (fCount3 > 6.28) ? 0.0 : (fCount3 + (2 * 3.141592 * (1.0 / iSimulationSpeed)));
    if(sin(fCount3) < 0)
      fValue = -1.5 * sin(fCount3) * fValue;
    else
      fValue = 1.5 * sin(fCount3) * fValue;

  }
  while((fValue > fOutMax1) || (fValue < (fOutflow2 * 0.25)));
  //modify outflow only in automativ mode of aoutflow valve
  if(bOutValve2Auto)
    fOutflow2 = fValue;

  if(GboSimValueOn && GboSimProcessOn) //simulate process
  {
    //feed back to avoid exeeding min/max reservoir levels
    if(fLevel1 < (fLevelMax1 / 3.0))
    {
      //do it only if inflow valve is in automatic mode
      if((fInflow1 < fOutflow1) && bInValve1Auto)
      {
        //increase inflow value
        fValue    = fInPosition1 + ((100.0 - fInPosition1) / 10.0);
        dpName[i] = "Reservoir_1_inflow_valve.value.position:_original.._value";
        values[i] = fValue;
        i++;
      }
    }
    if(fLevel1 > (2 * fLevelMax1 / 3.0))
    {
      //do it only if inflow valve is in automatic mode
      if((fInflow1 > fOutflow1) && bInValve1Auto)
      {
        //decrease inflow value
        fValue    = fInPosition1 - (fInPosition1 / 10.0);
        dpName[i] = "Reservoir_1_inflow_valve.value.position:_original.._value";
        values[i] = fValue;
        i++;
      }
    }
    if(fLevel2 < (fLevelMax2 / 3.0))
    {
      //do it only if inflow valve is in automatic mode
      if((fInflow2 < fOutflow2) && bInValve2Auto)
      {
        //increase inflow value
        fValue    = fInPosition2 + ((100.0 - fInPosition2) / 10.0);
        dpName[i] = "Reservoir_2_inflow_valve.value.position:_original.._value";
        values[i] = fValue;
        i++;
      }
    }
    if(fLevel2 > (2 * fLevelMax2 / 3.0))
    {
      //do it only if inflow valve is in automatic mode
      if((fInflow2 > fOutflow2) && bInValve2Auto)
      {
        //decrease inflow value
        fValue    = fInPosition2 - (fInPosition2 / 10.0);
        dpName[i] = "Reservoir_2_inflow_valve.value.position:_original.._value";
        values[i] = fValue;
        i++;
      }
    }
    
    fInflow1  /= 3600.0;// cubic meter per hour / 3600 = cubic meter per second
    fInflow2  /= 3600.0;      
    fOutflow1 /= 3600.0;// cubic meter per hour / 3600 = cubic meter per second
    fOutflow2 /= 3600.0;      
    //calculate difference between inflow and outflow to get a new reservoir level
    fTrend1 = fInflow1 - fOutflow1;
    fTrend2 = fInflow2 - fOutflow2;
  
    //in the following calculation the factor 0.07292 based on experience to make 
    //the alteration of level visible and smoothed together
    fLevel1 = fLevel1 + (fTrend1 * GiSpeedSimValue / 1000.0 / 0.07292);
    //avoid out of bounds
    fLevel1 = (fLevel1 < 0.0) ? 0.0 : ((fLevel1 > fLevelMax1) ? fLevelMax1 : fLevel1);
    fLevel2 = fLevel2 + (fTrend2 * GiSpeedSimValue / 1000.0 / 0.07292);
    //avoid out of bounds
    fLevel2 = (fLevel2 < 0.0) ? 0.0 : ((fLevel2 > fLevelMax2) ? fLevelMax2 : fLevel2);
    
    fInflow1  *= 3600.0;//cubic meter per second to cubic meter per hour
    fInflow2  *= 3600.0;
    fOutflow1 *= 3600.0;
    fOutflow2 *= 3600.0;

    //set new levels
    dpName[i] = "Reservoir_1_level.value:_original.._value";
    values[i] = fLevel1;
    i++;
    dpName[i] = "Reservoir_2_level.value:_original.._value";
    values[i] = fLevel2;
    i++;
    //new outflow if outflow valves are in automatic mode
    if(bOutValve1Auto)
    {
      dpName[i] = "Zone_1_flow.value:_original.._value";
      values[i] = fOutflow1;
      i++;
    }
    if(bOutValve2Auto)
    {
      dpName[i] = "Zone_2_flow.value:_original.._value";
      values[i] = fOutflow2;
      i++;
    }
  }    // GboSimValueOn && GboSimProcessOn
  else //simulate outflow values only, do not affect levels
  {
    //do it only if outflow valves are in automatic mode
    if(bOutValve1Auto)
    {
      dpName[i] = "Zone_1_flow.value:_original.._value";
      values[i] = fOutflow1;
      i++;
    }
    if(bOutValve2Auto)
    {
      dpName[i] = "Zone_2_flow.value:_original.._value";
      values[i] = fOutflow2;
      i++;
    }
  }
  
  if(i > 1) // at least one DP needs to be written
    dpSet(dpName,values);
}
//End of water_simulation


//*********************************************************************
//Building_automation is called by forever loop of All_simulations    *
//*********************************************************************
Building_automation(float fCount2)
{
  float fValue,
        fCount;

  dyn_string  dpName;
  dyn_anytype values;
  int   i = 1;

//DebugTN("Building_automation");
        
  //check for valid upper limits
  fCoolerMax     = (fCoolerMax > 0.0)     ? fCoolerMax     : 10.0;
  fPreHeaterMax  = (fPreHeaterMax > 0.0)  ? fPreHeaterMax  : 10.0;
  fReHeaterMax   = (fReHeaterMax > 0.0)   ? fReHeaterMax   : 10.0;
  fReHeaterMax2  = (fReHeaterMax2 > 0.0)  ? fReHeaterMax2  : 10.0;
  fReHeaterMax3  = (fReHeaterMax3 > 0.0)  ? fReHeaterMax3  : 10.0;
  fEvaporatorMax = (fEvaporatorMax > 0.0) ? fEvaporatorMax : 10.0;
    
  //Cooler
  if(!bCoolerState) //FALSE means cooler큦 state in automatic mode
  {
    fCount = fCount2;
    do
    {
      fValue = fCoolerMax;
      fCount = (fCount > 6.28) ? (fCount - 6.28) : (fCount + (2 * 3.141592 * (1.0 / 500.0)));
      if(sin(fCount) < 0)
        fValue = -1 * sin(fCount) * fValue;
      else
        fValue = sin(fCount) * fValue;
    }
    while((fValue > (fCoolerMax * 0.9)) || (fValue < 0.5));
    fCooler = fValue;
  }
     
  //PreHeater 
  if(!bPreHeaterState) //FALSE means PreHeater큦 state in automatic mode
  {
    fCount = fCount2 + 0.987654; 
    do
    {
      fValue = fPreHeaterMax;
      fCount = (fCount > 6.28) ? (fCount - 6.28) : (fCount + (2 * 3.141592 * (1.0 / 500.0)));
      if(sin(fCount) < 0)
        fValue = -1 * sin(fCount) * fValue;
      else
        fValue = sin(fCount) * fValue;
    }
    while((fValue > (fPreHeaterMax * 0.9)) || (fValue < 0.5));
    fPreHeater = fValue;
  }
    
  //ReHeater
  if(!bReHeaterState) //FALSE means ReHeater큦 state in automatic mode
  {
    fCount = fCount2 + 1.23456;
    do
    {
      fValue = fReHeaterMax;
      fCount = (fCount > 6.28) ? (fCount - 6.28) : (fCount + (2 * 3.141592 * (1.0 / 500.0)));
      if(sin(fCount) < 0)
        fValue = -1 * sin(fCount) * fValue;
      else
        fValue = sin(fCount) * fValue;
    }
    while((fValue > (fReHeaterMax * 0.9)) || (fValue < 0.5));
    fReHeater = fValue;
  }
    
  //ReHeater2
  if(!bReHeaterState2) //FALSE means ReHeater큦 state in automatic mode
  {
    fCount = fCount2 + 3.456789; 
    do
    {
      fValue = fReHeaterMax2;
      fCount = (fCount > 6.28) ? (fCount - 6.28) : (fCount + (2 * 3.141592 * (1.0 / 500.0)));
      if(sin(fCount) < 0)
        fValue = -1 * sin(fCount) * fValue;
      else
        fValue = sin(fCount) * fValue;
    }
    while((fValue > (fReHeaterMax2 * 0.9)) || (fValue < 0.5));
    fReHeater2 = fValue;
  }
    
  //ReHeater3
  if(!bReHeaterState3) //FALSE means ReHeater큦 state in automatic mode
  {
    fCount = fCount2 + 0.765432;
    do
    {
      fValue = fReHeaterMax3;
      fCount = (fCount > 6.28) ? (fCount - 6.28) : (fCount + (2 * 3.141592 * (1.0 / 500.0)));
      if(sin(fCount) < 0)
        fValue = -1 * sin(fCount) * fValue;
      else
        fValue = sin(fCount) * fValue;
    }
    while((fValue > (fReHeaterMax3 * 0.9)) || (fValue < 0.5));
    fReHeater3 = fValue;
  }
    
  //Evaporator
  if(!bEvaporatorState) //FALSE means Evaporator큦 state in automatic mode
  {
    fCount = fCount2 + 2.34567;
    do
    {
      fValue = fEvaporatorMax;
      fCount = (fCount > 6.28) ? (fCount - 6.28) : (fCount + (2 * 3.141592 * (1.0 / 500.0)));
      if(sin(fCount) < 0)
        fValue = -1 * sin(fCount) * fValue;
      else
        fValue = sin(fCount) * fValue;
    }
    while((fValue > (fEvaporatorMax * 0.9)) || (fValue < 0.5));
    fEvaporator = fValue;
  }    

  //set new values if state of ... is automatic
  if(!bCoolerState)
  {
    dpName[i] = "Cooler.valve.value.position:_original.._value";
    values[i] = fCooler;
    i++;
  }
  if(!bPreHeaterState)
  {
    dpName[i] = "PreHeater.valve.value.position:_original.._value";
    values[i] = fPreHeater;
    i++;
  }
  if(!bReHeaterState)
  {
    dpName[i] = "ReHeater.valve.value.position:_original.._value";
    values[i] = fReHeater;
    i++;
  }
  if(!bReHeaterState2)
  {
    dpName[i] = "ReHeater_2.valve.value.position:_original.._value";
    values[i] = fReHeater2;
    i++;
  }
  if(!bReHeaterState3)
  {
    dpName[i] = "ReHeater_3.valve.value.position:_original.._value";
    values[i] = fReHeater3;
    i++;
  }
  if(!bEvaporatorState)
  {
    dpName[i] = "Evaporator.value.position:_original.._value";
    values[i] = fEvaporator;
    i++;
  }
  if(i > 1) //at least one DP needs to be written
    dpSet(dpName,values);
    
}
//End of building automation

//*********************************************************************
//Traffic_Light_simulation is called by forever loop of All_simulations
//*********************************************************************
Traffic_Light_simulation()
{
  int  iOldTime = iTrafficTime / 3000,
       iNewTime = (iTrafficTime + GiSpeedSimValue) / 3000,
       i = 1,
       j,
       iLight;
       
  //this trigger has a shortest intervall of three sec, or
  //GiSpeedSimValue if GiSpeedSimValue > 3000 ms
  bool bTrigger = (iOldTime == iNewTime) ? FALSE : TRUE,
       bLightIsManual, bLightIsOff,
       bChanged = FALSE;
       
  dyn_string  dpName;
  dyn_anytype values;
  
//DebugTN("Traffic_Light_simulation");
  
  iTrafficTime += GiSpeedSimValue;
  if(!bTrigger) //do nothing
    return;
    
  //The sequences for the lights
  iLight  = iLight1 + 1;
  iLight1 = (iLight < 15) ? iLight : 1;
  iLight  = iLight2 + 1;
  iLight2 = (iLight < 15) ? iLight : 1;
  iLight  = iLight3 + 1;
  iLight3 = (iLight < 15) ? iLight : 1;
  iLight  = iLight4 + 1;
  iLight4 = (iLight < 15) ? iLight : 1;
  
  //control the traffic lights
  for(j = 1; j < 5; j++) //do it for all 4 lights
  {
    switch(j)
    {
      case 1 : //prepare for light 1
             bLightIsManual = bLight1Manual;
             bLightIsOff    = bLight1Off;
             iLight         = iLight1;
             break;
      case 2 : //prepare for light 2
             bLightIsManual = bLight2Manual;
             bLightIsOff    = bLight2Off;
             iLight         = iLight2;
             break;
      case 3 : //prepare for light 3
             bLightIsManual = bLight3Manual;
             bLightIsOff    = bLight3Off;
             iLight         = iLight3;
             break;
      case 4 : //prepare for light 4
             bLightIsManual = bLight4Manual;
             bLightIsOff    = bLight4Off;
             iLight         = iLight4;
             break;
    }
    switch(iLight)
    {
      case 1 : //for values of 1,7,8,12 and 14 the state of a light has to be changed
      case 7 :
      case 8 :
      case 12:
      case 14: bChanged = TRUE;
               break;
               // for all other values the state of all lights must be unchanged
      default: bChanged = FALSE;
               break;
    }
    //do this for all lights :
    //not in manual mode, not switched off and state has changed
    if(!bLightIsManual && !bLightIsOff && bChanged)
    {
      dpName[i] = "TC_traffic_light_"+j+".state.red:_original.._value"; 
      values[i] = bRed[iLight];
      i++;
      dpName[i] = "TC_traffic_light_"+j+".state.red-yellow:_original.._value"; 
      values[i] = bRedYellow[iLight];
      i++;    
      dpName[i] = "TC_traffic_light_"+j+".state.yellow:_original.._value"; 
      values[i] = bYellow[iLight];
      i++;    
      dpName[i] = "TC_traffic_light_"+j+".state.flashing_yellow:_original.._value"; 
      values[i] = FALSE;
      i++;    
      dpName[i] = "TC_traffic_light_"+j+".state.green:_original.._value"; 
      values[i] = bGreen[iLight];
      i++;        
      dpName[i] = "TC_traffic_light_"+j+".state.flashing_green:_original.._value"; 
      values[i] = bFlashingGreen[iLight];
      i++;    
    }
  }
  if(i > 1) //at least one DP needs to be written
    dpSet(dpName,values);
}
//End of Traffic_Light_simulation

//*********************************************************************
//weather_simulation is called by forever loop of All_simulations     *
//*********************************************************************
Weather_simulation()
{
  time  tToday   = getCurrentTime();
  int   iSec     = daySecond(tToday),
        i        = 1;
  
  bool  bTrigger_X_Sec  = (iWeatherTime % 6)   ? FALSE : TRUE;
  bool  bTrigger2Sec  = (iWeatherTime % 2)        ? FALSE : TRUE;
  bool  bTrigger5Sec  = (iWeatherTime % 5)        ? FALSE : TRUE;
  bool  bTrigger1Min  = (iWeatherTime % 60)       ? FALSE : TRUE;
  bool  bTrigger5Min  = (iWeatherTime % 300)      ? FALSE : TRUE;
  bool  bTrigger10Min = (iWeatherTime % 600)      ? FALSE : TRUE;
  bool  bTrigger15Min = (iWeatherTime % 1200)     ? FALSE : TRUE;

//DebugTN("iWeatherTime",iWeatherTime);
//DebugTN("bTrigger2Sec, bTrigger5Sec, bTrigger1Min, bTrigger5Min, bTrigger10Min, bTrigger15Min, iWeatherTime",bTrigger2Sec, bTrigger5Sec, bTrigger1Min, bTrigger5Min, bTrigger10Min, bTrigger15Min, iWeatherTime);
//DebugTN("iSec",iSec);

  float fCycle1 = sin(3.1415 * iSec / 86399.0);//1 cycles per 48 hours
  float fCycle2 = sin(6.2832 * iSec / 86399.0);//1 cycle  per 24 hours
  float fCycle3 = sin(6.2832 * iSec / 3600.0);

  //simulate a cycling temperature with max at noon and min at midnight                      
  float fTemp  = 17 + (12 * fCycle1);

  //simulate a wind direction cycling 360� per 24 hours
  if (fCycle3 < 0) fCycle3 = fCycle3 * -1;
  float fDir   = 180 * fCycle3;

  //simulate a wind speed with max at noon and min at midnight
  if (fCycle2 < 0) fCycle2 = fCycle2 * -1;
  float fSpeed = 10 + (20 * fCycle2);
  
  //simulate air pressure 
  float fPress = 1000 + (100 * fCycle2);

  //simulate humidity
  float fHumty = 60 + (10 * fCycle2);

  //simulate humidity
  float fRain = 1 + (10 * fCycle2);

  //simulate a random disturbance factor
  float fDist  = sin(rand());
  
  dyn_string  dpName;
  dyn_anytype values;
  
//DebugTN("Weather_simulation: fTemp, fDir, fSpeed, fPress, fHumty, fDist", fTemp, fDir, fSpeed, fPress, fHumty, fDist);
 
  //operate weather time count, counts up one per second if GiSpeedSimValue = 1000 ms
  //if GiSpeedSimValue > 1000ms -> all trigger rates are reduced with same proportion
  //if GiSpeedSimValue < 1000ms -> waits until 1000ms are expired
  if(GiSpeedSimValue < 1000)
  {
    iWeatherCountMS += GiSpeedSimValue;
    if(iWeatherCountMS < 1000)
      return; //do nothing wait until 1000ms expired
    iWeatherCountMS = 0;
  }
  iWeatherTime++;
    
  //superpose a disturbance
  fDir   = fDir * (1 + fDist);
  fSpeed = fSpeed *  (1 + fDist);
    
  if(bTrigger_X_Sec)
  {
//DebugTN("fSpeed, fDir");
    dpName[i] = "WS1.value.wind.speed:_original.._value";
    values[i] = fSpeed;
    i++;
    dpName[i] = "WS1.value.wind.direction:_original.._value";
    values[i] = fDir;
    i++;
  }
  
  if(bTrigger5Min)
  {
//DebugTN("fTemp");
    dpName[i] = "WS1.value.air.temperature:_original.._value";
    values[i] = fTemp;
    i++;
  }
  
  if(bTrigger10Min)
  {
//DebugTN("fPress");
    dpName[i] = "WS1.value.air.pressure:_original.._value";
    values[i] = fPress;
    i++;
  }

  if(bTrigger10Min)
  {
//DebugTN("fHumty, fRain");
    dpName[i] = "WS1.value.air.humidity:_original.._value";
    values[i] = fHumty;
    i++;
    dpName[i] = "WS1.value.rain.amount:_original.._value";
    values[i] = fRain;
    i++;
  }
  
  if(i > 1) //at least one DP needs to be written
    dpSet(dpName,values);
}
//End of weather measurements simulation

//************************************************************************
//Callback to make avalaible the atual values for the simulation loop    *
//************************************************************************
BuildingCB(
    //Cooler
        string dp1, float value1,
        string dp2, float value2,
        string dp3, bool  value3,
    //Preheater
        string dp4, float value4,
        string dp5, float value5,
        string dp6, bool  value6,
    //Reheaters
        string dp7, float value7,
        string dp8, float value8,
        string dp9, bool  value9,
        string dp10,float value10,
        string dp11,float value11,
        string dp12,bool  value12,
        string dp13,float value13,
        string dp14,float value14,
        string dp15,bool  value15,
    //Evaporator
        string dp16,float value16,
        string dp17,float value17,
        string dp18,bool  value18)
{

//DebugTN("BuildingCB");

    //Cooler
      fCooler           = value1;
      fCoolerMax        = value2;
      bCoolerState      = value3;
    //Preheater
      fPreHeater        = value4;
      fPreHeaterMax     = value5;
      bPreHeaterState   = value6;
    //Reheaters
      fReHeater         = value7;
      fReHeaterMax      = value8;
      bReHeaterState    = value9;
      fReHeater2        = value10;
      fReHeaterMax2     = value11;
      bReHeaterState2   = value12;
      fReHeater3        = value13;
      fReHeaterMax3     = value14;
      bReHeaterState3   = value15;
    //Evaporator
      fEvaporator       = value16;
      fEvaporatorMax    = value17;
      bEvaporatorState  = value18;
}
//End og BuildingCB

//*************************************************************************
// WaterCB makes avalaible the actual values for simulation thread        *
//*************************************************************************
WaterCB(
    //zone 1+2 inflow
          string dp1, float value1,
          string dp2, float value2,
          string dp3, float value3,
          string dp4, float value4,
    //zone 1+2 outflow
          string dp5, float value5,
          string dp6, float value6,
          string dp7, float value7,
          string dp8, float value8,
    //zone 1+2 levelmax
          string dp11,float value11,
          string dp12,float value12,
          string dp13,bool  value13,
          string dp14,bool  value14,
          string dp15,bool  value15,
          string dp16,bool  value16)
{
  float fInPosNew1, fInPosNew2, fOutPosNew1, fOutPosNew2;
  int   i = 1;
  
  dyn_string  dpName;
  dyn_anytype values;
  
//DebugTN("WaterCB");
  
    //zone 1+2 inflow
      fInPosNew1    = value1;
      fInMax1       = value2;
      fInPosNew2    = value3;
      fInMax2       = value4;
    //zone 1+2 outflow
      fOutPosNew1   = value5;
      fOutMax1      = value6;
      fOutPosNew2   = value7;
      fOutMax2      = value8;
    //zone 1+2 level
      fLevelMax1    = value11;
      fLevelMax2    = value12;
    //valve mode
      bInValve1Auto  = value13;
      bInValve2Auto  = value14;
      bOutValve1Auto = value15;
      bOutValve2Auto = value16;

      //check if position has changed and valves are in automatic mode
      if((fInPosition1 != fInPosNew1) || !bInValve1Auto)
      {
        fInflow1 = fInMax1 * fInPosNew1 / 100.0;
        dpName[i] = "Sources_1_flow.value:_original.._value";
        values[i] = fInflow1;
        fInPosition1  = fInPosNew1;
        i++;
      }
      if((fInPosition2 != fInPosNew2) || !bInValve2Auto)
      {
        fInflow2 = fInMax2 * fInPosNew2 / 100.0;   
        dpName[i] = "Sources_2_flow.value:_original.._value";
        values[i] = fInflow2;
        fInPosition2  = fInPosNew2;
        i++;
      }
      if((fOutPosition1 != fOutPosNew1) || !bOutValve1Auto)
      {
        fOutflow1 = fOutMax1 * fOutPosNew1 / 100.0;      
        dpName[i] = "Zone_1_flow.value:_original.._value";
        values[i] = fOutflow1;
        fOutPosition1 = fOutPosNew1;
        i++;
      }
      if((fOutPosition2 != fOutPosNew2) || !bOutValve2Auto)
      {
        fOutflow2 = fOutMax2 * fOutPosNew2 / 100.0;      
        dpName[i] = "Zone_2_flow.value:_original.._value";
        values[i] = fOutflow2;
        fOutPosition2 = fOutPosNew2;
        i++;
      }

      if(i > 1) //at least one DP needs to be written
        dpSet(dpName,values);
      
}
//End of WaterCB

//************************************************************************
//Callback to make avalaible the atual values for the simulation loop    *
//************************************************************************
TrafficCB(
    //Light 1                                                                 
    string dp1, bool value1,
    string dp2, bool value2,
    //Light 2                                                                 
    string dp3, bool value3,
    string dp4, bool value4,
    //Light 3                                                                
    string dp5, bool value5,
    string dp6, bool value6,
    //Light 4                                                                 
    string dp7, bool value7,
    string dp8, bool value8)
{

//DebugTN("TrafficCB");

  bLight1Off    = value1;
  bLight1Manual = value2;

  bLight2Off    = value3;
  bLight2Manual = value4;

  bLight3Off    = value5;
  bLight3Manual = value6;

  bLight4Off    = value7;
  bLight4Manual = value8;
}
//End of TrafficCB

//************************************************************************
//Callback to simulate the responses for active devices in color_plant   *
//************************************************************************

CP_DRIVE_CB(string dp1, bool on,
            string dp2, bool alert)
{
  string dp = dp1;

  strreplace(dp,"cmd","state");
  strreplace(dp,"online","original");

  if (on && !alert)
  {
    delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    dpSet(dp,on);
  }
  else if (on && alert)
  {
    delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    strreplace(dp1,"online","original");  
    dpSet(dp1, false,
          dp, false);
  }
  else
  {
    delay( (GfDelayCheckBack/1000),(GfDelayCheckBack % 1000) );
    dpSet(dp, false);
  }

}
//End of CP_DRIVE_CB