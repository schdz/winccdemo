//==================================================================================
// $License: comcenter
// Communication Center (c)2004 ETM AG
//==================================================================================


/*
Name:        CommunicationCenter.ctl
Author:      Thomas Schirk
Date:        20.7.2001
Version:     1.0
Description: This File includes Common Functions for the Commcenter Projekt
Changes:
             13.05.2004 - Peter Varga
             2007 - Markus Trummer

-- Functions in alphabetic order--
---------------------------------------------------------------------------------------------------------------------------------------
ccAppendDays:                     copies two day Vars to one
ccChangeDeviceData:               Changes the existing Device Data
ccChangeRecipientData:            Changes existing Recipient Datas
ccCreateDevice:                   Creates a new Device
ccCreateOrChangeRecipient:        Creates or Changes a new Recipient (if the Personnelnumber exists then change else create
ccCreateOrEditShift:              Creates or Changes a new Shift (if the ShiftDP exists then change else create)
ccCreateOrEditShiftAggregation:   Creates or Changes a new ShiftAggregation 
                                  (if the ShiftAggregationDP exists then change else create)
ccCreateRecipient:                Creates a new Recipient
ccDeleteDevice:                   Deletes a device
ccDeleteRecipient:                Deletes a recipient
ccDeleteShift:                    deletes a shift
ccDeleteShiftAggregation:         deletes a shiftaggregation
ccGetDevices:                     get devices with their datas
ccGetPersonnelIndex:              calculates with a time_var the index and returns the element of the 
                                  calculated index in the dyndyn
ccGetRecipients:                  get recipient with their datas
ccGetShift:                       get a shift with its datas
ccGetShiftAggregation:            get a shiftaggregation with its datas
ccGetShiftAggregationCalculation: get a calculated Aggregationdatas
ccGetAggregationDays:             get the day - var of the Aggregation 
ccGetShiftDPs:                    get the existing shift Datapoints
ccGetShiftAggregationDPs:         get the existing shiftaggregation Datapoints
ccRecipientUsed:                  searches in the shifts and shiftplans if the param PNr is used and returns found DPs 
ccUsedInAggs:                     searches the Aggregationparts of each Aggregation if the Parameter DP is used and 
                                  returns a DPList of all Aggs that use this DP
---------------------------------------------------------------------------------------------------------------------------------------
*/
//---------------------------------------------------------------------------------------------------------------------------------------
//global Variables
global dyn_string barColor = makeDynString("red","blue","green","yellow","brown","darkblue","orange","darkgreen","magenta","steelblue","gainsboro", "grey");  //set colors of Bars
string overParaColor = "red";   //red
string oldColor = "lightgrey";    //lightgrey
string shiftStartEndColor = "grey";    //grey
string emptyColor = "white";  //white
string actDayColor = "STD_bar";  //darkblue
string specialDayColor = "STD_object_background";  //STD_object_background
string normalDayColor = "lightgrey";  //lightgrey

//***fct***//
void ccCreateOrChangeRecipient(string     personnelNumber, // Key!!
                               string     name,            // Name of the Recipient
                               dyn_string isMember,        // Domains of this recipient
                               int        workLoadLevel,   // numbers from 1 to 5, 1 = minimum, 5 = maximum
                               string     addressingText,  // Text that is spoken at the beggining of the phonetalk
                               string     addressField1,   // including Street and number
                               string     addressField2,   // including ZIP and Country
                               dyn_string callingList,     // list of devices (index)
                               dyn_string remoteAlert,     // devices for remote alert
                               string     password,        // only digits
                               string     language,        // language of the Recipient
                               bool       ackPermission,   // is he allowed to acknowledge an alert
                               int        pvssUser,        // pvss userID if defined
                               int        fallOut,         // user is marked as failed
                               string     substPerson,     // substituting person (not used)
                               int        &iError)         // Error-Codes
//if the personnelNumber exists in the Datapoint _CommCenterRecipients.personnelNumber the function change the 
//       Data else a new Recipient will be added
//ReturnValues iError.......0 OK!
//                        -1  invalid personnelnumber (must not be "")
//                        -10 invalid domain found in isMember
//                        -11 workLoadLevel not between 1 and 5
//                        -12 invalid Deviceindex found in callingList
//                        -13 password incorrect
{
  dyn_string dpNr, dname, disMember, daddressingText, daddressField1, daddressField2;
  dyn_string dcallingList, dremoteAlert, dpassword, ddomainNames, didentifier, dlanguage, dSubstPerson;
  dyn_int dworkLoadLevel, dpvssUser, dFallOut;
  int index, i, convertInt;
  string convertString;
  dyn_bool dackPermission;

  iError = 0; //init iError with no Error

  // Get current Data from the Database
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dpNr,
        "_CommCenterRecipients.Name:_online.._value",            dname,
        "_CommCenterRecipients.IsMember:_online.._value",        disMember,
        "_CommCenterRecipients.WorkLoadLevel:_online.._value",   dworkLoadLevel,
        "_CommCenterRecipients.AddressingText:_online.._value",  daddressingText,
        "_CommCenterRecipients.AddressField1:_online.._value",   daddressField1,
        "_CommCenterRecipients.AddressField2:_online.._value",   daddressField2,
        "_CommCenterRecipients.CallingList:_online.._value",     dcallingList,
        "_CommCenterRecipients.RemoteAlert:_online.._value",     dremoteAlert,
        "_CommCenterRecipients.Password:_online.._value",        dpassword,
        "_CommCenterRecipients.Language:_online.._value",        dlanguage,
        "_CommCenterRecipients.AckPermission:_online.._value",   dackPermission,
        "_CommCenterRecipients.PvssUser:_online.._value",        dpvssUser,
        "_CommCenterRecipients.Failure:_online.._value",         dFallOut ,
        "_CommCenterRecipients.Substitution:_online.._value",    dSubstPerson,
        "_CommCenterMessagingDevice.Identifier:_online.._value", didentifier);


  ddomainNames = dpNames("*","_CommCenterDomains");
  
  if ( personnelNumber == "")
  {
    iError = -1;
    return;
  }

  // if personnelNumber exists take the index of this personnelNumber else get a new Index
  if ((index = dynContains(dpNr,personnelNumber)) < 1)
    index = dynlen(dpNr)+1;

  // check if the workLoadLevel is between 1 and 5
  if (workLoadLevel < 1 || workLoadLevel > 5)
  {
    iError = -11;
    return;
  }

  // check if every part of isMember is a valid DomainName
  for (i = 1; i <= dynlen(isMember); i++)
  {
    if (dynlen(ddomainNames) < isMember[i] || isMember[i] < 1)
    {
      iError = -10;
      return;
    }
  }

  //check if every Index in the CallingList exists in the Datapoint _CommCenterMessagingDevices
  for (i = 1; i <= dynlen(callingList); i++)
  {
    if (dynContains(didentifier, callingList[i]) < 1)
    {
      iError = -12;
      return;
    }
  }

  //check if the password is valid
  convertString = convertInt = password; //if there is a nondiggit Char in password convertString isn't the same

//  if ((convertString != password) || strlen(password) != 4)
  if ( strlen(password) != 4 || !patternMatch("[0123456789][0123456789][0123456789][0123456789]", password) )
  {
    iError = -13;
    return;
  }

  if (iError == 0)
  //no Error
  {
    // change the dyn - Values
    dpNr[index] = personnelNumber;              
    dname[index] = name;                       
    disMember[index] = isMember;               
    strreplace(disMember[index]," | ","|");    
    dworkLoadLevel[index] = workLoadLevel;     
    daddressingText[index] = addressingText;   
    daddressField1[index] = addressField1;     
    daddressField2[index] = addressField2;     
    dcallingList[index] = callingList;         
    strreplace(dcallingList[index]," | ","|"); 
    dremoteAlert[index] = remoteAlert;         
    strreplace(dremoteAlert[index]," | ","|"); 
    dpassword[index] = password;               
    dackPermission[index] = ackPermission;
    dpvssUser[index] = pvssUser;
    dlanguage[index] = language;
    dFallOut[index] = fallOut;
    dSubstPerson[index] = substPerson;
  
    //and write it back to the Datapoint
    dpSet("_CommCenterRecipients.PersonnelNumber:_original.._value", dpNr,
          "_CommCenterRecipients.Name:_original.._value",           dname,
          "_CommCenterRecipients.IsMember:_original.._value",       disMember,
          "_CommCenterRecipients.WorkLoadLevel:_original.._value",  dworkLoadLevel,
          "_CommCenterRecipients.AddressingText:_original.._value", daddressingText,
          "_CommCenterRecipients.AddressField1:_original.._value",  daddressField1,
          "_CommCenterRecipients.AddressField2:_original.._value",  daddressField2,
          "_CommCenterRecipients.CallingList:_original.._value",    dcallingList,
          "_CommCenterRecipients.RemoteAlert:_original.._value",    dremoteAlert,
          "_CommCenterRecipients.Password:_original.._value",       dpassword,
          "_CommCenterRecipients.Language:_original.._value",       dlanguage,
          "_CommCenterRecipients.AckPermission:_original.._value",  dackPermission,
          "_CommCenterRecipients.PvssUser:_original.._value",       dpvssUser,
          "_CommCenterRecipients.Failure:_original.._value",        dFallOut ,
          "_CommCenterRecipients.Substitution:_original.._value",   dSubstPerson);
  }
}

//***fct***//
void ccCreateRecipient(string     personnelNumber, // Key!!
                       string     name,            // Name of the Recipient
                       dyn_string isMember,        // Domains of this recipient
                       int        workLoadLevel,   // numbers from 1 to 5, 1 = minimum, 5 = maximum
                       string     addressingText,  // text that is spoken at the beginning of a phonetalk
                       string     addressField1,   // including Street and number
                       string     addressField2,   // including ZIP and Country
                       dyn_string callingList,     // list of devices (index)
                       dyn_string remoteAlert,     // devices for remote alert
                       string     password,        // only diggits
                       string     language,        // language of the recipient
                       bool       ackPermission,   // is he allowed to acknowledge an alert
                       int        pvssUser,        // pvss userID if defined
                       int        fallOut,         // user is marked as failed
                       string     substPerson,     // substituting person (not used)
                       int        &iError)         // Error-Codes
//adds an recipient to the existing recipients in the Datapoint _CommCenterRecipients
//ReturnValues iError.....0  OK!
//                        -1 personnelNumber already exixts!
//                        -10 invalid domain found in isMember
//                        -11 workLoadLevel not between 1 and 5
//                        -12 invalid Deviceindex found in callingList
//                        -13 password incorrect
{
  dyn_string dpNr;

  iError = 0; //init iError with no Error

  // get current Data from the Database
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dpNr);

  if (dynContains(dpNr,personnelNumber) > 0)
  //check if the personnelNumber is not in use
    iError = -1;
  else
  {
    //create the Recipient
    ccCreateOrChangeRecipient(personnelNumber, name, isMember, workLoadLevel, addressingText, addressField1, 
                              addressField2, callingList, remoteAlert, password, language, ackPermission, getUserId(pvssUser),
                              fallOut, substPerson, iError);
  }
}

//***fct***//
void ccChangeRecipientData(string     personnelNumber, // personnelNumber to search in the dyns, name and personnelNumber must not be changed
                           dyn_string isMember,        // Domains of this recipient
                           int        workLoadLevel,   // numbers from 1 to 5, 1 = minimum, 5 = maximum
                           string     addressingText,  // text that is spoken at the beginning of a phonetalk
                           string     addressField1,   // including Street and number
                           string     addressField2,   // including ZIP and Country
                           dyn_string callingList,     // list of devices (index)
                           dyn_string remoteAlert,     // devices for remote alert
                           string     password,        // only diggits 
                           string     language,        // language of the recipient
                           bool       ackPermisson,    // is he allowed to acknowledge an alert
                           int        pvssUser,        // pvss userID if defined
                           int        fallOut,         // user is marked as failed
                           string     substPerson,     // substituting person (not used)
                           int        &iError)         // Error-Codes
//find recipient with personnelNumber [personnelNumber] and change the values of the recipient
//ReturnValues iError......0  OK!
//                        -1 personnelNumber not found
//                        -10 invalid domain found in isMember
//                        -11 workLoadLevel not between 1 and 5
//                        -12 invalid Deviceindex found in callingList
//                        -13 password incorrect
{
  dyn_string dpNr, dname;

  iError = 0; //init iError with no Error

  //get current Data from the Database
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dpNr,
        "_CommCenterRecipients.Name:_online.._value",            dname);

  if (dynContains(dpNr,personnelNumber) < 1)
  //check if the personnelNumber exists
    iError = -1;
  else
  {
    //change Reipient Data
    ccCreateOrChangeRecipient(personnelNumber, dname[dynContains(dpNr,personnelNumber)], isMember, workLoadLevel, 
      addressingText, addressField1, addressField2, callingList, remoteAlert, password, language, ackPermission,
      pvssUser, fallOut, substPerson, iError);
  }
}

//***fct***//
void ccGetRecipients(dyn_string     &personnelNumber, // personnel - numbers to search
                     dyn_string     &name,            // Names to search
                     dyn_dyn_string &isMember,        // DomainLists to search
                     dyn_int        &workLoadLevel,   // workLoadLevels to search
                     dyn_string     &addressingText,  // addressingText to search
                     dyn_string     &addressField1,   // addressField1 to search
                     dyn_string     &addressField2,   // addressField2 to search
                     dyn_dyn_string &callingList,     // callingLists to search
                     dyn_dyn_string &remoteAlert,     // remoteAlerts to search
                     dyn_string     &password,        // passwords to search
                     dyn_string     &language,        // languages to search
                     dyn_bool       &ackPermission,   // ackPermissions to search
                     dyn_int        &pvssUser,        // pvss userID if defined
                     dyn_int        &fallOut,         // user is marked as failed
                     dyn_string     &substPerson)     // substituting person (not used)
//seeks the Recipients with fitting Datas
//all Parameters are Input and Outputvalues!
//Input: for example: seek personnelNumber A, and B -> personnelNumber[1] = A; personnelNumber[2] = B;
//                    or seek every Recipient with the password 1736 and workLoadLevel 3; password = 1736 workLoadLevel = 3
//Output: Datas of the fitting Recipients! No Distinct!!!! 
{
  dyn_string retpersonnelNumber, retName, retAddressingText, retAddressField1, retAddressField2, retPassword, retLanguage;
  dyn_string dpNr, dname, disMember, daddressingText, daddressField1, daddressField2,
             dcallingList, dremoteAlert, dpassword, dlanguage, retSubstPerson, dSubstPerson, ds1, ds2, ds3;
  dyn_dyn_string retIsMember, retCallingList, retRemoteAlert;
  dyn_int dworkLoadLevel, retWorkLoadLevel, retFallOut, dFallOut, dpvssUser, retPvssUser, dPvssUser;
  int maximum, i, j;
  dyn_bool retAckPermission, dackPermission;

  // get current Data from the Database
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dpNr,
        "_CommCenterRecipients.Name:_online.._value",            dname,
        "_CommCenterRecipients.IsMember:_online.._value",        disMember,
        "_CommCenterRecipients.WorkLoadLevel:_online.._value",   dworkLoadLevel,
        "_CommCenterRecipients.AddressingText:_online.._value",  daddressingText,
        "_CommCenterRecipients.AddressField1:_online.._value",   daddressField1,
        "_CommCenterRecipients.AddressField2:_online.._value",   daddressField2,
        "_CommCenterRecipients.CallingList:_online.._value",     dcallingList,
        "_CommCenterRecipients.RemoteAlert:_online.._value",     dremoteAlert,
        "_CommCenterRecipients.Password:_online.._value",        dpassword,
        "_CommCenterRecipients.Language:_online.._value",        dlanguage,
        "_CommCenterRecipients.AckPermission:_online.._value",   dackPermission,
        "_CommCenterRecipients.PvssUser:_online.._value",        dpvssUser,
        "_CommCenterRecipients.Failure:_online.._value",         dFallOut ,
        "_CommCenterRecipients.Substitution:_online.._value",    dSubstPerson);


  // get the maximum lenghts of the input dyns
  maximum = dynlen(personnelNumber);
  if (maximum < dynlen(name))           maximum = dynlen(name);
  if (maximum < dynlen(isMember))       maximum = dynlen(isMember);
  if (maximum < dynlen(workLoadLevel))  maximum = dynlen(workLoadLevel);
  if (maximum < dynlen(addressingText)) maximum = dynlen(addressingText);
  if (maximum < dynlen(addressField1))  maximum = dynlen(addressField1);
  if (maximum < dynlen(addressField2))  maximum = dynlen(addressField2);
  if (maximum < dynlen(callingList))    maximum = dynlen(callingList);
  if (maximum < dynlen(remoteAlert))    maximum = dynlen(remoteAlert);
  if (maximum < dynlen(password))       maximum = dynlen(password);
  if (maximum < dynlen(language))       maximum = dynlen(language);
  if (maximum < dynlen(ackPermission))  maximum = dynlen(ackPermission);
  if (maximum < dynlen(pvssUser))       maximum = dynlen(pvssUser);
  if (maximum < dynlen(substPerson))    maximum = dynlen(substPerson);
  if (maximum < dynlen(pvssUser))       maximum = dynlen(pvssUser);

  if (maximum == 0)
  //no searchcriterium -> all Recipients
    maximum = 1;

  for ( i = 1; i <= maximum; i++ )
  // from 1 to maximum dynlenghts
  {
    for ( j = 1; j <= dynlen(dpNr); j++ )
    // for all the existing Recipients
    {
      ds1 = strsplit(disMember[j], "|");
      ds2 = strsplit(dcallingList[j], "|");
      ds3 = strsplit(dremoteAlert[j], "|");
      if ( !( (dynlen(personnelNumber) >= i) && (personnelNumber[i] != dpNr[j])            ) &&
           !( (dynlen(name)            >= i) && (name[i]            != dname[j])           ) &&
//           !( (dynlen(isMember)        >= i) && (isMember[i]        != disMember[j])       ) &&
           !( (dynlen(isMember)        >= i) && (isMember[i]        != ds1)                ) &&
           !( (dynlen(workLoadLevel)   >= i) && (workLoadLevel[i]   != dworkLoadLevel[j])  ) &&
           !( (dynlen(addressingText)  >= i) && (addressingText[i]  != daddressingText[j]) ) &&
           !( (dynlen(addressField1)   >= i) && (addressField1[i]   != daddressField1[j])  ) &&
           !( (dynlen(addressField2)   >= i) && (addressField2[i]   != daddressField2[j])  ) &&
//           !( (dynlen(callingList)     >= i) && (callingList[i]     != dcallingList[j])    ) &&
           !( (dynlen(callingList)     >= i) && (callingList[i]     != ds2)                ) &&
           !( (dynlen(remoteAlert)     >= i) && (remoteAlert[i]     != ds3)                ) &&
           !( (dynlen(password)        >= i) && (password[i]        != dpassword[j])       ) &&
           !( (dynlen(language)        >= i) && (language[i]        != dlanguage[j])       ) &&
           !( (dynlen(ackPermission)   >= i) && (ackPermission[i]   != dackPermission[j])  ) &&
           !( (dynlen(fallOut)         >= i) && (fallOut[i]         != dFallOut[j])        ) &&
           !( (dynlen(substPerson)     >= i) && (substPerson[i]     != dSubstPerson[j])    ) &&
           !( (dynlen(pvssUser)        >= i) && (pvssUser[i]        != dpvssUser[j])       )   )
      // if a searchcriterium is valid then check if the current Dataset fulfills the criteria
      {
        // all criteries passed
        retpersonnelNumber[dynlen(retpersonnelNumber)+1] = dpNr[j];
        retName[dynlen(retName)+1]                       = dname[j];
        retIsMember[dynlen(retIsMember)+1]               = strsplit(disMember[j], "|");
        retWorkLoadLevel[dynlen(retWorkLoadLevel)+1]     = dworkLoadLevel[j];
        retAddressingText[dynlen(retAddressingText)+1]   = daddressingText[j];
        retAddressField1[dynlen(retAddressField1)+1]     = daddressField1[j];
        retAddressField2[dynlen(retAddressField2)+1]     = daddressField2[j];
        retCallingList[dynlen(retCallingList)+1]         = strsplit(dcallingList[j], "|");
        retRemoteAlert[dynlen(retRemoteAlert)+1]         = strsplit(dremoteAlert[j], "|");
        retPassword[dynlen(retPassword)+1]               = dpassword[j];
        retLanguage[dynlen(retLanguage)+1]               = dlanguage[j];
        retAckPermission[dynlen(retAckPermission)+1]     = dackPermission[j];
        retPvssUser[dynlen(retPvssUser)+1]               = dpvssUser[j];
        retFallOut[dynlen(retFallOut)+1]                 = dFallOut[j];
        retSubstPerson[dynlen(retSubstPerson)+1]         = dSubstPerson[j];
      }
    }
  }

  // return the recipients that are found
  personnelNumber = retpersonnelNumber;
  name = retName;
  isMember = retIsMember;
  workLoadLevel = retWorkLoadLevel;
  addressingText = retAddressingText;
  addressField1 = retAddressField1;
  addressField2 = retAddressField2;
  callingList = retCallingList;
  remoteAlert = retRemoteAlert;
  password = retPassword;
  language = retLanguage;
  ackPermission = retAckPermission;
  pvssUser = retPvssUser;
  fallOut = retFallOut;
  substPerson = retSubstPerson;
}

