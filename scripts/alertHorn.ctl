/////////////////////////////////////////////////
///  alert horn script - m. tschank 20.06.01  ///
///                                           ///
///  last modification: 26.09.02              ///
/////////////////////////////////////////////////

    //This script contains all alert- horn functions as controlling the main DPEs,
    //building alert lists, horn-start, horn-stop, horn-acknowledge and also the needed threads.
    //All required settings must be parametrized at least one time to make the horn run correctly.
    //Therefore there use this panel: \panels\vision\alertHornProps.pnl.


bool        g_contOrCycl, g_queryCheck, g_running, g_general_On_Off, g_prioLimit, g_startNew,
            g_highPriority, g_hornEnabled, g_hornConnCheck, g_queryActiveCheck, g_2ndRunCheck;
int         g_beeperThreadId, g_wavThreadId, g_sleepThreadId, g_checkThreadStop, g_previousPrio = 2;

dyn_string  g_firstTab, g_savedTab;

//1
     //The main function controls the 'Enabled'- DPE which can stop the AlarmHorn completely
main()
{
  dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  0,
            "AlertHorn.HighPrioHornActive:_original.._value", 0);

  if (dpConnect("enabled", "AlertHorn.Enabled:_online.._value")== -1)
    DebugN("Error in dpConnect in main");
}


     //In case that 'Enabled' is TRUE, the function 'hornAcknowledge' will be started.
     //In the other case all sounds will be stopped- if there are any.
     //In 'enabled' there are 2 possibilities to acknowledge the horn:
     //- by the 'HornAcknowledge' -DPE which is integrated in the 'basepanel'.
     //- by the 'ExternalAck' -DPE which can be adjusted together with an peripheral adress
     //  to acknowledge the horn- for example - with a pushbutton.
enabled(string dpe, bool active)
{
  bool checkHornAckVal, checkExternalAckVal;
  time twoPrios;
  int  iT;

  // Ti 15017 begin
  dpGet("AlertHorn.DistinguishTwoPrios:_online.._stime", twoPrios); iT = period(twoPrios);
  if ( iT == 0 ) return;
  // Ti 15017 end

  if (active == 1)                                                      //If Enabled- DPE == TRUE, continue
  {                                                                     //with checking.
    g_hornEnabled = 1;
    dpGet("AlertHorn.HornAcknowledge:_original.._value", checkHornAckVal,       //In case of a new start all
          "AlertHorn.ExternalAck:_original.._value",     checkExternalAckVal);  //ack. DPEs must be set to 0

    if (checkHornAckVal == 1 || checkExternalAckVal == 1)
      dpSetWait("AlertHorn.HornAcknowledge:_original.._value", 0,
                "AlertHorn.ExternalAck:_original.._value",     0);

    if (g_hornConnCheck)
    {
      dpDisconnect("hornAcknowledge", "AlertHorn.HornAcknowledge:_online.._value",
                                      "AlertHorn.ExternalAck:_online.._value");
      g_hornConnCheck = 0;
    }

    if (dpConnect("hornAcknowledge", "AlertHorn.HornAcknowledge:_online.._value",
                                     "AlertHorn.ExternalAck:_online.._value")== -1)
      DebugN("Error in dpConnect in 'enabled'");

    else
      g_hornConnCheck = 1;
  }
  else                                                                  //If Enabled- DPE == FALSE, stop
  {                                                                     //the sound.
    GeneralAlarmHornStop("", 1);
    g_startNew = 1;
    g_hornEnabled = 0;
  }
}


    //Controls the bool-option HornAcknowledge
