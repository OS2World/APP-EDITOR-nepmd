/****************************** Module Header *******************************
*
* Module Name: modecnf.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: modecnf.e,v 1.2 2004-06-29 22:44:10 aschn Exp $
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

; This is the default configuration file for modes, using the ModeExecute
; command.
;
; 1) Replace all settings of this file
;
;    You may want to create your own MODECNF.E in you MYEPM\MACROS directory
;    to replace the file in the NETLABS\MACROS directory. Don't simply
;    overwrite a file of the NETLABS tree. After changing your configuration,
;    you have to recompile EPM.E.
;
; 2) Add your own settings or change several settings
;
;    Create a file MYSTUFF.E in your MYEPM\MACROS directory and use this file
;    as an example. The commands from MYSTUFF.E will be executed after the
;    ones from this file, so you're able to overwrite the following.
;
;    As an alternative, you simply may want to specify the here used commands
;    in your MYEPM\PROFILE.ERX. The commands from PROFILE.ERX will be
;    executed after the ones from this file, so you're able to overwrite the
;    following.
;
;    Additionally, you can even reset all settings without modifying
;    MODECNF.E: Use the command 'ModeExecute CLEAR'.
/*
In order to create or edit one of these files, put the cursor on one of the
following both lines and press Alt+= or Alt+0

   e %NEPMD_ROOTDIR%\myepm\macros\modecnf.e
   e %NEPMD_ROOTDIR%\myepm\macros\mystuff.e
   e %NEPMD_ROOTDIR%\myepm\bin\profile.erx

*/
; You may want to reset all prior used ModeExecute defs with
; 'ModeExecute CLEAR'.
;
; Syntax: ModeExecute <mode> <set_cmd> <args>
;
;         <set_cmd>         <args>
;
;         SetStreamMode     0 | 1
;         SetCuaMarking     0 | 1
;         SetInsertMode     0 | 1
;         SetHighlight      0 | 1
;         SetTabs           <number> or <list of numbers>
;         SetTabkey         0 | 1
;         SetMatchTab       0 | 1
;         SetMargins        <left> <right> <par>
;         SetExpand         0 | 1
;         SetIndent         <number> (default = const, if defined,
;                           e.g. REXX_INDENT; else first number of tabs)
;         SetTextColor      number (with PROFILE.ERX, or const, see COLORS.E)
;         SetMarkColor      number (with PROFILE.ERX, or const, see COLORS.E)
;                           (Hint: place cursor on COLORS.E and press Alt+1 to
;                                  load the file)
;         SetTextFont       <font_size>.<font_name>[.<font_sel>]  (<font_size>
;                           and <font_name> can be exchanged. Any EPM font
;                           specification syntax will be accepted as well. The
;                           args are case-sensitive.)
;         SetToolbar        <toolbar_name> (must be defined in EPM.INI)
;         SetDynaspell      0 | 1
;         SetEditOptions    see description of EDIT command
;         SetSaveOptions    see description of SAVE command
;         SetSearchOptions  see description of LOCATE and REPLACE commands
;                           (plus undocumented TB options)
;         SetKeys           <keyset_name>
;
; Any <set_cmd> can also be executed in EPM's commandline. Then it will
; affect only the current file.
;
;   SetTextColor 31     (31 = (15 = white) + (16 = blue background))

; Specify DEFAULT as <args>, if you want to reset a setting to NEPMD's
; default value.
;
;   SetTextColor default

; If you want to reset all settings of the current file to the default
; settings for a mode, then use the mode command:
;
;   Mode 0        (redetermine mode and apply mode-specific settings)
;   Mode rexx     (change mode to REXX and apply all REXX-specific settings)

; ---------------------------------------------------------------------------
; Omit DEFINIT when you put the following lines in your PROFILE.ERX.
definit

/* 'ModeExecute CLEAR' removes all prior ModeExecute definitions  */
/* Use it, if you want to overwrite all NEPMD's defaults, without */
/* creating your own MYEPM\MACROS\MODECNF.E file.                 */
/*
'ModeExecute CLEAR'
*/

'ModeExecute Shell SetKeys Shell_keys'

'ModeExecute E SetKeys E_keys'
'ModeExecute E SetTabs 3'
'ModeExecute E SetMargins 1 1599 1'
'ModeExecute E SetIndent 3'

'ModeExecute REXX SetKeys REXX_keys'
'ModeExecute REXX SetTabs 3'
'ModeExecute REXX SetMargins 1 1599 1'
'ModeExecute REXX SetIndent 3'

'ModeExecute C SetKeys C_keys'
'ModeExecute C SetTabs 3'
'ModeExecute C SetMargins 1 1599 1'
'ModeExecute C SetIndent 3'

'ModeExecute JAVA SetKeys C_keys'
'ModeExecute JAVA SetTabs 3'
'ModeExecute JAVA SetMargins 1 1599 1'
'ModeExecute JAVA SetIndent 3'

'ModeExecute PASCAL SetKeys Pas_keys'
'ModeExecute PASCAL SetTabs 3'
'ModeExecute PASCAL SetMargins 1 1599 1'
'ModeExecute PASCAL SetIndent 3'



/* ---- Some more examples: ---- */

/* Experimental 1 */
/*
'ModeExecute TEXT SetHighlight 0'
'ModeExecute TEXT SetTabKey 1'
'ModeExecute TEXT SetInsertMode 0'
'ModeExecute TEXT SetDynaSpell 1'
'ModeExecute TEXT SetTextColor BLACK + LIGHT_GREYB'
'ModeExecute TEXT SetMarkColor WHITE + DARK_GREYB'
/*'ModeExecute TEXT SetTextFont 10x6.System VIO.underscore'*/
'ModeExecute TEXT SetTextFont 9.WarpSans'
'ModeExecute TEXT SetStreamMode 0'

/*'ModeExecute BIN SetEditOptions /t /64 /bin'*/
'ModeExecute BIN SetSaveOptions /ne /ns /nt'
'ModeExecute BIN SetTabs 1'
'ModeExecute BIN SetTabKey 1'
'ModeExecute BIN SetMatchTab 0'

'ModeExecute E SetIndent 3'
'ModeExecute REXX SetIndent 4'
'ModeExecute C SetIndent 5'
*/

/* Experimental 2 */
/*
'ModeExecute E SetTabKey 0'
'ModeExecute E SetToolbar BUILDIN'
'ModeExecute E SetHighlight 1'
'ModeExecute E SetTextColor BLACK + WHITEB'
'ModeExecute E SetMarkColor BLUE + LIGHT_GREYB'
'ModeExecute E SetTextFont 14.System VIO'
*/