//***fct***//
void ccDeleteRecipient(string personnelNumber, // Key!
                       int    &iError)         // Error-Codes
//search the personnelNumber and delete this recipient
//ReturnValues iError......0  OK!
//                        -1 personnelNumber not found
{
  int index;
  int i, err;
  dyn_string dpNr, dname, disMember, daddressingText, daddressField1, daddressField2,
             dcallingList, dremoteAlert, dpassword, dlanguage, dpvssUser, dSubstPerson;
  dyn_int dworkLoadLevel, dFallOut;
  dyn_int CList;
  dyn_bool dackPermission;

  iError = 0; //init iError with no Error

  //get current Data from the Database
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dpNr,
        "_CommCenterRecipients.Name:_online.._value",            dname,
        "_CommCenterRecipients.IsMember:_online.._value",        disMember,
        "_CommCenterRecipients.WorkLoadLevel:_online.._value",   dworkLoadLevel,
        "_CommCenterRecipients.AddressingText:_online.._value",  daddressingText,
        "_CommCenterRecipients.AddressField1:_online.._value",   daddressField1,
        "_CommCenterRecipients.AddressField2:_online.._value",   daddressField2,
        "_CommCenterRecipients.CallingList:_online.._value",     dcallingList,
        "_CommCenterRecipients.RemoteAlert:_online.._value",     dremoteAlert,
        "_CommCenterRecipients.Password:_online.._value",        dpassword,
        "_CommCenterRecipients.Language:_online.._value",        dlanguage,
        "_CommCenterRecipients.AckPermission:_online.._value",   dackPermission,
        "_CommCenterRecipients.PvssUser:_online.._value",        dpvssUser,
        "_CommCenterRecipients.Failure:_online.._value",         dFallOut ,
        "_CommCenterRecipients.Substitution:_online.._value",    dSubstPerson,
        "_CommCenterRecipients.PvssUser:_online.._value",        dpvssUser);

  if ((index = dynContains(dpNr,personnelNumber)) <= 0)
  //check if the personnelNumber exists
    iError = -1;
  else
  {
    // delete private Devices
    CList = strsplit(dcallingList[index], "|");
    for ( i = 1; i <= dynlen(CList); i++)
      ccDeleteDevice(CList[i],err);

    //delete Recipient
    dynRemove(dpNr,index);
    dynRemove(dname,index);
    dynRemove(disMember,index);
    dynRemove(dworkLoadLevel,index);
    dynRemove(daddressingText,index);
    dynRemove(daddressField1,index);
    dynRemove(daddressField2,index);
    dynRemove(dcallingList,index);
    dynRemove(dremoteAlert,index);
    dynRemove(dpassword,index);
    dynRemove(dlanguage,index);
    dynRemove(dackPermission,index);
    dynRemove(dpvssUser,index);
    dynRemove(dFallOut,index);
    dynRemove(dSubstPerson,index);

    //write the dyns back in the Database
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
          "_CommCenterRecipients.Substitution:_original.._value",    dSubstPerson);
  }
}

//***fct***//
void ccCreateDevice(string number,     // number of the device
                    int    deviceType, // deviceType (has to exist)
                    string identifier, // if private name of the Recipient
                    string user,       // userID
                    int    &index,     // index of the new device
                    int    &iError,    // Error-Codes
                    string provider = "")
//adds an Device to the Datapoint _CommCenterMessagingDevices
//ReturnValues iError......0  OK!
//                        -10 Device already defined
//             index.......index of the new device
{
  dyn_string dnumber, ddeviceType, didentifier, dsUser, dsProvider;
  dyn_time dfrom, dto;
  dyn_bool dAutoHS;
  int i;

  iError = 0; //init iError with no Error

  //get current Data from the Database
  dpGet("_CommCenterMessagingDevice.Number:_online.._value",               dnumber,
        "_CommCenterMessagingDevice.Identifier:_online.._value",           didentifier,
        "_CommCenterMessagingDevice.DeviceType:_online.._value",           ddeviceType,
        "_CommCenterMessagingDevice.User:_online.._value",                 dsUser,
        "_CommCenterMessagingDevice.Provider:_online.._value",             dsProvider);

  // get new Index
  index = dynlen(didentifier)+1;

  // check if the device isn't defined yet
  for (i = 1; i <= dynlen(didentifier); i++)
  {
    if ( didentifier[i] == identifier )/* &&
         dnumber[i]     != number)*/

      iError = -10;
  }
  
  if (iError == 0)
  //no Error
  {
    // change the dyn - Values
    dnumber[index]     = number;     
    didentifier[index] = identifier; 
    ddeviceType[index] = deviceType; 
    dsUser[index]      = user;
    dsProvider[index]  = provider;
  
    //and write it back to the Datapoint
    dpSet("_CommCenterMessagingDevice.Number:_original.._value",               dnumber,
          "_CommCenterMessagingDevice.Identifier:_original.._value",           didentifier,
          "_CommCenterMessagingDevice.DeviceType:_original.._value",           ddeviceType,
          "_CommCenterMessagingDevice.User:_original.._value",                 dsUser,
          "_CommCenterMessagingDevice.Provider:_original.._value",             dsProvider);
  }
}

//***fct***//
void ccChangeDeviceData(int    index,      // 0 = newId, 1 = changeId, 2 = changeData
                        string number,     // number of the device
                        int    deviceType, // deviceType (has to exist)
                        string identifier, // if private name of the Recipient
                        string user,       // userID
                        int    &iError,    // Error-Codes
                        string provider = "")
//ReturnValues iError......0  OK!
//                        -1  invalid index
//                        -10 Device already defined
{
  dyn_string dnumber, ddeviceType, didentifier, dsUser, dsProvider;
  int i, iPos;

  iError = 0; //init iError with no Error

  //get current Data from the Database
  dpGet("_CommCenterMessagingDevice.Number:_online.._value",               dnumber,
        "_CommCenterMessagingDevice.Identifier:_online.._value",           didentifier,
        "_CommCenterMessagingDevice.DeviceType:_online.._value",           ddeviceType,
        "_CommCenterMessagingDevice.User:_online.._value",                 dsUser,
        "_CommCenterMessagingDevice.Provider:_online.._value",             dsProvider);


  // check if the device isn't defined yet
  iPos = dynContains(didentifier, identifier);
  if ( iPos > 0 )
  {
    // change the dyn - Values
    dnumber[iPos]     = number;     
    didentifier[iPos] = identifier; 
    ddeviceType[iPos] = deviceType; 
    dsUser[iPos]      = user;       
    dsProvider[iPos]  = provider;
  
    //and write it back to the Datapoint
    dpSet("_CommCenterMessagingDevice.Number:_original.._value",               dnumber,
          "_CommCenterMessagingDevice.Identifier:_original.._value",           didentifier,
          "_CommCenterMessagingDevice.DeviceType:_original.._value",           ddeviceType,
          "_CommCenterMessagingDevice.User:_original.._value",                 dsUser,
          "_CommCenterMessagingDevice.Provider:_original.._value",             dsProvider);
  }
}

//***fct***//
void ccGetDevices(dyn_string &index,      // indexes to search
                  dyn_string &number,     // numbers to search
                  dyn_int    &deviceType, // deviceTypes to search
                  dyn_string &identifier, // identifiers to search
                  dyn_string &user,       // userID
                  dyn_string &provider)
//seeks the devices with fitting Datas
//like ccGetRecipients
{
  dyn_string dnumber, ddeviceType, didentifier, dsUser, dsProvider;
  dyn_string retindex, retnumber, retdeviceType, retidentifier, retuser, retprovider;
  dyn_time retfrom, retto;

  int maximum, i, j;

  //get current Data from the Database
  dpGet("_CommCenterMessagingDevice.Number:_online.._value",               dnumber,
        "_CommCenterMessagingDevice.Identifier:_online.._value",           didentifier,
        "_CommCenterMessagingDevice.DeviceType:_online.._value",           ddeviceType,
        "_CommCenterMessagingDevice.User:_online.._value",                 dsUser,
        "_CommCenterMessagingDevice.Provider:_original.._value",           dsProvider);


  // get the maximum lenghts of the input dyns
  maximum = dynlen(index);
  if (maximum < dynlen(number))         maximum = dynlen(number);
  if (maximum < dynlen(deviceType))     maximum = dynlen(deviceType);
  if (maximum < dynlen(identifier))     maximum = dynlen(identifier);
  if (maximum < dynlen(user))           maximum = dynlen(user);
  if (maximum < dynlen(provider))       maximum = dynlen(provider);

  // no criterium -> all Devices
  if (maximum == 0)
    maximum = 1;

  // from 1 to maximum dynlenghts
  for ( i = 1; i <= maximum; i++ )
  {
    // for all the existing Devices
    for ( j = 1; j <= dynlen(didentifier); j++ )
    {
      // if a searchcriterium is valid then check if the current Dataset fulfills the criteria
      if ( !( (dynlen(index)      >= i) && (index[i]      != j)             ) &&
           !( (dynlen(number)     >= i) && (number[i]     != dnumber[j])    ) &&
           !( (dynlen(deviceType) >= i) && (deviceType[i] != ddeviceType[j])) &&
           !( (dynlen(identifier) >= i) && (identifier[i] != didentifier[j])) &&
           !( (dynlen(provider)   >= i) && (provider[i]   != dsProvider[j]))  &&
           !( (dynlen(user)       >= i) && (user[i]       != dsUser[j])     )   )
      {
        // all criteries passed
        retindex[dynlen(retindex)+1]           = j;
        retnumber[dynlen(retnumber)+1]         = dnumber[j];
        retdeviceType[dynlen(retdeviceType)+1] = ddeviceType[j];
        retidentifier[dynlen(retidentifier)+1] = didentifier[j];
        retuser[dynlen(retuser)+1]             = dsUser[j];
        retprovider[dynlen(retprovider)+1]     = dsProvider[j];
      }
    }
  }

  // return the devices that are found
  index = retindex;
  number = retnumber;
  deviceType = retdeviceType;
  identifier = retidentifier;
  user = retuser;
  provider = retprovider;
}

//***fct***//
void ccDeleteDevice(string  index,   // index of the device that should be deleted
                    int    &iError)  // Error-Codes
//deletes the Device with the index [index]
//ReturnValues iError......0  OK!
//                        -1  invalid index
{
  dyn_string dnumber, ddeviceType, didentifier, dlanguage, dsUser, dsProvider;
  dyn_time dfrom, dto;
  int i,j, err;
  dyn_string pNumber, name, addressingText, addressField1, addressField2, password;
  dyn_dyn_string callingList;
  dyn_dyn_string isMember;
  dyn_uint workLoadLevel, dpvssUser;                      
  dyn_bool dAutoHS, dackPermission;

  iError = 0; //init iError with no Error

  //get current Data from the Database
  dpGet("_CommCenterMessagingDevice.Number:_online.._value",               dnumber,
        "_CommCenterMessagingDevice.Identifier:_online.._value",           didentifier,
        "_CommCenterMessagingDevice.DeviceType:_online.._value",           ddeviceType,
        "_CommCenterMessagingDevice.User:_online.._value",                 dsUser,
        "_CommCenterMessagingDevice.Provider:_online.._value",             dsProvider);

  // check Index
//  if (dynlen(didentifier) < index || index < 1)
  if ( dynContains(didentifier, index) < 1)
    iError = -1;
  
  if (iError == 0)
  //no Error
  {
    // remove the device
    dynRemove(dnumber,index);
    dynRemove(didentifier,index);
    dynRemove(ddeviceType,index);
    dynRemove(dsUser,index);
    dynRemove(dsProvider,index);

   //and write it back to the Datapoint
    dpSet("_CommCenterMessagingDevice.Number:_original.._value",               dnumber,
          "_CommCenterMessagingDevice.Identifier:_original.._value",           didentifier,
          "_CommCenterMessagingDevice.DeviceType:_original.._value",           ddeviceType,
          "_CommCenterMessagingDevice.User:_original.._value",                 dsUser,
          "_CommCenterMessagingDevice.Provider:_original.._value",               dsProvider);
  }
}

//***fct***//
void ccDeleteShift(string shiftDP,   // DPName of the shift to be deleted
                   int    &iError)   // Error-Codes
//search the shiftDP and delete this Shift
//ReturnValues iError......0  OK!
//                        -1 ShiftDP not found
{
  iError = 0; //init iError with no Error

  if (dpExists(shiftDP))
  // if DP exists delete it
    dpDelete(shiftDP,"_CommCenterShift");
  else
  // else Error: ShiftDP not found
    iError = -1;
}

//***fct***//
void ccCreateOrEditShift(string      &shiftDP,   // DPName of the shift, if create the shiftDP has to be ""
                         langString  shiftName,  // Name of the Shift
                         int         domain,     // Shift belongs to this Domain
                         bool        daybound,   // if true, begin is a fiy day and a fix time
                         time        begin,      // Shiftstart
                         dyn_dyn_int days,       // timetable of the shift, includes the index of the Personneldatas
                                                 // 0...empty; -1...not defined!   column...15 min, line...days
                         // -------------personneldatas--------------
                         dyn_string  recipient,  // personnelNumber of recipients that are used in this shift
                         dyn_string  agency,     // personnelNumber of substituting recipients
                                                 // for the recipients with the same index
                         dyn_string  color,      // Color that is assigned to the recipient with the same index
                         // -------------personneldatas--------------
                         int         &iError)    // Error-Codes
