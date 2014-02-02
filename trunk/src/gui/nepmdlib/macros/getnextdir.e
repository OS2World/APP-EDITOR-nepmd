/****************************** Module Header *******************************
*
* Module Name: getnextdir.e
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
@@NepmdGetNextDir@PROTOTYPE
Flag = NepmdGetNextDir( DirMask, Handle, NextDirname)

@@NepmdGetNextDir@CATEGORY@DIR

@@NepmdGetNextDir@SYNTAX
This function implements an easy directory lookup
for subdirectories with one function. For that it needs to be
[.IDPNL_EFUNC_NEPMDGETNEXTDIR_EXAMPLE called in a loop].

@@NepmdGetNextDir@PARM@DirMask
This parameter specifies the dirs to be searched
and may contain wildcards.

@@NepmdGetNextDir@PARM@Handle
This parameter must be a variable. It specifies the handle used for the
search.

Note that on the first call to NepmdGetNextDir() the value
of the variable holding the handle must be set to '' or to
GETNEXT__CREATE__NEW__HANDLE in order to initiate a new search.

The used handle is stored in this parameter.

@@NepmdGetNextDir@PARM@NextDirname
This parameter must be a variable. It should be set to '' when specified.

The next found dirname is stored in this parameter.

@@NepmdGetNextDir@EXAMPLE
The following code searches all subdirectories within the directory C:\OS2:
.fo off
 DirMask     = 'C:\OS2\**'
 Handle       = ''  -- always create a new handle
 NextDirname = ''

 -- Search all dirs
 do while NepmdGetNextDir( DirMask, Handle, NextDirname)
    -- Process subdirectory - here as a sample we display a popup
    messagenwait( 'Dir found:' NextDirname)
 enddo
.fo on

@@NepmdGetNextDir@REMARKS
The search handle created by *NepmdGetNextDir* is automatically closed
if the search is repeated until no more entries are available.

If a search for dirs is interrupted for any reason before receiving
the error code 18 (ERROR__NO__MORE__FILES), the search handle is closed
automatically by a call to [.IDPNL_EFUNC_NEPMDGETNEXTCLOSE].

@@NepmdGetNextDir@RETURNS
*NepmdGetNextDir* returns either
.ul compact
- *0* (zero), if no more dirs exist or on error
- *1*, if next directory name was queried successfully.

The next dirname returned by the search is stored in the
[.IDPNL_EFUNC_NEPMDGETNEXTDIR_PARM_NEXTDIRNAME NextDirname] parameter.

The search handle returned by the search is stored in the
[.IDPNL_EFUNC_NEPMDGETNEXTDIR_PARM_HANDLE Handle] parameter.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.
rc is set to 18 = ERROR__NO__MORE__FILES if no directory name was found.

@@NepmdGetNextDir@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetNextDir* [.IDPNL_EFUNC_NEPMDGETNEXTDIR_PARM_DIRMASK dirmask]
  - or
- *GetNextDir* [.IDPNL_EFUNC_NEPMDGETNEXTDIR_PARM_DIRMASK dirmask]

Executing this command will
open up a virtual file and
write all found directories into it.

*Example:*
.fo off
 GetNextDir c:\os2\**
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdGetNextDir, GetNextDir

   do i = 1 to 1

      DirMask = arg( 1)
      if (DirMask = '') then
         sayerror 'Error: no dir mask specified.'
         leave
      endif

      DirMask = NepmdQueryFullname( DirMask)
      if rc then
         sayerror 'Error: invalid dir mask specified.'
         leave
      endif

      Handle       = ''
      NextDirName = ''

      -- Create virtual file
      helperNepmdCreateDumpdir( 'NepmdGetNextDir', DirMask)

      -- Search all dirs
      do while NepmdGetNextDir( DirMask, Handle, NextDirname)
         insertline( NextDirname)
      enddo
      .modify = 0

/*
      rc = 0
      do while not rc
         Flag = NepmdGetNextDir( DirMask, Handle, NextDirname)
         dprintf( 'rc = 'rc', Flage = 'Flag', NextDirname = 'NextDirname', address( Handle) = 'address( Handle))
      enddo
*/

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdGetNextDir
; ---------------------------------------------------------------------------
; E syntax:
;    Flag = NepmdGetNextDir( DirMask, Handle, NextDirname)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdGetNextDir( PSZ   pszDirMask,
;                                     PSZ   pszHandle,
;                                     PSZ   pszBuffer,
;                                     ULONG ulBuflen);
; ---------------------------------------------------------------------------

compile if not defined( GETNEXT_CREATE_NEW_HANDLE) then
   include 'STDCONST.E'
compile endif

defproc NepmdGetNextDir( DirMask, var Handle, var NextDirname)

   if (strip( Handle) = '') then
      Handle = GETNEXT_CREATE_NEW_HANDLE
   endif
   BufLen       = 260
   NextDirname = copies( \0, BufLen)

   -- Prepare parameters for C routine
   -- Don't touch the handle parameter, as we must report
   -- the address of the original var of the caller.
   DirMask = DirMask\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdGetNextDir",
                    address( DirMask)            ||
                    address( Handle)             ||
                    address( NextDirname)        ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)
   if rc then
      Flag = 0
      NextDirname = ''
      -- Automatically close the handle in case of an error <> 18.
      -- Keep previous rc.
      if rc <> 18 then  -- ERROR_NO_MORE_FILES
         Savedrc = rc   -- save rc
         call NepmdGetNextClose( Handle)
         rcx = rc       -- ignore rc of NepmdGetNextClose
         rc = Savedrc   -- restore rc
      endif
   else
      Flag = 1
      NextDirname = makerexxstring( NextDirname)
   endif
   return Flag

