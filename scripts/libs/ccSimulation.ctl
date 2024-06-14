ccSimulateValues()
{  
// Initialize  
  
  string sysName; 
  
  string domain; 
  langString domainName;   

  dyn_errClass errors; 

  dyn_string color;
    
// CommCenterDomains

  sysName = getSystemName(); 
  domain = sysName + "Domain1"; 

  dpSet(domain+".Status:_original.._value", 1);
  dpSet(domain+".used:_original.._value", true);  

// CommCenterRecipients

  dyn_string dpNr, dname, disMember, daddressingText, daddressField1, daddressField2;
  dyn_string dcallingList, dremoteAlert, dpassword, ddomainNames, didentifier, dlanguage, dSubstPerson;
  dyn_string drecipient, dagency, dcolor; 
  dyn_int dworkLoadLevel, dpvssUser, dFallOut;
  dyn_bool dackPermission;
  
  dpNr = makeDynString("000001", "000002", "000003", "000004", "000005", "000006");
  dname = makeDynString("Anderson", "Black", "Collister", "Franklin", "Jackson", "King"); 
  disMember = makeDynInt(1, 1, 1, 1, 1, 1);
  dworkLoadLevel = makeDynInt(1, 1, 1, 1, 1, 1); 
  dFallOut = makeDynInt(0, 0, 0, 0, 0, 0);
  daddressingText = makeDynString("Mr.", "Mr.", "Mr.", "Mr.", "Mr.", "Mr."); 
  dcallingList = makeDynString("", "", "", "", "", "");
  daddressField1 = makeDynString("", "", "", "", "", "");
  daddressField2 = makeDynString("", "", "", "", "", ""); 
  dremoteAlert = makeDynString("", "", "", "", "", "");
  dpassword = makeDynString("", "", "", "", "", "");
  dpassword = makeDynInt("1111", "2222", "3333", "4444", "5555", "6666"); 
  dlanguage = makeDynString("en_US.utf8", "en_US.utf8", "en_US.utf8", "en_US.utf8", "en_US.utf8", "en_US.utf8");  
  dackPermission = makeDynBool(true, true, true, true, true, true);  
  dpvssUser = makeDynInt(0, 0, 0, 0, 0, 0);   
  dSubstPerson = makeDynString("", "", "", "", "", "");
  
// CommCenterRecipients
  
  dpSet("_CommCenterRecipients.PersonnelNumber:_original.._value", dpNr,
        "_CommCenterRecipients.Name:_original.._value",            dname,
        "_CommCenterRecipients.IsMember:_original.._value",        disMember,
        "_CommCenterRecipients.WorkLoadLevel:_original.._value",   dworkLoadLevel,
        "_CommCenterRecipients.AddressingText:_original.._value",  daddressingText,
        "_CommCenterRecipients.AddressField1:_original.._value",   daddressField1,
        "_CommCenterRecipients.AddressField2:_original.._value",   daddressField2,
        "_CommCenterRecipients.CallingList:_original.._value",     dcallingList,
        "_CommCenterRecipients.RemoteAlert:_original.._value",     dremoteAlert,
        "_CommCenterRecipients.Password:_original.._value",        dpassword,
        "_CommCenterRecipients.Language:_original.._value",        dlanguage,
        "_CommCenterRecipients.AckPermission:_original.._value",   dackPermission,
        "_CommCenterRecipients.PvssUser:_original.._value",        dpvssUser,
        "_CommCenterRecipients.Failure:_original.._value",         dFallOut ,
        "_CommCenterRecipients.Substitution:_original.._value",    dSubstPerson,
        "_CommCenterMessagingDevice.Identifier:_original.._value", didentifier);  
  
// CommCenterShift

  string shiftDP = "shift00001"; 

  drecipient = makeDynString(dpNr[1], dpNr[3], dpNr[5]); 
  dagency = makeDynString(dpNr[2], dpNr[4], dpNr[6]); 
  dcolor = makeDynString("STD_trend_pen1", "STD_trend_pen2", "STD_trend_pen3", "STD_trend_pen4", "STD_trend_pen5", "STD_trend_pen6", "STD_trend_pen7", "STD_trend_pen8");    
  
  if(!dpExists(shiftDP))
  {
    dpCreate(shiftDP, "_CommCenterShift"); 
    errors = getLastError();   
  }
  
  dpSet(shiftDP+".Personnel.Recipient:_original.._value",   drecipient,
        shiftDP+".Personnel.Substitute:_original.._value",  dagency, 
        shiftDP+".Personnel.Color:_original.._value",       dcolor, 
        shiftDP+".Domain:_original.._value", 1);    
  
}
