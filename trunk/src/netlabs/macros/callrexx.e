/****************************** Module Header *******************************
*
* Module Name: callrexx.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: callrexx.e,v 1.2 2002-07-22 18:59:04 cla Exp $
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
   RXCOMMAND       = '0'
   RXSUBROUTINE    = '1'          -- Program called as Subroutine
   RXFUNCTION      = '2'
   RXFUNC_DYNALINK = '1'          -- Function Available in DLL
   RXFUNC_CALLENTRY ='2'          -- Registered as mem entry pt.

compile if not defined(ERES_DLL)  -- Being compiled separately?  (For debug use...)
   include 'STDCONST.E'
   include 'ENGLISH.E'
compile endif

defc epmrexx,rx=
   parse value arg(1) with  macro getall
   if macro='' then
      sayerror RX_PROMPT__MSG
      return
   endif
   call parse_filename(macro, .filename)
   if not pos('.',substr(macro,lastpos('\',macro)+1)) then
      macro=macro||'.erx'   /* add the default extention */
   endif
              /* Try to register the subcommand interface */
   rc= rexxsubcomregister()
   if rc then
      sayerror RX_SUBCOM_FAIL__MSG rc
      return
   endif
   rc= rexxfunctionregister()
   if rc then
      sayerror RX_FUNC_FAIL__MSG rc
      return
   endif
;  string=atol(length(getall))||offset(getall)||selector(getall)
   /*
    *    Call the macro named by the macro variable
    *    The default environment is "ERXSUBCOM".
    *    The EPM subcommand DLL is "ERXSBCOM.DLL".
    */
;  sayerror 'EPM REXX macro "'macro'" running...'
   functionname =macro\0
;  saveautoshell = .autoshell
;  .autoshell = 0

; Allocate buffer for string, functionname, envname, rcresult, and resultstring.
;                                           'ENV'\0   2 bytes       8 bytes
;  len = length(string) + length(functionname) + length(envname) + 2 + 8
;  string_ofs = 0
   func_ofs = 8  -- length(string)
   env_ofs = func_ofs + length(functionname)
   rc_ofs = env_ofs + 4
compile if EPM32
   res_ofs = rc_ofs + 4  -- return code is a long
compile else
   res_ofs = rc_ofs + 2  -- return code is a short
compile endif
   parm_ofs = res_ofs + 8
   len = parm_ofs + length(getall)
compile if 0 -- POWERPC  -- mymalloc returns a long; keep it as is
   bufhndla = dynalink32(E_DLL, 'mymalloc', atol(len), 2)
   bufhndl  = atol(bufhndla)
   r = -270 * (bufhndla = 0)
compile elseif EPM32  -- mymalloc returns a long; we split off selector.
   bufhndl  = substr(atol(dynalink32(E_DLL, 'mymalloc', atol(len), 2)), 3, 2)
   bufhndla =  ltoa(bufhndl\0\0, 10)
   r = -270 * (bufhndla = 0)
compile else
   bufhndl = "??"                  -- initialize string pointer
   r =  dynalink('DOSCALLS',           -- dynamic link library name
            '#34',                     -- DosAllocSeg
            atoi(len)              ||  -- Number of Bytes requested
            address(bufhndl)   ||
            atoi(0))                   -- Share information
   bufhndla = itoa(bufhndl,10)
compile endif

   if r | not bufhndla then sayerror 'Error 'r' allocating memory segment; command halted.'; stop; endif
;  poke bufhndla, 0, string  -- assume string_ofs = 0
compile if 0 --POWERPC
   poke bufhndla, 0, atol(length(getall))||atol(parm_ofs + bufhndla)
compile else
   poke bufhndla, 0, atol(length(getall))||atoi(parm_ofs)||bufhndl
compile endif
   poke bufhndla, func_ofs, functionname
   poke bufhndla, env_ofs, 'EPM'\0
   poke bufhndla, parm_ofs, getall

