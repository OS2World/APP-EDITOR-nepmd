/****************************** Module Header *******************************
*
* Module Name: gettextmessage.e
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
@@NepmdGetTextMessage@PROTOTYPE
TextMessage = NepmdGetTextMessage( Filename, Messagename, Parameters);

@@NepmdGetTextMessage@CATEGORY@NLS

@@NepmdGetTextMessage@SYNTAX
This function queries messages from a specified text message file. Up to
[.IDPNL_EFUNC_NEPMDGETTEXTMESSAGE_PARM_PARAMETERS nine optional parameters]
can be specified to be inserted into the message.

@@NepmdGetTextMessage@PARM@Filename
This parameter specifies the filename of the text message file.

If you ommit that parameter or specify an empty string, the
text message file of the [=TITLE] is assumed to be taken.
This file contains language dependant strings. The name of
it can be optained by executing the command
[.IDPNL_EFUNC_NEPMDINFO NepmdInfo] on the *EPM* commandline.

[=NOTE]
.ul compact
- text message files are not an OS/2 message file, but a text
  file with a certain format.

@@NepmdGetTextMessage@PARM@Messagename
This parameter specifies the name of the message to be searched within
the specified text message file.

@@NepmdGetTextMessage@PARM@Parameters
Up to nine optional parameters can be specified to be inserted into
the text message, if the message contains placeholders from *%1* to *%9*.
If no variable parameters are required, *NepmdGetTextMessage* can be called
with the two parameters [.IDPNL_EFUNC_NEPMDGETTEXTMESSAGE_PARM_FILENAME Filename]
and [.IDPNL_EFUNC_NEPMDGETTEXTMESSAGE_PARM_MESSAGENAME Messagename] only.

The placeholders from *%1* to *%9* can be specified several times. If a
parameter is not specified or empty, its related placeholder is replaced
with an empty string.

The following example reads the message *MSG__DRIVE__NOT__READY* from the
text message file *myproject.tmf* and inserts the string *A:*, where
the message text includes the palceholder *%1*.

.fo text
 TextMessage = NepmdGetTextMessage( "myproject.tmf", "MSG__DRIVE__NOT__READY",  "A:")
.fo on
.
Taken that the file *myproject.tmf* contains a message like this one
.fo text
 <--MSG__DRIVE__NOT__READY-->:Drive %1 is not ready, please insert a diskette and press any key!
.fo on
.
The resulting message would be:

Drive A: is not ready, please insert a diskette and press any key!

@@NepmdGetTextMessage@RETURNS
*NepmdGetTextMessage* returns the text message with the supplied parameters
inserted. In case of an error, an empty string is returned.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdGetTextMessage@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetTextMessage*
    [.IDPNL_EFUNC_NEPMDGETTEXTMESSAGE_PARM_MESSAGENAME messagename]
    [[ [.IDPNL_EFUNC_NEPMDGETTEXTMESSAGE_PARM_PARAMETERS parameters] ]]
  - or
- *GetTextMessage*
    [.IDPNL_EFUNC_NEPMDGETTEXTMESSAGE_PARM_MESSAGENAME messagename]
    [[ [.IDPNL_EFUNC_NEPMDGETTEXTMESSAGE_PARM_PARAMETERS parameters] ]]

Executing this command will display the specified message from the
text message file of the [TITLE], having inserted the specified parameters
and display the result within the status area.

You can also use an alternate text message file by specifying its
pathname with the environment variable *NEPMD__TMFTESTFILE*.

*Example:*
.fo text
 GetTextMessage INSERTTEST parm1 parm2 parm3
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdGetTextMessage, GetTextMessage

   -- Determine message name or use default
   if ( words( arg( 1)) = 0) then
      Messagename = 'TESTMESSAGE'
   else
      Messagename = word( arg( 1), 1)
   endif

   -- Determine TMF name
   Envvar = 'NEPMD_TMFTESTFILE'
   Testfile = get_env( Envvar)

   -- Fetch message - Note: word 1 is already message name
   ParmCount = words( arg( 1))
   Parm1     = word( arg( 1),  2)
   Parm2     = word( arg( 1),  3)
   Parm3     = word( arg( 1),  4)
   Parm4     = word( arg( 1),  5)
   Parm5     = word( arg( 1),  6)
   Parm6     = word( arg( 1),  7)
   Parm7     = word( arg( 1),  8)
   Parm8     = word( arg( 1),  9)
   Parm9     = word( arg( 1), 10)
   if (ParmCount < 2) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename)
   elseif (ParmCount = 2) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1)
   elseif (ParmCount = 3) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2)
   elseif (ParmCount = 4) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2, Parm3)
   elseif (ParmCount = 5) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2, Parm3, Parm4)
   elseif (ParmCount = 6) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2, Parm3, Parm4, Parm5)
   elseif (ParmCount = 7) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2, Parm3, Parm4, Parm5, Parm6)
   elseif (ParmCount = 8) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2, Parm3, Parm4, Parm5, Parm6, Parm7)
   elseif (ParmCount = 9) then
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2, Parm3, Parm4, Parm5, Parm6, Parm7, Parm8)
   else
      MessageText = NepmdGetTextMessage( Testfile, Messagename,
                                         Parm1, Parm2, Parm3, Parm4, Parm5, Parm6, Parm7, Parm8, Parm9)
   endif

   if rc then
      sayerror 'Error: message' Messagename 'could not be retrieved, rc = 'rc'.'
   else
      sayerror 'Message is: "'MessageText'"'
   endif

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdGetTextMessage
; ---------------------------------------------------------------------------
; E syntax:
;    TextMessage = NepmdGetTextMessage( Filename, Messagename
;                                       [, parm1, parm2, ... ,parm9])
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdGetTextMessage( PSZ pszFilename,
;                                         PSZ pszMessageName,
;                                         PSZ pszBuffer,
;                                         ULONG ulBuflen,
;                                         PSZ pszParm1,
;                                         PSZ pszParm2,
;                                         PSZ pszParm3,
;                                         PSZ pszParm4,
;                                         PSZ pszParm5,
;                                         PSZ pszParm6,
;                                         PSZ pszParm7,
;                                         PSZ pszParm8,
;                                         PSZ pszParm9);
;    Note: unlike DosGetMessage, this function returns an ASCIIZ.
; ---------------------------------------------------------------------------

compile if not defined( NEPMD_MAXLEN_ESTRING) then
   include 'STDCONST.E'
compile endif

defproc NepmdGetTextMessage( Filename, Messagename)

   BufLen      = NEPMD_MAXLEN_ESTRING
   TextMessage = copies( \0, BufLen)

   -- Prepare parameters for C routine
   Filename    = Filename\0
   Messagename = Messagename\0

   -- Prepare all parms as ASSCIZ string and assemble variable parm list.
   -- Note: we need to setup vars for each parm, as arg()
   --       returns the same address for all values :-((
   --       address() needs a variable as parameter.
   if (arg() >=  3) then  Parm1 = arg(  3)''atoi( 0); Addr1 = address( Parm1); else Addr1 = atol( 0); endif
   if (arg() >=  4) then  Parm2 = arg(  4)''atoi( 0); Addr2 = address( Parm2); else Addr2 = atol( 0); endif
   if (arg() >=  5) then  Parm3 = arg(  5)''atoi( 0); Addr3 = address( Parm3); else Addr3 = atol( 0); endif
   if (arg() >=  6) then  Parm4 = arg(  6)''atoi( 0); Addr4 = address( Parm4); else Addr4 = atol( 0); endif
   if (arg() >=  7) then  Parm5 = arg(  7)''atoi( 0); Addr5 = address( Parm5); else Addr5 = atol( 0); endif
   if (arg() >=  8) then  Parm6 = arg(  8)''atoi( 0); Addr6 = address( Parm6); else Addr6 = atol( 0); endif
   if (arg() >=  9) then  Parm7 = arg(  9)''atoi( 0); Addr7 = address( Parm7); else Addr7 = atol( 0); endif
   if (arg() >= 10) then  Parm8 = arg( 10)''atoi( 0); Addr8 = address( Parm8); else Addr8 = atol( 0); endif
   if (arg() >= 11) then  Parm9 = arg( 11)''atoi( 0); Addr9 = address( Parm9); else Addr9 = atol( 0); endif
   VarParmList = Addr1 || Addr2 || Addr3 || Addr4 || Addr5 || Addr6 || Addr7 || Addr8 || Addr9

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdGetTextMessage",
                    address( Filename)            ||
                    address( Messagename)         ||
                    address( TextMessage)         ||
                    atol( Buflen)                 ||
                    VarParmList)

   helperNepmdCheckliberror( LibFile, rc)

   if rc then
      return ''
   else
      return makerexxstring( TextMessage)
   endif