//if the shiftDP exists change the shiftdatas, else create a new shift with these datas
//ReturnValues iError......0  OK!
//                        -1  ShiftDP not "" but does not exist
//                        -2  shiftName not defined
//                        -10 Domain not found!
//                        -11 Invalid index in dyn_dyn days
//                        -12 Invalid personnelNumber in dyn recipient
//                        -13 Invalid personnelNumber in dyn agency
{
  dyn_string domainNames, ds = shiftName;
  dyn_string pNr;
  int i, j;

  iError = 0; // init iError with no Error

  if (shiftDP != "" && !dpExists(shiftDP))
  {
    iError = -1;
    return;
  }
  
  for ( i = 1; i <= dynlen(ds); i++ )
  {
    if (ds[i] == "")
    {
      iError = -2;
      return;
    }
  }

  //Check validation of Domain
  domainNames = dpNames("*","_CommCenterDomains");
  if ( domain < 1 || domain > dynlen(domainNames))
  {
    iError = -10;
    return;
  }

  //check indizess in days
  for ( i = 1; i <= dynlen(days); i++)
    for ( j = 1; j <= dynlen(days[i]); j++)
      if (days[i][j] < -1 || days[i][j] > dynlen(recipient))
      {
        iError = -11;
        return;
      }

  //check personnel Number in recipient and in agency
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", pNr);
  for ( i = 1; i <= dynlen(recipient); i++)
  {
    if (dynContains(pNr,recipient[i]) < 1)
    {
      iError = -12;
      return;
    }
    if (agency[i] != "" && dynContains(pNr,agency[i]) < 1)
    //no agency is valid!!
    {
      iError = -13;
      return;
    }
  }


  if (iError == 0) //noError
  {
    dyn_string daysStr;

    if (shiftDP == "") //if "" then create
    {
      dyn_string eShifts; //existing Shifts
      string number;
    
      ccGetShiftDPs(eShifts);
      dynSortAsc(eShifts);                //sort minimum first, maximum last
      if (dynlen(eShifts) == 0)
        number = "00001";
      else
      {
        number = eShifts[dynlen(eShifts)];  // get maximum
        strreplace(number,"shift","");      //get only the diggits
        i = number;
        i++;                                //increase the number
        number = i;
        while (strlen(number) < 5)          //fill with leading zeros
          number = "0" + number;
      }

      shiftDP = "shift"+number;
      dpCreate(shiftDP,"_CommCenterShift"); //create shiftDP
    }

    for ( i = 1; i <= dynlen(days); i++)
    {
      daysStr[i] = days[i];             //convert dyn to a string
      strreplace(daysStr[i]," | ","|"); //trim the Blanks
    }
    //Write Datas back to Datapoint
    dpSetComment(shiftDP+".",shiftName);
    dpSet(shiftDP+".Days:_original.._value",                daysStr,
          shiftDP+".Daybound:_original.._value",            daybound,
          shiftDP+".Domain:_original.._value",              domain,
          shiftDP+".Begin:_original.._value",               begin,
          shiftDP+".Personnel.Recipient:_original.._value", recipient,
          shiftDP+".Personnel.Substitute:_original.._value",    agency,
          shiftDP+".Personnel.Color:_original.._value",     color);
  }
}

//***fct***//
void ccGetShift(string      shiftDP,     // DPName of the shift
                langString  &shiftName,  // Name of the Shift
                int         &domain,     // Shift belongs to this Domain
                bool        &daybound,   // if true, begin is a fiy day and a fix time
                time        &begin,      // Shiftstart
                dyn_dyn_int &days,       // timetable of the shift, includes the index of the Personneldatas
                                         // 0...empty; -1...not defined!   column...15 min, line...days
                // -------------personneldatas--------------
                dyn_string  &recipient,  // personnel Number of recipients that are used in this shift
                dyn_string  &agency,     // personnel Number of substituting recipients
                                         // for the recipients with the same index
                dyn_string  &color,      // Color that is assigned to the recipient with the same index
                // -------------personneldatas--------------
                int         &iError)     // Error-Codes
//if the shiftName exists change the shiftdatas, else create a new shift with these datas
//ReturnValues iError......0 OK!
//                        -1 ShiftDP not found
{
  iError = 0;  //init iError with no Error
  
  if (dpExists(shiftDP))
  {
    dyn_string daysStr;
    dyn_dyn_int retDays;
    int i;

    //get existing Datas
    shiftName = dpGetComment(shiftDP+".");
    dpGet(shiftDP+".Days:_online.._value",                daysStr,
          shiftDP+".Daybound:_online.._value",            daybound,
          shiftDP+".Domain:_online.._value",              domain,
          shiftDP+".Begin:_online.._value",               begin,
          shiftDP+".Personnel.Recipient:_online.._value", recipient,
          shiftDP+".Personnel.Substitute:_online.._value",    agency,
          shiftDP+".Personnel.Color:_online.._value",     color);
    for ( i = 1; i <= dynlen(daysStr); i++)
    //convert dyn into a dyn_dyn
      retDays[i] = strsplit(daysStr[i], "|");
    days = retDays;
  }
  else  //ShiftDP not found
    iError = -1;
}

//***fct***//
void ccGetShiftDPs(dyn_string &shiftDPs) //existing shifts
// this function returns the names of the existing shift DPs
{
  int i;

  shiftDPs = dpNames("*","_CommCenterShift");
  for ( i = 1; i <= dynlen(shiftDPs); i++)
    shiftDPs[i] = dpSubStr(shiftDPs[i],DPSUB_DP);
}

//***fct***//
void ccCreateOrEditShiftAggregation(string     &shiftAggregationDP,   //DPName of the shift set, if create the shift set DP has to be ""
                                    langString shiftAggregationName,  //Name of the shift set
                                    int        domain,                //shift set belongs to this domain
                                    dyn_string shiftAggregationParts, //DPs of shifts and other sets that are parts of this set
                                    dyn_int    minDuration,           //duration with format T|HH|MM
                                    time       begin,                 //begintime and day (if day() = 4 then no beginday)
                                    time       end,                   //endtime and day
                                    bool       blanks,                //are there blank time intervals in the aggregation
                                    int        &iError)               //Error-Codes
//if the shiftAggregationDP exists change the shiftaggregationdatas, else create a new shiftaggregation with these datas
//ReturnValues iError......0  OK!
//                        -1  ShiftAggregationDP not "" but does not exist
//                        -2  No ShiftAggregationName
//                        -10 Domain not found!
//                        -11 Invalid DP in ShiftAggregationParts
//                        -12 Invalid duration
{
  dyn_string domainNames, ds = shiftAggregationName;
  int i;

  iError = 0; // init iError with no Error

  if (shiftAggregationDP != "" && !dpExists(shiftAggregationDP))
    iError = -1;

  for ( i = 1; i <= dynlen(ds); i++ )
  {
    if (ds[i] == "")
      iError = -2;
  }
  
  //Check validation of Domain
  domainNames = dpNames("*","_CommCenterDomains");
  if ( domain < 1 || domain > dynlen(domainNames))
    iError = -10;
  
  //check validation of shiftAggregationParts
  for (i = 1; i <= dynlen(shiftAggregationParts); i++)
    if(!dpExists(shiftAggregationParts[i]))
      iError = -11;
  
  //check Duration
  if (minDuration[2] > 23 || minDuration[3] > 59)
    iError = -12;

  if (iError == 0) //noError
  {
    if (shiftAggregationDP == "") //if "" then create
    {
      dyn_string eShiftAggs; //existing ShiftsAggregations
      string number;
               
      ccGetShiftAggregationDPs(eShiftAggs);
      dynSortAsc(eShiftAggs);                //sort minimum first, maximum last
      if (dynlen(eShiftAggs) == 0)
        number = "00001";
      else
      {
        number = eShiftAggs[dynlen(eShiftAggs)];  // get maximum
        strreplace(number,"aggregation","");      // get only the diggits
        i = number;
        i++;                                      // increase the number
        number = i;
        while (strlen(number) < 5)                // fill with leading zeros
          number = "0" + number;
      }

      shiftAggregationDP = "aggregation"+number;
      dpCreate(shiftAggregationDP,"_CommCenterShiftAggregation"); //create shiftAggregationDP
    }
    
    //Write Datas back to Datapoint
    dpSetComment(shiftAggregationDP+".",shiftAggregationName);
    dpSet(shiftAggregationDP+".AggregationParts:_original.._value",    shiftAggregationParts,
          shiftAggregationDP+".MinDuration:_original.._value",         minDuration,
          shiftAggregationDP+".Begin:_original.._value",               begin,
          shiftAggregationDP+".End:_original.._value",                 end,
          shiftAggregationDP+".Blanks:_original.._value",              blanks,
          shiftAggregationDP+".Domain:_original.._value",              domain);
  }
}

//***fct***//
void ccGetShiftAggregation(string     shiftAggregationDP,     //DPName of the shift set
                           langString &shiftAggregationName,  //Name of the shift set
                           int        &domain,                //shift set belongs to this domain
                           dyn_string &shiftAggregationParts, //DPs of shifts and other sets that are parts of this set
                           dyn_int    &minDuration,           //duration with format T|HH|MM
                           time       &begin,                 //begintime and day (if day() = 4 then no beginday)
                           time       &end,                   //endtime and day
                           bool       &blanks,                //are there blank time intervals in the aggregation
                           int        &iError)                //Error-Codes
//get Shiftaggregation Datas
//ReturnValues iError......0  OK!
//                        -1  ShiftAggregationDP not "" but does not exist
{
  iError = 0;  //init iError with no Error
  
  if (dpExists(shiftAggregationDP))
  {
    //get existing Datas
    shiftAggregationName = dpGetComment(shiftAggregationDP+".");
    dpGet(shiftAggregationDP+".AggregationParts:_online.._value",    shiftAggregationParts,
          shiftAggregationDP+".MinDuration:_online.._value",         minDuration,
          shiftAggregationDP+".Begin:_online.._value",               begin,
          shiftAggregationDP+".End:_online.._value",                 end,
          shiftAggregationDP+".Blanks:_online.._value",              blanks,
          shiftAggregationDP+".Domain:_online.._value",              domain);
  }
  else  //shiftAggregationDP not found
    iError = -1;
}

//***fct***//
void ccGetShiftAggregationDPs(dyn_string &shiftAggregationDPs) //existing shifts sets
// this function returns the names of the existing shift set DPs
{
  int i;

  shiftAggregationDPs = dpNames("*","_CommCenterShiftAggregation");
  for ( i = 1; i <= dynlen(shiftAggregationDPs); i++)
    shiftAggregationDPs[i] = dpSubStr(shiftAggregationDPs[i],DPSUB_DP);
}

//***fct***//
void ccDeleteShiftAggregation(string shiftAggregationDP,   // DPName of the shift
                              int    &iError)              // Error-Codes
//search the shift set DP and delete this shift set
//ReturnValues iError......0  OK!
//                        -1 shift set DP not found
{
  iError = 0; //init iError with no Error

  if (dpExists(shiftAggregationDP))
  // if DP exists delete it
    dpDelete(shiftAggregationDP,"_CommCenterShiftAggregation");
  else
  // else Error: shift set DP not found
    iError = -1;
}

//***fct***//
void ccGetShiftAggregationCalculation(string      shDP,               //DPs of shifts and other sets that are parts of this set
                                      dyn_string  parts,
                                      dyn_int    &duration,           //duration with format T|HH|MM
                                      time       &begin,              //begintime and day (if day() = 4 then no beginday)
                                      time       &end,                //endtime and day
                                      bool       &blanks)             //is time between the parts or a blank?
{
  dyn_string     dsShifts;
  dyn_dyn_int    ddiDays, ddiSubs;
  dyn_dyn_string ddsShifts, ddsUsers;
  int            beginDay, iLen, i, j, iB, iE, d, h, m, iDayIndex;
  bool           dayBound, bStart = true;
  time           tCurrentTime;
  string         sUser;

  duration = makeDynInt(0,0,0);
  begin    = 0;
  end      = 0;
  blanks = false;

  ccGetAggregationShifts("", parts, dsShifts);
  ccGetAggregationDays_WIN( dsShifts, 
                            ddiDays,
                            ddsShifts,
                            ddsUsers,
                            ddiSubs,
                            sUser,
                            iDayIndex,
                            beginDay,
                            dayBound,
                            tCurrentTime );

  iLen = dynlen(ddiDays);
  if ( iLen < 1 )
  {
    return;
  }

  begin    = (dayBound)?makeTime(1970, 1, beginDay + 4):makeTime(1970, 1, 4);

  iB = 0; iE = 97;
  for ( i = 1; i <= iLen; i++ )
  {
    for ( j = 1; j <= 96; j++ )
    {
//      if ( !bStart && (dynlen(ddiDays[i]) > j || ddiDays[i][j] < 1) )
      if ( !bStart && dynlen(ddiDays[i]) >= j && ddiDays[i][j] < 1 )
      {
        blanks = true;
        break;
      }
      if ( bStart && ddiDays[i][j] < 1 )
      {
        begin += 15 * 60; iB = j;
      }
      if ( bStart && ddiDays[i][j] > 0 )
      {
        bStart = false;
      }
    }
    if ( blanks )
    {
      break;
    }
  }
  iB++;

  for ( i = 96; i > 0; i-- )
  {
    if ( dynlen(ddiDays[iLen]) < i )
    {
      continue;
    }
    else
    if ( ddiDays[iLen][i] < 1 )
    {
      iE--;
    }
    else
      break;
  }
  if(iLen == 7)//IM99989
    i = ( iLen * 96 - iB - (96 - iE) ) * 15 * 60 - 1;
  else
    i = ( iLen * 96 - iB - (96 - iE) ) * 15 * 60;

  end = begin + i;// + 15*60;
  d = i/86400; i -= d*86400;
  h = i/3600;  i -= h*3600;
  m = i/60;
  duration = makeDynInt(d,h,m);
}

//***fct***//
void ccGetPersonnelIndex(string domain, //for which domain
                         time   tIndex, //for calculating the index
                         int    &ret)   //index of personnel
//returnValues ret: ... if -1 then OnCallServicePlan not defined for this time
{
  int line, column, i;
  dyn_dyn_int days;
  dyn_string daysStr;
  string OCSPDP; //OnCallServicePlan DP
  
  domain = dpSubStr(domain,DPSUB_DP);
  strreplace(domain,"Domain","");
  OCSPDP = year(tIndex) + "_" + domain; //DPName = YEAR_DomainNr
  line = 1; 
  column = hour(tIndex)*4 + minute(tIndex)/15 + 1; //Calculate column of days
  if(dpExists(OCSPDP)) // if not Error (because dynlen days = 0!!!!)
    dpGet(OCSPDP+".Days:_online.._value", daysStr);
  for ( i = 1; i <= dynlen(daysStr); i++)
  //convert dyn into a dyn_dyn
    days[i] = strsplit(daysStr[i], "|");

  if (line   < 1 || dynlen(days)       < line  || 
      column < 1 || dynlen(days[line]) < column  ) //if index out of range
    ret = -1;
  else
    ret = days[line][column]; //return index of Personnel Block
}

//***fct***//
dyn_dyn_int ccAppendDays(dyn_dyn_int days1,     // begin of the new dyn
                       dyn_dyn_int days2,       // end of the new dyn
                       int         blankdays)   // copies n lines (filled with index 0) between days1 and days2; if -1 then days2 = unbound
//returnvalue: new days dyn
{
  int i, j;
  if (dynlen(days2) > 0 && dynlen(days2[dynlen(days2)]) > 0)
  {
    for (i=1; days2[1][i] == -1; i++) // seek first valid index in days2
    ;
    if (dynlen(days1) != 0)
    {
      if (blankdays == -1)
        if (i < dynlen(days1[dynlen(days1)])) //if end of day1 later than begin of days2 then move to next day
          blankdays++;
      else
        if (i < dynlen(days1[dynlen(days1)])) //if end of day1 later than begin of days2 then move to next day
          blankdays+= (blankdays!=0)?0:7;
      blankdays+=dynlen(days1)+1; //move to begin of day2

      if (dynlen(days1[dynlen(days1)]) < 96)
        days1[dynlen(days1)][96] = 0;
      for (j = dynlen(days1); j < blankdays; j++)
        days1[j+1][96] = 0;
    }
    else
      blankdays = 1;
    for (i = ((dynlen(days1) == 0)?1:i); i <= dynlen(days2[1]); i++) //copy first line of days2 and begin with the first valid index
      days1[blankdays][i] = days2[1][i];
    dynRemove(days2,1); //line is already copied -> delete it
    dynAppend(days1,days2); //append rest of days2 to days1
  }
  return days1;
}

///////////////////////////////////////////////////////////////////////////////////////
// recursive function to find all shifts in a shift set
// if shift set includes another shift set this will also be searched via recursivity
//***fct***//
ccGetAggregationShifts(string shiftSetDP,     // shift set DP
                       dyn_string dsParts,    // shifts/shift sets of this set
                       dyn_string &dsShifts)  // shift DPs
{
  int        i, j;
  string     dp;
  dyn_string ds, dss, tmpShifts;

  dynClear(dsShifts);
  if ( shiftSetDP != "" && dpExists(shiftSetDP) )
    dpGet(shiftSetDP+".AggregationParts:_online.._value", ds);
  else
    ds = dsParts;

  for ( i = 1; i <= dynlen(ds); i++ )
  {
    if ( dpTypeName(ds[i]) == "_CommCenterShiftAggregation" )
    {
      // call with tmpShifts because otherwise we delete the calculated ShiftAggregation
      ccGetAggregationShifts(ds[i], makeDynString(), tmpShifts);
      dynAppend(dsShifts, tmpShifts);
/*
      for ( j = 1; j <= dynlen(dss); j++ )
      {
        if ( dpTypeName(dss[j]) == "_CommCenterShift" )
          dynAppend(dsShifts, dss[j]);
      }
*/
    }
    else
    {
      dynAppend(dsShifts, ds[i]);
    }
  }
//  Debug("newParts: "+dsShifts);
}

