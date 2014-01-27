/****************************** Module Header *******************************
*
* Module Name: activatehighlight.e
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
@@NepmdActivateHighlight@PROTOTYPE
NepmdActivateHighlight( ActivateFlag, EpmMode, HiliteOptions, Handle)

@@NepmdActivateHighlight@CATEGORY@MODE

@@NepmdActivateHighlight@SYNTAX
This function activates or deactivates the keyword highlighting for
the loaded file. On activating, mode files are checked for changes.
When they were changed, the temporary standard EPM keyword file is
rebuilt. Additionally, mode settings from the GLOBAL section are always
written to NEPMD.INI on activating as well.

@@NepmdActivateHighlight@PARM@ActivateFlag
This parameter specifies wether the keyword highlighting should be
activated or deactivated,

Specifiy one of the following values:
.pl compact tsize=5
- *0* or *OFF*
= deactivate keyword highlighting
- *1* or *ON*
= activate keyword highlighting

The default value is to activate keyword highlighting.

@@NepmdActivateHighlight@PARM@EpmMode
This optional parameter specifies the mode to be used. If no mode
is specified, the mode of the current file is used.

@@NepmdActivateHighlight@PARM@HiliteOptions
This optional parameter specifies options.

Specifiy one of the following values:
.pl compact tsize=5
- *N*
= don't check the internal *EPM* highlight file for being outdated.
  The file is nevertheless newly generated, if it does not yet exist

By default no options are used.

@@NepmdActivateHighlight@PARM@Handle
This optional parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdActivateHighlight@RETURNS
*NepmdActivateHighlight* returns nothing.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdActivateHighlight@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdActivateHighlight*
    [.IDPNL_EFUNC_NEPMDACTIVATEHIGHLIGHT_PARM_ACTIVATEFLAG ActivateFlag]
  - or
- *ActivateHighlight*
    [.IDPNL_EFUNC_NEPMDACTIVATEHIGHLIGHT_PARM_ACTIVATEFLAG ActivateFlag]

Executing this command will (de)activate syntax highlighting according to the
mode of the currently loaded file

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdActivateHighlight, ActivateHighlight

   do i = 1 to 1

      ActivateFlag = translate( word( arg( 1), 1))
      if (ActivateFlag = '') then
         ActivateFlag = 'ON'
      endif

      EpmMode = translate( word( arg( 1), 2))

      NewStatus = 1
      if (wordpos( ActivateFlag, 'ON 1') > 0) then
         NewStatus = 'activated'
      elseif (wordpos( ActivateFlag, 'OFF 0') > 0) then
         NewStatus = 'deactivated'
      else
         sayerror 'Wrong parameter "'ActivateFlag'" specified.'
         leave
      endif

      call NepmdActivateHighlight( ActivateFlag, EpmMode, 0, NewStatus)
      if rc then
         sayerror 'Keyword highlighting could not be' NewStatus', rc = 'rc'.'
      else
         sayerror 'Keyword highlighting was' NewStatus 'successfully.'
      endif

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdActivateHighlight
; ---------------------------------------------------------------------------
; E syntax:
;    rc = NepmdActivateHighlight( ActivateFlag,
;                                 Mode,
;                                 HiliteOptions,
;                                 Handle)
;
; ---------------------------------------------------------------------------
; C prototype:
;     APIRET EXPENTRY NepmdQueryHighlightArgs( PSZ pszActivateFlag,
;                                              PSZ pszEpmMode,
;                                              PSZ pszOptions,
;                                              HCONFIG hconfig,
;                                              PSZ pszBuffer,
;                                              ULONG ulBuflen);
; ---------------------------------------------------------------------------

compile if not defined( NEPMD_MAXLEN_ESTRING) then
   include 'STDCONST.E'
compile endif

defproc NepmdActivateHighlight( ActivateFlag)

   -- Get mode of current file, if not specified
   EpmMode = arg( 2)
   if (EpmMode = '') then
      EpmMode = GetMode()
   endif

   HiliteOptions = arg( 3)

   -- Use zero as handle if none specified
   Handle = arg( 4)
   if (strip( Handle) = '') then
      Handle = 0
   endif

   ActivateFlag  = ActivateFlag\0
   EpmMode       = EpmMode\0
   HiliteOptions = HiliteOptions\0
   BufLen        = NEPMD_MAXLEN_ESTRING
   HighlightArgs = copies( \0, BufLen)

   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    'NepmdQueryHighlightArgs',
                    address( ActivateFlag)        ||
                    address( EpmMode)             ||
                    address( HiliteOptions)       ||
                    atol( Handle)                 ||
                    address( HighlightArgs)       ||
                    atol( BufLen))

   call helperNepmdCheckliberror( LibFile, rc)
   if not rc then
      HighlightArgs = makerexxstring( HighlightArgs)
      'toggle_parse' HighlightArgs
   endif
   return

