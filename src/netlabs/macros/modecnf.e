/****************************** Module Header *******************************
*
* Module Name: modecnf.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: modecnf.e,v 1.6 2006-03-11 21:15:10 aschn Exp $
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
;    You may want to create your own MODECNF.E in your %NEPMD_USERDIR%\MACROS
;    directory to replace the file in the NETLABS\MACROS directory. Don't
;    simply overwrite a file of the NETLABS tree. After changing your
;    configuration, you have to recompile EPM.E.
;
; 2) Add your own settings or change several settings
;
;    Create a file MYSTUFF.E in your %NEPMD_USERDIR%\MACROS directory and use
;    this file as an example. The commands from MYSTUFF.E will be executed
;    after the ones from this file, so you're able to overwrite the
;    following.
;
;    As an alternative, you simply may want to specify the here used commands
;    in your %NEPMD_USERDIR%\PROFILE.ERX. The commands from PROFILE.ERX will
;    be executed after the ones from this file, so you're able to overwrite
;    the following.
;
;    Additionally, you can even reset all settings without modifying
;    MODECNF.E: Use the command 'ModeExecute CLEAR'.
/*
In order to create or edit one of these files, put the cursor on one of the
following three lines and press Alt+= or Alt+0

   e %NEPMD_USERDIR%\macros\modecnf.e
   e %NEPMD_USERDIR%\macros\mystuff.e
   e %NEPMD_USERDIR%\bin\profile.erx

View Netlabs' default mode configuration file:

   e %NEPMD_ROOTDIR%\netlabs\macros\modecnf.e

*/
; Syntax: ModeExecute <mode> <set_cmd> <args>
;
;         <set_cmd>         <args>
;
;         SetStreamMode     0 | 1
;         SetInsertMode     0 | 1
;         SetHighlight      0 | 1
;         SetTabs           <number> or <list of numbers>
;         SetTabkey         0 | 1
;         SetMatchTab       0 | 1
;         SetMargins        <left> <right> <par>
;         SetTextColor      <number> or <color_name> (see COLORS.E)
;         SetMarkColor      <number> or <color_name> (see COLORS.E)
;                           (Hint: place cursor on COLORS.E and press Alt+1
;                                  to load the file)
;         SetTextFont       <font_size>.<font_name>[.<font_sel>]
;                              <font_size> and <font_name> can be exchanged.
;                              Any EPM font specification syntax is
;                              accepted as well. The args are case-sensitive.
;         SetToolbar        <toolbar_name> (must be defined in NEPMD.INI)
;         SetDynaspell      0 | 1
;         SetEditOptions    see description of EDIT command
;         SetSaveOptions    see description of SAVE command
;         SetSearchOptions  see description of LOCATE and REPLACE commands
;                           (plus undocumented TB options)
;         SetKeys           <keyset_name>
;
;      Settings for syntax expansion:
;         SetExpand         0 | 1
;         SetIndent         <number> (default = first number of tabs)
;         SetHeaderStyle    1 | 2
;                              HeaderStyle 1 (default):
;                              /********************
;                              * |
;                              ********************/
;                              HeaderStyle 2:
;                              /********************
;                               * |
;                               *******************/
;         SetHeaderLength      <-- header_length --> (default = 77)
;         SetEndCommented   0 | 1
;         SetMatchChars     <space-separated list of pairs> (default = '')
;                              list of possible pairs: '{ } [ ] ( ) < >'
;         SetCommentAutoTerminate
;                           0 | 1 (default = 0)
;         SetFunctionSpacing
;                           'N' | 'C' | 'SC' | 'SCE' (default = 'C')
;                               'N' no spaces
;                               'C' space after a comma in a parameter list
;                               'S' space after start (opening parenthesis)
;                                   of a parameter list
;                               'E' space before end (closing parenthesis)
;                                   of a parameter list
;         SetClosingBraceAutoIndent
;                           0 | 1 (default = 0)
;         SetCodingStyle    <coding_style>
;                              Coding styles can be defined with the
;                              AddCodingStyle command, even in PROFILE.ERX
;
;      Settings for keyset C_KEYS:
;         SetCBraceStyle    'BELOW' | 'APPEND' | 'INDENT' | 'HALFINDENT'
;                              (default = 'BELOW')
;         SetCCaseStyle     'INDENT' | 'BELOW' (style of "case" statement,
;                              default = 'INDENT')
;         SetCDefaultStyle  'INDENT' | 'BELOW' (style of "default" statement,
;                              default = 'INDENT')
;         SetCMainStyle     'STANDARD' | 'SHORT' (style of "main" statement,
;                              default = 'SHORT')
;         SetCCommentStyle  'CPP' | 'C' (use either // ... or /* ... */, if
;                              EndCommented = 1, default = 'CPP')