compile if EPM32
   result=dynalink32('REXX',                   -- dynamic link library name
                     '#1',   -- 'RexxStart',   -- Rexx input function
                     atol(1)                || -- Num of args passed to rexx
 compile if 0 --POWERPC
                     bufhndl                || -- Address of Arglist
                     atol(bufhndla+func_ofs)|| -- Address of program name
                     atol(0)                || -- Loc of rexx proc in memory
                     atol(bufhndla+env_ofs) || -- Address of ASCIIZ initial environment.
                     atol(RXCOMMAND )       || -- type (command,subrtn,funct)
                     atol(0)                || -- SysExit env. names &  codes
                     atol(bufhndla+rc_ofs)  || -- Address Ret code from if numeric
                     atol(bufhndla+res_ofs))   -- Address Retvalue from the rexx proc
 compile else
                     \0\0                   || -- offset of Arglist
                     bufhndl                || -- selector of "
                     atoi(func_ofs)         || -- offset of program name
                     bufhndl                || -- selector of "
                     atol(0)                || -- Loc of rexx proc in memory
                     atoi(env_ofs)          || -- offset of env.
                     bufhndl                || -- sel. ASCIIZ initial environment.
                     atol(RXCOMMAND )       || -- type (command,subrtn,funct)
                     atol(0)                || -- SysExit env. names &  codes
                     atoi(rc_ofs)           || -- offset Ret code from if numeric
                     bufhndl                || -- sel. Ret code from if numeric
                     atoi(res_ofs)          || -- offset Retvalue from the rexx proc
                     bufhndl)                  -- selector of "
 compile endif -- POWERPC
compile else
   result=dynalink('REXX',                   -- dynamic link library name
                   'REXXSAA',                -- Rexx input function
                   atoi(1)                || -- Num of args passed to rexx
                   bufhndl                || -- Array of args passed to rex
                   \0\0                   || --
                   bufhndl                || -- [d:][path] filename[.ext]
                   atoi(func_ofs)         || --
                   atol(0)                || -- Loc of rexx proc in memory
                   bufhndl                || -- ASCIIZ initial environment.
                   atoi(env_ofs)          || --
                   atoi(RXCOMMAND )       || -- type (command,subrtn,funct)
                   atol(0)                || -- SysExit env. names &  codes
                   bufhndl                || -- Ret code from proc if numeric
                   atoi(rc_ofs)           || --  "
                   bufhndl                || -- Retvalue from the rexx proc
                   atoi(res_ofs) )           --  "
compile endif

;  .autoshell = saveautoshell
   rc= rexxsubcomdrop()
      if rc then
         sayerror RX_SUBCOM_FAIL__MSG rc
;;       return
      endif
   if result then
      rc = result
      if result=-3 | result=65533 then
         result = result':  'FILE_NOT_FOUND__MSG '('macro')'
      endif
      sayerror 'Rexx:  'ERROR__MSG result
   else
compile if EPM32         -- return code is a long
      rc = ltoa(peek(bufhndla, rc_ofs, 4) ,10)  -- Set universal RC for use by callers.
compile else             -- return code is a short
      rc = itoa(peek(bufhndla, rc_ofs, 2) ,10)  -- Set universal RC for use by callers.
compile endif
   endif
/* debug info...
   rcresult = peek(bufhndla,rc_ofs,2)
   resultstring = peek(bufhndla,res_ofs,8)
   peekseg=itoa(substr( resultstring ,7 ,2),10)
   peekoff=itoa(substr( resultstring ,5 ,2),10)
   peeklen=ltoa(substr( resultstring ,1 ,4),10)
   sayerror 'result='result'; Input <'||getall||'>  and the result from REXX is <'|| peek(peekseg,peekoff,peeklen)||'>; rc='rc
*/
compile if EPM32
   call dynalink32(E_DLL,         -- dynamic link library name
                   'myfree',                   -- DosFreeSeg
;compile if not POWERPC  -- For PowerPC, bufhndl is an address; don't need to
                   atoi(0) ||  -- add an offset to make the selector an address
;compile endif
                   bufhndl)
compile else
   call dynalink('DOSCALLS',         -- dynamic link library name
            '#39',                   -- DosFreeSeg
            bufhndl)
compile endif

defc rxme =  -- Invoke current file as a Rexx macro, passing it the arguments specified (if any).
   if .modify then
      result = winmessagebox("RxMe", MODIFIED_PROMPT__MSG, MB_YESNOCANCEL + MB_ICONQUESTION + MB_MOVEABLE)
      if result=MBID_YES then
         'save'
      elseif result=MBID_NO then
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

