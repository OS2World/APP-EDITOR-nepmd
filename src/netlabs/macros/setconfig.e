/****************************** Module Header *******************************
*
* Module Name: setconfig.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: setconfig.e,v 1.4 2002-11-04 18:04:56 aschn Exp $
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

; Change configuration keys per command.
; These commands were added temporarily to change the current values until
; a GUI exists.

; A defc may have the same name as a var.

defc DragAlwaysMarks
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Mark\DragAlwaysMarks"
   ConfigValue = strip( arg(1) )
   if ConfigValue = '' then
      ConfigValue = NepmdQueryConfigValue( nepmd_hini, KeyPath )
      sayerror 'Value for 'KeyPath' is: 'ConfigValue
   else
      ConfigValue = ( ConfigValue = 1 )  -- (0|1)
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue )
      'mouse_init'  -- refresh the register_mousehandler defs
   endif
   return rc

defc MouseStyle
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Mark\MouseStyle"
   ConfigValue = strip( arg(1) )
   if ConfigValue = '' then
      ConfigValue = NepmdQueryConfigValue( nepmd_hini, KeyPath )
      sayerror 'Value for 'KeyPath' is: 'ConfigValue
   else
      ConfigValue = ( ConfigValue <> 1 ) + 1  -- (1|2)
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue )
      'mouse_init'  -- refresh the register_mousehandler defs
   endif
   return rc

defc MouseMarkWorkaround
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Mark\Workaround"
   ConfigValue = strip( arg(1) )
   if ConfigValue = '' then
      ConfigValue = NepmdQueryConfigValue( nepmd_hini, KeyPath )
      sayerror 'Value for 'KeyPath' is: 'ConfigValue
   else
      ConfigValue = ( ConfigValue = 1 )  -- (0|1)
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue )
      'mouse_init'  -- refresh the register_mousehandler defs
   endif
   return rc

defc HomeRespectIndent
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Indent\Home\RespectIndent"
   ConfigValue = strip( arg(1) )
   if ConfigValue = '' then
      ConfigValue = NepmdQueryConfigValue( nepmd_hini, KeyPath )
      sayerror 'Value for 'KeyPath' is: 'ConfigValue
   else
      ConfigValue = ( ConfigValue = 1 )  -- (0|1)
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue )
   endif
   return rc

; -------------------------------------------------------------------
; Reset settings for fonts, colors, options to default NEPMD settings

defc NepmdDefaultControls
   universal appname, app_hini
   if appname = '' then
      appname = 'EPM'
   endif
   -- set REXX profile (bit 12) and stream mode (bit 10) = ON
   inikey  = 'OPTFLAGS'
   inidata = '1 1 1 1 1 1 0 0 1 1 1 1 1 0 1 1 0 '\0
   call setprofile(app_hini, appname, inikey, inidata)
   -- set colors
   -- doesn't do nothing!
   -- how to change colors?
   inikey  = 'DTCOLOR'
   inidata = '07'\0
   call setprofile(app_hini, appname, inikey, inidata)
   -- set fonts - this works well
   inikey  = 'FONT'
   inidata = 'System VIO.DD120WW0HH0BB.0'\0
   call setprofile(app_hini, appname, inikey, inidata)
   inikey  = 'MSGFONT'
   inidata = 'System VIO.DD120WW0HH0BB.0'\0
   call setprofile(app_hini, appname, inikey, inidata)
   inikey  = 'STATFONT'
   inidata = '10.System Proportional Non-ISO'\0
   call setprofile(app_hini, appname, inikey, inidata)
   return