;      Settings for keyset REXX_KEYS:
;         SetRexxDoStyle    'APPEND' | 'INDENT' | 'BELOW' (style of "do"
;                              statement, default = 'BELOW')
;         SetRexxIfStyle    'ADDELSE' | 'NOELSE' (style of "if" statement,
;                              default = 'NOELSE')
;         SetRexxCase       'LOWER' | 'MIXED' | 'UPPER' (default = 'LOWER')
;         SetRexxForceCase  0 | 1 (default = 1)
;                              1 means: change case of typed statements as
;                              well, not only of the added statements
;
; Any <set_cmd> can also be executed in EPM's commandline. Then it will
; effect only the current file.
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
; InitModeCnf is executed by defmain, before a file is loaded and before
; PROFILE.ERX is called.
; Omit the "defc" line when you put the following lines in your PROFILE.ERX.
; The rest of the file is valid REXX and E code.
defc InitModeCnf

/* ----------------------------------------------------------------------- */
/* Coding styles                                                           */
/* ----------------------------------------------------------------------- */

/* K&R */
'AddCodingStyle K&R SetIndent 4'
'AddCodingStyle K&R SetTabs 4'
'AddCodingStyle K&R SetTabKey 0'
'AddCodingStyle K&R SetCBraceStyle APPEND'
'AddCodingStyle K&R SetCCaseStyle INDENT'

/* K&R8 */
'AddCodingStyle K&R8 SetIndent 8'
'AddCodingStyle K&R8 SetTabs 8'
'AddCodingStyle K&R8 SetTabKey 0'
'AddCodingStyle K&R8 SetCBraceStyle APPEND'
'AddCodingStyle K&R8 SetCCaseStyle INDENT'

/* K&R3 */
'AddCodingStyle K&R3 SetIndent 3'
'AddCodingStyle K&R3 SetTabs 3'
'AddCodingStyle K&R3 SetTabKey 0'
'AddCodingStyle K&R3 SetCBraceStyle APPEND'
'AddCodingStyle K&R3 SetCCaseStyle INDENT'

/* Linux = Gnome */
/* use tabs for indent -> convert spaces to tabs before save */
'AddCodingStyle Linux SetIndent 8'
'AddCodingStyle Linux SetTabs 8'
'AddCodingStyle Linux SetTabKey 1'
'AddCodingStyle Linux SetCBraceStyle APPEND'
'AddCodingStyle Linux SetCCaseStyle INDENT'

/* BSD = Allman */
'AddCodingStyle BSD SetIndent 8'
'AddCodingStyle BSD SetTabs 8'
'AddCodingStyle BSD SetTabKey 0'
'AddCodingStyle BSD SetCBraceStyle BELOW'
'AddCodingStyle BSD SetCCaseStyle INDENT'

/* BSD4 = XWP */
'AddCodingStyle BSD4 SetIndent 4'
'AddCodingStyle BSD4 SetTabs 4'
'AddCodingStyle BSD4 SetTabKey 0'
'AddCodingStyle BSD4 SetCBraceStyle BELOW'
'AddCodingStyle BSD4 SetCCaseStyle INDENT'

/* BSD3 */
'AddCodingStyle BSD3 SetIndent 3'
'AddCodingStyle BSD3 SetTabs 3'
'AddCodingStyle BSD3 SetTabKey 0'
'AddCodingStyle BSD3 SetCBraceStyle BELOW'
'AddCodingStyle BSD3 SetCCaseStyle INDENT'

