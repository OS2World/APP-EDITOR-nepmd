/****************************** Module Header *******************************
*
* Module Name: nldeinst.cmd
*
* Frame batch for to call all required CMD files when deleting
* the NEPMD base package
*
* This module is called by the WarpIn package directly.
* In order to prevent a VIO windo opening for this REXX script,
* this (and only this script) is compiled to a PM executable.
*
* This program is intended to be called only during installation of the
* Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nldeinst.cmd,v 1.2 2002-08-13 15:39:14 cla Exp $
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

 /* init */
 '@ECHO OFF';

 /* make sure we are called on purpose */
 ARG Parm .;

/* this code deactivated due to an error in WarpIn 0.9.20:
   a DEEXECUTE call to a program including parameters writes
   a corrupt ini to the WarpIn Database, making all Warpin
   instances crash !
 IF (Parm \= 'NEPMD') THEN
    ShowError( 'Netlabs EPM Distribution Installation', 'Error: not called by Warpin Package !');
*/

 /* make calldir the current directory */
 PARSE Source . . CallName;
 CallDir = LEFT( CallName, LASTPOS( '\', CallName) - 1);
 rcx = DIRECTORY( CallDir);

 /* call all modules required */
 'CALL DYNCFG DEINSTALL';

 EXIT( 0);


/* ========================================================================= */
ShowError: PROCEDURE
 PARSE ARG Title, Message;

 /* show message box in PM mode */
 SIGNAL ON SYNTAX;
 rcx = rxmessagebox( Message, Title, 'CANCEL', 'ERROR');
 EXIT( 99);

 /* print text in VIO mode */
SYNTAX:
 SIGNAL OFF SYNTAX;
 SAY '';
 SAY Title;
 SAY Message;
 EXIT( 99);

