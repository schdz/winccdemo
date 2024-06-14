// ==================================================================================
// File:	SimModel.ctl ...  PVSS II Runtime Script (CTRL)
// Date:	2003-05-19
// Author:	ms
// Purpose:	Simulation of tank temperature and tank level dependent of device
//		positions in the tank example(s) /panels/mainpanels/reaktor.pnl
//		in a simplified way ... no pyhsically correct calculation !
// Changes:	prime version	(...please add!)
// ==================================================================================
main()
{
  bool 		on = true, noSimCenterDP = true;
  int 	 	i, lcnt, delta_t = 600;
  string 	sys;
  float  	min_level, max_level, level, level_old, flow, aperture;
  float  	flowFactor = 0.02, apFactor = 0.005,
  		v2, v1, flow_exchanger, temp, min_temp, max_temp, temp_exchanger, 
		temp_env = 22, contactArea, k = 0.000000001, k2 = 0.00000000005,
  		bowl_bottom = 0.17, bowl_top = 0.83, effective_level, volume, r=1,
                temp_old;
  dyn_string 	reactors = dpNames("*LICA*","PID_Control");
  time	        lastCall, now;


  // if no 'SimCenter' datapoint exists, use defaults from var declaration
  if(dpExists("SimCenter.modelLoopTime"))
  {
    dpGet("SimCenter.modelLoopTime",delta_t,
	  "SimCenter.modelSimOn",on);
    noSimCenterDP = false;
  }

  for(i=1; i<=dynlen(reactors); i++)
  {
    sprintf(sys,"R%02d_",i);
    reactors[i] = sys;
  }

  for(i=1; i<=dynlen(reactors); i++)
  {
    dpConnect("syncValves",reactors[i]+"HE_Inlet_Hot_Valve.cmd.setpoint");
  }
 

  lastCall = getCurrentTime();

  while(true)
  {
    lcnt++;
    if(on)
    { 
      for (i=1; i<= dynlen(reactors); i++)
      {
      dpGet(reactors[i]+"Feeder_Pump.state.value",flow,
    	    reactors[i]+"LICA_01.state.value",level,
    	    reactors[i]+"LICA_01.state.value:_pv_range.._max",max_level,
    	    reactors[i]+"LICA_01.state.value:_pv_range.._min",min_level,
    	    reactors[i]+"Discharge_Valve.state.value",aperture,
    	    reactors[i]+"TICA_02.state.value",temp,
    	    reactors[i]+"TICA_02.state.value:_pv_range.._max",max_temp,
    	    reactors[i]+"TICA_02.state.value:_pv_range.._min",min_temp,
    	    reactors[i]+"HE_Inlet_Hot_Valve.state.value",v2,	
    	    reactors[i]+"HE_Inlet_Cold_Valve.state.value",v1);

      temp_old = temp;
      level_old = level;
      
      // ================================================================================
      // Calculation of tank level in dependency of old level, pump speed, outflow valve
      // aperture ... including a rough approx of the bottom and top rot-ellipsoids
      
      if((level > min_level + bowl_bottom*(max_level-min_level))&&(level < min_level +bowl_top*(max_level-min_level)))
      {	
        level = level + flow * flowFactor - aperture*apFactor*sqrt(19.62*level*0.003);
      }
      else if (level < min_level + bowl_bottom*(max_level-min_level))
      {
        level = level + (1 + sin(1.57*level/(min_level + bowl_bottom*(max_level-min_level))))*1.5*(flow * flowFactor - aperture*apFactor*sqrt(19.62*level*0.01));      
      } 
      else
      {
        level = level + (1+ sin(1.57*level/(min_level + bowl_top*(max_level-min_level))))*1.5*(flow * flowFactor - aperture*apFactor*sqrt(19.62*level*0.01));            
      }
      
      if (level < min_level)
        level = min_level;
      if (level > max_level)
        level = max_level;
      

      // ================================================================================
      // Calculation of tank temperature in dependency of old temp, heat-exchanger flow
      // resulting from valve positions, current level&volume, contact area, aso.....
      if(fmod(lcnt,6)==0)
      {
        effective_level = level -  (min_level + bowl_bottom*(max_level-min_level));
        if (effective_level > (max_level - bowl_top*(max_level-min_level)))
          effective_level = effective_level - bowl_bottom*(max_level-min_level);

        flow_exchanger = (v1 + v2)/100;

        if(flow_exchanger)
          temp_exchanger = (v1*min_temp + v2*max_temp)/(v1+v2);
	else
        {
  	  temp_exchanger = temp_env;
	}
		
        contactArea = (max_level - min_level)*2*r*3.14;  
        contactArea =  contactArea * effective_level*(max_level-min_level);
      
        volume = level*r*r*3.14;

        if (volume <= 0)
          volume = 0.1;
      
        temp = temp + delta_t*(((temp_exchanger-temp)*flow_exchanger*contactArea*k/volume) + (temp_env - temp)*(contactArea + 2*r*r*3.14)*k2/volume);

	if (temp >= max_temp)
           temp = max_temp;
        if (temp <= min_temp)
           temp = min_temp;
             
        if(temp != temp_old)
          dpSet(reactors[i]+"TICA_02.state.value",temp);
      }     
      if (level != level_old)
        dpSet(reactors[i]+"LICA_01.state.value",level);  
      }
    }
    if(!noSimCenterDP)
      dpGet("SimCenter.modelLoopTime",delta_t,
	    "SimCenter.modelSimOn",on);
    
    // calculate the required delay to get an exact loop time independent from
    // calculation time in the for-loop!
    now = getCurrentTime(); 
    delta_t = delta_t - 1000*second(now - lastCall) - milliSecond(now - lastCall);
    if (delta_t > 1)
      delay(delta_t/1000,delta_t - 1000*(delta_t/1000));

    lastCall = getCurrentTime();
  }
}

// hot and cold stream through the heat exchanger are allway
// 100 % - the controller manipulates only the valve in the
// hot stream, the following lines set the cold stream valve
// always to the inverted position...
syncValves(string dp, float v1)
{
  float v2 = 100-v1;
  
  dp = dpSubStr(dp,DPSUB_DP);

  dp = substr(dp,0,4);
  dpSet(dp+"HE_Inlet_Cold_Valve.cmd.setpoint",v2);
}