hornAcknowledge(string dpe, bool val, string dpe1, bool val2)
{
  bool            bHornAck, bExtAck;

  dyn_dyn_anytype tab;

  if (val == 1 || val2 == 1) g_general_On_Off = 1;                      //Check HornAck DPE & Ext.Ack DPE
  if (val !=1  && val2 != 1) g_general_On_Off = 0;

  if (g_general_On_Off == 1 && g_sleepThreadId == 0 && g_running != 0)  //With this part the horn will be stopped
  {                                                                     //immediately in case that there is at least one
    g_sleepThreadId = startThread("AlertHornSleep");                    //pending alert.
    GeneralAlarmHornStop("", 1);                                        //
  }                                                                     //(This function used to be in the 'work'- part)
  else if (g_general_On_Off == 1 && g_sleepThreadId == 0 && g_running == 0)
  {
    dpGet("AlertHorn.HornAcknowledge:_online.._value", bHornAck,
          "AlertHorn.ExternalAck:_online.._value",     bExtAck);

    if ( (bHornAck) || (bExtAck))
    {
      g_queryCheck = 1;
      g_queryActiveCheck = 1;
      g_2ndRunCheck = 1;
    }
  }


  if (g_2ndRunCheck == 1)
  {
    g_queryCheck = 1;
    g_queryActiveCheck = 1;
    g_2ndRunCheck = 0;
  }

  if (g_queryCheck == 1)
  {
    if (g_queryActiveCheck == 1)
    {
      dpQueryDisconnect("work","ident");                                //If the horn was disabled in any way before
      g_queryActiveCheck = 0;
    }
  }


  if (g_hornEnabled == 1)                                               //connect new.
  {
    if (g_queryActiveCheck == 0)
    {
      g_queryActiveCheck = 1;
      if (dpQueryConnectSingle("work", 1, "ident", "SELECT ALERT '_alert_hdl.._ackable' FROM '*' WHERE '_alert_hdl.._direction' == 1") == -1)
        DebugN("Error in dpQueryConnectSingle in hornAcknowledge");
      g_queryCheck = 1;
    }
  }
}


     //Function for stopping the horn
GeneralAlarmHornStop(string dpe, bool val)
{
  bool   beeperStatus, wavStatus, dpeStatus;
  string sDPE, sDPE2;

  if (val == 1)
  {
    dpGet("AlertHorn.BeeperProps.Enabled:_online.._value",   beeperStatus, //Is beeper, wav-sound or dpe-setting
          "AlertHorn.WavProps.Enabled:_online.._value",      wavStatus,    //enabled?
          "AlertHorn.ExternalProps.Enabled:_online.._value", dpeStatus);

    // BEEPER STOP //
    if (beeperStatus == 1)
    {
      if (g_beeperThreadId > 0)
      {
        g_checkThreadStop = stopThread(g_beeperThreadId);
        while (g_checkThreadStop != 0)
        {
          DebugN("BEEPER-STOP Error - ThreadID:",g_beeperThreadId);
          g_checkThreadStop = stopThread(g_beeperThreadId);
          delay(5);
        }
        g_checkThreadStop = 0;
        g_beeperThreadId  = 0;
      }
      g_running = 0;
    }

    // WAV STOP //
    if (wavStatus == 1)
    {
      if (g_contOrCycl != 1)
        stopSound();

      if (g_contOrCycl == 1 && g_wavThreadId != 0)
      {
        g_checkThreadStop = stopThread(g_wavThreadId);
        while (g_checkThreadStop != 0)
        {
          DebugN("WAV-STOP Error - ThreadID:",g_wavThreadId);
          g_checkThreadStop = stopThread(g_wavThreadId);
          delay (5);
        }
        g_checkThreadStop = 0;
        g_wavThreadId = 0;
        stopSound();
      }
      g_running = 0;
    }

    // DPE STOP //
    if (dpeStatus == 1)
    {
    if (g_running != 0)
      {
        dpGet("AlertHorn.ExternalProps.LowPrioExternalHornDPE:_online.._value",  sDPE,
              "AlertHorn.ExternalProps.HighPrioExternalHornDPE:_online.._value", sDPE2);

        if (g_prioLimit != 0) dpSetWait(sDPE2+":_original.._value", 0);
          dpSetWait(sDPE+":_original.._value", 0);
      }
      g_running = 0;
    }
    dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  0,      // shows in DP: Low/High PrioHornActive if low or high Prio
              "AlertHorn.HighPrioHornActive:_original.._value", 0);
  }
}


        //Function for building the alert list including all pending alerts //
