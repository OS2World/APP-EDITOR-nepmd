/****************************** Module Header *******************************
*
* Module Name: setconfig.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: setconfig.e,v 1.2 2002-10-20 10:40:25 cla Exp $
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

; Change configuration keys per command


; Current DEFAULTS.DAT:
/*

; Statusline
;"\NEPMD\User\Statusline\Template" = "Line %l of %s | Col %c | '%x'x/%z | %f | ma %ma | tabs %ta | %mo | %m"
;"\NEPMD\User\Statusline\Separator" = " ú "
;"\NEPMD\User\Statusline\Font" = "10.System Proportional.Non-ISO"
;"\NEPMD\User\Statusline\Color" = "BLACK + LIGHT_GREYB"
;"\NEPMD\User\Statusline\ModifiedColor" = "MAGENTA + LIGHT_GREYB"

; Titletext
;"\NEPMD\User\Titletext\Template" = "%fn   (%dt)"

; Messageline
;"\NEPMD\User\Messageline\Font" = "10.Helv"
;"\NEPMD\User\Messageline\Color" = "LIGHT_RED + WHITEB"

; Mouse
"\NEPMD\User\Mouse\Mark\DragAlwaysMarks" = "1"
;    MouseStyle =  1: MB1 = block marking, MB2 = char marking
;    MouseStyle <> 1: MB2 = block marking, MB1 = char marking
"\NEPMD\User\Mouse\Mark\MouseStyle" = "1"
"\NEPMD\User\Mouse\Mark\Workaround" = "1"

"\NEPMD\User\Mouse\Url\MB1_DClick" = "1"
"\NEPMD\User\Mouse\Url\Browser" = "DEFAULT"
;"\NEPMD\User\Mouse\Url\ContextMenu" = "1"

; Indent
"\NEPMD\User\Indent\Home\RespectIndent" = "1"
*/

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
      -- sayerror 'Querying with rc = 'rc', Value = 'ConfigValue', KeyPath = 'Keypath
      sayerror 'Value for 'KeyPath' is: 'ConfigValue
   else
      ConfigValue = ( ConfigValue <> 1 ) + 1  -- (1|2)
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue )
      --sayerror 'Writing with rc = 'rc', Value = 'ConfigValue', KeyPath = 'Keypath
      'mouse_init'  -- refresh the register_mousehandler defs
   endif
; May a defc have the same name as a var?
;   MouseStyle = ConfigValue
;   sayerror 'MouseStyle = 'MouseStyle
; Yes!
   return rc


; rc=457: Session started in the background (seen in PMPrintF window at recompiling)
; rc=105: Previous semaphore owner ended without freeing the semaphore
;         after recompiling, because epm /i is still opened and nepmd_hini was
;         *not* closed at that time by a defexit in MAIN.E

