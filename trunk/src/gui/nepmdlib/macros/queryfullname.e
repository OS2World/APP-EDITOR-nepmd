/****************************** Module Header *******************************
*
* Module Name: queryfullname.e
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
@@NepmdQueryFullname@PROTOTYPE
Fullname = NepmdQueryFullname( Filename)

@@NepmdQueryFullname@CATEGORY@FILE

@@NepmdQueryFullname@SYNTAX
This function queries the fullname of the specified filename. It
does not check, wether a file or directory really exists, for that use
the functions [.IDPNL_EFUNC_NEPMDFILEEXISTS] or [.IDPNL_EFUNC_NEPMDDIREXISTS].

@@NepmdQueryFullname@PARM@Filename
This parameter specifies the file or directory name. it may include
.ul compact
- absolute or relative pathname specifications
- wildcards, but only within the filename part,
  they are returned within the result.

It is not necessary to specify a name of a file, which exists
or of which all directories of the path specification exist.
The only requirement is that the resulting file or directory entry
#could# exist in the resulting directory, that means it must be valid.

@@NepmdQueryFullname@RETURNS
*NepmdQueryFullname* returns the fully qualified filename.
In case of an error an empty string is returned.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdQueryFullname@REMARKS
This function calls the OS/2 API *DosQueryPathInfo* and will
return the full name of any directory or filename, even if it does
not exist. It is especially useful where relative path specifications
are to be translated into absolute pathnames or to prove that they are
valid.

@@NepmdQueryFullname@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryFullname* [.IDPNL_EFUNC_NEPMDQUERYFULLNAME_PARM_FILENAME filename]
  - or
- *QueryFullname* [.IDPNL_EFUNC_NEPMDQUERYFULLNAME_PARM_FILENAME filename]

Executing this command will
return the fully qualified pathname specification for the given filename
and display the result within the status area.

_*Examples:*_
.fo off
 QueryFullname myscript.txt
 QueryFullname ..\*.cmd
.fo on

@@
*/


; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdQueryFullname, QueryFullname

   do i = 1 to 1

      Filename = arg( 1)
      if (Filename = '') then
         sayerror 'Error: no filename specified.'
         leave
      endif

      Fullname = NepmdQueryFullname( Filename)

      if rc then
         sayerror 'Fullname of "'Filename'" could not be retrieved, rc = 'rc'.'
      else
         sayerror 'Fullname of "'Filename'" is:' Fullname
      endif

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdQueryFullname
; ---------------------------------------------------------------------------
; E syntax:
;    Fullname = NepmdQueryFullname( filename)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdQueryFullname( PSZ pszFilename,
;                                        PSZ pszBuffer,
;                                        ULONG ulBuflen);
; ---------------------------------------------------------------------------

defproc NepmdQueryFullname( Filename)

   BufLen   = 260
   FullName = copies( \0, BufLen)

   -- Prepare parameters for C routine
   Filename   = Filename\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdQueryFullname",
                    address( Filename)            ||
                    address( Fullname)            ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)

   if rc then
      return ''
   else
      return makerexxstring( FullName)
   endif

