/****************************** Module Header *******************************
*
* Module Name: querydefaultmode.e
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
@@NepmdQueryDefaultMode@PROTOTYPE
DefaultMode = NepmdQueryDefaultMode( Filename)

@@NepmdQueryDefaultMode@CATEGORY@MODE

@@NepmdQueryDefaultMode@SYNTAX
This function determines the default *EPM* mode for the specified file.

@@NepmdQueryDefaultMode@PARM@Filename
This parameter specifies the name of the file, for which
the default *EPM* mode is to be determined.

@@NepmdQueryDefaultMode@RETURNS
*NepmdQueryDefaultMode* returns either
.ul compact
- the name of the default *EPM* mode or
- *TEXT*, if no mode could be determined or if in case of an error.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.
rc is set to 3 = ERROR__PATH__NOT__FOUND if no mode could be determined.


@@NepmdQueryDefaultMode@TESTCASE
You can test this function from the *EPM* commandline by executing:
.sl
- *NepmdQueryDefaultMode*
   [.IDPNL_EFUNC_NEPMDQUERYDEFAULTMODE_PARM_FILENAME filename]
  - or
- *QueryDefaultMode*
   [.IDPNL_EFUNC_NEPMDQUERYDEFAULTMODE_PARM_FILENAME filename]

Executing this command will determine the default mode of the
the specified file.

*Example:*
.fo off
 QueryDefaultMode d:\test.cmd
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdQueryDefaultMode, QueryDefaultMode

   do i = 1 to 1

      Filename =  arg( 1)
      if (Filename = '') then
         sayerror 'Error: no filename specified.'
         leave
      endif

      DefaultMode = NepmdQueryDefaultMode( Filename)
      if rc then
         sayerror 'Default EPM mode could not be determined, rc = 'rc'.'
      else
         sayerror 'Default mode for "'Filename'" is:' DefaultMode
      endif

   enddo


compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdQueryDefaultMode
; ---------------------------------------------------------------------------
; E syntax:
;    DefaultMode = NepmdQueryDefaultMode( Filename)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdQueryDefaultMode( PSZ pszFilename,
;                                           PSZ pszBuffer,
;                                           ULONG ulBuflen);
; ---------------------------------------------------------------------------

compile if not defined( NEPMD_MAXLEN_ESTRING) then
   include 'STDCONST.E'
compile endif

defproc NepmdQueryDefaultMode( Filename)

   BufLen      = NEPMD_MAXLEN_ESTRING
   DefaultMode = copies( \0, BufLen)

   -- Prepare parameters for C routine
   Filename = Filename\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    'NepmdQueryDefaultMode',
                    address( Filename)    ||
                    address( DefaultMode) ||
                    atol( Buflen))


   if (rc == 3) then        -- 3 = reserved value, if no mode found
      DefaultMode = 'TEXT'
   elseif rc then
      DefaultMode = 'TEXT'  -- use TEXT also for other errors
   else
      DefaultMode = makerexxstring( DefaultMode)
   endif

   helperNepmdCheckliberror( LibFile, rc)

   return DefaultMode;

