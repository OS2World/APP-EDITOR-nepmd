/*
 *      TOUCHREL.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: touchrel filemask
 *
 *    This program calls GNU touch to set the timestamp of the specified
 *    files. The timestamp of the last full hour or last half hour is used.
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: touchrel.cmd
*
* Batch for to touch files with an automatic selected timestamp
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: touchrel.cmd,v 1.1 2002-11-04 23:18:28 cla Exp $
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

 '@ECHO OFF'

 /* get command parms */
 PARSE ARG Parms;
 IF (Parms = '') THEN
 DO
    SAY 'no parms given.';
    EXIT( 87);
 END;

 /* check timestamp */
 PARSE VALUE DATE('S')  WITH Year +4 MonthDay;
 PARSE VALUE TIME( 'N') WITH Hours':'Mins':'Secs;
 Hours = RIGHT( Hours, 2, '0');

 IF (Mins > 30) THEN
    Mins = '30';
 ELSE
    Mins = '00';
 TimeStamp = MonthDay''Hours''Mins''Year'.00';


 'call touch -t' TimeStamp Parms