/* GNU */
'AddCodingStyle GNU SetIndent 4'
'AddCodingStyle GNU SetTabs 4'
'AddCodingStyle GNU SetTabKey 0'
'AddCodingStyle GNU SetCBraceStyle HALFINDENT'
'AddCodingStyle GNU SetCCaseStyle INDENT'

/* Whitesmith */
'AddCodingStyle Whitesmith SetIndent 8'
'AddCodingStyle Whitesmith SetTabs 8'
'AddCodingStyle Whitesmith SetTabKey 0'
'AddCodingStyle Whitesmith SetCBraceStyle INDENT'
'AddCodingStyle Whitesmith SetCCaseStyle INDENT'

/* JAVA */
'AddCodingStyle JAVA SetIndent 4'
'AddCodingStyle JAVA SetTabs 8'
'AddCodingStyle JAVA SetTabKey 0'
'AddCodingStyle JAVA SetCBraceStyle APPEND'
'AddCodingStyle JAVA SetCCaseStyle INDENT'

/* You may want to create your own REXX style. Therefore copy some (or     */
/* all) of the "ModeExecute REXX ..." settings below here, use             */
/* "AddCodingStyle MYREXX ..." commands and configure the Set* command     */
/* values. Then specify "ModeExecute REXX SetCodingStyle MYREXX" in the    */
/* "ModeExecute REXX" block below.                                         */


/* ----------------------------------------------------------------------- */
/* 'ModeExecute CLEAR' removes all prior ModeExecute definitions.          */
/* Use it, if you want to overwrite all NEPMD's defaults, without          */
/* creating your own %NEPMD_USERDIR%\MACROS\MODECNF.E file.                */
/* ----------------------------------------------------------------------- */
/*
'ModeExecute CLEAR'
*/

/* ----------------------------------------------------------------------- */
/* Settings for all modes, if no ModeExecute command exists.               */
/* These settings are not accessable via the Options menu,                 */
/* therefore a DEFAULT pseudo mode is defined for them.                    */
/* ----------------------------------------------------------------------- */

'ModeExecute DEFAULT SetHeaderStyle 1'
'ModeExecute DEFAULT SetHeaderLength 77'
'ModeExecute DEFAULT SetMatchChars'
'ModeExecute DEFAULT SetFunctionSpacing C'
'ModeExecute DEFAULT SetClosingBraceAutoIndent 1'


/* ----------------------------------------------------------------------- */
/* Settings for special modes                                              */
/* ----------------------------------------------------------------------- */

'ModeExecute Shell SetKeys Shell_keys'

'ModeExecute E SetKeys E_keys'
'ModeExecute E SetTabs 3'
'ModeExecute E SetIndent 3'
'ModeExecute E SetMargins 1 1599 1'

'ModeExecute REXX SetKeys REXX_keys'
'ModeExecute REXX SetRexxDoStyle INDENT'
'ModeExecute REXX SetRexxIfStyle ADDELSE'
'ModeExecute REXX SetRexxCase LOWER'
'ModeExecute REXX SetRexxForceCase 1'
'ModeExecute REXX SetTabs 3'
'ModeExecute REXX SetIndent 3'
'ModeExecute REXX SetMargins 1 1599 1'

'ModeExecute C SetKeys C_keys'
'ModeExecute C SetCodingStyle BSD4'
'ModeExecute C SetMatchChars { } ( ) [ ]'
'ModeExecute C SetMargins 1 1599 1'

'ModeExecute JAVA SetKeys C_keys'
'ModeExecute JAVA SetCodingStyle JAVA'
'ModeExecute JAVA SetMatchChars { } ( ) [ ]'
'ModeExecute JAVA SetMargins 1 1599 1'

'ModeExecute PASCAL SetKeys Pas_keys'
'ModeExecute PASCAL SetTabs 3'
'ModeExecute PASCAL SetIndent 3'
'ModeExecute PASCAL SetMargins 1 1599 1'

'ModeExecute HTML SetMatchChars < >'
'ModeExecute HTML SetMargins 1 1599 1'



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