///////////////////////////////////////////////////////////////////////////////////////
// the big function to get the following &data of a shift set
// dyn_dyn return values are indexed by [day][time] (times are 15-minutes intervals)
//***fct***//
void ccGetAggregationDays_WIN(dyn_string      parts,        // parts of the shift set
                              dyn_dyn_int    &ddiDays,      // table with shift internal user indices
                              dyn_dyn_string &ddsShifts,    // table with shiftDPs
                              dyn_dyn_string &ddsUsers,     // table with user IDs
                              dyn_dyn_int    &ddiSubs,      // indices of substituting persons in shift if any
                              string         &sUser,        // user[+substitute] of tCurrentTime
                              int            &iDayIndex,    // index of the day of tCurrentTime
                              int            &beginDay,     // start day of the shift set
                              bool           &dayBound,     // shift set begins on a weekday
                              time            tCurrentTime) // time to read data for
{

  int i, j, k;
  dyn_string dsPersonalNr;
  dyn_bool dbFailure;
  int iDomainNr;
  time tShiftBegin;
  dyn_string dsRecipient, dsSubstitute;
  dyn_dyn_int ddiShiftDays;
  time tTopLevelBegin;
  dyn_time dtOverParaDate;
  dyn_string dsOverParaIntervals;
  int currentAggregationDay=0, insertEmptyDays=0;
  int lastShiftEndDay=0, lastShiftEndTime=0;
  int firstShiftBeginDay, firstShiftBeginTime;
  string sFallback, sSubstitute;
  int iSubstitute;
  bool DEBUG1 = false, DEBUG2 = false, DEBUG3 = false;
  int actShiftBeginDay, actShiftBeginTime;
  int lastShiftLength=0;

  
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dsPersonalNr,
        "_CommCenterRecipients.Failure:_online.._value", dbFailure);  
  
  for ( i = 1; i <= dynlen(parts); i++ )  //for every shift
  {

    if ( i > 1 )
    {
      lastShiftEndDay = weekDay(tShiftBegin);
      lastShiftEndTime = (hour(tShiftBegin) * 60) + minute(tShiftBegin);
      lastShiftLength = dynlen(ddiShiftDays);
    }
    
    // reading Data for shift
    ccReadShiftData(parts[i], iDomainNr, tShiftBegin, dayBound, dsRecipient, dsSubstitute, ddiShiftDays, tTopLevelBegin, dtOverParaDate, dsOverParaIntervals);

    if ( i == 1 )  //if it's the first shift notice begin-day and time
    {
      firstShiftBeginDay = weekDay(tShiftBegin);
      firstShiftBeginTime = (hour(tShiftBegin) * 60) + minute(tShiftBegin);      
    }
    for ( j = 1; j <= dynlen(ddiShiftDays); j++ )  //for every day of the shift
    {
      insertEmptyDays = 0;
      if (dayBound)
      {
        if ( j == 1 && i != 1 )  //check the begin of shift and insert empty day if needed
        {
          actShiftBeginDay = weekDay (tShiftBegin);
          actShiftBeginTime = (hour(tShiftBegin) * 60) + minute(tShiftBegin);
          
          if ( actShiftBeginDay == lastShiftEndDay && actShiftBeginTime < lastShiftEndTime ) // if overlapping on the same day
          {
            insertEmptyDays = 7;                // insert an empty week
          }
          else if ( actShiftBeginDay > lastShiftEndDay )  // if there is a gap in begin-days
          {
            insertEmptyDays = ( actShiftBeginDay - lastShiftEndDay );  //fill up the missing days to a whole week
          } 
          else if ( actShiftBeginDay < lastShiftEndDay )  // if there is a gap in begin-days
          {
            insertEmptyDays = ( 7 - lastShiftEndDay ) + actShiftBeginDay;  //fill up the missing days to a whole week
          }
          else if (actShiftBeginDay == lastShiftEndDay && lastShiftLength == 7)  // if it isn't overlapping on same day
          {
            insertEmptyDays = 1;
          }
          // else -> insert no empty days - to merge the last day of the shift before and the first day of act shift
        }
        else  //insert an empty day for the current day - to initialize with empty-values
        {
          insertEmptyDays = 1;
        }
      }
      else  //insert an empty day for the current day - to initialize with empty-values
      {
        insertEmptyDays = 1;
      }
      // fill in empty days
      ccInsertEmptyDays(currentAggregationDay+1, insertEmptyDays, ddiDays, ddsShifts, ddsUsers, ddiSubs);

      currentAggregationDay = dynlen(ddiDays);  

      for ( k = 1; k <= dynlen(ddiShiftDays[j]); k++ )  //fill the act. day with data
      {
        if ( ddiShiftDays[j][k] > 0 )
        {
          ddiDays[currentAggregationDay][k] = ddiShiftDays[j][k];
          ddsShifts[currentAggregationDay][k] = parts[i];
          ccGetSubstitute (dsRecipient[ddiShiftDays[j][k]], ddiShiftDays[j][k], dsSubstitute, sFallback, dsPersonalNr, dbFailure, sSubstitute, iSubstitute);
          ddsUsers[currentAggregationDay][k] = dsRecipient[ddiShiftDays[j][k]] + "|" + sSubstitute;
          ddiSubs[currentAggregationDay][k] = iSubstitute;
        }
      }
    }
  }
  
  //notice end-day and time of act. shift
  lastShiftEndDay = weekDay(tShiftBegin);
  lastShiftEndTime = (hour(tShiftBegin) * 60) + minute(tShiftBegin);
  
  // if called with data -> calculate the current week
  if ( tCurrentTime > 0 && dynlen(ddiDays)>0 )  
  {
    int iUserIndex;
    
    // insert empty days to get whole weeks (only in day-bound mode)
    if (dayBound)
    {
      if ( firstShiftBeginDay == lastShiftEndDay && firstShiftBeginTime < lastShiftEndTime )
        insertEmptyDays = 6;                // insert an empty week
      else if ( firstShiftBeginDay > lastShiftEndDay )
        insertEmptyDays = ( firstShiftBeginDay - lastShiftEndDay ) - 1;
      else if ( firstShiftBeginDay < lastShiftEndDay )
        insertEmptyDays = ( 6 - lastShiftEndDay ) + firstShiftBeginDay;
      else
        insertEmptyDays = 0;
    // else -> insert no empty days       

      ccInsertEmptyDays(currentAggregationDay+1, insertEmptyDays, ddiDays, ddsShifts, ddsUsers, ddiSubs);
      currentAggregationDay = dynlen(ddiDays);  //increase the currentDay
    }
    
    j = dynlen(ddiDays)%7;
    // if not dayBound -> fill up days to get whole weeks
    if ( j != 0 && !dayBound )
    {
      for ( i = 1; i <= 7 - j; i++ )
      {
        ddiDays[dynlen(ddiDays)+1] = ddiDays[i];
        ddsShifts[dynlen(ddsShifts)+1] = ddsShifts[i];
        ddsUsers[dynlen(ddsUsers)+1] = ddsUsers[i];
        ddiSubs[dynlen(ddiSubs)+1] = ddiSubs[i];
      }
    }
    
//searching for first ShiftBeginDay from topLevelBegin
    int shiftStartDiffDays=0;
    
    // looking for first shift-day from toplevelbegin-day
    
    //calulate the diffence in starting weekday
    if ( dayBound )
      shiftStartDiffDays = firstShiftBeginDay - weekDay(tTopLevelBegin);
    if (DEBUG1)  DebugN("TopLevelStart: "+ weekDay(tTopLevelBegin),"ShiftStart: "+firstShiftBeginDay, "startShiftDiff in weekDays: "+shiftStartDiffDays);        
    
    if ( shiftStartDiffDays < 0 )
      shiftStartDiffDays += 7;

    //calculate the seconds from 1.1.1970 to the called day
    int currentDay = cc_getUTCTimeSeconds(year(tCurrentTime), month(tCurrentTime), day(tCurrentTime));//period (tmpCurrentTime) + daylightsaving(tmpCurrentTime)*3600;  

    //calculate the seconds from 1.1.1970 to the toplevel-begin-day
    int calculatedTopLevelBeginDay = ( shiftStartDiffDays * 86400 ) + cc_getUTCTimeSeconds(year(tTopLevelBegin), month(tTopLevelBegin), day(tTopLevelBegin)) ;//+ period(tTopLevelBegin) + 43200 + daylightsaving(tTopLevelBegin)*3600;  //at 12:00 <- to avoid light-saving poblems

    if (DEBUG2)  DebugN("##########",shiftStartDiffDays, cc_getUTCTimeSeconds(year(tTopLevelBegin), month(tTopLevelBegin), day(tTopLevelBegin)));
            
    if (DEBUG2)  DebugN("calculatedTopLevelBeginDay: "+calculatedTopLevelBeginDay, tTopLevelBegin, period(tTopLevelBegin) + 43200, daylightsaving(tTopLevelBegin)*3600);
    
    if (DEBUG1)  DebugN("calculatedTopLevelBeginDay: "+calculatedTopLevelBeginDay, "currentDay: "+currentDay);
    
    // Calculating the days since TopLevel-Begin
    int iDaysFromTopLevelBegin = (( currentDay - calculatedTopLevelBeginDay ) / 86400);// - ((( currentDay% 86400 - calculatedTopLevelBeginDay % 86400) / 3600) );  
    if (DEBUG1)  DebugN("iDaysFromTopLevelBegin: "+iDaysFromTopLevelBegin);    

    //calculate iDayIndex (=the day in the shift-Aggregation)
    iDayIndex = iDaysFromTopLevelBegin % (dynlen(ddiDays) - (dynlen(ddiDays)%7) );//<- -1 if week has 8 days
    if (DEBUG1)  DebugN("iDayIndex: "+iDayIndex);
    
    // dayIndex must be possitiv
    if (iDayIndex<0)  
    {
      iDayIndex+=dynlen(ddiDays);
      if (DEBUG1)  DebugN("iDayIndex changed to: "+iDayIndex);
    }

    beginDay = firstShiftBeginDay;
    
    int shiftDisplayStartDay = currentDay - (iDayIndex * 86400);
    
    if ( parts[1] == parts[dynlen(parts)] && dayBound )
      cc_mergeFirstAndLastDay (ddiDays, ddsShifts, ddsUsers, ddiSubs);

    // delete data that is before TopLevelBegin
    if ( shiftDisplayStartDay < calculatedTopLevelBeginDay ) 
    {
      ccInsertEmptyDays(1, dynlen(ddiDays), ddiDays, ddsShifts, ddsUsers, ddiSubs);
      currentAggregationDay = dynlen(ddiDays);
    }

    //  get current User
    iUserIndex = (hour(tCurrentTime)/*-1*/)*4 + minute(tCurrentTime)/15 + 1;
    if ( dynlen(ddiDays) >= iDayIndex+1 )
    {
      if(DEBUG1) DebugN("users:", ddiDays[iDayIndex+1]);
      sUser = ddsUsers[iDayIndex+1][iUserIndex] + "|" + ddiSubs[iDayIndex+1][iUserIndex]; //!!! from + |... added
    }
    else
    {
      sUser = "<>|<>";    
    }
    
//  get overPara if there is any
    if ( tCurrentTime >= getCurrentTime() -500 ) // better would be to check, if it's the same day
    {
      time tD = makeTime(year(tCurrentTime), month(tCurrentTime), day(tCurrentTime));
      int  iPos = dynContains(dtOverParaDate, tD), iIdx, iF, iT;
      
      if ( iPos > 0 )
      {
        iIdx = hour(tCurrentTime)*60 + minute(tCurrentTime);
        dyn_string ds1 = strsplit(dsOverParaIntervals[iPos], "#");
        
        for ( i = 1; i <= dynlen(ds1); i++ )
        {
          dyn_string ds2 = strsplit(ds1[i], "|");
          string overParaSubstitutePerson = dynlen(ds2)>=5 && ds2[5]!="" ? ds2[5] : "<>"; //use subsitutePerson if there is any
          iF = ds2[2]; iT = ds2[3];
          if ( iIdx >= iF && iIdx < iT )
          {
            sUser = ds2[4] + "|"+overParaSubstitutePerson+"|0"; //!!! |0 added newly 
            break;
          }
        }
      }          
    }
  }
  else
  {
//    iDayIndex = firstShiftBeginDay;  
    if (dayBound)
     beginDay = firstShiftBeginDay;  
    else
      beginDay = 1;
  }
  if (DEBUG3)DebugN("CurrentUsers:", sUser);
}

void ccInsertEmptyDays(int currentDay, int number, dyn_dyn_int &ddiDays, dyn_dyn_string &ddsShifts, dyn_dyn_string &ddsUsers, dyn_dyn_int &ddiSubs)
{
  dyn_int diEmpty;
  dyn_string dsEmpty1, dsEmpty2;
  for ( int i = 1; i <= 96; i++ )
  {
    diEmpty[i] = 0;
    dsEmpty1[i] = "<>";
    dsEmpty2[i] = "<>|<>";
  }
  for ( int i = 0; i < number; i++ )
  {
    ddiDays[currentDay+i] = diEmpty;
    ddsShifts[currentDay+i] = dsEmpty1;
    ddsUsers[currentDay+i] = dsEmpty2;
    ddiSubs[currentDay+i] = diEmpty;
  }
}

