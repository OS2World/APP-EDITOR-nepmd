/****************************** Module Header *******************************
*
* Module Name: alarm.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: alarm.e,v 1.1 2002-09-02 20:08:25 cla Exp $
*
* ===========================================================================
*
* This file is part of the Netlabs EPM Distribution package and is free
* software.  You can redistribute it and/or modify it under the terms of the
* GNU General Public License as published by the Free Software
* Foundation, in version 2 as it comes in the "COPYING" file of the
* Netlabs EPM Distribution.  This library is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
****************************************************************************/

/*
@@NepmdAlarm@PROTOTYPE
fResult = NepmdAlarm( AlarmStyle);

@@NepmdAlarm@CATEGORY@DIALOG

@@NepmdAlarm@SYNTAX
This function generates an alarm according to the style specified.

@@NepmdAlarm@PARM@AlarmStyle
This optional parameter specifies the style of the alarm to be generated.
If no style is specified, the alarm for *NOTE* is generated.

The following styles are supported:
.ul compact
- NOTE
- WARNING
- ERROR

@@NepmdAlarm@RETURNS
NepmdAlarm returns either
.ul compact
- *0* (zero), if the alarm was not generated  or
- *1* , if the alarm was generated.


@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdAlarm, Alarm =

 AlarmStyle = arg( 1);

 fResult = NepmdAlarm( AlarmStyle);
 if (fResult) then
    StrResult = 'was';
 else
    StrResult = 'was not';
 endif
 sayerror 'alarm' StrResult 'generated'

/* ------------------------------------------------------------- */
/* procedure: NepmdAlarm                                         */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    fResult = NepmdAlarm( AlarmStyle);                         */
/*                                                               */
/*  Valid tags are: NOTE ALARM WARNING                           */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  BOOL EXPENTRY NepmdAlarm( PSZ pszAlarmStyle);                */
/* ------------------------------------------------------------- */

defproc NepmdAlarm( AlarmStyle) =

 /* prepare parameters for C routine */
 AlarmStyle = AlarmStyle''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 fResult = dynalink32( LibFile,
                       "NepmdAlarm",
                       address( AlarmStyle));

 checkliberror( LibFile, fResult);

 return fResult;

