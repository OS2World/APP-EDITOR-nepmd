/*
 *      COMSTAT.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      This program scans the db subdirectory fo uncommitted changes
 *      and commits them.
 *
 *      Syntax: comstat
 */
/* First three comments are being used as online helptext */
/****************************** Module Header *******************************
*
* Module Name: comstat.cmd
*
* Batch for to checkin uncommitted changes to the status db directory
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


 SIGNAL ON HALT;

 TitleLine = STRIP(SUBSTR(SourceLine(2), 3));
 PARSE VAR TitleLine CmdName'.CMD 'Info
 Title     = CmdName Info

 env          = 'OS2ENVIRONMENT';
 TRUE         = (1 = 1);
 FALSE        = (0 = 1);
 Redirection  = '> NUL 2>&1';
 '@ECHO OFF'

 /* OS/2 errorcodes */
 ERROR.NO_ERROR           =   0;
 ERROR.INVALID_FUNCTION   =   1;
 ERROR.FILE_NOT_FOUND     =   2;
 ERROR.PATH_NOT_FOUND     =   3;
 ERROR.ACCESS_DENIED      =   5;
 ERROR.NOT_ENOUGH_MEMORY  =   8;
 ERROR.INVALID_FORMAT     =  11;
 ERROR.INVALID_DATA       =  13;
 ERROR.NO_MORE_FILES      =  18;
 ERROR.WRITE_FAULT        =  29;
 ERROR.READ_FAULT         =  30;
 ERROR.GEN_FAILURE        =  31;
 ERROR.INVALID_PARAMETER  =  87;
 ERROR.ENVVAR_NOT_FOUND   = 203;

 GlobalVars = 'Title CmdName env TRUE FALSE Redirection ERROR.';

 /* show help */
 ARG Parm .
 IF (POS('/?', Parm) > 0) THEN
 DO
    rc = ShowHelp( );
    EXIT( rc);
 END;

 /* load RexxUtil */
 CALL RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 CALL SysLoadFuncs

 /* default values */
 GlobalVars = GlobalVars '';
 rc         = ERROR.NO_ERROR;

 DO UNTIL (TRUE)

    /* update status db directory */
    rc = UpdateStatus( 'db');

 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
HALT:
  SAY 'Interrupted by user.';
  EXIT(ERROR.GEN_FAILURE);

/* ------------------------------------------------------------------------- */
ShowHelp: PROCEDURE EXPOSE (GlobalVars)
 ARG Section;

 SAY;
 SAY Title
 SAY;

 /* read this file directly -> quicker than SOURCELINE() ! */
 PARSE SOURCE . . ThisFile;

 DO 3
    rc = LINEIN(ThisFile);
 END;

 ThisLine = LINEIN(Thisfile);
 DO WHILE (ThisLine \= ' */')
    SAY SUBSTR(ThisLine, 7);
    ThisLine = LINEIN(Thisfile);
 END;

 rc = LINEOUT(Thisfile);

 RETURN( ERROR.INVALID_PARAMETER);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') > '');

/* ========================================================================= */

UpdateStatus: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG SubDir;

 /* default values */
 rc = ERROR.NO_ERROR;
 CommitTag = '.commit';
 StatusCount  = 0;
 AddedCount   = 0;
 ModifyCount  = 0;
 InvalidCount = 0;
 UpdateCount  = 0;
 ErrorCount   = 0;


 DO UNTIL (TRUE)

    /* search all files files for status purposes */
    rc = SysFileTree( SubDir'\*', 'AllFile.', 'FO');
    IF (rc \= ERROR.NO_ERROR) THEN
    DO
       SAY 'error in SysFileTree, rc='rc;
       EXIT( rc);
    END;

    StatusCount = AllFile.0;

    IF (AllFile.0 = 0) THEN
    DO
       SAY 'error: status db directory is empty!';
       rc = ERROR.FILE_NOT_FOUND;
       LEAVE;
    END;

    /* search commit files */
    rc = SysFileTree( SubDir'\*'CommitTag, 'CommitFile.', 'FO');
    IF (CommitFile.0 = 0) THEN
    DO
       SAY 'error: all status entries are up-to-date!';
       rc = ERROR.NO_MORE_FILES;
       LEAVE;
    END;

    /* calculate some basic stats */
    StatusCount = AllFile.0 - CommitFile.0;
    ModifyCount = CommitFile.0;

    /* now process all commit files */
    DO i = 1 TO CommitFile.0

       /* determien some filenames */
       ThisFile = LEFT( CommitFile.i, LENGTH( CommitFile.i) - LENGTH( CommitTag));
       BaseName = FILESPEC( 'N', ThisFile);

       SourceFile  = SubDir'\'BaseName;
       MessageFile = CommitFile.i;

       /* does appropriate entries exist ? */
       IF (\FileExist( ThisFile)) THEN
       DO
          SAY 'error: invalid commit comment, entry' Basename 'could not be found.';
          InvalidCount = InvalidCount + 1;
       END
       ELSE
       DO
          /* determine temp file */
          LogFile = SysTempFilename( VALUE('TMP',,env)'\comstat.???');

          /* read out comment */
          rcx = STREAM( CommitFile.i, 'C', 'OPEN READ');
          FirstComment = LINEIN( CommitFile.i);
          rcx = STREAM( CommitFile.i, 'C', 'CLOSE');
          fNewFile = (FirstComment = 'First revision');
          IF (fNewFile) THEN
          DO
             SAY '-> adding' BaseName;
             'cvs add' SourceFile '>' LogFile '2>&1';
             IF (rc \= ERROR.NO_ERROR) THEN
             DO
                ErrorCount = ErrorCount + 1;
                SAY 'error:' BaseName 'could not be added, rc='rc;
                SAY;
                'TYPE' LogFile;
                SAY;
                'PAUSE';
                ITERATE;
             END;
          END;

          /* commit the change */
          SAY '-> commit' BaseName;
          'cvs com -F' MessageFile SourceFile '>' LogFile '2>&1';
          IF (rc = ERROR.NO_ERROR) THEN
          DO
             IF (fNewFile) THEN
                AddedCount = AddedCount + 1;
             ELSE
                UpdateCount = UpdateCount + 1;
             rcx = SysFileDelete( CommitFile.i);
          END;
          ELSE
          DO
             ErrorCount = ErrorCount + 1;
             SAY 'error:' BaseName 'could not be committed, rc='rc;
             SAY;
             'TYPE' LogFile;
             SAY;
             'PAUSE';
          END;
          /* cleanup */
          rcx = SysFileDelete( LogFile);
       END;

    END;

 END;

 SAY;
 SAY 'overall result:';
 SAY '---------------';
 SAY StatusCount  'status entries in database directory';
 SAY ModifyCount  'entries were uncommitted';
 IF (InvalidCount > 0) THEN
    SAY '-' InvalidCount 'invalid uncommitted entries';
    SAY '-' UpdateCount  'entries committed.';
 IF (AddedCount > 0) THEN
    SAY '-' AddedCount   'entries added';
    SAY '-' ErrorCount   'errors occurred';

'PAUSE'

 RETURN( rc);


