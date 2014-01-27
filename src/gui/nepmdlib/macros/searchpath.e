/****************************** Module Header *******************************
*
* Module Name: searchpath.e
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
@@NepmdSearchPath@PROTOTYPE
Fullname = NepmdSearchPath( Filename, EnvVar)

@@NepmdSearchPath@CATEGORY@FILE

@@NepmdSearchPath@SYNTAX
This function queries the full pathname of the specified filename,
having been searched on a path. The path can optionally be specified
by the name of an environment variable, otherwise *PATH* is searched.

@@NepmdSearchPath@PARM@Filename
This parameter specifies the filename, it may not include wildcards
or drive or path specifications, otherwise the search will be unsuccessful.

@@NepmdSearchPath@PARM@EnvVar
This optional parameter specifies the name of an environment variable, that
contains the path where the file is seached in.

When this parameter is not specified, the file is searched along the path
specified bye the environment variable *PATH*.

@@NepmdSearchPath@RETURNS
*NepmdSearchPath* returns the full qualified filename.
In case of an error an empty string is returned.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdSearchPath@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdSearchPath*
   [.IDPNL_EFUNC_NEPMDSEARCHPATH_PARM_FILENAME filename]
   [[ [.IDPNL_EFUNC_NEPMDSEARCHPATH_PARM_ENVVAR envvar] ]]
  - or
- *SearchPath*
   [.IDPNL_EFUNC_NEPMDSEARCHPATH_PARM_FILENAME filename]
   [[ [.IDPNL_EFUNC_NEPMDSEARCHPATH_PARM_ENVVAR envvar] ]]

Executing this command will
search the specified file in the path given by the content of the specified environment variable
(default is *PATH*, if not specified !)
and display the result within the status area.

_*Examples:*_
.fo off
 SearchPath epm.exe
 SearchPath cmdref.inf BOOKSHELF
.fo on

@@
*/


; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdSearchPath, SearchPath

   do i = 1 to 1

      parse arg Filename EnvVarName
      if leftstr( Filename, 1) = '"' then
         parse arg '"'Filename'"' EnvVarName
      endif

      if (Filename = '') then
         sayerror 'error: no filename specified.'
         leave
      endif
      if (EnvVarName = '') then
         EnvVarName = 'PATH'
      endif

      Fullname = NepmdSearchPath( Filename, EnvVarName)
      if rc then
         sayerror '"'Filename'" could not be found on "'EnvVarName'", rc = 'rc'.'
      else
         sayerror 'Location of "'Filename'" on "'EnvVarName'" is:' Fullname
      endif

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdSearchPath
; ---------------------------------------------------------------------------
; E syntax:
;    Fullname = NepmdSearchPath( filename)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdSearchPath( PSZ pszFilename,
;                                     PSZ pszEnvVarName,
;                                     PSZ pszBuffer,
;                                     ULONG ulBuflen);
; ---------------------------------------------------------------------------

defproc NepmdSearchPath( Filename)

   BufLen   = 260
   FullName = copies( \0, BufLen)

   -- Prepare parameters for C routine
   Filename   = Filename\0
   EnvVarName = arg( 2)\0  -- this parm is optional

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdSearchPath",
                    address( Filename)            ||
                    address( EnvVarName)          ||
                    address( Fullname)            ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)

   if rc then
      return ''
   else
      return makerexxstring( FullName)
   endif

