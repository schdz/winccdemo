// ==================================================================================
// File:	SimDevices.ctl ... PVSS II Runtime Script (CTRL)
// Date:	2003-05-19
// Author:	ms
// Purpose:	Simulation of all devices of dptype 'Device' for the control example.
//		Aim it to model the behavior of finite reaktion of speed / aperture
//		values to setpoint changes.
// Changes:	prime version	(...please add!)
// ==================================================================================
main()
{
  int	     delta_t = 500; // Cycle time for one simulation loop in ms
  float       i, value, last_value, setpoint, 
             changeRatePU, //maximum change of device value pu of value range [0..1]
	     min, max, changeRate, dev;
  bool	     transition, transition_old, 
             on = true, 
             noSimCenterDP = true; 
  time	     lastCall, now;


  // Event driven simulation of device "Motor_N1"
  dyn_string  devices = dpNames("*","Motor_N1");
 
  for (i=1; i <= dynlen(devices); i++)
  {
    if (substr(dpSubStr(devices[i],DPSUB_DP),0,3) != "_mp")
       dpConnect("sim_Motor_N1",	devices[i]+".cmd.on");
  }


  // Cyclic simulation of  all other devices (type = "Device")
  devices = dpNames("*","Device");
  
  for (i=1; i <= dynlen(devices); i++)
  {
    if (substr(dpSubStr(devices[i],DPSUB_DP),0,3) == "_mp")
    {
       dynRemove(devices,i);
       i--;
       delay(0,50);
    }
  }

  // if no 'SimCenter' datapoint exists, use defaults
  if(dpExists("SimCenter.devicesLoopTime"))
  {
    dpGet("SimCenter.devicesLoopTime",delta_t,
	  "SimCenter.devicesSimOn",on);
    noSimCenterDP = false;
  }

  lastCall = getCurrentTime();

  // main loop for output changes... a value is 
  // changed only by changeRatePU per loop until
  // it reaches the setpoint of the device...
  while (true)
  {
    if(on)  // main switch for device simulation !
    {
      for (i=1; i <= dynlen(devices); i++)
      {
        dpGet(devices[i]+".cmd.setpoint",setpoint,
              devices[i]+".state.value",value,
              devices[i]+".state.value:_pv_range.._min",min, 
	      devices[i]+".state.value:_pv_range.._max",max,
	      devices[i]+".state.transition",transition_old,
	      devices[i]+".para.maxChangeRate",changeRatePU);

        last_value = value;
        changeRate = changeRatePU*(max-min);
        dev = value-setpoint;

        if(fabs(dev) < changeRate)
          value = setpoint;
        else
          value = (dev < 0)?value+changeRate:value-changeRate;   
      
        if (value != last_value)
        {
          transition = true;
          dpSet(devices[i]+".state.value",value);	  
          if(value == 0)
            dpSet(devices[i]+".state.on",false,
		  devices[i]+".state.off",true);
	  else if(value == 100)
            dpSet(devices[i]+".state.off",false,
		  devices[i]+".state.on",true);
          else if ((last_value != 0) && (last_value != 100))
            dpSet(devices[i]+".state.off",false,
		  devices[i]+".state.on",false);
        }
        else
          transition = false;

        if (transition != transition_old)
         dpSet(devices[i]+".state.transition",transition);       
      }
    }
    if(!noSimCenterDP)
      dpGet("SimCenter.devicesLoopTime",delta_t,
	    "SimCenter.devicesSimOn",on);
    
    // calculate the required delay to get an exact loop time independent from
    // calculation time in the for-loop!
    now = getCurrentTime(); 
    delta_t = delta_t - 1000*second(now - lastCall) - milliSecond(now - lastCall);
    if (delta_t > 1)
      delay(delta_t/1000,delta_t - 1000*(delta_t/1000));

    lastCall = getCurrentTime();
  }
}


sim_Motor_N1(string dp, bool dev_on)
{
  bool prev_state;
  time lastChange;

  dp = dpSubStr(dp, DPSUB_DP);

  dpGet(dp+".state.on", prev_state);

  if (prev_state !=dev_on)
  { 
    dpSet(dp+".state.transition",true);
    delay(3);
    dpSet(dp+".state.on",dev_on,
          dp+".state.transition",false);
  }  
}