void ccReadShiftData(string part, int &iDomainNr, time &tShiftBegin, bool &bDayBound, dyn_string &dsRecipient, 
              dyn_string &dsSubstitute, dyn_dyn_int &ddiShiftDays, time &tTopLevelBegin, dyn_time &dtOverParaDate, 
              dyn_string &dsOverParaIntervals)
{
  dyn_string dsDays;
  dpGet(part+".Domain:_online.._value", iDomainNr,
        part+".Begin:_online.._value", tShiftBegin,
        part+".Daybound:_online.._value", bDayBound,
        part+".Personnel.Recipient:_online.._value", dsRecipient,
        part+".Personnel.Substitute:_online.._value", dsSubstitute,
        part+".Days:_online.._value", dsDays); 
  dpGet("Domain" + iDomainNr + ".TopLevelShiftSetStartDate:_online.._value", tTopLevelBegin,
        "Domain" + iDomainNr + ".OverPara.Date:_online.._value", dtOverParaDate,
        "Domain" + iDomainNr + ".OverPara.Intervals:_online.._value", dsOverParaIntervals);
  for ( int j = 1; j <= dynlen(dsDays); j++ )
    ddiShiftDays[j] = strsplit(dsDays[j], "|");
  
  if ( bDayBound ) // fill up to whole weeks if dayBound
  {
    if ( dynlen(dsDays)%7 != 0 && minute(tShiftBegin) == 0 && hour(tShiftBegin) == 0 )
    {
      dyn_int emptyDay;
      emptyDay[96] = 0;

      for ( int i = 1; i <= 7 - (dynlen(dsDays)%7); i++ )
      {
        ddiShiftDays[dynlen(dsDays) + i] = emptyDay;
      }
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// searches the substituting for sUser
//   sSubs == substituteID (defined in shift) if any, else "<>"
//   iSubs == 0 -> current user is sUser
//   iSubs == 1 -> user failured, current user is sSubs
//   iSubs == 2 -> user failured, use fallback list
//***fct***//
ccGetSubstitute(string     sUser,      // userID
                int        iUser,      // user index in shift
                dyn_string dsSubs,     // substitutes
                string     sFallback,  // fallback person (not used)
                dyn_string dsNr,       // user IDs of the shift
                dyn_bool   dbF,        // users' failure flag
                string     &sSubs,     // substitute
                int        &iSubs)     // substitution flag, see above
{
//  dyn_string dsNr;
//  dyn_bool   dbF;
  int        iPos;

  sSubs = "<>";
  iSubs = 0;
//  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dsNr,
//        "_CommCenterRecipients.Failure:_online.._value", dbF);

  iPos = dynContains(dsNr, sUser);
  if ( iPos > 0 )//&& dbF[iPos] )
  {
    // user fails
    if ( dbF[iPos] )
    {
      iSubs = 1;
    }

    // 
    if ( dsSubs[iUser] != "" )
    {
      sSubs = dsSubs[iUser];
      iPos = dynContains(dsNr, sSubs);
      if ( iSubs > 0 && (iPos < 1 || dbF[iPos]) )
      {
        iSubs = 2;
      }
    }
    else
    {
      if ( iSubs > 0 ) iSubs = 2;
    }
  }
}


//***fct***//
void ccUsedInAggs(string     DP,         //DP of shift or set to search in set
                  dyn_string &foundAggs) //shift set DPs in which the DP is found
{
  dyn_string allAggs, parts;
  int i;

  dynClear(foundAggs); //dyn has to be empty
  ccGetShiftAggregationDPs(allAggs); 
  for ( i = 1; i <= dynlen(allAggs); i++)
  {
    dpGet(allAggs[i]+".AggregationParts:_online.._value", parts);
    if (dynContains(parts, dpSubStr(DP,DPSUB_SYS_DP)) > 0) //if the DP is an element of the Parts
      dynAppend(foundAggs,allAggs[i]); 
  }
}

//***fct***//
ccAggTopLevel(string DP,  // shift set DP
             int &isTop)  // is this shift set a top level shift set of any domain?
{
  int        i;
  string     sTop;
  dyn_string dps = dpNames("*", "_CommCenterDomains");
  
  isTop = 0;
  for ( i = 1; i <= dynlen(dps); i++ )
  {
    dpGet("Domain" + i + ".TopLevelShiftSet:_online.._value", sTop);
    if ( sTop == DP )
    {
      isTop = i;
      break;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////
// checking if all user of a calling list do belong to the domain
//***fct***//
ccCheckIfAllUsersInDomain(string sCallingListDp, int iDomain, bool &bOk)
{
  int        i, iPos;
  dyn_int    di;
  dyn_string dsMembers, dsUsers, allPNrs, ds;
  
  bOk = true;
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", allPNrs,
        "_CommCenterRecipients.IsMember:_online.._value", dsMembers,
        sCallingListDp + ".Recipients:_online.._value", dsUsers);
  for ( i = 1; i <= dynlen(dsUsers); i++ )
  {
    iPos = dynContains(allPNrs, dsUsers[i]);
    if ( iPos < 1 )
    {
      bOk = false;
      break;
    }
    ds = strsplit(dsMembers[iPos], "|");
    di = ds;
    if ( dynContains(di, iDomain) < 1 )
    {
      bOk = false;
      break;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////
// checking if a user is used
//***fct***//
void ccRecipientUsed(string     PNr,          //userID to search
                     dyn_string &foundShifts, //shifts that use this recipient
                     dyn_string &foundSPlans) //OnCallServicePlans that use this recipient (check begin with currentTime)
{
  int i, j, k, column;
  dyn_string shifts, plans, recipients, agencies, allPNrs;
  dyn_string isMember;
  dyn_int sPlanDP;
  dyn_dyn_string days;
  time now = getCurrentTime();
  
  column = hour(now)*4 + minute(now)/15 + 1; //calculate index of ServicePlan
  
  dynClear(foundShifts); //dyn has to be empty
  dynClear(foundSPlans); //dyn has to be empty

  ccGetShiftDPs(shifts);
  plans = dpNames("*","_CommCenterOnCallServicePlan");
  
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", allPNrs,
        "_CommCenterRecipients.IsMember:_online.._value",        isMember);
  if (dynContains(allPNrs,PNr) > 0) //if PNr exists
  {
    isMember = strsplit(isMember[dynContains(allPNrs,PNr)],"|");     //get Domains of this recipient
  
    for ( i = 1; i <= dynlen(shifts); i++)
    {
      dpGet(shifts[i]+".Personnel.Recipient:_online.._value", recipients,
            shifts[i]+".Personnel.Substitute:_online.._value",    agencies);
      if (dynContains(recipients, PNr) > 0 || //if recipient is in this shift
          dynContains(agencies  , PNr) > 0)
        dynAppend(foundShifts,shifts[i]);
    }
  
    for ( i = 1; i <= dynlen(plans); i++)
    {
      sPlanDP = strsplit(dpSubStr(plans[i],DPSUB_DP),"_"); //get DomainNr of ServicePlan
      if ( dynContains(isMember,sPlanDP[2]) > 0 ) //only if the recipient is member of this domain
      {
        dpGet(plans[i]+".Personnel.Recipient:_online.._value", recipients,
              plans[i]+".Personnel.Substitute:_online.._value",    agencies);
        if (dynContains(recipients, PNr) > 0 || //if the recipient is in this ServicePlan
            dynContains(agencies  , PNr) > 0)
        {
          dpGet(plans[i]+".Days:_online.._value", days);
          for (j = yearDay(now); j <= dynlen(days); j++)  //look from now to the end of the Serviceplan
            for ( k = (j==yearDay(now)?column:1); k <= dynlen(days[j]); k++)
              if (recipients[days[j][k]] == PNr || //if he is devided in this Serviceplan
                  agencies[days[j][k]]   == PNr )
                  dynAppend(foundSPlans,plans[i]);
        }
      }
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// converts device type index into device type name
//***fct***//***pv***//
ccGetDeviceType(int iType,      // device type index
                string &sType)  // device type name
{
  int     iPos;
  dyn_int diIndex;
  dyn_string dsName;
  
  dpGet("_CommCenterDeviceType.Index:_online.._value", diIndex,
        "_CommCenterDeviceType.Name:_online.._value", dsName);

  if ( (iPos = dynContains(diIndex, iType)) )
    sType = dsName[iPos];
  else
    sType = "";
}

///////////////////////////////////////////////////////////////////////////////////////
// converts userID into user name
//***fct***//
ccGetUserName(string sNumber, // userID
              string &sUser)  // user name
{
  int iPos;
  dyn_string dsName, dsIndex;

  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dsIndex,
        "_CommCenterRecipients.Name:_online.._value", dsName);

  if ( (iPos = dynContains(dsIndex, sNumber)) )
    sUser = dsName[iPos];
  else
    sUser = "";
}

///////////////////////////////////////////////////////////////////////////////////////
// checks if device type is used for any device
//***fct***//
ccIsDeviceTypeUsed(int     index,   // device type index
                   bool   &bUsed,   // is used?
                   string &sWhere,  // in a device
                   string &sWhich)  // in which device
{
  int        iPos;
  dyn_int    diType;
  dyn_string dsName;
  
  sWhere = getCatStr("cc","device");

  bUsed = false;
  dpGet("_CommCenterMessagingDevice.DeviceType:_online.._value", diType,
        "_CommCenterMessagingDevice.Identifier:_online.._value", dsName);

  bUsed = ( (iPos=dynContains(diType, index)));
  sWhich = (bUsed)?dsName[iPos]:"";
}

///////////////////////////////////////////////////////////////////////////////////////
// checks if a user is used in any shift
//***fct***//
ccIsUserUsedInShifts(string   sPN,       // userID
                     dyn_bool dbDomains, // domainDPs
                     bool    &bUsed,     // is user used?
                     string  &sWhere,    // in a shift
                     string  &sWhich,    // in which shift
                     string  &sDomain)   // in which domain
{
  int        i, iPos, iDomain;
  dyn_string ds, ds2,
             dsD = dpNames("*", "_CommCenterDomains"),
             dsS = dpNames("*", "_CommCenterShift");
  
  bUsed = false;
  sDomain = "";

  for ( i = 1; i <= dynlen(dsS); i++ )
  {
    dpGet(dsS[i] + ".Domain:_online.._value", iDomain,
          dsS[i] + ".Personnel.Recipient:_online.._value", ds,
          dsS[i] + ".Personnel.Substitute:_online.._value", ds2);
    if ( iDomain < 1 || dbDomains[iDomain] ) continue;
    
    if ( (iPos=dynContains(ds, sPN)) || (iPos=dynContains(ds2, sPN)) )
    {
      bUsed = true;
      sWhere = getCatStr("cc","shift");
      sWhich = dpGetComment(dsS[i] + ".");
      sDomain = dpGetComment(dsD[iDomain] + ".");
      return;
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// checks if a user is used in any shift, as fallback in any domain, in any calling list
//***fct***//
ccIsUserUsed(string  sPN,    // userID
             bool   &bUsed,  // is used?
             string &sWhere, // in shift/domain/calling list
             string &sWhich) // in which shift/domain/calling list
{
  int        i, iPos;
  string     s;
  langString ls;
  dyn_string dsD = dpNames("*", "_CommCenterDomains"),
             dsC = dpNames("*", "_CommCenterCallingList"), dsU, ds, ds2,
             dsS = dpNames("*", "_CommCenterShift"),
             dsName;
  
  bUsed = false;

  for ( i = 1; i <= dynlen(dsS); i++ )
  {
    dpGet(dsS[i] + ".Personnel.Recipient:_online.._value", ds,
          dsS[i] + ".Personnel.Substitute:_online.._value", ds2);
    if ( (iPos=dynContains(ds, sPN)) || (iPos=dynContains(ds2, sPN)) )
    {
      bUsed = true;
      sWhere = getCatStr("cc","shift");
      sWhich = dpGetComment(dsS[i] + ".");
      return;
    }
  }

  for ( i = 1; i <= dynlen(dsC); i++ )
  {
    dpGet(dsC[i] + ".Recipients:_online.._value", ds,
          dsC[i] + ".Name:_online.._value", dsName);
    if ( (iPos=dynContains(ds, sPN)) )
    {
      bUsed = true;
      sWhere = getCatStr("cc","callingList");
      sWhich = dsName[iPos];
      return;
    }
  }
/*  
  dpGet("_CommCenterMessagingDevice.User:_online.._value", dsU,
        "_CommCenterMessagingDevice.Identifier:_online.._value", dsName);
  if ( (iPos=dynContains(dsU, sPN)) )
  {
    sWhere = getCatStr("cc","device");
    sWhich = dsName[iPos];
    bUsed = true;
    return;
  }
*/
}

///////////////////////////////////////////////////////////////////////////////////////
// checks if a device is used by any user
//***fct***//
ccIsDeviceUsed(string  sDev,   // deviceID
               bool   &bUsed,  // is used?
               string &sWhere, // by a user
               string &sWhich) // by which user
{
  int        i, iPos;
  string     s;
  dyn_string dsCL, ds, dsName, dsCyclicDevice, dsID;
  
  bUsed = false;
  dpGet("_CommCenterRecipients.CallingList:_online.._value", dsCL,
        "_CommCenterRecipients.Name:_online.._value", dsName,
        "_CommCenterCyclicDataSet.ID:_online.._value", dsID,
        "_CommCenterCyclicDataSet.deviceID:_online.._value", dsCyclicDevice);
  
  for ( i = 1; i <= dynlen(dsCL); i++ )
  {
    ds = strsplit(dsCL[i], "|");
    if ( dynContains(ds, sDev) )
    {
      bUsed = true;
      sWhere = getCatStr("cc","user");
      sWhich = dsName[i];
      return;
    }
  }
  for ( i = 1; i <= dynlen(dsCyclicDevice); i++ )
  {
    ds = strsplit(dsCyclicDevice[i], "|");
    if ( dynContains(ds, sDev) )
    {
      bUsed = true;
      sWhere = getCatStr("cc","cyclicDataset");
      sWhich = dsID[i];
      return;
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// user doesn't use any devices in the future (because the user has been deleted)
//***fct***//
ccRemoveUserFromDevice( string sUser) // userID
{
  int        i, iPos;
  dyn_string dsUser, ds;
  
  dpGet("_CommCenterMessagingDevice.User:_online.._value", dsUser);
  for ( i = 1; i <= dynlen(dsUser); i++ )
  {
    ds = strsplit(dsUser[i], "|");
    if ( (iPos=dynContains(ds, sUser)) > 0 )
      dynRemove(ds, iPos);
    dsUser[i] = ds;
    strreplace(dsUser[i], " | ", "|");
  }
  dpSet("_CommCenterMessagingDevice.User:_original.._value", dsUser);
}

///////////////////////////////////////////////////////////////////////////////////////
// check of any changes in the domain management panel
//***fct***//
ccCheckDomainChanges(int &iOk) // true == save changes
{
  dyn_float  df;
  dyn_string ds;

  if ( gAllData != gAllDataOld )
  {
    ChildPanelOnCentralModalReturn("vision/MessageInfo3", getCatStr("para", "warning"),
      makeDynString(getCatStr("ac", "notsaved"),
                    getCatStr("para", "yes"),
                    getCatStr("para", "no"),
                    getCatStr("para", "cancel")), df, ds);
    iOk = df[1];

    if ( iOk == 1 )
    {
      ccSaveDomains();
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// saving domain settings in the domain management panel
//***fct***//
ccSaveDomains()
{
  int    i, j;
  string s;
  langString ls;
  dyn_string ds;// = 

  if ( gAllData == gAllDataOld )
    return;

  for ( i = 1; i <= dynlen(gAllData); i++ )
  {
    if ( gAllData[i] == gAllDataOld[i] ) continue;
    
    dpSetComment(gAllData[i][1] + ".", gAllData[i][2]);
    s = (dynlen(gAllData[i][6])>0)?gAllData[i][6][1]:"";
    dpSet(gAllData[i][1] + ".Status:_original.._value", gAllData[i][4],
          gAllData[i][1] + ".OrigStatus:_original.._value", gAllData[i][4],
          gAllData[i][1] + ".FallBackPerson:_original.._value", gAllData[i][5],
          gAllData[i][1] + ".used:_original.._value", gAllData[i][3],
          gAllData[i][1] + ".DataSets:_original.._value", gAllData[i][6],
          gAllData[i][1] + ".CallingList:_original.._value", gAllData[i][8],
          gAllData[i][1] + ".ActiveCallingList:_original.._value", gAllData[i][10],
          gAllData[i][1] + ".TopLevelShiftSet:_original.._value", gAllData[i][11],
          gAllData[i][1] + ".TopLevelShiftSetStartDate:_original.._value", gAllData[i][12]);
    if ( s != "" )
    {
      ds = gAllData[i][2];
      for ( j = 1; j <= dynlen(ds); j++ )
      {
        ds[j] = "cc_" + ds[j];
      }
      ls = ds;
      dpSetComment(s + ".", ls);
    }
    gAllDataOld[i] = gAllData[i];
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// reads user settings from the user management panel
//***fct***//
dyn_anytype ccGetUserDataFromPanel()
{
  int         i, j = 0;
  bool        b;
  dyn_string  ds;
  dyn_anytype da;
  
  dynClear(da);
  j++;
  da[j] = txtPersonnelNumber.text;
  for ( i = 1; i <= 8; i++ )
  {
    j++;
    getValue("chkIsMember" + i, "state", 0, b);
    da[j] = b;
  }
  j++;
  da[j] = chbFallOut.state(0);
  for ( i = 0; i < tblCallingList.lineCount; i++ )
  {
    ds = tblCallingList.getLineN(i);
    j++;
    da[j] = ds;
  }
  return (da);
}

///////////////////////////////////////////////////////////////////////////////////////
// check of any changes in the user management panel
//***fct***//
ccCheckUserChanges(int &iOk)
{
  dyn_float  df;
  dyn_string ds;

  gdaNewUserData = ccGetUserDataFromPanel();
  if ( gdaNewUserData != gdaOldUserData )
  {
    ChildPanelOnCentralModalReturn("vision/MessageInfo3", getCatStr("para", "warning"),
      makeDynString(getCatStr("cc", "userChanged"),
                    getCatStr("para", "yes"),
                    getCatStr("para", "no"),
                    getCatStr("para", "cancel")),
                    df, ds);

    if ( df[1] == 1 )
    {
      int iOk = -1;
      
      ccSaveUserData(iOk);
      while ( iOk == -1 ) delay(0,100);
    }
    iOk = df[1];
  }
  else
  {
    iOk = 1;
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// saves user settings in the user management panel
//***fct***//
ccSaveUserData(int &iOk)
{
  dyn_string isMember, callingList, remoteAlert;
  int err, i, index, iPos, iiPos, fOut;
  dyn_string line;
  bool checked, ackPermission, bUsed, bRemoteAlert;
  dyn_bool autoHS, dackPermission, dbDomains;  
  
  dyn_string number, identifier, user, provider;
  dyn_uint deviceType, diIndex;
  dyn_time from, to;
  
  dyn_string pNumber, name, addressingText, addressField1, addressField2, password, language, substPerson;
  dyn_dyn_string disMember, dcallingList, dremoteAlert;
  dyn_uint workLoadLevel, pvssUser;
  
  string newuser = txtPersonnelNumber.text;
  string sPN, sWhere, sWhich, sDomain, sPerson;

  dyn_int    selLines, fallOut;
  
  dyn_string dsTmp;
  string     sNewUser;

//  getValue("tblRecipient", "getSelectedLines", selLines);
//!!!  if ( dynlen(selLines) < 1 ) return;
  if ( gUserIndex < 0 ) return;

  for ( i = 1; i <= 8; i++)
  //get choosen Domains
  {
    getValue("chkIsMember"+i, "state",   0, checked);
    dbDomains[i] = checked;
    if (checked)
      isMember[dynlen(isMember) +1] = i;
  }

  sPN = txtPersonnelNumber.text;
  ccIsUserUsedInShifts(sPN, dbDomains, bUsed, sWhere, sWhich, sDomain);
  if ( bUsed )
  {
    string sMess;
    
    sMess = getCatStr("cc", "inDomainUsed");
    strreplace(sMess, "%1", sDomain);
    strreplace(sMess, "%2", sWhere);
    strreplace(sMess, "%3", sWhich);
    ChildPanelOnCentralModal("vision/MessageWarning",
      getCatStr("para","warning"),
      makeDynString(sMess));
    iOk = -99;
    return;
  }
  
  fOut = chbFallOut.state(0);

  for (i = 0; i < tblCallingListOri.lineCount; i++)
  { 
    diIndex = makeDynInt();
    number = makeDynString();
    deviceType = makeDynString();
    user = makeDynString();
    provider = makeDynString();

    line = tblCallingListOri.getLineN(i);
    identifier = makeDynString(line[4]);

    ccGetDevices(diIndex,
                 number,     // numbers to search
                 deviceType,    // deviceTypes to search
                 identifier,    // identifiers to search
                 user,
                 provider);

    if ( dynlen(identifier) > 0 )
    {
      iPos = dynContains(identifier, line[4]);
      if ( iPos > 0 )
      {
        dsTmp = strsplit(user[iPos], "|");
        iiPos = dynContains(dsTmp, newuser);
        if ( iiPos > 0 )
        dynRemove(dsTmp, iiPos);
        //dynUnique(dsTmp);
        sNewUser = dsTmp;
        strreplace(sNewUser, " | ", "|");
      }
      ccChangeDeviceData(2,line[3],dynContains(dtText,line[2]),line[4],sNewUser, err, provider[iPos]);
    }
  }
  tblCallingListOri.deleteAllLines;

  for (i = 0; i < tblCallingList.lineCount; i++)
  { 
    diIndex = makeDynInt();
    number = makeDynString();
    deviceType = makeDynString();
    user = makeDynString();
    provider = makeDynString();

    line = tblCallingList.getLineN(i);
    identifier = makeDynString(line[4]);

    ccGetDevices(diIndex,
                 number,     // numbers to search
                 deviceType,    // deviceTypes to search
                 identifier,    // identifiers to search
                 user,
                 provider);

    if ( dynlen(identifier) > 0 )
    {
      iPos = dynContains(identifier, line[4]);
      if ( iPos > 0 )
      {
        dsTmp = strsplit(user[iPos], "|");
        dynAppend(dsTmp, newuser);
        //dynUnique(dsTmp);
        sNewUser = dsTmp;
        strreplace(sNewUser, " | ", "|");
      }
      ccChangeDeviceData(2,line[3],dynContains(dtText,line[2]),line[4],sNewUser, err, provider[iPos]);
      tblCallingListOri.appendLine("CallingListIndex",     line[1],
                                   "DeviceType",           line[2],
                                   "Number",               line[3],
                                   "Identifier",           line[4],
                                   "RemoteAlert",          line[5]);
    }
    else
    {
      ;//ccCreateDevice(line[3],dynContains(dtText,line[2]),line[4],newuser,index,err, provider[iPos]);
      //tblCallingList.cellValueRC(i, "CallingListIndex", makeDynString(index,"white","black"));
    }

    callingList[i+1] = line[4];
    remoteAlert[i+1] = (line[5]==getCatStr("para","yes"))?1:0;
  }

  pNumber[1] = txtPersonnelNumber.text;
  ccGetRecipients(pNumber, name, disMember, workLoadLevel, addressingText, addressField1, addressField2, 
                  dcallingList, dremoteAlert, password, language, dackPermission, pvssUser, fallOut, substPerson);
  
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value",     pNumber);
  if ( (iPos = dynContains(pNumber,txtPersonnelNumber.text)) != 0 )
    ccCreateOrChangeRecipient(txtPersonnelNumber.text,txtName.text, isMember, workLoadLevel[1],
                              addressingText[1], addressField1[1], addressField2[1], callingList, remoteAlert, 
                              password[1], language[1], dackPermission[1], pvssUser[1],
                              fOut, sPerson, err);

//                        -10 invalid domain found in isMember
//                        -11 workLoadLevel not between 1 and 5
//                        -12 invalid Deviceindex found in callingList
//                        -13 password incorrect
  if (err == -10)  //invalid domain found in isMember
    ChildPanelOnCentralModal("vision/MessageWarning",
      getCatStr("para","warning"),
      makeDynString(getCatStr("CommunicationCenter","-10")));
      
  if (err == -11)  //workLoadLevel not between 1 and 5
    ChildPanelOnCentralModal("vision/MessageWarning",
      getCatStr("para","warning"),
      makeDynString(getCatStr("CommunicationCenter","-11")));
      
  if (err == -12)  //invalid Deviceindex found in callingList
    ChildPanelOnCentralModal("vision/MessageWarning",
      getCatStr("para","warning"),
      makeDynString(getCatStr("CommunicationCenter","-12")));
      
  if (err == -13)  //password incorrect
    ChildPanelOnCentralModal("vision/MessageWarning",
      getCatStr("para","warning"),
      makeDynString(getCatStr("CommunicationCenter","validPassword")));
      
  if (err == -1)  //invalid personnelnumber
    ChildPanelOnCentralModal("vision/MessageWarning",
      getCatStr("para","warning"),
      makeDynString(getCatStr("CommunicationCenter","validPersNum")));
  if (true)//err == 0 )
  {
    int        j;
    string     outputIsMember = "";
    dyn_string domains;

    gSelectedUser       = txtName.text;
    gSelectedUserNumber = txtPersonnelNumber.text;

    domains = dpNames("*","_CommCenterDomains");
    for (i = 1; i <= dynlen(domains); i++)
      domains[i] = dpGetComment(domains[i]+".");

    for (j = 1; j <= dynlen(isMember); j++)
    {
      outputIsMember += domains[isMember[j]];
      if ( j < dynlen(isMember) )
        outputIsMember += ", ";
    }
    
//!!!    tblRecipient.cellValueRC(selLines[1], "IsMember", outputIsMember);
    tblRecipient.cellValueRC(gUserIndex, "IsMember", outputIsMember);
    tblRecipient.cellValueRC(gUserIndex, "Fails", (fOut)?getCatStr("para","yes"):getCatStr("para","no"));
    gdaNewUserData = ccGetUserDataFromPanel();
    gdaOldUserData = gdaNewUserData;
  }
  iOk = 1; 
  if ( /*err == 0 &&*/ gFromPanel == "ccDomain" && gFromDomainPanel )
    gShowPanel = gFromPanel;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// check if a user is allocated in more than one shifts
// or                           for a longer interval than defined in general settings
//***fct***//
ccCheckAllocationTimeAndMultiple(string      shiftDP,    // shiftDP
                                 string      pNr,        // userID
                                 int         iPnr,       // user index in shift
                                 dyn_dyn_int days,       // allocations in shift ( [days][times]
                                 time        begin,      // start time of the shift
                                 dyn_string  dsR,        // userIDs
                                 bool        bOneLine,   // not used
                                 bool        &bErrAlloc, // multiple or too long allocation
                                 int         iItem,
                                 int         iTimeBar)
{
  int        iTime;
  bool       bMulti, bAllocated, bAllocatedTime;
  string     s, shiftName;
  dyn_float  dfReturn;
  dyn_string dsReturn;

  bErrAlloc = false;
  dpGet("_CommCenter.Configuration.MaxTimeForRecipient:_online.._value", iTime,
        "_CommCenter.Configuration.MultipleAllocAllowed:_online.._value", bMulti);

  if ( iTime > 0 )
  {
//    ccCheckMaxTime(iTime, iPnr, days, bOneLine, bAllocatedTime);
    ccCheckMaxTimeOneItem(iTime, iItem, iTimeBar, bAllocatedTime);
    if ( bAllocatedTime )
    {
/*
      s = getCatStr("cc","allocatedTimeTooLongNotAllowed");
      strreplace(s, "%1", iTime);
      ChildPanelOnCentralModal("vision/MessageWarning",
        getCatStr("para","warning"),
        makeDynString(s));
      bErrAlloc = true;
      return;
*/
      s = getCatStr("cc","allocatedTimeTooLong");
      strreplace(s, "%1", iTime);
      ChildPanelOnCentralModalReturn("vision/MessageWarning2",
        getCatStr("para","warning"),
        makeDynString(s, getCatStr("cc", "allocate"), getCatStr("para", "cancel")),
        dfReturn, dsReturn);

      bErrAlloc = (dfReturn[1] < 1);
      return;
    }
  }

  ccCheckMultiAlloc(shiftDP, pNr, days, begin, dsR, bAllocated, shiftName);
  if ( bAllocated )
  {
/*
    if ( !bMulti )
    {
      s = getCatStr("cc","multipleAllocatedNotAllowed");
      strreplace(s, "%1", shiftName);
      ChildPanelOnCentralModal("vision/MessageWarning",
        getCatStr("para","warning"),
        makeDynString(s));
      bErrAlloc = true;
      return;
    }
    else
*/
    {
      s = getCatStr("cc","multipleAllocated");
      strreplace(s, "%1", shiftName);
      ChildPanelOnCentralModalReturn("vision/MessageWarning2",
        getCatStr("para","warning"),
        makeDynString(s, getCatStr("cc", "allocate"), getCatStr("para", "cancel")),
        dfReturn, dsReturn);

      bErrAlloc = (dfReturn[1] < 1);
      return;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// check if a user is allocated in more than one shifts
// parameters see above by ccCheckAllocationTimeAndMultiple
//***fct***//
ccCheckMultiAlloc(string shiftDP, string pNr, dyn_dyn_int days, time begin,
                  dyn_string dsR, bool &bAllocated, string &shiftName)
{
  int         i, j, k, l, n, iIdx, iCount, day1, day2;
  time        tBegin;
  dyn_string  dsShiftDps, dsDays, dsRecipient;
  dyn_dyn_int ddiDays, ddii;
  
  bAllocated = false;
  shiftName = "";
  dsShiftDps = dpNames("*", "_CommCenterShift");
  day1 = day(begin);

  for ( n = 1; n <= dynlen(dsShiftDps); n++ )
  {
    dynClear(ddiDays);
    if ( dpSubStr(dsShiftDps[n], DPSUB_SYS_DP) == dpSubStr(shiftDP, DPSUB_SYS_DP) ) continue; // don't check own shift
    
    dpGet(dsShiftDps[n] + ".Days:_online.._value", dsDays,
          dsShiftDps[n] + ".Personnel.Recipient:_online.._value", dsRecipient,
          dsShiftDps[n] + ".Begin:_online.._value", tBegin);

    iIdx = dynContains(dsRecipient, pNr);
    if ( iIdx < 1 ) continue; //recipient not used in this shift
    
    for ( i = 1; i <= dynlen(dsDays); i++ )
    {
      ddiDays[i] = strsplit(dsDays[i], "|");
    }
    day2 = day(tBegin);

    if ( day1 != 4 && day2 == 4 )
    {
      for ( i = 1; i <= dynlen(ddiDays); i++ )
      {
        for ( j = 1; j <= dynlen(days); j++ )
        {
          k = 1;
          while ( k <= dynlen(ddiDays[i]) && k <= dynlen(days[j]) && !bAllocated )
          {
            if ( days[j][k] > 0 && ddiDays[i][k] > 0 &&
                 dsRecipient[ddiDays[i][k]] == dsR[days[j][k]] &&
                 dsR[days[j][k]] == pNr )
            {
              bAllocated = true;
            }
            else
              k++;
          }
          if ( bAllocated ) break;
        }
        if ( bAllocated ) break;
      }
      if ( bAllocated )
      {
        shiftName = dpGetComment(dsShiftDps[n] + ".");
        return;
      }
    }
    else
    if ( day1 == 4 )
    {
      for ( i = 1; i <= dynlen(days); i++ )
      {
        for ( j = 1; j <= dynlen(ddiDays); j++ )
        {
          k = 1;
          while ( k <= dynlen(days[i]) && k <= dynlen(ddiDays[j]) && !bAllocated )
          {
            if ( days[i][k] > 0 && ddiDays[j][k] > 0 &&
                 dsR[days[i][k]] == dsRecipient[ddiDays[j][k]] &&
                 pNr == dsR[days[i][k]] )
              bAllocated = true;
            else
              k++;
          }
          if ( bAllocated ) break;
        }
        if ( bAllocated ) break;
      }
      if ( bAllocated )
      {
        shiftName = dpGetComment(dsShiftDps[n] + ".");
        return;
      }
    }
    else
    if ( day1 == day2 )
    {
      i = 1;
      while ( i <= dynlen(days) && i <= dynlen(ddiDays) && !bAllocated )
      {
        k = 1;
        while ( k <= dynlen(days[i]) && k <= dynlen(ddiDays[i]) && !bAllocated )
        {
          if ( days[i][k] > 0 && ddiDays[i][k] > 0 &&
               dsR[days[i][k]] == dsRecipient[ddiDays[i][k]] &&
               pNr == dsR[days[i][k]] )
            bAllocated = true;
          else
            k++;
        }
        if ( bAllocated )
          break;
        else
          i++;
      }
      if ( bAllocated )
      {
        shiftName = dpGetComment(dsShiftDps[n] + ".");
        return;
      }
    }
    else
    {
      dyn_int di;
      
      for ( i == 1; i <= 96; i++ ) di[i] = -1;
      dynClear(ddii);
      if ( day1 < day2 )
      {
        j = 1;
        for ( i = day1; i < day2; i++ )
        {
          ddii[j] = di;
          j++;
        }
        j = dynlen(ddii) + 1;
        for ( i = 1; i <= dynlen(ddiDays); i++ )
        {
          ddii[j] = ddiDays[i];
          j++;
        }
        ddiDays = ddii;
      }
      else
      {
        j = 1;
        for ( i = day2; i < day1; i++ )
        {
          ddii[j] = di;
          j++;
        }
        j = dynlen(ddii) + 1;
        for ( i = 1; i < dynlen(days); i++ )
        {
          ddii[j] = days[i];
          j++;
        }
        days = ddii;
      }
      i = 1;
      while ( i <= dynlen(days) && i <= dynlen(ddiDays) && !bAllocated )
      {
        k = 1;
        while ( k <= dynlen(days[i]) && k <= dynlen(ddiDays[i]) && !bAllocated )
        {
          if ( days[i][k] > 0 && ddiDays[i][k] > 0 &&
               dsR[days[i][k]] == dsRecipient[ddiDays[i][k]] &&
               pNr == dsR[days[i][k]] )
          {
            bAllocated = true;
          }
          else
            k++;
        }
        if ( bAllocated )
          break;
        else
          i++;
      }
      if ( bAllocated )
      {
        shiftName = dpGetComment(dsShiftDps[n] + ".");
        return;
      }
    }
  }
}
    
/////////////////////////////////////////////////////////////////////////////////////////////////
// check if a user is allocated  for a longer interval than defined in general settings
// parameters see above by ccCheckAllocationTimeAndMultiple
//***fct***//
ccCheckMaxTime(int maxTime, int pNr, dyn_dyn_int days, bool bOneLine, bool &bAllocatedTime)
{
  int     i, j, iCount;
  
  bAllocatedTime = false;
  iCount = 0;
  for ( i = 1; i <= dynlen(days); i++ )
  {
    for ( j = 1; j <= dynlen(days[i]); j++ )
    {
      if ( days[i][j] == pNr )
        iCount++;
      else
        iCount = 0;
      
      if ( iCount > maxTime * 4 )
      {
        bAllocatedTime = true;
        return;
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// returns the current user(s) for a domain at a time
//   dsUser[1] == userID
//   dsUser[2] == substituteID (defined in shift) if any, else "<>"
//   dsUser[3] is a flag:
//     dsUser[3] == 0 -> userID is the current user
//     dsUser[3] == 1 -> user failured, substituteID is the current user
//     dsUser[3] == 2 -> user failured, lase use fallback list
//***fct***//
ccGetCurrentUser(int         iDomain,      // domain number
                 time        tCurrentTime, // time to query
                 dyn_string &dsUser)       // users to be called (last element is a flag, see above)
{
  int            i;
  string         sUser, shiftSetDP, sDomainDp;
  dyn_string     dsUsers, dsParts;
  int            iErr;

  dyn_string     dsShifts;
  dyn_dyn_int    ddiDays, ddiSubs;
  dyn_dyn_string ddsShifts, ddsUsers;
  int            beginDay, iDayIndex;
  bool           dayBound;


  sDomainDp = "Domain" + iDomain;
  // domain does not exist
  if ( !dpExists(sDomainDp) )
  {
     dsUser = makeDynString("",""); //Domain does not exist
     return;
  }

  dpGet(sDomainDp + ".TopLevelShiftSet:_online.._value", shiftSetDP);
  ccGetAggregationShifts(shiftSetDP, makeDynString(), dsShifts);

  ccGetAggregationDays_WIN( dsShifts, 
                            ddiDays,
                            ddsShifts,
                            ddsUsers,
                            ddiSubs,
                            sUser,
                            iDayIndex,
                            beginDay,
                            dayBound,
                            tCurrentTime );
  dsUser = strsplit(sUser, "|");
//!!!  for ( i = 1; i <= dynlen(dsUser); i++ ) if ( dsUser[i] == "<>" ) dsUser[i] = "";
//   if (dynlen(dsUser)>=2)
  for ( i = 1; i <= 2 && i <= dynlen(dsUser); i++ ) if ( dsUser[i] == "<>" ) dsUser[i] = "";

//!!!  for ( i = dynlen(dsUser) +1; i < 3; i++ ) dsUser[i] = "";
  if ( dynlen(dsUser) < 3 ) dsUser[3] = "0";
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//***fct***//
// Checking if user exists and if fails
// Return values
//  string sUser  == "" - user does not exist
//  bool   bFails - user fails
/////////////////////////////////////////////////////////////////////////////////////////////////
ccCheckIfUserFailured(string sUser, bool &bFails) 
{
  int        i, iPos;
  dyn_int    diFailure;
  dyn_string dsPersonnelNumber;
  
  bFails = false;
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dsPersonnelNumber,
        "_CommCenterRecipients.Failure:_online.._value", diFailure);

  iPos = dynContains(dsPersonnelNumber, sUser);
  if ( iPos < 1 )
  {
    sUser = "";
  }
  else
  {
    bFails = ( diFailure[iPos] > 0 );
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// replacing failured users by their substitutes
//
// at the moment not used, because substitutes will only be used in shifts!
//
//***fct***//
ccReplaceFailuredUsers(dyn_string &dsUsers) 
{
  int        i, iPos;
  dyn_int    diFailure;
  dyn_string dsPersonnelNumber, dsSubstitution;
  
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dsPersonnelNumber,
        "_CommCenterRecipients.Failure:_online.._value", diFailure,
        "_CommCenterRecipients.Substitution:_online.._value", dsSubstitution);

  for ( i = dynlen(dsUsers); i > 0; i-- )
  {
    iPos = dynContains(dsPersonnelNumber, dsUsers[i]);
    if ( iPos < 1 )
    {
      dynRemove(dsUsers, iPos);
      continue;
    }
    if ( diFailure[iPos] )
    {
      if ( dsSubstitution[iPos] == "" )
      {
        dynRemove(dsUsers, iPos);
        continue;
      }
      else
      {
        dsUsers[i] = dsSubstitution[iPos];
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// reading devices of users
//***fct***//
ccGetUserDevices(dyn_string      dsUsers,    // userIDs, who's devices are to be found
                 dyn_dyn_string &ddsDevices) // devices used by the above users
{
  int        i, iPos;
  dyn_string dsPersonnelNumber, dsCallingList, ds;

  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", dsPersonnelNumber,
        "_CommCenterRecipients.CallingList:_online.._value", dsCallingList);

  for ( i = 1; i <= dynlen(dsUsers); i++ )
  {
    iPos = dynContains(dsPersonnelNumber, dsUsers[i]);
    if ( iPos > 0 )
    {
      ds = strsplit(dsCallingList[iPos], "|");
      ddsDevices[i] = ds;
    }
    else
    {
      ddsDevices[i] = makeDynString();
    }
  }
}

// ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **
// ActiveX Library Functions - START
// ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **
// ============================================================================
// Function:    cc_ewoSettings() - Initial Scheduler-EWO settings
// Requirement: Schedule_ewo
//
// bShift == true:  called from shift edit panel, schedule object will be filled
//        == false: called from domain time chart or overpara panel, no filling
//
// ============================================================================
//***fct***//
cc_ewoSettings(bool bShift = false) // flag if called from shift edit panel
{
  int            sec, nItem = 1, i, err, iDay, iHour;
  int displayedDays=0;
  bool           daybound;
  time           t1, 
                 t2, begin;
  string         sTank, shiftName, domain;
  long           rgb;
  dyn_string     recipient, agency, color;
  dyn_dyn_string dsDays;
  
  //Time view settings
  sec = period(makeTime(1970, 01, 04, 1, 0, 0));
  //86400 seconds represent 1 day
  p_lDayStart = (sec/86400);
//  p_lDayEnd = (sec/86400) + 25568;
  p_lDayEnd = (sec/86400);
  p_bBarChanged = FALSE;

  if ( bShift )
  {
    ccGetShift(shiftDP, shiftName, domain, daybound, begin, dsDays, recipient, agency, color, err);  // read Shift-Data from DPs
    iDay = weekDay(begin);
    if ( !daybound ) iDay = 1;
    iHour = hour(begin);
  
    for ( i = iDay; i <= 7; i++ )  //add days in Scheduler-Ewo
    {
      if ( daybound )
      {
          Scheduler_ewo.setDayText(++displayedDays,getCatStr("CommunicationCenter", "weekDay" + i));
      }
      else
      {
        Scheduler_ewo.setDayText(++displayedDays,getCatStr("CommunicationCenter", "Day") + i);
      }

      if ( i == iDay && iHour > 0 )
      {
        int iBar;
      }
    }
    for ( i = 1; i < iDay; i++ )
    {
      if ( daybound )
      {
          Scheduler_ewo.setDayText(++displayedDays,getCatStr("CommunicationCenter", "weekDay" + i));        
      }
      else
      {
        Scheduler_ewo.setDayText(++displayedDays,getCatStr("CommunicationCenter", "Day") + i);        
      }
    }
    if ( hour(begin) > 0 )
    {
      Scheduler_ewo.numDays(8);      
      int iBar;
      if ( daybound )
      {
        Scheduler_ewo.setDayText(++displayedDays,getCatStr("CommunicationCenter", "weekDay" + i));        
      }
      else
      {
        Scheduler_ewo.setDayText(++displayedDays,getCatStr("CommunicationCenter", "Day") + i);        
      }
    }
  }
}

// ============================================================================
// Function:    cc_ctSchedule_EventBarSelect()
// Requirement: Scheduler-Ewo
// ============================================================================
//***fct***//
void cc_BarSelect_ChangeSpinButtons(int idx)
{
  getStartAndEnd(idx, p_lCuBarTimeStart, p_lCuBarTimeEnd);
  
  int H, M, s_ON, s_OFF, iIndex;
  
//if (DEBUG) DebugTN("cc_ctSchedule_EventBarSelect");  

  //Set bar data on global variables
  p_iIndex = idx;
  p_iBar   = idx;

  p_iIdx = p_lCuBarTimeStart / 15 + 1;
  p_jIdx = p_lCuBarTimeEnd / 15;

  p_bBarChanged = FALSE;
  p_bBarDel = FALSE;
  p_bAdd = FALSE;

  cc_getHM(p_lCuBarTimeStart, H, M);
  cc_hMMSCorrect(H, M, s_ON);
  spFromH.text = H;  spFromM.text = M;
  cc_getHM(p_lCuBarTimeEnd, H, M);
  cc_hMMSCorrect(H, M, s_OFF);
  
  if ( H > 23 )
    H = 0;
  spToH.text = H;  spToM.text = M;
  
  p_bBarSelected = TRUE;
  iIndex = Scheduler_ewo.getRangeText(idx);
  tblPersonnel.selectLineN(iIndex - 1);
  tblPersonnel.lineVisible(iIndex-1);
  itemIndex = idx;
  barIndex = idx;
  oldTimeStart = p_lCuBarTimeStart;
  oldTimeEnd = p_lCuBarTimeEnd;
}

// ============================================================================
// Function:    cc_ctSchedule_EventBarDeleted()
// Requirement: ctSchedule
// ============================================================================
//***fct***//
cc_ctSchedule_EventBarDeleted(int nIndex, int nBar)
{
  int iErr;
  
  p_bBarDeleted = TRUE;
  p_bBarSelected = FALSE;
  cc_zoomButtonsDelDelAllClick();
  tblPersonnel.selectLineN(-1);
}

// ============================================================================
// Function:    cc_hMSCorrect()
// Requirement: ctSchedule
// ============================================================================
//***fct***//
cc_hMMSCorrect(int &h, int &m, int &s)
{
  if (h<0 || m<0 || s<0)
  {
    h = 0;
    m = 0;
    s = 0;
    p_lCuBarTimeStart = 0;
    p_lCuBarTimeEnd = 0;
    p_iIndex = 0;
    p_iBar = 0; 
  }
}

// ============================================================================
// Function:  cc_getHM() - Convert minutes in hours + minutes
// ============================================================================                    
//***fct***//
cc_getHM(int minutes, int &H, int &M)
{
  M = minutes % 60;
  H = ((minutes - M) / 60) % 60;
}                

// ============================================================================
// Function:  cc_getSeconds() - Convert a seconds string into secondsON 
//                              and secondsOFF
// ============================================================================   
//***fct***//
cc_getSeconds(string seconds, int &secondsON, int &secondsOFF)
{
  dyn_string secStr;
  
  secStr = strsplit(seconds, "*");
  if (dynlen(secStr) > 1)
  {
    secondsON = secStr[1];
    secondsOFF = secStr[2];
  }
  else
  {
    secondsON = 0; secondsOFF = 0;
  }
}

// ============================================================================
// Function: cc_adjustTime() - Returns a time (minutes) which is within 
//                             the allowed (day) values
// ============================================================================
//***fct***//
long cc_adjustTime(long t)
{
  return (t > 1440 ? 1440 : (t < 0 ? 0 : t)); //(t > 1440 ? 1440 : (t < 0 ? 0 : t));
}

// ==========================================================
// Function:    cc_validFrom()
// Requirement: txtFieldValidFrom
// ==========================================================
//***fct***//
cc_validFrom(time tIn, time &tOut, string setFocus = "")
{
  dateTimePicker(tIn, tOut, TRUE, TRUE, TRUE, FALSE, 0, 0, TRUE, TRUE);
  
  txtFieldValidFrom.text(formatTime(getCatStr(KAT, "m7"), tOut));

  if (setFocus != "")
    setInputFocus(myModuleName(), myPanelName(), setFocus);
}        
   
// ==========================================================
// Function:    cc_validUntil()
// Requirement: txtFieldValidUntil
// ==========================================================
//***fct***//
cc_validUntil(time tIn, time &tOut, string setFocus = "")
{
  dateTimePicker(tIn, tOut, TRUE, TRUE, TRUE, FALSE, 0, 0, TRUE, TRUE);
  
  txtFieldValidUntil.text(formatTime(getCatStr(KAT, "m7"), tOut));
   
  if (setFocus != "")
    setInputFocus(myModuleName(), myPanelName(), setFocus);
}

// ============================================================================
// Function: cc_setCheckbox(), cc_getCheckbox() - Get and set the checkbox value
// ============================================================================
//***fct***//
cc_setCheckbox(int index, bool b)
{
  string chk;

  sprintf(chk, "chk%d", index);
  setValue(chk, "state", 0, b);
}

cc_getCheckbox(int index, bool &b)
{
  string chk;

  sprintf(chk, "chk%d", index);
  getValue(chk, "state", 0, b);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// days is a global variable containing user allocations in a time chart of a domain
//***fct***//
ct_getLastTimeInDays(int &iIdx,  // last allocated day
                     int &jIdx)  // last allocated time on day iIdx
{
  int i, j;
  
  iIdx = 0;
  jIdx = 0;
  
  if ( dynlen(days) < 1 )
  {
    return;
  }
  for ( i = dynlen(days); i > 0; i-- )
  {
    for ( j = dynlen(days[i]); j > 0; j-- )
    {
      if ( days[i][j] != 0 )
      {
        iIdx = i;
        jIdx = j;
        return;
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// results the last free interval in a time chart of a domain
//***fct***//
ct_getLastFreeTime(int &iItem, int &iBarFreeTime)
{
  int j;
  
  iItem = Scheduler_ewo.numRanges(); //iItem = ctSchedule.ListCount;
  j = Scheduler_ewo.numRanges();
  int start, end;
  getStartAndEnd(j-1, start, end);
  iBarFreeTime = (Scheduler_ewo.getRangeColor(j-1) == OLEColor("_3DFace") ) ? start:1440; //?ctSchedule.BarTimeStart(iItem,j):1440;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// deleting allocation from a time chart
//***fct***//
ct_deleteTimeBarFromDays(int EwoBarIndex)
{
  int d = Scheduler_ewo.getRangeDay(EwoBarIndex);  
  if (EwoBarIndex==-1)  //if all bars to delete
  {
    int len = Scheduler_ewo.numRanges();
    for ( int i = Scheduler_ewo.numRanges-1 ; i >= 0; i-- )
    {
      if (Scheduler_ewo.getRangeText(i) != "- - -" && Scheduler_ewo.getRangeText(i) != "- -")  //don't remove the first and last bar if they are shiftblocking
      {
        Scheduler_ewo.removeRange(i);
      }
    }
  }
  else
  {
    if (Scheduler_ewo.getRangeText(EwoBarIndex) != "- - -" && Scheduler_ewo.getRangeText(EwoBarIndex) != "- -")
      Scheduler_ewo.removeRange(EwoBarIndex);
  } 

/*  for ( i = s; i <= e; i++)
  //append index
  {
    days[d][i] = 0;
  }
  */
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// converting begin/end time and duration into string
//***fct***//
cc_BeginEndDuration(time begin, time end, dyn_int duration,
                    string &sBeginTime, string &sEndTime,
                    string &sBeginDay, string &sEndDay,
                    string &sDuration, bool bDayBound = false)
{
  sBeginTime = ((hour(begin) < 10)?("0"+hour(begin)):hour(begin))+":"+
                      ((minute(begin) < 10)?("0"+minute(begin)):minute(begin));
  sEndTime   = ((hour(end) < 10)?("0"+hour(end)):hour(end))+":"+
                      ((minute(end) < 10)?("0"+minute(end)):minute(end));

  if ( bDayBound )
  {
    if (day(begin) > 4)
      sBeginDay = weekDays[weekDay(begin)];
    if (day(end) > 4)
      sEndDay = weekDays[weekDay(end)];
  }
  else
  {
    sBeginDay = getCatStr("CommunicationCenter","Day") + 1;
    sEndDay = getCatStr("CommunicationCenter","Day") + (day(end)-day(begin)+1);
  }

  sDuration = ccDurationToString(duration);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// removing current overpara in a domain
//***fct***//
ccRemoveOldOverPara(int iDomain)  // domain number
{
  int        i, uRemoveOldOverpara, iDayDifference, iTime;
  time       tCurrent = getCurrentTime();
  dyn_time   dtOverParaDate;
  dyn_string dtOverParaIntervals;
  
  tCurrent = makeTime(year(tCurrent), month(tCurrent), day(tCurrent));
  
  dpGet("Domain" + iDomain + ".OverPara.Date:_online.._value", dtOverParaDate,
        "Domain" + iDomain + ".OverPara.Intervals:_online.._value", dtOverParaIntervals,
        "_CommCenter.Configuration.RemoveOldOverpara:_online.._value", uRemoveOldOverpara);

  // don't remove overpara at all
  if ( uRemoveOldOverpara < 1 ) return;

  // removing overpara
  for ( i = dynlen(dtOverParaDate); i > 0; i-- )
  {
    iTime = tCurrent - dtOverParaDate[i];
    iDayDifference = iTime / 86400;
    if ( dtOverParaDate[i] < tCurrent && iDayDifference > uRemoveOldOverpara )
    {
      dynRemove(dtOverParaDate, i);
      dynRemove(dtOverParaIntervals, i);
    }
  }
  dpSet("Domain" + iDomain + ".OverPara.Date:_original.._value", dtOverParaDate,
        "Domain" + iDomain + ".OverPara.Intervals:_original.._value", dtOverParaIntervals);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// showing overparametrization of a domain on a date
//***fct***//
ccShowOverPara(int iDomain, time tDate, int iItem, bool bFromOverPara)
{
  int         i, iPos, iiPos, iVal;
  time        tCurrent = getCurrentTime();
  string      empty   = txtValid.backCol,
              used    = txtUsed.backCol,
              old     = txtOld.backCol,
              sColor = empty,
              sVal;
  dyn_time    dtOverParaDate;
  dyn_bool    dbF;
  dyn_string  dtOverParaIntervals, ds1, ds2, ds3, dsNr;
  dyn_dyn_int iBars;
  string      rangeData, rangeColor, rangeText;
  
  dyn_dyn_int overParaBars;

  tCurrent = makeTime(year(tCurrent), month(tCurrent), day(tCurrent));
  tDate    = makeTime(year(tDate), month(tDate), day(tDate));

  // old data is irrelevant
//  if ( tDate < tCurrent ) return;

  dpGet("Domain" + iDomain + ".OverPara.Date:_online.._value", dtOverParaDate,
        "Domain" + iDomain + ".OverPara.Intervals:_online.._value", dtOverParaIntervals,
        "_CommCenterRecipients.PersonnelNumber:_online.._value", dsNr,
        "_CommCenterRecipients.Failure:_online.._value", dbF);

  // no overpara on this date
  if ( (iPos = dynContains(dtOverParaDate, tDate)) < 1 ) return;

  ds1 = strsplit(dtOverParaIntervals[iPos], "#");
  
  if (dynlen(ds1)>=1 && ds1[1]=="")
    dynRemove(ds1,1);

  // overpara sorting before displaying
  ds3 = makeDynString();

  for ( i = 1; i <= dynlen(ds1); i++ )
  {
    ds2 = strsplit(ds1[i], "|");
    while ( dynlen(ds2) < 5 ) dynAppend(ds2, "<>");
    iVal = ds2[2];
    sprintf(sVal, "%04d", iVal);
    ds3[i] = sVal + "|";
    iVal = ds2[3];
    sprintf(sVal, "%04d", iVal);
    ds3[i] += sVal + "|" + ds2[1] + "|" + ds2[4] + "|" + ds2[5];
  }
  dynSortAsc(ds3);
  ds1 = makeDynString();
  for ( i = 1; i <= dynlen(ds3); i++ )
  {
    ds2 = strsplit(ds3[i], "|");
    ds1[i] = ds2[3] + "|";
    iVal = ds2[1]; sVal = iVal;
    ds1[i] += sVal + "|";
    iVal = ds2[2]; sVal = iVal;
    ds1[i] += sVal + "|" + ds2[4] + "|" + ds2[5];
    dynAppend(overParaBars, makeDynInt(ds2[1], ds2[2]));
  }

  // draw time bars
  for ( i = 1; i <= dynlen(ds1); i++ )
  {
    ds2 = strsplit(ds1[i], "|");
    if (i==1 && ds2[2]!=0)  //if first bar doesn't start at 0:00
    {
      Scheduler_ewo.setRangeReadOnly(Scheduler_ewo.addRange(iItem, getTimeFromInt(0), getTimeFromInt(ds2[2]), emptyColor, "", ""), true);
    }
    else if ( i>1 && strsplit(ds1[i-1], "|")[3]!=ds2[2])  //if there is a gap between the bar before and the act bar
      Scheduler_ewo.setRangeReadOnly(Scheduler_ewo.addRange(iItem, getTimeFromInt(strsplit(ds1[i-1], "|")[3]), getTimeFromInt(ds2[2]), emptyColor, "", ""), true);
    while ( dynlen(ds2) < 5 ) dynAppend(ds2, "<>");
    if ( ds2[1] == "<>" )
      sColor = empty;
    else if ( tDate < tCurrent )
      sColor = old;
    else
      sColor = used;
  
//    Scheduler_ewo.setDayColor(iItem, overParaColor);

    iPos = dynContains(dsNr, ds2[4]);
    iiPos = dynContains(dsNr, ds2[5]);
    if ( iPos > 0 && dbF[iPos] )
    {
      if ( iiPos > 0 && dbF[iiPos] )
      {
        rangeData = ds2[1] + "|" + ds2[4] + "|" + ds2[5] + "|2";

      }
      else
      {
        rangeDate = ds2[1] + "|" + ds2[4] + "|" + ds2[5] + "|1";
      }
    }
    else
    {
      rangeData = ds2[1] + "|" + ds2[4] + "|" + ds2[5] + "|0";
    }

    if ( sColor != empty && bFromOverPara )
    {
      rangeText = ccGetUserTextFromSubText(rangeData);
      rangeColor = overParaColor;
    }
    else
    {
      rangeText = "";
      rangeColor = emptyColor;
    }
    int idx = Scheduler_ewo.addRange(iItem, getTimeFromInt(overParaBars[i][1]), getTimeFromInt(overParaBars[i][2]), rangeColor, rangeText, rangeData);
    Scheduler_ewo.setRangeReadOnly(idx,(sColor != used || !bFromOverPara));
    
    if (i == dynlen(ds1) && ds2[3] < 1439)//if last bar doesn't end at 23:59
    {
      Scheduler_ewo.setRangeReadOnly(Scheduler_ewo.addRange(iItem, getTimeFromInt(ds2[3]), getTimeFromInt(1439), emptyColor, "", ""), true);
    }    
  }

}

/////////////////////////////////////////////////////////////////////////////////////////////////
//***fct***//
string ccGetUserTextFromSubText(string s)
{
  dyn_string ds = strsplit(s, "|");

  s = "";
  if ( ds[1] == "<>" && ds[2] == "<>" )
    return(s);

  if ( ds[2] != "<>" )
  {
//    if (dynlen(ds)>=4)//error!
//    {
      if ( ds[4] == "0" )
        s = gg_UserName[dynContains(gg_UserNr, ds[2])];
      else if ( ds[4] == "1" )
        s = gg_UserName[dynContains(gg_UserNr, ds[3])];
//     }
//     else
//       DebugN("dyn-len error!");
  }
  return(s);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//***fct***//
ccIsFreeOrSpecialDay(time t, bool &bSpecial)
{
  int      i;
  dyn_time dt;

  bSpecial = false;

  // weekend day?
  if ( weekDay(t) > 5 )
  {
    bSpecial = true;
    return;
  }

  // special day (defined in scheduler)?
  dpGet("_ScCom.specDays.list.DayDates:_original.._value", dt);
  for ( i = 1; i <= dynlen(dt); i++ )
  {
    if ( month(t) == month(dt[i]) && day(t) == day(dt[i]) )
    {
      bSpecial = true;
      return;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// reading minimum priority of a domain at a given time
//***fct***//
ccGetMinPriority(int iDomain, time tTime, int &iPrio)
{
  int      i,
           iWeekDay = weekDay(tTime),
           iTime    = 1000*60*(hour(tTime)*60 + minute(tTime));
           
  bool     bSpecial;
  dyn_int  diDomain, diDay, diFrom, diTo, diPriority;
  dyn_time dt;

  iPrio = 256;

  if ( !dpExists("_CommCenterMinPriority") )
  {
    dpCreate("_CommCenterMinPriority", "_CommCenterMinPriority");     // IM 64214
  }


  dpGet("_CommCenterMinPriority.Domain:_online.._value", diDomain,
        "_CommCenterMinPriority.Day:_online.._value", diDay,
        "_CommCenterMinPriority.From:_online.._value", diFrom,
        "_CommCenterMinPriority.To:_online.._value", diTo,
        "_CommCenterMinPriority.Priority:_online.._value", diPriority);

  ccIsFreeOrSpecialDay(tTime, bSpecial);

  for ( i = 1; i <= dynlen(diDomain); i++ )
  {

         //same domain
    if (
         //in timerange
         diFrom[i] <= iTime && iTime <= diTo[i] &&
         //all days     or special day                 or same day
         (diDay[i] == 0 || (diDay[i] == 8 && bSpecial) || iWeekDay == diDay[i])
       )
    {  
      if ( diDomain[i] == iDomain || diDomain[i] == 0) //Checks if a spec domain or all domains (0 = all)
      {
          if (diPriority[i] <= iPrio)
           {
              iPrio = diPriority[i];
           }
       
        }

    }
  }
  
  if (iPrio >= 256) iPrio = 0;
  
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Result: xd yh zm
//***fct***//
string ccDurationToString(dyn_int diDuration)
{
  string sDuration = diDuration[1]+"d "+((diDuration[2]<10)?"0":"")+diDuration[2]+"h "+((diDuration[3]<10)?"0":"")+diDuration[3]+"m"; 

  if ( dynlen(diDuration) < 3 ) diDuration[3] = 0;
  sDuration = diDuration[1]+"d "+((diDuration[2]<10)?"0":"")+diDuration[2]+"h "+((diDuration[3]<10)?"0":"")+diDuration[3]+"m";
  return(sDuration);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//***fct***//
void ccInitOverpara()
{
  int            i, j, begU, iLen, iDayIndex, iDomain, iState;
  dyn_int        diEmpty;
  dyn_dyn_int    daysU, daysB;
  time           begin, tTopStart;
  string         invalid, empty, used, strText, firstShift, s, sTopLevelShiftSet;
  dyn_float      dfReturn;
  dyn_string     spnItems, dsEmpty, dsName = makeDynString(), dsDps,
                 dsDomains = dpNames("*", "_CommCenterDomains"), dsReturn;
  
  if ( isMotif() )
  {
    panelSize(myPanelName(), 589, 571);
    LayerOff(2);
    LayerOn(3);
  }
  else
  {
    LayerOff(3);
    LayerOn(2);
  }

  addGlobal("days",DYN_DYN_INT_VAR);
  dynClear(days);
  
  for ( i = 1; i <= dynlen(dsDomains); i++ )
  {
    dpGet(dsDomains[i] + ".TopLevelShiftSet:_online.._value", sTopLevelShiftSet);
    if ( sTopLevelShiftSet != "" )
    {
      dynAppend(dsDps, dsDomains[i]);
      s = dpGetComment(dsDomains[i] + ".");
      dynAppend(dsName, s);
    }
  }

  cmbDomain.items = dsName;
  cmbDomainDp.items = dsDps;

  if ( cmbDomain.itemCount < 1 )
  {
    txtNoDomain.text = getCatStr("cc", "noDomainWithShiftPlan");
    txtNoDomain.visible = true;
    return;
  }
  
  txtDomain.visible = true;
  cmbDomain.visible = true;
  dpGet("_CommCenterRecipients.PersonnelNumber:_online.._value", gg_UserNr,
        "_CommCenterRecipients.Name:_online.._value", gg_UserName);

  if ( !isMotif() )
  {
    cc_ewoSettings();
  }
  
  gg_Start    = getCatStr("cc", "start");
  gg_End      = getCatStr("cc", "end");
  gg_Shift    = getCatStr("cc", "Shift");
  gg_User     = getCatStr("cc", "User");
  gg_Subs     = getCatStr("cc", "Substitute");
  gg_Fallback = getCatStr("cc", "FallbackPerson");
  
  txtBeginTime.text   = "";
  txtBeginDay.text    = "";
  txtEndTime.text     = "";
  txtEndDay.text      = "";
  txtMinDuration.text = "";
  txtMaxDuration.text = "";
  tCurrentTime        = "";
  iDomain             = "";
  txtTop.text         = "";
}

void ccDefineColors()
{
  barColor = makeDynString("red","blue","green","yellow","brown","darkblue","orange","darkgreen","magenta","steelblue","gainsboro", "grey");  //set colors of Bars
}
string ccGetColor(string color)
{
/*  if (color = "STD_on")  //for shiftAggregationPlan
    return "green";
  if (dynlen(barColor)<1)
    ccDefineColors();
  
  string tmp = strrtrim(color,"0123456789");

  string inx="";
  if(strlen(tmp)==strlen(color))
      return barColor[dynlen(barColor)];
  else
  {
    for(int i=strlen(tmp); i<strlen(color); i++)
    {
      inx += color[i];
    }
  }
  int colorIndex = (int)inx;
  if (colorIndex >= dynlen(barColor) || colorIndex<1)
    return barColor[dynlen(barColor)];
  
  return barColor[colorIndex];
  */
  return color;
}
// ============================================================================
// Function:    void setSpinbuttonsEnable(bool en)
//        <- enable or disable all Spinbuttons
// ============================================================================
void setSpinbuttonsEnable(bool en)
{
  spFromH.enabled(en);
  spFromM.enabled(en);
  spToH.enabled(en);
  spToM.enabled(en);
  cmdDeleteBar.enabled(en);
}

// ============================================================================
// Function:    void ccSetBarWithSpinbuttons() 
//        <- set start and end the selected bar to the values of the SpinButtons
// ============================================================================
void ccSetBarWithSpinbuttons()
{
  time nullTime = makeTime(1970,6,6,0,0,0,0,true);
  int from = spFromH.text * 60 + spFromM.text;
  int to = spToH.text * 60 + spToM.text;
  Scheduler_ewo.setRangeStart(Scheduler_ewo.selectedRange(), nullTime+(from*60));
  Scheduler_ewo.setRangeEnd(Scheduler_ewo.selectedRange(), nullTime+(to*60));
}

// ============================================================================
// Function:    void ccDeleteBarsOfDay(int nDay) <- deltetes all bars of the day nDay or all if -1 is given
// ============================================================================
void ccDeleteBarsOfDay(int nDay)
{
  for (int i=Scheduler_ewo.numRanges()-1; i>=0; i--)
  {
    if ( nDay==-1 || Scheduler_ewo.getRangeDay(i) == nDay )
      Scheduler_ewo.removeRange(i);
  }
}

// ============================================================================
// Function:    dyn_dyn_int ccSetBarColorOfDay(int nDay, string color, string ignoreText="")
//    <- change all barColors of a day, but ignore bars with are labled with the ignoreText
// Parameter:   int nDay          ... number of day
//              string color      ... color to set
//              string ignoreText ... ignore bars with are labled with the ignoreText
// return:      dyn_dyn_int       ... [1] -> changed Bars, [2] -> all Bars of the day
// ============================================================================
dyn_dyn_int ccSetBarColorOfDay(int nDay, string color, string ignoreText="")
{
  dyn_int iBars;
  dyn_int allBarsOfDay;
  dyn_dyn_int barsChangedAndallBars;
  int numRanges = Scheduler_ewo.numRanges();
  for (int i=0; i<numRanges; i++)
  {
    if ( Scheduler_ewo.getRangeDay(i) == nDay)
    {
      if(Scheduler_ewo.getRangeText(i)!=ignoreText)
      {
        Scheduler_ewo.setRangeColor(i, color);
        dynAppend(iBars, i);
        dynAppend(allBarsOfDay, i);        
      }
      else
        dynAppend(allBarsOfDay, i);
    }
  }  
  dynAppend (barsChangedAndallBars,iBars);
  dynAppend (barsChangedAndallBars,allBarsOfDay);  
  return(barsChangedAndallBars);
}

// ============================================================================
// Function:    void getStartAndEnd(int idx, int &start, int &end) <- gives the Minutes of Start and End of a Bar
// Parameter:   int idx ...Bar-Id
//              int &start ... return Minutes of Start
//              int &end   ... return Minutes of End
// ============================================================================
void getStartAndEnd(int idx, int &start, int &end, bool quarter=false)
{
  int s = period(Scheduler_ewo.getRangeStart(idx)), e = period(Scheduler_ewo.getRangeEnd(idx));
  start = s / 60 + (s % 60 > 1 ? 1 : 0);
  end = e / 60 + (e % 60 >= 1 ? 1 : 0);
  if (quarter)
  {
    start = start / 15;
    end = end / 15;
  }
}
// ============================================================================
// Function:    time getTimeFromInt(int iTime) <- converts Minutes to time
// Parameter:                 int iMinutes
// ============================================================================
time getTimeFromInt(int iMinutes)
{
  time ret = makeTime(1970,6,6,0,0,0,0,true);
  ret += (iMinutes*60) - (iMinutes>1439);
  return ret;
}
// ============================================================================
// Function:    dyn_string getroundedUpHM(int idx) <- returns a dyn_string with start (e.g. 01:15) and end (e.g. 10:45) with filled 0 of a bar
// Parameter:                 int idx  ...the bar-id
// ============================================================================
dyn_string getroundedUpHM(int idx)
{
  int start, end;
  getStartAndEnd(idx, start, end);
  dyn_string ret;
  int H, M;
  H=start/60;
  M=start%60;

  dynAppend(ret,((H<10)?"0":"") + H + ":" + ((M<10)?"0":"") + M + ";"); 
  
  H = end/60;
  M = end%60;  
  dynAppend(ret,((H<10)?"0":"") + H + ":" + ((M<10)?"0":"") + M + ";");   
  return (ret);
}
// ============================================================================
// Function:    dyn_string getOverParaDays(int iDomain) <- returns a dyn_string with the overParaDays of a Domain
// Parameter:                 int iDomain  ...the DomainNumber
// ============================================================================
dyn_string getOverParaDays(int iDomain)
{
  dyn_string dtOverParaDate, ret;
  string tmp;
  time t;
  dpGet("Domain" + iDomain + ".OverPara.Date:_online.._value", dtOverParaDate);
  for (int i = 1; i<=dynlen(dtOverParaDate); i++)
  {
    t = dtOverParaDate[i];
    tmp = formatTime("%d.%m.%Y", t);
    dynAppend(ret, tmp);
  }
  return ret;
}
// ============================================================================
// Function:    cc_mergeFirstAndLastDay (...) <- merge the first and last day in an aggregation shiftplan
// Parameter:                 dyn_dyn_int    &ddiDays,                       // table with shift internal user indices
//                            dyn_dyn_string &ddsShifts,                     // table with shiftDPs
//                            dyn_dyn_string &ddsUsers,                      // table with user IDs
//                            dyn_dyn_int    &ddiSubs)                       // indices of substituting persons in shift if any
// ============================================================================
void cc_mergeFirstAndLastDay (dyn_dyn_int    &ddiDays,                       // table with shift internal user indices
                              dyn_dyn_string &ddsShifts,                     // table with shiftDPs
                              dyn_dyn_string &ddsUsers,                      // table with user IDs
                              dyn_dyn_int    &ddiSubs)                       // indices of substituting persons in shift if any
{
  int last = dynlen(ddiDays);
  if (last==0 || dynlen(ddsShifts)==0 || dynlen(ddsUsers)==0 || dynlen(ddiSubs)==0)  //return if one Parameter is empty
    return;
  
  dyn_int firstDays = ddiDays[1];
  
//  if(firstDays[1]!=-1)  //no merge if there is no shift-limiter on first day -> because shift starts at 0:00
//    return;
  
  dyn_string firstShifts = ddsShifts[1];
  dyn_string firstUsers = ddsUsers[1];
  dyn_int firstSubs = ddiSubs[1];

  dyn_int lastDays = ddiDays[last];
  dyn_string lastShifts = ddsShifts[last];
  dyn_string lastUsers = ddsUsers[last];
  dyn_int lastSubs = ddiSubs[last];  
  
  int i;
  //merge first day
  for(i = 1; i<=dynlen(ddiDays[1]) ; i++)
  {
    if (ddiDays[1][i]!=-1)
      break;

    ddiDays[1][i] = lastDays[i];
    ddsShifts[1][i] = lastShifts[i];
    ddsUsers[1][i] = lastUsers[i];
    ddiSubs[1][i] = lastSubs[i];
  }
  if(i!=1)  //if the first day has been merged with last day
  {
    dynRemove(ddiDays, last);
    dynRemove(ddsShifts, last);
    dynRemove(ddsUsers, last);
    dynRemove(ddiSubs, last);
  }
}

// ============================================================================
// Function:    cc_getSubstituteForUser (...) <- get the Substitute person for a person for a shift
// Parameter:                 string shift,                       // dp of shift
//                            string UserNr                       // number of User
// return:      string the Substitute person
// ============================================================================
string cc_getSubstituteForUser (string shift, string UserNr)
{
  dyn_string users, subs;
  
  //reading users and Substitutes from shift-dp
  dpGet(shift+".Personnel.Recipient", users,
      shift+".Personnel.Substitute", subs);
  
  //finding user
  int pos = dynContains(users, UserNr);
  
  //finding substitute
  if ( dynlen(subs) >= pos )
    return subs[pos];
  return "<>";
}

// ============================================================================
// Function:    cc_getUTCTimeSeconds (...) <- get Sconds since 1.1.1970 in UTC-Time <- workaround because makeTime cannot create UTC-Time
// Parameter:                 int iYear=1970
//                            int iMonth=1
//                            int iDay=1
//                            int iHour=0
//                            int iMinute=0
//                            int iSecond=0
//                            int iMilli=0
// ============================================================================
int cc_getUTCTimeSeconds(int iYear=1970, int iMonth=1, int iDay=1, int iHour=0, int iMinute=0, int iSecond=0, int iMilli=0)
{
  // calculate the differnece between UTC-Time and LocalTime in seconds
  int Diff = period(makeTime(1970,1,2,12)) - 129600;
  time t = makeTime(iYear, iMonth, iDay, iHour, iMinute, iSecond, iMilli);
  
  // calculate the seconds and add the difference - but the before 1.1.1970 is 0
  int ret = ((period(t)>0) ? period(t) : Diff)+ daylightsaving(t)*3600 - Diff;
  return ( ret );
}



// ============================================================================
// Function:  cc_getDpsForDpGroup (...) <- get Datapointelements from dpGroup for dpConnect to enable distributed Systems (because dpConnets to dpGroups only work on local System)
// Parameter: string dpGroup
// return:    string DPEs of dpGroup Kommaseperated
// ============================================================================
string cc_getDpsForDpGroup(string dpGroup)
{
  string sDPEs;

  int  overflow=0;
  dyn_string dsItemsInFilter, res_typfilter, res_dpfilter;
  dyn_string dsDpElements = makeDynString();

  groupGetFilterItems(dpGroup, res_typfilter, res_dpfilter);

  for (int i=1;i<=dynlen(res_typfilter);i++)
  {
    // reading DP(E)-Items
    dsItemsInFilter=makeDynString();
    groupGetFilteredDps(res_typfilter[i], res_dpfilter[i], dsItemsInFilter, overflow);
    for (int j=1;j<=dynlen(dsItemsInFilter);j++)
    {
      // add each item in this filter to list of all dps in this dpgroup
      dynAppend(dsDpElements, dsItemsInFilter[j]);
    }
  }  
  for(int i=1; i<=dynlen(dsDpElements); i++)
  {
    if(i!=1)
      sDPEs+=",";
    sDPEs+=dsDpElements[i];
  }
  return sDPEs;
}
