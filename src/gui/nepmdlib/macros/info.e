/****************************** Module Header *******************************
*
* Module Name: info.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: info.e,v 1.12 2003-08-30 16:01:01 aschn Exp $
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
@@NepmdInfo@PROTOTYPE
rc = NepmdInfo();

@@NepmdInfo@CATEGORY@INSTALL

@@NepmdInfo@SYNTAX
This function creates a virtual file named *.NEPMD__INFO*
within the file ring of the active EPM window
and writes runtime information into it like for example about
.ul compact
- the *NEPMD* modules loaded and config files used
- the loaded *EPM* modules
.el

@@NepmdInfo@RETURNS
*NepmdInfo* returns an OS/2 error code or zero for no error.

@@NepmdInfo@REMARKS
Note that any existing file in the ring named *.NEPMD__INFO*
is dscarded before the current file is being created.

@@NepmdInfo@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdInfo*

Executing this command will
open up a virtual file and
write all information related to *EPM* and the [=TITLE] into it.

The contents of this file may be useful when reporting the
configuration of your system and the installation of your
[=TITLE] to the project team in order to allow us to help you.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
; We want this command also if included in EPM.E to call it from
; the command line or from an menu item.

defc NepmdInfo =

 rc = NepmdInfo();

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdInfo                                          */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdInfo();                                          */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdInfo( HWND hwndClient);                 */
/* ------------------------------------------------------------- */

defproc NepmdInfo =

 NepmdInfoFilename = '.NEPMD_INFO';

 /* discard previously loaded info file from ring */
 if (.filename = NepmdInfoFilename) then;
    RestoreStartFid = 0;
 else;
    RestoreStartFid = 1;
    getfileid startfid;
 endif;
 MaxFiles = filesinring(2);  -- 1 (default): .visible files only, 2: include hidden files, 3: not defined
 do i = 1 to MaxFiles        -- prevent looping forever
    if (.filename = NepmdInfoFilename) then
       .modify = 0;
       'QUIT'
    endif;
    next_file;
 enddo;
 /* activate start file only if not just quitted */
 if (RestoreStartFid = 1) then;
    activatefile startfid;
 endif;

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdInfo",
                  gethwndc( EPMINFO_EDITCLIENT));

 helperNepmdCheckliberror( LibFile, rc);

 /* make id discardable */
 .modify = 0;

 return rc;