work(string ident, dyn_dyn_anytype tab)
{
  int                   i, iLineNr, PriorRange, actState;
  string                dpElement;
  time                  ti;
  unsigned              ranges;
  bool                  moreRanges;
  dyn_time              times;
  dyn_int               ackState, realAckState, oldestAck, counts;
  dyn_string            dpes;

  for (i = 2; i <= dynlen(tab); i++ )                                   //This section creates the alert list.
  {                                                                     //Alerts with state "came" will be appended,
    dpElement = dpSubStr(tab[i][1], DPSUB_DP_EL);                       //others as "acknowledged" will be deleted.
    dpGet(dpElement+":_online.._stime",        ti,
          dpElement+":_alert_hdl.._act_range", PriorRange);
    dpGet(dpElement+":_alert_hdl."+PriorRange+"._act_state",actState);
    dpGet(dpElement+":_alert_hdl.._num_ranges", ranges);

    if (ranges >=1)
      moreRanges = 1;
    if (actState == 1 && dynContains(g_firstTab, dpElement) == 0)
      dynAppend(g_firstTab, dpElement);

    if (actState == 0 || actState == 2 || actState == 3)
    {
      iLineNr = dynContains(g_firstTab, dpElement);
      dynRemove(g_firstTab, iLineNr);
    }
  }
  /////////

  if (g_general_On_Off == 1 && dynlen(g_firstTab) == 0)                  //If the horn was acknowledged, but the list is
  {                                                                      //empty- both ack- DPEs will be set to 0.
    if (g_sleepThreadId > 0)                                             //If there is a sleep thread running stop it.
    {
      g_checkThreadStop = stopThread(g_sleepThreadId);
      while (g_checkThreadStop != 0)
      {
        DebugN("ALARM SLEEP-STOP Error - ThreadID:",g_sleepThreadId);
        g_checkThreadStop = stopThread(g_sleepThreadId);
        delay(5);
      }
    }                                                           //If g_sleepThreadId == 0
    g_running         = 0;
    g_checkThreadStop = 0;
    g_sleepThreadId   = 0;
    g_queryCheck      = 0;                                      //DpQuery shall not be started again when
    dpSetWait("AlertHorn.HornAcknowledge:_original.._value", 0, //both ack- DPEs are just changed to 0.
              "AlertHorn.ExternalAck:_original.._value",     0);
  }

  if ((g_firstTab == g_savedTab) && moreRanges == 1)
    g_startNew = 1;                                              //If there are the same alerts but different prio ranges
                                                                                                                                        //start sound new

  if (g_firstTab != g_savedTab || g_startNew == 1)               //If also the list has changed since last time OR sound shall
  {                                                                                                                             //be restarted.
    g_startNew = 0;
    if (dynlen(g_firstTab) > 0)
    {
      if (g_general_On_Off == 0 && g_hornEnabled == 1)
        startAlarmSound(g_firstTab);
    }
    else if (g_running == 1)
      GeneralAlarmHornStop("", 1);
  }
  g_savedTab = g_firstTab;
}


         //function for starting the alert horn;            //
         //also controls the priority of the pending alerts //
