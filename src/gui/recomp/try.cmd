/****************************** Module Header *******************************
*
* Module Name: try.cmd
*
* Batch file for testing purposes:
* This program loads several files into one or more EPM windows (file rings)
* in order to ease testing of the reload function.
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

 env          = 'OS2ENVIRONMENT';
 TRUE         = (1 = 1);
 FALSE        = (0 = 1);
 CrLf         = '0d0a'x;
 Redirection  = '> NUL 2>&1';
 '@ECHO OFF'


 /* load rexxutils */
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 /* determine some directories */
 TmpDir = VALUE('TMP',,env);

 /* ####################### maintain testcases here ####################### */

 Testcase.0  = '*.c *.h *.cmd *.rc*';  /* some few rings with some more files */
 Testcase.1  = 'tc.*';                 /* one ring with few files */
 Testcase.2  = 'client.* dde.*' ,      /* lot of rings with few files */
               'ddereload.* frame.* job.*' ,
               'dde.* recomp.* ';

 /* ####################################################################### */

 /* defaults */
 rc = 0;
 SleepBetweenLoads = 2;
 TmpFilesToDelete = TmpDir'\*.C2T';

 DO UNTIL (TRUE)
    /* delete temporary files from previous tests */
    DO WHILE (TmpFilesToDelete \= '')
       PARSE VAR TmpFilesToDelete ThisFiles TmpFilesToDelete;
       rcx = DeleteFiles( ThisFiles);
    END;

    /* display all testcase definitions when help is requested */
    PARSE ARG Parm .;
    IF (POS( '?', Parm) > 0) THEN
    DO
       SAY 'Testcases:';
       i = 0;
       DO WHILE (SYMBOL( 'Testcase.'i) = 'VAR')
          SAY i':' Testcase.i;
          i = i + 1;
       END;

       LEAVE;
    END;

    /* check parm for testcase number */
    IF (DATATYPE( Parm) \= 'NUM') THEN
       Parm = '1';

    IF (SYMBOL( 'Testcase.'Parm) = 'LIT') THEN
    DO
       SAY 'specified testcase is not defined.';
       rc = 87;
       LEAVE;
    END;

    /* start testcase */
    SAY 'loading testcase' Parm':'
    rc = LoadFiles( Testcase.Parm);

    /* load program */
    'call q'

 END;

 EXIT( rc);

/* ========================================================================= */
DeleteFiles: PROCEDURE
 PARSE ARG Filemask;

 File.0 = 0;
 rc = SysFileTree( Filemask, 'File.', 'FO');
 DO i = 1 TO File.0
    rcx = SysFileDelete( File.i);
 END;
 RETURN( rc);

/* ========================================================================= */
LoadFiles: PROCEDURE EXPOSE SleepBetweenLoads;
 PARSE ARG FileList;

 /* defaults */
 rc = 0;
 RingNo = 1;

 DO WHILE (FileList \= '')
    /* load this ring */
    PARSE VAR FileList ThisFilemask FileList;
    SAY '> ring' RingNo':' ThisFilemask;
    'start EPM' ThisFilemask;

    /* wait a while, then next please */
    rcx = SysSleep( SleepBetweenLoads);
    RingNo = RingNo + 1;
 END;

 RETURN( rc);

