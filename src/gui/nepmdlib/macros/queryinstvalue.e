/****************************** Module Header *******************************
*
* Module Name: queryinstvalue.e
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
@@NepmdQueryInstValue@PROTOTYPE
InstValue = NepmdQueryInstValue( ValueTag)

@@NepmdQueryInstValue@CATEGORY@INSTALL

@@NepmdQueryInstValue@SYNTAX
This function queries installation related values
from the [=TITLE].

@@NepmdQueryInstValue@PARM@ValueTag
This parameter specifies a keyword determining the
installation value to be returned.
The following keywords are supported:
.pl bold
- ROOTDIR
= returns the installation directory of the [=TITLE]. If the
  installation directory cannot be determined, an error is returned.
- USERDIR
= returns the user's directory of the [=TITLE]. Normally this is
  ROOTDIR"\myepm", but this can be changed with the ini entry
  NEPMD -> UserDir. If the user's directory cannot be determined,
  an error is returned.
- LANGUAGE
= returns the language selected by the installation of the [=TITLE].
.
  If the installation directory cannot be determined, *eng* for the
  english language is returned.
- INIT
= returns the fully qualified pathname of the initialization file of
  the [=TITLE].
- MESSAGE
= returns the fully qualified pathname of the message file of
  the [=TITLE].
- USRGUIDE
= returns the fully qualified pathname of the user guide
  information file of the [=TITLE] (neusr**.inf).
- PRGGUIDE
= returns the fully qualified pathname of the programming guide
  information file of the [=TITLE] (neusr**.inf).
- HELP
= returns the fully qualified pathname of the online help file of
  the [=TITLE] (nepmd**.hlp).

If the installation directory cannot be determined, pathnames
of course cannot point to a subdirectory of the NEPMD directory
tree, but rather specify filenames from within the directory where
the calling executable is called from - this way all values
except for *ROOT* can be used even if not the complete [=TITLE]
is installed.

@@NepmdQueryInstValue@RETURNS
*NepmdQueryInstValue* returns the installation value.
In case of an error an empty string is returned.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdQueryInstValue@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryInstValue*
  - or
- *QueryInstValue*

Executing this command will open up a virtual file and
write all [.IDPNL_EFUNC_NEPMDQUERYINSTVALUE_PARM_VALUETAG supported installation values]
into it.

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------

defc NepmdQueryInstValue, QueryInstValue

   helperNepmdCreateDumpfile( 'NepmdQueryInstValue', '')
   insertline helperNepmdQueryInstValue( 'ROOTDIR')
   insertline helperNepmdQueryInstValue( 'USERDIR')
   insertline helperNepmdQueryInstValue( 'LANGUAGE')
   insertline helperNepmdQueryInstValue( 'INIT')
   insertline helperNepmdQueryInstValue( 'MESSAGE')
   insertline helperNepmdQueryInstValue( 'USRGUIDE')
   insertline helperNepmdQueryInstValue( 'PRGGUIDE')
   insertline helperNepmdQueryInstValue( 'HELP')
   .modify = 0

defproc helperNepmdQueryInstValue( ValueTag)
   return leftstr( ValueTag, 8) ':' NepmdQueryInstValue( ValueTag)

; ---------------------------------------------------------------------------
; Procedure: NepmdQueryInstValue
; ---------------------------------------------------------------------------
; E syntax:
;    InstValue = NepmdQueryInstValue( ValueTag)
;
;    See valig tags in src\gui\common\nepmd.h: NEPMD_INSTVALUE_*
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdQueryInstValue( PSZ pszTagName,
;                                         PSZ pszBuffer,
;                                         ULONG ulBuflen):
; ---------------------------------------------------------------------------

defproc NepmdQueryInstValue( ValueTag)

   BufLen    = 260
   InstValue = copies( \0, BufLen)

   -- Prepare parameters for C routine
   ValueTag = ValueTag\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdQueryInstValue",
                    address( ValueTag)          ||
                    address( InstValue)         ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)

   if rc then
      return ''
   else
      return makerexxstring( InstValue)
   endif

