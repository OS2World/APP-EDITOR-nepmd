/****************************** Module Header *******************************
*
* Module Name: setframewindowpos.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: setframewindowpos.e,v 1.2 2002-09-06 10:01:17 cla Exp $
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
@@NepmdSetFrameWindowPos@PROTOTYPE
rc = NepmdSetFrameWindowPos( x, y, cx, cy, flags);

@@NepmdSetFrameWindowPos@CATEGORY@EPMWINDOW

@@NepmdSetFrameWindowPos@SYNTAX
This function sets the window position of the EPM
frame window.

@@NepmdSetFrameWindowPos@PARM@x
This parameter specifies the x coordinate of the lower left corner of
the EPM frame window in pixels.

In order to modify the window coordinate to this new value (move the window),
the parameter [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_FLAGS flags] must be set to *2* or *3*.

@@NepmdSetFrameWindowPos@PARM@y
This parameter specifies the y coordinate of the lower left corner of
the EPM frame window in pixels.

In order to modify the window coordinate to this new value (move the window),
the parameter [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_FLAGS flags] must be set to *2* or *3*.

@@NepmdSetFrameWindowPos@PARM@cx
This parameter specifies the width of the EPM frame window in pixels.

In order to modify the window size to this new value,
the parameter [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_FLAGS flags] must be set to *1* or *3*.

@@NepmdSetFrameWindowPos@PARM@cy
This parameter specifies the height of the EPM frame window in pixels.

In order to modify the window size to this new value,
the parameter [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_FLAGS flags] must be set to *1* or *3*.

@@NepmdSetFrameWindowPos@PARM@flags
This optional parameter specifies how to modify the window position.

Specifiy one of the following values:
.pl compact bold tsize=5 break=none
- 1
= size the *EPM* window according to the parameters 
  [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_CX cx] and [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_CY cy].
- 2
= move the (lower left corner of the) *EPM* window according to the parameters
  [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_X x] and [.IDPNL_EFUNC_NEPMDSETFRAMEWINDOWPOS_PARM_Y y].
- 3
= size #and# move the *EPM* window

If *flags* has not been specified, the window is both sized and moved,
as if *3* had been specified for flags.

@@NepmdSetFrameWindowPos@RETURNS
NepmdSetFrameWindowPos returns an OS/2 error code or zero for no error.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdSetFrameWindowPos, SetFrameWindowPos

 parse value arg( 1) with x y cx cy flags;
 if (cy = '') then
    sayerror 'no complete window position specified!';
    return
 endif

 rc = NepmdSetFrameWindowPos( x, y, cx, cy, flags);

 if (rc > 0) then
    sayerror 'window pos of frame cannot be modified, rc='rc;
    return
 endif

 sayerror 'window pos of frame modified successfully.';

/* ------------------------------------------------------------- */
/* procedure: NepmdSetFrameWindowPos                             */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdSetFrameWindowPos( x, y, cx, cy, style);         */
/*                                                               */
/*   windowId is one of the EPMINFO_* values of stdconst.e       */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdSetFrameWindowPos( HWND hwndFrame,      */
/*                                          ULONG x, ULONG y,    */
/*                                          ULONG cx, ULONG cy,  */
/*                                          ULONG flags);        */
/* ------------------------------------------------------------- */

defproc NepmdSetFrameWindowPos( x, y, cx, cy) =

 /* use default for flags */
 Flags = arg( 5);
 if (flags = '') then
    flags = 3;
 endif

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdSetFrameWindowPos",
                  gethwndc( EPMINFO_EDITFRAME)  ||
                  atol( x)                      ||
                  atol( y)                      ||
                  atol( cx)                     ||
                  atol( cy)                     ||
                  atol( flags));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