/*
 *    Register the EPM subcommand DLL.
 *    Store the EPM window handle in the Rexx subcommand user area.
 */
defproc rexxsubcomregister()
compile if EPM32
   pib = 1234
   tid = 1234

   call dynalink32('DOSCALLS',      /* dynamic link library name       */
                   '#312',           /* ordinal value for DOS32GETINFOBLOCKS */
                   address(tid) ||
                   address(pib), 2)

    pid = peek32(ltoa(pib, 10), 0, 4)

compile else
   string='LarryM'
   call dynalink('DOSCALLS',      /* dynamic link library name       */
                 '#94',           /* ordinal value for DOSGETPID     */
                 address(string) )    /* stack string                    */
   pid=itoa(string,10)
compile endif

compile if EPM32
  SubcomName='EPM'\0
  SubcomDLL =ERES_DLL\0
  SubcomProc='ERESREXX'\0
  UserArea  =atol(getpminfo(EPMINFO_EDITCLIENT)) || pid

  result=dynalink32('REXXAPI',
                    '#6',        -- 'RexxRegisterSubcomDll',
                    address(SubcomName) ||
                    address(SubcomDll)  ||
                    address(SubcomProc) ||
                    address(UserArea)   ||
                    atol(0))

   if result & result<>10 then  -- 10 = RXSUBCOM_DUP; registration was successful.
      result=dynalink32('REXXAPI',
                        '#9',       -- 'RexxDeregisterSubcom',
                         address(SubcomName) ||
                         address(SubcomDll) )
      if result & result<>30 then   -- 30 = RXSUBCOM_NOTREG
         return result
      endif

      result=dynalink32('REXXAPI',
                        '#6', -- 'RexxRegisterSubcomDll',
                        address(SubcomName) ||
                        address(SubcomDll)  ||
                        address(SubcomProc) ||
                        address(UserArea)   ||
                        atol(0))
      if result=10 then  result=0; endif  -- 10 = RXSUBCOM_DUP; registration was successful.
      return result
   endif
compile else
   scbname='EPM'\0
   scbdll_name=ERES_DLL\0
   scbproc_name='ERESREXX'\0
   subcomblock= atol(0)||                           /* pointer to the next block  */
      offset(scbname)||selector(scbname)||          /* subcom environment name    */
      offset(scbdll_name)||selector(scbdll_name)||  /* subcom module name         */
      offset(scbproc_name)||selector(scbproc_name)||/* subcom procedure name      */
      atol(getpminfo(EPMINFO_EDITCLIENT))||atol(pid)||  /* user area                  */
      atol(0)||                                     /* subcom environment address */
      atoi(0)||                                     /* dynalink module handle     */
      atoi(0)||                                     /* Permission to drop         */
      atoi(0)||                                     /* Pid of Registrant          */
      atoi(0)                                       /* Session ID.                */

   result=dynalink('REXXAPI',              /* dynamic link library name       */
                   'RXSUBCOMREGISTER',     /* Rexx input function             */
                   address(subcomblock))

   if result & result<>10 then  -- 10 = RXSUBCOM_DUP; registration was successful.
      result=dynalink('REXXAPI',         /* dynamic link library name       */
                      'RXSUBCOMDROP',     /* Rexx input function             */
                      address(scbname)||
                      address(scbdll_name))
        if result then
           return result
        endif
        result=dynalink('REXXAPI',         /* dynamic link library name       */
                   'RXSUBCOMREGISTER',     /* Rexx input function             */
                   address(subcomblock))
      if result=10 then  result=0; endif  -- 10 = RXSUBCOM_DUP; registration was successful.
      return result
   endif
compile endif
return 0

defproc rexxsubcomdrop()
   scbname='EPM'\0
   scbdll_name=ERES_DLL\0
compile if EPM32
   result=dynalink32('REXXAPI',
                     'RexxDeregisterSubcom',
                      address(scbname)   ||
                      address(scbdll_name) )
compile else
   scbproc_name='ERESREXX'\0
   result=dynalink('REXXAPI',         /* dynamic link library name       */
                  'RXSUBCOMDROP',     /* Rexx input function             */
                  address(scbname)||
                  address(scbdll_name))
compile endif
   return result