startAlarmSound(dyn_string g_firstTab)
{
  string          sLowerSnd, sHigherSnd, sDPE, sDPE2, Prior, dpElement, SoundFile;
  int             beepDuration, frequency, pause_time, i, iPriority, wavLoop, ElementPrior, PriorRange;
  bool            beeperStat, wavStat, dpeStat, continous;
  dyn_dyn_anytype tab;

  dpGet("AlertHorn.BeeperProps.Enabled:_online.._value",   beeperStat,
        "AlertHorn.WavProps.Enabled:_online.._value",      wavStat,
        "AlertHorn.ExternalProps.Enabled:_online.._value", dpeStat,
        "AlertHorn.HighPrioLimit:_online.._value",         iPriority,
        "AlertHorn.DistinguishTwoPrios:_online.._value",   g_prioLimit);

    for (i = 1; i <= dynlen(g_firstTab); i++)
    {
      dpElement = dpSubStr(g_firstTab[i], DPSUB_DP_EL);
      dpGet(dpElement+":_alert_hdl.._act_range",PriorRange);
      dpGet(dpElement+":_alert_hdl."+PriorRange+"._class",Prior);
      dpGet(Prior+":_alert_class.._prior",ElementPrior);
      if (ElementPrior >= iPriority)
      {
        g_highPriority = 1;
        break;
      }
      else
        g_highPriority = 0;
    }

  if (g_running == 1)                                                   // if there is a sound already running but with different Prio
  {                                                                     // then it will be stopped
    if (g_previousPrio != g_highPriority)
      GeneralAlarmHornStop("", 1);
  }

  if (g_running == 0)                                                   // if there is no sound running
  {
    g_contOrCycl   = 0;
    g_running      = 1;
    g_previousPrio = g_highPriority;

    // case: BEEPER
    if (beeperStat == 1 && g_general_On_Off == 0)
    {
      if (g_highPriority == 0 || g_prioLimit == 0)                              //if low or high Prio
      {
        dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  1,          //Shows in DP: Low/High PrioHornActive
                  "AlertHorn.HighPrioHornActive:_original.._value", 0);

        dpGet("AlertHorn.BeeperProps.LowPrioIntervalTime:_online.._value", pause_time,
              "AlertHorn.BeeperProps.LowPrioFrequency:_online.._value",    frequency,
              "AlertHorn.BeeperProps.LowPrioBeepTime:_online.._value",     beepDuration);

        g_beeperThreadId = startThread("BeeperSound",beepDuration, frequency, pause_time);
      }
      else
      {
        dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  0,
                  "AlertHorn.HighPrioHornActive:_original.._value", 1);

        dpGet("AlertHorn.BeeperProps.HighPrioIntervalTime:_online.._value", pause_time,
              "AlertHorn.BeeperProps.HighPrioFrequency:_online.._value",    frequency,
              "AlertHorn.BeeperProps.HighPrioBeepTime:_online.._value",     beepDuration);

        g_beeperThreadId = startThread("BeeperSound",beepDuration, frequency, pause_time);
      }
    }

    // case: WAV
    if (wavStat == 1 && g_general_On_Off == 0)
    {
      if (g_highPriority == 0 || g_prioLimit == 0)
      {
        dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  1,
                  "AlertHorn.HighPrioHornActive:_original.._value", 0);

        dpGet("AlertHorn.WavProps.LowPrioWavFile:_online.._value",       sLowerSnd,
              "AlertHorn.WavProps.LowPrioCycleInterval:_online.._value", wavLoop,
              "AlertHorn.WavProps.LowPrioContinous:_original.._value",   continous);

        if (continous == 1)
        {
          SoundFile = getPath(DATA_REL_PATH,"sounds/"+sLowerSnd);
          startSound(SoundFile,1);
        }
        else
        {
          g_contOrCycl = 1;
          g_wavThreadId = startThread("StartCyclicSound", sLowerSnd, wavLoop);
        }
      }
      else
      {
        dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  0,
                  "AlertHorn.HighPrioHornActive:_original.._value", 1);

        dpGet("AlertHorn.WavProps.HighPrioWavFile:_online.._value",       sHigherSnd,
              "AlertHorn.WavProps.HighPrioCycleInterval:_online.._value", wavLoop,
              "AlertHorn.WavProps.HighPrioContinous:_original.._value",   continous);

        if (continous == 1)
        {
          SoundFile = getPath(DATA_REL_PATH,"sounds/"+sHigherSnd);
          startSound(SoundFile,1);
        }
        else
        {
          g_contOrCycl  = 1;
          g_wavThreadId = startThread("StartCyclicSound", sHigherSnd, wavLoop);
        }
      }
    }

    // case: DPE
    if (dpeStat == 1 && g_general_On_Off == 0)
    {
      if (g_highPriority == 0 || g_prioLimit == 0)
      {
        dpGet("AlertHorn.ExternalProps.LowPrioExternalHornDPE:_online.._value", sDPE);
        dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  1,
                  "AlertHorn.HighPrioHornActive:_original.._value", 0,
                   sDPE+":_original.._value", 1);                   // sets ExternalDPE to 1
      }
      else
      {
        dpGet("AlertHorn.ExternalProps.HighPrioExternalHornDPE:_online.._value", sDPE2);
        dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  1,
                  "AlertHorn.HighPrioHornActive:_original.._value", 0,
                   sDPE2+":_original.._value", 1);
      }
    }
  }
}


/// THREADS //////

// Beeper //
void BeeperSound(int beepDuration, int frequency, int pause_time)
{
  if (pause_time <= 0)
  {
   if (frequency == 0 && beepDuration == 0)
     return;
   DebugN("BeeperSound: Pause time set automatical to 1 second!!", frequency,beepDuration);
   pause_time = 1000;
  }

  while(true)
  {
    beep(frequency,beepDuration);
    delay(0, pause_time);
  }
}

// Wav //
void StartCyclicSound(string wavFile, int wavLoop)
{
  string SoundFile = getPath(DATA_REL_PATH,"sounds/"+wavFile);

  if ( wavFile == "")
    return;

  while(true)
  {
    startSound(SoundFile);
    delay(wavLoop);
  }
}

// AlertHorn Sleep Mode //
void AlertHornSleep()
{
  int iAlertDelay;

  dpGet("AlertHorn.HornSilenceTime:_online.._value", iAlertDelay);
  dpSetWait("AlertHorn.LowPrioHornActive:_original.._value",  0,
            "AlertHorn.HighPrioHornActive:_original.._value", 0);
  delay(iAlertDelay);

  g_startNew      = 1;
  g_sleepThreadId = 0;
  g_2ndRunCheck   = 1;
  dpSetWait("AlertHorn.HornAcknowledge:_original.._value", 0,
            "AlertHorn.ExternalAck:_original.._value",     0);
}
