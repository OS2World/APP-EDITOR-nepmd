/****************************** Module Header *******************************
*
* Module Name: info.e
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
@@NepmdInfo@PROTOTYPE
NepmdInfo()

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
*NepmdInfo* returns nothing.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdInfo@REMARKS
Note that any existing file in the ring named *.NEPMD__INFO*
is discarded before the current file is being created.

@@NepmdInfo@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdInfo*

Executing this command will open up a virtual file and
write all information related to *EPM* and the [=TITLE] into it.

The contents of this file may be useful when reporting the
configuration of your system and the installation of your
[=TITLE] to the project team in order to allow us to help you.

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
; This command is executed from the menu and should be available from cammand
; line.

defc NepmdInfo
   call NepmdInfo()

; ---------------------------------------------------------------------------
; Procedure: NepmdInfo
; ---------------------------------------------------------------------------
; E syntax:
;    NepmdInfo()
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdInfo( HWND hwndClient);
; ---------------------------------------------------------------------------

defproc NepmdInfo
   InfoFilename = '.NEPMD_INFO'

   -- Check if old info file already in ring
   getfileid oldinfofid, InfoFilename
   if oldinfofid <> '' then
      -- Discard previously loaded info file from ring
      getfileid curfid
      if curfid = oldinfofid then
         -- Quit current file
         'xcom quit'
      else
         -- Temporarily switch to old info file and quit it
         activatefile oldinfofid
         'xcom quit'
         activatefile curfid
      endif
   endif

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    'NepmdInfo',
                    gethwndc( EPMINFO_EDITCLIENT))

   helperNepmdCheckliberror( LibFile, rc)

   -- Make file discardable
   .modify = 0

   return

; ---------------------------------------------------------------------------
;   Helper commands used by the C routine 'NepmdInfo'
; ---------------------------------------------------------------------------
;   Some values can only be queried by E commands, so they're
;   defined here to get executed by the C routine.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Insert a line with version of ETK DLLs after the current.
; Used by nepmdinfo.
defc InsertEditorVersion
   MsgName = 'STR_INFO_EDITORVERSION'

   n = 1
   insertline NepmdGetTextMessage( '', MsgName, ver(0)), .line + n

; ---------------------------------------------------------------------------
; Insert a line with version of NEPMD after the current.
; Used a const from STDCONST.E, contained in EPM.E.
; Used by nepmdinfo.
defc InsertNepmdVersion
   MsgName = 'STR_INFO_NEPMDVERSION'

   n = 1
   insertline NepmdGetTextMessage( '', MsgName, GetNepmdVersion()), .line + n

; ---------------------------------------------------------------------------
; Insert a line with version of EPM macros after the current.
; Used by nepmdinfo.
; The const EVERSION is supplied automatically by the ETPM compiler.
defc InsertMacrosVersion
   MsgName = 'STR_INFO_MACROSVERSION'

   if isadefproc( 'GetEVersion') then
      -- In NEPMD, there should exist this proc
      MacrosVersion = GetEVersion()
   else
      -- This should not happen
      MacrosVersion = EVERSION' (queried from NEPMDLIB.EX)'
   endif

   n = 1
   insertline NepmdGetTextMessage( '', MsgName, MacrosVersion), .line + n

; ---------------------------------------------------------------------------
; Insert a line with path info of EPM.EX after the current
; Used by nepmdinfo.
defc InsertLoaderVersion
   MsgName = 'STR_INFO_NEPMDMODULESTAMP'

   Loader = get_env( 'NEPMD_LOADEREXECUTABLE')
   Loader = NepmdQueryFullName( Loader)
   lp = lastpos( '\', Loader)
   Name = substr( Loader, lp + 1)
   Name = substr( Name, 1, max( 12, min( 12, length(Name))))  -- len = 12, keep in sync with NepmdLib
   Path = substr( Loader, 1, max( 0, lp - 1))
   TStamp = NepmdQueryPathInfo( Loader, 'MTIME')

   n = 1
   insertline NepmdGetTextMessage( '', MsgName, Name, TStamp, Path), .line + n

; ---------------------------------------------------------------------------
; Insert lines with path info of EPM.EX and other linked .ex files after the current.
; Used by nepmdinfo.
defc InsertExVersions
   MsgName = 'STR_INFO_NEPMDMODULESTAMP'

   -- Add epm.ex
   EpmEx = wheredefc( 'versioncheck')
   EpmEx = NepmdQueryFullName( EpmEx)
   lp = lastpos( '\', EpmEx)
   Name = substr( EpmEx, lp + 1)
   Name = substr( Name, 1, max( 12, min( 12, length(Name))))  -- len = 12, keep in sync with NepmdLib
   Path = substr( EpmEx, 1, max( 0, lp - 1))
   TStamp = NepmdQueryPathInfo( EpmEx, 'MTIME')

   n = 1
   insertline NepmdGetTextMessage( '', MsgName, Name, TStamp, Path), .line + n

   -- Find more linked .ex files
   AutolinkDir = get_env( 'NEPMD_USERDIR')'\autolink'
   EpmPath = get_env( 'EPMPATH')';'
   rest = AutoLinkDir';'EpmPath
   ExFileList = ''
   do while rest <> ''
      parse value rest with Path';'rest
      if Path = '' then
         iterate
      endif
      Handle = 0
      FileMask = Path'\*.ex'

      do while NepmdGetNextFile( FileMask, Handle, ExFile)
         ExFile = NepmdQueryFullName( ExFile)

         -- Ignore EPM.EX
         if upcase( ExFile) = upcase( EpmEx) then
            iterate
         endif

         -- Ignore not linked files
         ret = linked( ExFile)
            -- -307  -- sayerror("Link: file not found")
            -- -308  -- sayerror("Link: invalid filename")
            -- < 0   -- exists but not linked
         if ret < 0 then
            iterate
         endif

         -- Check if already processed. Maybe Path is multiple times in EpmPath.
         fAlreadyProcessed = 0
         restlist = upcase( ExFileList)
         do while restlist <> ''
            parse value restlist with next';'restlist  -- ; is separator
            if upcase( ExFile) = next then
               fAlreadyProcessed = 1
               leave
            endif
         enddo
         if fAlreadyProcessed then
            iterate
         endif

         ExFileList = ExFileList''ExFile';'  -- ; is separator
         lp = lastpos( '\', ExFile)
         Name = substr( ExFile, lp + 1)
         Name = substr( Name, 1, max( 12, min( 12, length(Name))))  -- len = 12, keep in sync with NepmdLib
         Path = substr( ExFile, 1, max( 0, lp - 1))
         TStamp = NepmdQueryPathInfo( ExFile, 'MTIME')

         n = n + 1
         insertline NepmdGetTextMessage( '', MsgName, Name, TStamp, Path), .line + n
      enddo

   enddo

