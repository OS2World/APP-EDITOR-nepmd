/****************************** Module Header *******************************
*
* Module Name: _unpack.cmd zipfile targetpath
*
* Helper batch for to unpack a ZIP file with info-zip
*
* Unlike Info-Zip this file creates the complete path specified as parameter.
*
* NOTE: No special zip parameters are passed from the caller.
* Files are unpacked with -o option (overwrite) by default.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: _unpack.cmd,v 1.2 2002-04-18 17:01:35 cla Exp $
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

 PARSE ARG Source Target;
 Source = STRIP( Source);
 Target = STRIP( Target);

 IF (Target \= '') THEN
 DO
    SAY;
    MakePath( Target);
    '@PKUNZIP2 -o' Source '-d' Target;
 END;
 EXIT( rc);

/* ------------------------------------------------------------------------- */
MakePath: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG PathName;
 Redirection = '>NUL 2>&1';

 PARSE SOURCE . . CallName
 FileName = SUBSTR( CallName, LASTPOS( '\', CallName) + 1);
 'XCOPY' CallName PathName'\'Redirection;
 rcx = SysFileDelete( PathName'\'FileName);
 RETURN( '');