/*
 *    Call the PIPEDLL dynamic link library.
 *    This function will start a window and allows
 *    interaction with the standard input and standard output of EPM.
 */
defc rxshell=
   if arg(1)='' then
      string='PMMORE.EXE'\0
   else
      string=arg(1)\0
   endif
compile if EPM32
   result=dynalink32(ERES_DLL,                  /* dynamic link library name       */
                     'PipeStartExecution',      /* input function                  */
                     address(string) )          /* command to execute              */
compile else
   result=dynalink(ERES_DLL,                  /* dynamic link library name       */
                   'PIPESTARTEXECUTION',      /* input function                  */
                   address(string))           /* command to execute              */
compile endif


/*
 *    Register the EPM functions.
 */
defproc rexxfunctionregister()
   functionname='all'\0
compile if EPM32
   result=dynalink32(ERES_DLL,                 /* dynamic link library name  */
                    'EtkRexxFunctionRegister',  /* Rexx input function        */
                    address(functionname))
compile else
   result=dynalink(ERES_DLL,                 /* dynamic link library name  */
                   'ETKREXXFUNCTIONREGISTER',  /* Rexx input function        */
                   address(functionname))
compile endif
   if result then
       call messagenwait(ERES_DLL': ETKREXXFUNCTIONREGISTER: rc='result);
   endif
   return result

defc buildsubmenu
   parse arg menuname submenuid submenutext attrib helppanel e_command
   buildsubmenu menuname, submenuid, submenutext, e_command, attrib, helppanel

defc buildmenuitem
   parse arg menuname submenuid menuitemid submenutext attrib helppanel e_command
   buildmenuitem menuname,submenuid,menuitemid,submenutext,e_command,attrib,helppanel

defc showmenu
   universal activemenu, defaultmenu
   activemenu = arg(1)
   if activemenu=defaultmenu then
      call showmenu_activemenu()  -- This handles the posting of cascademenu cmds, if necessary.
   else
      showmenu activemenu         -- Just show the updated EPM menu
   endif

defc deletemenu
   parse arg menuname submenuid menuitemid itemonly
   deletemenu menuname, submenuid, menuitemid, itemonly

defc showlist
   if arg(1)<>'' then
      return listbox('List',arg(1));
   endif

defc sayerror = sayerror arg(1)

defc buildaccel
   universal activeaccel
   parse arg table flags key index command
   if table='*' then
      table = activeaccel
   endif
   buildacceltable table, command, flags, key, index

defc activateaccel
   universal activeaccel
   parse arg newtable .
   if newtable <> '' then
      activeaccel = newtable
   endif
   activateacceltable activeaccel

defc register_mouse
   parse arg which button action shifts command
   call register_mousehandler(which, button action shifts, command)

defc display
   display arg(1)

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

defc Insert_attr_val_Pair
   parse arg class attr_val fstline lstline fstcol lstcol fid
   if attr_val='' | (fstline<>'' & lstcol='') then
      sayerror -263  -- Invalid argument
      return
   endif
   mt = marktype()
   if fstline='' then  -- assume mark
      if mt='' then
         sayerror NO_MARK__MSG
         return
      endif
      getmark fstline, lstline, fstcol, lstcol, fid
   else
      mt = 'CHAR'
   endif
   if fid='' then   -- default to current file
      getfileid fid
   endif
   if leftstr(mt,5)='BLOCK' then
      do i = fstline to lstline
         Insert_Attribute_Pair(class, attr_val, i, i, fstcol, lstcol, fid)
      enddo
   else
      if mt='LINE' then
         getline line, lstline, mkfileid
         lstcol=length(line)
      endif
      Insert_Attribute_Pair(class, attr_val, fstline, lstline, fstcol, lstcol, fid)
   endif

defc Insert_attribute
   parse arg class attr_val IsPush offst col line fid junk
   if offst='' | junk<>'' then
      sayerror -263  -- Invalid argument
      return
   endif
   if fid='' then   -- default to current file
      getfileid fid
      if line='' then   -- default to current file
         line = .line
         if col='' then   -- default to current file
            col = .col
         endif
      endif
   endif
   insert_attribute class, attr_val, IsPush, offst, col, line, fid

defc attribute_on
   if isnum(arg(1)) then
      call attribute_on(arg(1))
   else
      sayerror -263  -- Invalid argument
   endif
