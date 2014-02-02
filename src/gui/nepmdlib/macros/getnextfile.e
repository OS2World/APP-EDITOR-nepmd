/****************************** Module Header *******************************
*
* Module Name: getnextfile.e
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
@@NepmdGetNextFile@PROTOTYPE
Flag = NepmdGetNextFile( FileMask, Handle, NextFilename)

@@NepmdGetNextFile@CATEGORY@FILE

@@NepmdGetNextFile@SYNTAX
This function implements an easy directory lookup
for files with one function. For that it needs to be
[.IDPNL_EFUNC_NEPMDGETNEXTFILE_EXAMPLE called in a loop].

@@NepmdGetNextFile@PARM@FileMask
This parameter specifies the files to be searched
and may contain wildcards.

@@NepmdGetNextFile@PARM@Handle
This parameter specifies the handle used for the search.

Note that on the first call to NepmdGetNextFile() the value
of the variable holding the handle must be set to '' or to
GETNEXT__CREATE__NEW__HANDLE in order to initiate a new search.

The used handle is stored in this parameter.

@@NepmdGetNextFile@PARM@NextFilename
This parameter should be set to '' when specified.

The next found filename is stored in this parameter.

@@NepmdGetNextFile@EXAMPLE
The following code searches all files within the directory C:\OS2:
.fo text
 FileMask     = 'C:\OS2\*'
 Handle       = ''  -- always create a new handle
 NextFilename = ''

 -- Search all files
 do while NepmdGetNextFile( FileMask, Handle, NextFilename)
    -- Process subdirectory - here as a sample we display a popup
    messagenwait( 'File found:' NextFilename)
 enddo
.fo on

@@NepmdGetNextFile@REMARKS
The search handle created by *NepmdGetNextFile* is automatically closed
if the search is repeated until no more entries are available.

If a search for files is interrupted for any reason before receiving
the error code 18 (ERROR__NO__MORE__FILES), the search handle is closed
automatically by a call to [.IDPNL_EFUNC_NEPMDGETNEXTCLOSE].

@@NepmdGetNextFile@RETURNS
*NepmdGetNextFile* returns either
.ul compact
- *0* (zero), if no more files exist or on error
- *1*, if next filename was queried successfully.

The next filename returned by the search is stored in the
[.IDPNL_EFUNC_NEPMDGETNEXTFILE_PARM_NEXTFILENAME NextFilename] parameter.

The search handle returned by the search is stored in the
[.IDPNL_EFUNC_NEPMDGETNEXTFILE_PARM_HANDLE Handle] parameter.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.
rc is set to 18 = ERROR__NO__MORE__FILES if no filename was found.

@@NepmdGetNextFile@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetNextFile* [.IDPNL_EFUNC_NEPMDGETNEXTFILE_PARM_FILEMASK filemask]
  - or
- *GetNextFile* [.IDPNL_EFUNC_NEPMDGETNEXTFILE_PARM_FILEMASK filemask]

Executing this command will
open up a virtual file and
write all found files into it.

*Example:*
.fo text
 GetNextFile c:\os2\*
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdGetNextFile, GetNextFile

   do i = 1 to 1

      FileMask = arg( 1)
      if (FileMask = '') then
         sayerror 'Error: no file mask specified.'
         leave
      endif

      FileMask = NepmdQueryFullname( FileMask)
      if rc then
         sayerror 'Error: invalid file mask specified.'
         leave
      endif

      Handle       = ''
      NextFileName = ''

      -- Create virtual file
      helperNepmdCreateDumpfile( 'NepmdGetNextFile', FileMask)

      -- Search all files
      do while NepmdGetNextFile( FileMask, Handle, NextFilename)
         insertline( NextFilename)
      enddo
      .modify = 0

/*
      rc = 0
      do while not rc
         Flag = NepmdGetNextFile( FileMask, Handle, NextFilename)
         dprintf( 'rc = 'rc', Flage = 'Flag', NextFilename = 'NextFilename', address( Handle) = 'address( Handle))
      enddo
*/

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdGetNextFile
; ---------------------------------------------------------------------------
; E syntax:
;    Flag = NepmdGetNextFile( FileMask, Handle, NextFilename)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdGetNextFile( PSZ   pszFileMask,
;                                      PSZ   pszHandle,
;                                      PSZ   pszBuffer,
;                                      ULONG ulBuflen);
; ---------------------------------------------------------------------------

compile if not defined( GETNEXT_CREATE_NEW_HANDLE) then
   include 'STDCONST.E'
compile endif

defproc NepmdGetNextFile( FileMask, var Handle, var NextFilename)

   if (strip( Handle) = '') then
      Handle = GETNEXT_CREATE_NEW_HANDLE
   endif
   BufLen       = 260
   NextFilename = copies( \0, BufLen)

   -- Prepare parameters for C routine
   -- Don't touch the handle parameter, as we must report
   -- the address of the original var of the caller.
   FileMask = FileMask\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdGetNextFile",
                    address( FileMask)            ||
                    address( Handle)              ||
                    address( NextFilename)        ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)
   if rc then
      Flag = 0
      NextFilename = ''
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
      NextFilename = makerexxstring( NextFilename)
   endif
   return Flag

