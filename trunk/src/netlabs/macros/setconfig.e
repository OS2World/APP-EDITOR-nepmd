/****************************** Module Header *******************************
*
* Module Name: setconfig.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: setconfig.e,v 1.5 2003-08-31 22:14:02 aschn Exp $
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

/*
see also: STDCTRL.E: defc initconfig

OPTFLAGS:
   Bit              Setting
        for value = 1      for value = 0
   ---  ----------------   -------------------
    1   statusline on      statusline off
    2   msgline on         msgline off
    3   vscrollbar on      vscrollbar off
    4   hscrollbar on      hscrollbar off
    5   fileicon on        fileicon off        icon beside system menu icon
    6   rotbuttons on      rotbuttons off
    7   info at top        info at bottom      pos of status + msg lines
    8   CUA marking        advanced marking
    9   menuprompt on      menuprompt off      menu hints on msg line
   10   stream mode        line mode
   11   longnames on       longnames off       show .LONGNAME EA instead of file name in titletext
   12   REXX profile on    REXX profile off
   13   escapekey on       escapekey off       ESC opens cmdbox
   14   tabkey on          tabkey off          1 = TAB inserts tab char
   15   bgbitmap on        bgbitmap off
   16   toolbar on         toolbar off
   17   dropstyle modif    dropstyle unmodif   text for drop on another EFrame or folder
   18   ?extra stuff on    ?extra stuff off    ?

OPT2FLAGS:
   Bit              Setting
        for value = 1      for value = 0
   ---  ----------------   -------------------
    1   I-beam pointer     arrow pointer       1 = (vEPM_POINTER=2)
    2   underline cursor   bar cursor          1 = (cursordimensions = '-128.3 -128.-64')
*/
defc NepmdDefaultControls
   universal appname, app_hini
   if appname = '' then
      appname = 'EPM'
   endif
   -- set REXX profile (bit 12) and stream mode (bit 10) = ON
   inikey  = 'OPTFLAGS'
   inidata = '1 1 1 1 1 1 0 0 1 1 1 1 1 0 0 1 0'\0  -- trailing space, required?
   --   Bit:  1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7
   call setprofile(app_hini, appname, inikey, inidata)
   inikey  = 'OPT2FLAGS'
   inidata = '1 0'\0
   --   Bit:  1 2
   call setprofile(app_hini, appname, inikey, inidata)
   -- set colors, see COLORS.E
   inikey  = 'DTCOLOR' -- vDESKTOPColor (bgbitmap area if bgbitmap off)
   inidata = '07'\0
   call setprofile(app_hini, appname, inikey, inidata)
   inikey  = 'STUFF'
   inidata = '240 113 112 252'\0  --.textcolor .markcolor vSTATUSCOLOR vMESSAGECOLOR
   call setprofile(app_hini, appname, inikey, inidata)
   -- set fonts
   inikey  = 'FONT'
   inidata = 'System VIO.DD120WW0HH0BB.0'\0
   call setprofile(app_hini, appname, inikey, inidata)
   inikey  = 'MSGFONT'
   inidata = '10.Helv'\0
   call setprofile(app_hini, appname, inikey, inidata)
   inikey  = 'STATFONT'
   inidata = '10.System Proportional Non-ISO'\0
   call setprofile(app_hini, appname, inikey, inidata)
   return

