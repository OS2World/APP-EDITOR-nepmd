/*
 *      RECOMP.CMD - V2.0 C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: recomp.cmd
 *
 *    This program recompiles the EPM configuration.
 *
 *    Required:
 *
 *      pgmcntrl.exe - for closing open instances of EPM
 *
 *    !!! NOT YET IMPLEMENTED !!!!
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: recomp.cmd
*
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: recomp.cmd,v 1.1 2002-04-18 16:11:10 cla Exp $
*
* ===========================================================================
*
* This file is part of the Netlabs EPM Distribution package and is free
* software.  You can redistribute it and/or modify it under the terms of the
* GNU Library General Public License as published by the Free Software
* Foundation, in version 2 as it comes in the "COPYING.LIB" file of the WPS
* Toolkit main distribution.  This library is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Library General Public License for more details.
*
****************************************************************************/

 SIGNAL ON HALT

 TitleLine = STRIP(SUBSTR(SourceLine(2), 3));
 PARSE VAR TitleLine CmdName'.CMD 'Info
 Title     = CmdName Info

 env          = 'OS2ENVIRONMENT';
 TRUE         = (1 = 1);
 FALSE        = (0 = 1);
 CrLf         = '0d0a'x;
 Redirection  = '> NUL 2>&1';
 '@ECHO OFF'

 /* OS/2 Error codes */
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

 GlobalVars = 'Title CmdName CrLf env TRUE FALSE Redirection ERROR.';
 SAY;

 /* eventually show help */
 ARG Parm .
 IF ((Parm = '') | (POS('?', Parm) > 0)) THEN
 DO
    rc = ShowHelp();
    EXIT(ERROR.INVALID_PARAMETER);
 END;

 /* dafault values */
 GlobalVars = GlobalVars '';
 rc = ERROR.NO_ERROR;


 DO UNTIL (TRUE)



 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
HALT:
 SAY 'Abbruch durch Benutzer.';
 EXIT(ERROR.GEN_FAILURE);

/* ------------------------------------------------------------------------- */
ShowHelp: PROCEDURE EXPOSE (GlobalVars)

 /* show title */
 SAY Title;
 SAY;

 PARSE SOURCE . . ThisFile

 /* skip header */
 DO i = 1 TO 3
    rc = LINEIN(ThisFile);
 END;

 /* show help text */
 ThisLine = LINEIN(Thisfile);
 DO WHILE (ThisLine \= ' */')
    SAY SUBSTR(ThisLine, 7);
    ThisLine = LINEIN(Thisfile);
 END;

 /* close file */
 rc = LINEOUT(Thisfile);

 RETURN('');

