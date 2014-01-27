/****************************** Module Header *******************************
*
* Module Name: alarm.e
*
* E wrapper routine to access the NEPMD library DLL.
* Include of nepmdlib.e.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
NepmdAlarm( AlarmStyle)

@@NepmdAlarm@CATEGORY@INTERACT

@@NepmdAlarm@SYNTAX
This function generates an alarm according to the style specified.

@@NepmdAlarm@PARM@AlarmStyle
This optional parameter specifies the style of the alarm to be generated.
The following styles are supported:
.ul compact
- NOTE
- WARNING
- ERROR

If no style is specified, the alarm for *NOTE* is generated.

@@NepmdAlarm@RETURNS
*NepmdAlarm* returns nothing.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdAlarm@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdAlarm* [.IDPNL_EFUNC_NEPMDALARM_PARM_ALARMSTYLE alarm__style]
  - or
- *Alarm* [.IDPNL_EFUNC_NEPMDALARM_PARM_ALARMSTYLE alarm__style]

Executing this command will
generate the apropriate alarm sound, if the related system setting is set to on,
and display the result within the status area.

*Example:*
.fo off
 Alarm ERROR
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdAlarm, Alarm

   AlarmStyle = arg( 1)

   call NepmdAlarm( AlarmStyle)
   if rc then
      StrResult = 'was'
   else
      StrResult = 'was not'
   endif
   sayerror 'Alarm' StrResult 'generated.'

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdAlarm
; ---------------------------------------------------------------------------
; E Syntax:
;    NepmdAlarm( AlarmStyle)
;
;  Valid tags are: NOTE ALARM WARNING
; ---------------------------------------------------------------------------
; C prototype:
;    BOOL EXPENTRY NepmdAlarm( PSZ pszAlarmStyle);
; ---------------------------------------------------------------------------

defproc NepmdAlarm( AlarmStyle)

   -- Prepare parameters for C routine
   AlarmStyle = AlarmStyle\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdAlarm",
                    address( AlarmStyle))

   helperNepmdCheckliberror( LibFile, rc)

   return

