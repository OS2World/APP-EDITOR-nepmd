/****************************** Module Header *******************************
*
* Module Name: activatehighlight.e
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
@@NepmdActivateHighlight@PROTOTYPE
rc = NepmdActivateHighlight( ActivateFlag, EpmMode, HiliteOptions);

@@NepmdActivateHighlight@CATEGORY@MODE

@@NepmdActivateHighlight@SYNTAX
This function activates or deactivates the syntax highlighting for
the loaded file.

@@NepmdActivateHighlight@PARM@ActivateFlag
This parameter specifies wether the syntax highlighting should be
activated or deactivated,

Specifiy one of the following values:
.pl compact tsize=5
- *0* or *OFF*
= deactivate syntax highlighting
- *1* or *ON*
= activate syntax highlighting

The default value is to activate syntax highlighting.

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

@@NepmdActivateHighlight@RETURNS
*NepmdActivateHighlight* returns an OS/2 error code or zero for no error.

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

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdActivateHighlight, ActivateHighlight =

 ActivateFlag = translate( word( arg( 1), 1));
 if (ActivateFlag = '') then
    ActivateFlag = 'ON';
 endif

 EpmMode = translate( word( arg( 1), 2));

 if (wordpos( ActivateFlag, 'ON 1') > 0) then
    NewStatus = 'activated';
 elseif (wordpos( ActivateFlag, 'OFF 0') > 0) then
    NewStatus = 'deactivated';
 else
    sayerror 'Wrong parameter "'ActivateFlag'" specified !';
    return;
 endif

 rc = NepmdActivateHighlight( ActivateFlag, EpmMode);
 if (rc > 0) then
    sayerror 'syntax highlighting could not be' NewStatus ', rc='rc;
    return;
 endif

 sayerror 'syntax highlighting was' NewStatus 'successfully.';

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdActivateHighlight                             */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdActivateHighlight( ActivateFlag,                 */
/*                                 Mode,                         */
/*                                 HiliteOptions)                */
/*                                                               */
/*   windowId is one of the EPMINFO_* values of stdconst.e       */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdActivateHighlight(  HWND hwndClient,    */
/*                                           PSZ pszActivateFlag,*/
/*                                           PSZ pszEpmMode,     */
/*                                           PSZ pszOptions);    */
/* ------------------------------------------------------------- */

defproc NepmdActivateHighlight( ActivateFlag)

 /* get mode of current file, if not specified */
 EpmMode = arg( 2);
 if (EpmMode = '') then
    EpmMode = NepmdGetMode();
 endif
 HiliteOptions = arg( 3);

 /* prepare parameters for C routine */
 ActivateFlag  = ActivateFlag''atoi( 0);
 EpmMode       = EpmMode''atoi( 0);
 HiliteOptions = HiliteOptions''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdActivateHighlight",
                  gethwndc( EPMINFO_EDITCLIENT) ||
                  address( ActivateFlag)        ||
                  address( EpmMode)             ||
                  address( HiliteOptions));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

