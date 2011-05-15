/****************************** Module Header *******************************
*
* Module Name: info.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
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
@@NepmdInfo@PROTOTYPE
rc = NepmdInfo();

@@NepmdInfo@CATEGORY@INSTALL

@@NepmdInfo@SYNTAX
This function creates a virtual file named *.NEPMD__INFO*
within the file ring of the active EPM window
and writes runtime information into it like for example about
.ul compact
- the *NEPMD* modules loaded and config files used
- the loaded *EPM* modules
.el

@@NepmdInfo@RETURNS
*NepmdInfo* returns an OS/2 error code or zero for no error.

@@NepmdInfo@REMARKS
Note that any existing file in the ring named *.NEPMD__INFO*
is dscarded before the current file is being created.

@@NepmdInfo@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdInfo*

Executing this command will
open up a virtual file and
write all information related to *EPM* and the [=TITLE] into it.

The contents of this file may be useful when reporting the
configuration of your system and the installation of your
[=TITLE] to the project team in order to allow us to help you.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
; We want this command also if included in EPM.E to call it from
; the command line or from an menu item.

defc NepmdInfo
   rc = NepmdInfo()
   return

/* ------------------------------------------------------------- */
/* procedure: NepmdInfo                                          */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdInfo();                                          */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdInfo( HWND hwndClient);                 */
/* ------------------------------------------------------------- */

defproc NepmdInfo
   InfoFilename = '.NEPMD_INFO'

   -- check if old info file already in ring
   getfileid oldinfofid, InfoFilename
   if oldinfofid <> '' then
      -- discard previously loaded info file from ring
      getfileid curfid
      if curfid = oldinfofid then
         -- quit current file
         'xcom quit'
      else
         -- temporarily switch to old info file and quit it
         activatefile oldinfofid
         'xcom quit'
         activatefile curfid
      endif
   endif

   -- call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    'NepmdInfo',
                    gethwndc( EPMINFO_EDITCLIENT))

   helperNepmdCheckliberror( LibFile, rc)

   -- make id discardable
   .modify = 0

   return rc

/* ------------------------------------------------------------- */
/*   Helper commands used by the C routine 'NepmdInfo'           */
/* ------------------------------------------------------------- */
/*   Some values can only be queried by E commands, so they're   */
/*   defined here to get executed by the C routine.              */
/* ------------------------------------------------------------- */

; Insert a line with version of ETK DLLs after the current.
; Used by nepmdinfo.
defc InsertEditorVersion
   MsgName = 'STR_INFO_EDITORVERSION'
   insertline NepmdGetTextMessage( '', MsgName, ver(0)), .line + 1
   return

; Insert a line with version of NEPMD after the current.
; Used a const from STDCONST.E, contained in EPM.E.
; Used by nepmdinfo.
defc InsertNepmdVersion
   MsgName = 'STR_INFO_NEPMDVERSION'
   insertline NepmdGetTextMessage( '', MsgName, GetNepmdVersion()), .line + 1
   return

; Insert a line with version of EPM macros after the current.
; Used by nepmdinfo.
; The const EVERSION is supplied automatically by the ETPM compiler.
defc InsertMacrosVersion
   MsgName = 'STR_INFO_MACROSVERSION'
   if isadefproc('GetEVersion') then
      -- In NEPMD, there should exist this proc
      MacrosVersion = GetEVersion()
   else
      -- This should not happen
      MacrosVersion = EVERSION' (queried from NEPMDLIB.EX)'
   endif
   insertline NepmdGetTextMessage( '', MsgName, MacrosVersion), .line + 1
   return

; Insert a line with path info of EPM.EX after the current
; Used by nepmdinfo.
defc InsertLoaderVersion
   MsgName = 'STR_INFO_NEPMDMODULESTAMP'
   Loader = get_env('NEPMD_LOADEREXECUTABLE')
   Loader = NepmdQueryFullName(Loader)
   lp = lastpos( '\', Loader)
   Name = substr( Loader, lp + 1)
   Name = substr( Name, 1, max( 12, min( 12, length(Name))))  -- len = 12, keep in sync with NepmdLib
   Path = substr( Loader, 1, max( 0, lp - 1))
   TStamp = NepmdQueryPathInfo( Loader, 'MTIME')
   n = 1
   insertline NepmdGetTextMessage( '', MsgName, Name, TStamp, Path), .line + n
   return

; Insert lines with path info of EPM.EX and other linked .ex files after the current.
; Used by nepmdinfo.
defc InsertExVersions
   MsgName = 'STR_INFO_NEPMDMODULESTAMP'
   EpmEx = wheredefc('versioncheck')
   EpmEx = NepmdQueryFullName(EpmEx)
   lp = lastpos( '\', EpmEx)
   Name = substr( EpmEx, lp + 1)
   Name = substr( Name, 1, max( 12, min( 12, length(Name))))  -- len = 12, keep in sync with NepmdLib
   Path = substr( EpmEx, 1, max( 0, lp - 1))
   TStamp = NepmdQueryPathInfo( EpmEx, 'MTIME')
   n = 1
   insertline NepmdGetTextMessage( '', MsgName, Name, TStamp, Path), .line + n
   -- find more linked .ex files
   AutolinkDir = get_env('NEPMD_USERDIR')'\autolink'
   EpmPath = get_env('EPMPATH')';'
   rest = AutoLinkDir';'EpmPath
   ExFileList = ''
   do while rest <> ''
      parse value rest with Path';'rest
      if Path = '' then
         iterate
      endif
      Handle = 0
      AddressOfHandle = address(Handle)
      FileMask = Path'\*.ex'
      do forever
         ExFile = NepmdGetNextFile( FileMask, AddressOfHandle)
         parse value ExFile with 'ERROR:'rc
         if (rc > '') then
            leave
         endif
         -- ignore EPM.EX
         ExFile = NepmdQueryFullName(ExFile)
         if upcase(ExFile) = upcase(EpmEx) then
            iterate
         endif
         ret = linked(ExFile)
            -- -307  -- sayerror("Link: file not found")
            -- -308  -- sayerror("Link: invalid filename")
            -- < 0   -- exists but not linked
         if ret < 0 then
            iterate
         endif
         -- Check if already processed. Maybe Path is multiple times in EpmPath.
         AlreadyProcessed = 0
         restlist = upcase(ExFileList)
         do while restlist <> ''
            parse value restlist with next';'restlist  -- ; is separator
            if upcase(ExFile) = next then
               AlreadyProcessed = 1
               leave
            endif
         enddo
         if AlreadyProcessed = 0 then
            ExFileList = ExFileList''ExFile';'  -- ; is separator
            lp = lastpos( '\', ExFile)
            Name = substr( ExFile, lp + 1)
            Name = substr( Name, 1, max( 12, min( 12, length(Name))))  -- len = 12, keep in sync with NepmdLib
            Path = substr( ExFile, 1, max( 0, lp - 1))
            TStamp = NepmdQueryPathInfo( ExFile, 'MTIME')
            n = n + 1
            insertline NepmdGetTextMessage( '', MsgName, Name, TStamp, Path), .line + n
         endif
      enddo
   enddo
   return

