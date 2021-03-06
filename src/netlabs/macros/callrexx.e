/****************************** Module Header *******************************
*
* Module Name: callrexx.e
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
Todo:
- Part 2 contains defprocs, defined as defcs to use them in REXX.
  Move them to where they belong to.
*/

/*
 * Name        CallRexx
 *
 * Author      Ralph E. Yozzo & Larry Margolis
 *
 * Function    Call a Rexx Macro from EPM
 *
 *                The steps that are followed are:
 *
 *                  - We set up the default environment to point to EPM
 *                  - We register our subcommand DLL.
 *                  - We call the EPM-REXX macro.
 */

const
   RXCOMMAND        = '0'
   RXSUBROUTINE     = '1'          -- Program called as Subroutine
   RXFUNCTION       = '2'
   RXFUNC_DYNALINK  = '1'          -- Function Available in DLL
   RXFUNC_CALLENTRY = '2'          -- Registered as mem entry pt.

compile if not defined(ERES_DLL)  -- Being compiled separately?  (For debug use...)
   include 'STDCONST.E'
   include 'ENGLISH.E'
compile endif

; ---------------------------------------------------------------------------
defproc RxResult
   universal rexxresult
   parse arg RxMacro
   'rx 'RxMacro
   return rexxresult

; ---------------------------------------------------------------------------
; Universal vars can be used to check the result:
;   rc = 0: success
;   rc < 0: E error
;   rc > 0: REXX error
;   rexxresult: return value of the REXX function
defc epmrexx, rx
   universal rexxresult
   -- Reset universal var
   rexxresult = ''

   parse value arg(1) with Macro Args
   if Macro = '' then
      sayerror RX_PROMPT__MSG
      return
   endif
   call parse_filename( Macro, .filename)
   if not pos( '.', substr( Macro, lastpos( '\', Macro) + 1)) then
      Macro = Macro'.erx'   -- add the default extention
   endif

   -- Try to register the subcommand interface
   rc = rexxsubcomregister()
   if rc then
      sayerror RX_SUBCOM_FAIL__MSG rc
      return
   endif
   rc = rexxfunctionregister()
   if rc then
      sayerror RX_FUNC_FAIL__MSG rc
      return
   endif

;  string=atol(length(getall))||offset(getall)||selector(getall)
   -- Call the macro named by the macro variable
   -- The default environment is "ERXSUBCOM".
   -- The EPM subcommand DLL is "ERXSBCOM.DLL".
;  sayerror 'EPM REXX macro "'macro'" running...'
   Functionname =macro\0
;  saveautoshell = .autoshell
;  .autoshell = 0

   -- Allocate buffer for string, functionname, envname, rcresult, and resultstring.
   --                                           'ENV'\0   2 bytes       8 bytes
;  len = length(string) + length(functionname) + length(envname) + 2 + 8
;  string_ofs = 0
   func_ofs = 8  -- length(string)
   env_ofs  = func_ofs + length( Functionname)
   rc_ofs   = env_ofs + 4
   res_ofs  = rc_ofs + 4  -- return code is a long
   parm_ofs = res_ofs + 8
   len      = parm_ofs + length( Args)
   bufhndl  = substr( atol( dynalink32( E_DLL,
                                        'mymalloc',
                                        atol( len), 2)), 3, 2)
   bufhndla =  ltoa( bufhndl\0\0, 10)
   r = -270 * (bufhndla = 0)

   if r | not bufhndla then sayerror 'Error 'r' allocating memory segment; command halted.'; stop; endif
;  poke bufhndla, 0, string  -- assume string_ofs = 0
   poke bufhndla, 0, atol( length( Args))||atoi( parm_ofs)||bufhndl
   poke bufhndla, func_ofs, Functionname
   poke bufhndla, env_ofs, 'EPM'\0
   poke bufhndla, parm_ofs, Args

   result = dynalink32( 'REXX',                   -- dynamic link library name
                        '#1',   -- 'RexxStart',   -- Rexx input function
                        atol(1)                || -- Num of args passed to rexx
                        \0\0                   || -- offset of Arglist
                        bufhndl                || -- selector of "
                        atoi(func_ofs)         || -- offset of program name
                        bufhndl                || -- selector of "
                        atol(0)                || -- Loc of rexx proc in memory
                        atoi(env_ofs)          || -- offset of env.
                        bufhndl                || -- sel. ASCIIZ initial environment.
                        atol(RXCOMMAND)        || -- type (command,subrtn,funct)
                        atol(0)                || -- SysExit env. names &  codes
                        atoi(rc_ofs)           || -- offset Ret code from if numeric
                        bufhndl                || -- sel. Ret code from if numeric
                        atoi(res_ofs)          || -- offset Retvalue from the rexx proc
                        bufhndl)                  -- selector of "

;  .autoshell = saveautoshell
   rc = rexxsubcomdrop()
      if rc & rc <> 30 then  -- rc = 30, when 'rx' is executed from another .erx file
         sayerror RX_SUBCOM_FAIL__MSG rc
;;       return
      endif
   if result then
      if result = -3 | result = 65533 then
         rc = result
         result = result':  'FILE_NOT_FOUND__MSG '('Macro')'
         sayerror FILE_NOT_FOUND__MSG '('Macro')'
      elseif result < 0 then
         rc = result
      else
         rc = 65536 - result
         -- This error msg is only written if the REXX syntax error was not
         -- catched by the macro itself. Using the ERX file can be much more
         -- comfortable, because also the REXX error line is saved in the
         -- sigl var. With the error line, the erranous file can be loaded
         -- and EPM can jump to that line.
         -- The ERX code for that looks like that:
         --    signal on syntax name Error
         --    parse source . . ThisFile
         --    ...
         --    Error:
         --       'sayerror REX'right( rc, 4, 0)': Error 'rc' running 'ThisFile', line 'sigl ||,
         --       ': 'errortext( rc)
         --       "e "ThisFile" 'postme "sigl"'"
         --       exit( 31)
         saved_rc = rc
         Msg = GetHelpMsg( rc)
         rc = saved_rc
         sayerror 'REX'rightstr( rc, 4, 0)': Error 'rc' running 'Macro': 'Msg
      endif
   else
      -- Set universal RC for use by callers.
      --rc = ltoa( peek( bufhndla, rc_ofs, 4), 10)
      -- Better use rexxresult for return value from REXX proc
      rc = 0
   endif
   Saved_rc = rc

   if rc = 0 then
      rcresult = peek( bufhndla, rc_ofs, 2)
      resultstring = peek( bufhndla, res_ofs, 8)
      peekseg = itoa( substr( resultstring, 7, 2), 10)
      peekoff = itoa( substr( resultstring, 5, 2), 10)
      peeklen = ltoa( substr( resultstring, 1, 4), 10)
      -- Set universal var
      rexxresult = peek( peekseg, peekoff, peeklen)
      --dprintf( 'result='result'; Input <'Args'>  and the result from REXX is <'rexxresult'>; rc='rc)
   endif

   call dynalink32( E_DLL,         -- dynamic link library name
                    'myfree',                   -- DosFreeSeg
                    atoi(0) ||  -- add an offset to make the selector an address
                    bufhndl)
   rc = Saved_rc

; ---------------------------------------------------------------------------
defproc GetHelpMsg( rex_rc)
   universal vTEMP_FILENAME
   Msg = ''

   quietshell 'helpmsg REX'rex_rc' 1>'vTEMP_FILENAME' 2>&1'
   'xcom e /D /Q' vTEMP_FILENAME
   if not rc then
      parse value textline(2) with . '***'Msg'***'
   endif
   'xcom q'
   call erasetemp( vTEMP_FILENAME)
   return Msg

; ---------------------------------------------------------------------------
; Invoke current file as a Rexx macro, passing it the arguments specified (if any).
defc rxme =
   if .modify then
      result = winmessagebox( "RxMe", MODIFIED_PROMPT__MSG, MB_YESNOCANCEL + MB_ICONQUESTION + MB_MOVEABLE)
      if result = MBID_YES then
         'save'
      elseif result = MBID_NO then
         -- nop
      else
         return
      endif
   endif

   if not exist(.filename) then
      sayerror '"'.filename'"' NOT_ON_DISK__MSG
      return
   endif

   'rx' .filename arg(1)

; ---------------------------------------------------------------------------
; Register the EPM subcommand DLL.
; Store the EPM window handle in the Rexx subcommand user area.
defproc rexxsubcomregister()
   pib = 1234
   tid = 1234

   call dynalink32( 'DOSCALLS',      /* dynamic link library name       */
                    '#312',           /* ordinal value for DOS32GETINFOBLOCKS */
                    address(tid) ||
                    address(pib), 2)

   pid = peek32( ltoa( pib, 10), 0, 4)

   SubcomName = 'EPM'\0
   SubcomDLL  = ERES_DLL\0
   SubcomProc = 'ERESREXX'\0
   UserArea   = atol(getpminfo(EPMINFO_EDITCLIENT)) || pid

   result = dynalink32( 'REXXAPI',
                        '#6',        -- 'RexxRegisterSubcomDll',
                        address(SubcomName) ||
                        address(SubcomDll)  ||
                        address(SubcomProc) ||
                        address(UserArea)   ||
                        atol(0))

   if result & result <> 10 then  -- 10 = RXSUBCOM_DUP; registration was successful.
      result = dynalink32( 'REXXAPI',
                           '#9',       -- 'RexxDeregisterSubcom',
                            address(SubcomName) ||
                            address(SubcomDll))
      if result & result <> 30 then   -- 30 = RXSUBCOM_NOTREG
         return result
      endif

      result = dynalink32( 'REXXAPI',
                           '#6', -- 'RexxRegisterSubcomDll',
                           address(SubcomName) ||
                           address(SubcomDll)  ||
                           address(SubcomProc) ||
                           address(UserArea)   ||
                           atol(0))
      if result = 10 then  -- 10 = RXSUBCOM_DUP; registration was successful.
         result=0
      endif
      return result
   endif
   return 0

; ---------------------------------------------------------------------------
defproc rexxsubcomdrop()
   scbname     = 'EPM'\0
   scbdll_name = ERES_DLL\0
   result = dynalink32( 'REXXAPI',
                        'RexxDeregisterSubcom',
                         address(scbname)   ||
                         address(scbdll_name))
   return result

; ---------------------------------------------------------------------------
; Call the PIPEDLL dynamic link library.
; This function will start a window and allows
; interaction with the standard input and standard output of EPM.
defc rxshell=
   if arg(1) = '' then
      string = 'PMMORE.EXE'\0
   else
      string = arg(1)\0
   endif
   result = dynalink32( ERES_DLL,                  /* dynamic link library name       */
                        'PipeStartExecution',      /* input function                  */
                        address(string))           /* command to execute              */


; ---------------------------------------------------------------------------
; Register the EPM functions.
defproc rexxfunctionregister()
   functionname = 'all'\0
   result = dynalink32( ERES_DLL,                 /* dynamic link library name  */
                        'EtkRexxFunctionRegister',  /* Rexx input function        */
                        address(functionname))
   if result then
       call messagenwait( ERES_DLL': ETKREXXFUNCTIONREGISTER: rc='result);
   endif
   return result


; ---------------------------------------------------------------------------
;                                 PART 2
; ---------------------------------------------------------------------------
;       Define some procedures as commands to make them usable in REXX
; ---------------------------------------------------------------------------
defc buildsubmenu
   parse arg menuname submenuid submenutext attrib helppanel e_command
   buildsubmenu menuname, submenuid, submenutext, e_command, attrib, helppanel

; ---------------------------------------------------------------------------
defc buildmenuitem
   parse arg menuname submenuid menuitemid submenutext attrib helppanel e_command
   buildmenuitem menuname, submenuid, menuitemid, submenutext, e_command, attrib, helppanel

; ---------------------------------------------------------------------------
defc showmenu
   universal activemenu, defaultmenu
   activemenu = arg(1)
   if activemenu = defaultmenu then
      call showmenu_activemenu()  -- This handles the posting of cascademenu cmds, if necessary.
   else
      showmenu activemenu         -- Just show the updated EPM menu
   endif

; ---------------------------------------------------------------------------
defc deletemenu
   parse arg menuname submenuid menuitemid itemonly
   deletemenu menuname, submenuid, menuitemid, itemonly

; ---------------------------------------------------------------------------
defc showlist
   if arg(1) <> '' then
      return listbox( 'List', arg(1))
   endif

; ---------------------------------------------------------------------------
defc sayerror = sayerror arg(1)

; ---------------------------------------------------------------------------
defc buildaccel
   universal activeaccel
   parse arg table flags key index command
   if table = '*' then
      table = activeaccel
   endif
   buildacceltable table, command, flags, key, index

; ---------------------------------------------------------------------------
defc activateaccel
   universal activeaccel
   parse arg newtable .
   if newtable <> '' then
      activeaccel = newtable
   endif
   activateacceltable activeaccel

; ---------------------------------------------------------------------------
defc register_mouse
   parse arg which button action shifts command
   call register_mousehandler( which, button action shifts, command)

; ---------------------------------------------------------------------------
defc display
   display arg(1)

; ---------------------------------------------------------------------------
defc refresh
   refresh

; ---------------------------------------------------------------------------
defc universal
   universal default_search_options, default_edit_options, default_save_options
   universal defload_profile_name
   parse arg varname varvalue
   varname = upcase(varname)
   if varname='DEFAULT_SEARCH_OPTIONS' then
;     if varvalue='' then           -- Removed this; want to give the user the ability to set to null.
;        sayerror varname '=' default_search_options
;     else
         default_search_options = varvalue
;     endif
   elseif varname='DEFAULT_EDIT_OPTIONS' then
         default_edit_options = varvalue
   elseif varname='DEFAULT_SAVE_OPTIONS' then
         default_save_options = varvalue
   elseif varname='DEFLOAD_PROFILE_NAME' then
         defload_profile_name = varvalue
   else
      sayerror -263  -- Invalid argument
   endif

; ---------------------------------------------------------------------------
defc Insert_attr_val_Pair
   parse arg class attr_val fstline lstline fstcol lstcol fid
   if attr_val = '' | (fstline <> '' & lstcol = '') then
      sayerror -263  -- Invalid argument
      return
   endif
   mt = marktype()
   if fstline = '' then  -- assume mark
      if mt = '' then
         sayerror NO_MARK__MSG
         return
      endif
      getmark fstline, lstline, fstcol, lstcol, fid
   else
      mt = 'CHAR'
   endif
   if fid = '' then   -- default to current file
      getfileid fid
   endif
   if leftstr( mt, 5) = 'BLOCK' then
      do i = fstline to lstline
         Insert_Attribute_Pair( class, attr_val, i, i, fstcol, lstcol, fid)
      enddo
   else
      if mt = 'LINE' then
         getline line, lstline, mkfileid
         lstcol = length(line)
      endif
      Insert_Attribute_Pair( class, attr_val, fstline, lstline, fstcol, lstcol, fid)
   endif

; ---------------------------------------------------------------------------
defc Insert_attribute
   parse arg class attr_val IsPush offst col line fid junk
   if offst = '' | junk <> '' then
      sayerror -263  -- Invalid argument
      return
   endif
   if fid = '' then   -- default to current file
      getfileid fid
      if line = '' then   -- default to current file
         line = .line
         if col = '' then   -- default to current file
            col = .col
         endif
      endif
   endif
   insert_attribute class, attr_val, IsPush, offst, col, line, fid

; ---------------------------------------------------------------------------
defc attribute_on
   if isnum(arg(1)) then
      call attribute_on(arg(1))
   else
      sayerror -263  -- Invalid argument
   endif

; ---------------------------------------------------------------------------
;                          .userstring commands
;                see getmode.erx for an example and descriptions
; ---------------------------------------------------------------------------
defc saveuserstring
   universal saveduserstring
   saveduserstring = .userstring

; ---------------------------------------------------------------------------
defc restoreuserstring
   universal saveduserstring
   .userstring = saveduserstring

; ---------------------------------------------------------------------------
defc FileAVar2Userstring, field2userstring
   universal EPM_utility_array_id
   AVarName = arg(1)
   getfileid fid
   rc = get_array_value( EPM_utility_array_id, AVarName'.'fid, CurValue)
   .userstring = CurValue

; ---------------------------------------------------------------------------
defc AVar2Userstring
   universal EPM_utility_array_id
   AVarName = arg(1)
   rc = get_array_value( EPM_utility_array_id, AVarName, CurValue)
   .userstring = CurValue


