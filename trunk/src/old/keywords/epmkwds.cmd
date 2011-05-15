@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.cmd
@
@ Copyright (c) Netlabs EPM Distribution Project 2002
@
@ $Id$
@
@ ===========================================================================
@
@ This file is part of the Netlabs EPM Distribution package and is free
@ software.  You can redistribute it and/or modify it under the terms of the
@ GNU General Public License as published by the Free Software
@ Foundation, in version 2 as it comes in the "COPYING" file of the
@ Netlabs EPM Distribution.  This library is distributed in the hope that it
@ will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
@ of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
@ General Public License for more details.
@
@ **************************************************************************/

@ ------------------------------------------------------------------
@ Format of the file - see NEPMD.INF
@ ------------------------------------------------------------------
@
@ This file is provided by Christian Langanke and is intended for
@ use with plain CMD/BAT files only, not REXX scripts.
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start   Color Color  End     Escape     column
@ string  bg    fg     string  character
  %        -1      3   %       ^
  "        -1      2   "       ^
  '        -1      2   '       ^

@DELIMI
@
@ Start   Color Color  End     Escape     column
@ string  bg    fg     string  character
  REM      -1      1

@
@SPECIAL
@
" -1 0
% -1 0
& -1 0
' -1 0
( -1 0
) -1 0
* -1 0
, -1 0
/ -1 0
< -1 0
> -1 0
@ -1 0
\ -1 0
| -1 0
ª -1 0
@
@CHARSET
@
.\:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
@
@INSENSITIVE
@
@ ------------------- internal commands and keywords of CMD.EXE
BREAK                     -1  4
CALL                      -1  4
CD                        -1  4
CHCP                      -1  4
CHDIR                     -1  4
CLS                       -1  4
COPY                      -1  4
DATE                      -1  4
DATE                      -1  4
DEL                       -1  4
DETACH                    -1  4
DIR                       -1  4
DO                        -1  4
ECHO                      -1  4
ENDLOCAL                  -1  4
ERASE                     -1  4
EXIT                      -1  4
EXIT_VDM                  -1  4
EXTPROC                   -1  4
FOR                       -1  4
GOTO                      -1  4
IF                        -1  4
KEYS                      -1  4
MD                        -1  4
MKDIR                     -1  4
MOVE                      -1  4
OFF                       -1  4
ON                        -1  4
PATH                      -1  4
PAUSE                     -1  4
PROMPT                    -1  4
REN                       -1  4
RENAME                    -1  4
RM                        -1  4
RMDIR                     -1  4
SET                       -1  4
SETLOCAL                  -1  4
SHIFT                     -1  4
TIME                      -1  4
VER                       -1  4
VERIFY                    -1  4
VOL                       -1  4

@ -------------------- external executables of OS/2

ANSI                      -1  5
APPEND                    -1  5
ARCINST                   -1  5
ARCRECOV                  -1  5
ASSIGN                    -1  5
ATTRIB                    -1  5
BACKUP                    -1  5
BLDLEVEL                  -1  5
BOOT                      -1  5
CACHE                     -1  5
CHKDSK                    -1  5
CHKDSK32                  -1  5
CLIPOS2                   -1  5
CMD                       -1  5
COMETRUN                  -1  5
COMMAND                   -1  5
COMP                      -1  5
DEBUG                     -1  5
DISKCOMP                  -1  5
DISKCOPY                  -1  5
DMIPM                     -1  5
DMISL                     -1  5
DOCKMGR                   -1  5
DOSKEY                    -1  5
DTRACE                    -1  5
DUMPPROCESS               -1  5
E                         -1  5
EAUTIL                    -1  5
EJECT                     -1  5
EPM                       -1  5
EPW                       -1  5
EPWCONS                   -1  5
EPWDDR3                   -1  5
EPWDF                     -1  5
EPWDFOLD                  -1  5
EPWICON                   -1  5
EPWMP                     -1  5
EPWMUX                    -1  5
EPWPCT                    -1  5
EPWPSI                    -1  5
EPWRCV                    -1  5
EPWROUT                   -1  5
ERLOGGER                  -1  5
FDISK                     -1  5
FDISKPM                   -1  5
FFST                      -1  5
FFSTCONF                  -1  5
FFSTPCT                   -1  5
FIND                      -1  5
FORMAT                    -1  5
FSACCESS                  -1  5
FSFILTER                  -1  5
GRAFTABL                  -1  5
GSVINST                   -1  5
HDMON                     -1  5
HELP                      -1  5
HELPMSG                   -1  5
IBMDAPAT                  -1  5
IBMDAPPS                  -1  5
ICONEDIT                  -1  5
JOIN                      -1  5
KEYB                      -1  5
LABEL                     -1  5
LD2FIX                    -1  5
LH                        -1  5
LINK                      -1  5
LINK386                   -1  5
LOADHIGH                  -1  5
MAKEINI                   -1  5
MAKETSF                   -1  5
MEM                       -1  5
MODE                      -1  5
MORE                      -1  5
MSGLOGF                   -1  5
MSGWRT                    -1  5
PATCH                     -1  5
PMCHKDSK                  -1  5
PMFORMAT                  -1  5
PMREXX                    -1  5
PMSHELL                   -1  5
PMSPOOL                   -1  5
PRINT                     -1  5
PSFILES                   -1  5
PSSEMS                    -1  5
PSTAT                     -1  5
RC                        -1  5
RCPP                      -1  5
RECOVER                   -1  5
REMOTERR                  -1  5
REPLACE                   -1  5
RESTORE                   -1  5
REXXC                     -1  5
RJAPPLET                  -1  5
RMVIEW                    -1  5
RPLFDISK                  -1  5
RXQUEUE                   -1  5
RXSUBCOM                  -1  5
SETBOOT                   -1  5
SMSTART                   -1  5
SOMDD                     -1  5
SOMDSVR                   -1  5
SORT                      -1  5
SPOOL                     -1  5
STRACE                    -1  5
SVDETECT                  -1  5
SVGA                      -1  5
SVGA5333                  -1  5
SYSLEVEL                  -1  5
SYSLOG                    -1  5
SYSLOGPM                  -1  5
TEDIT                     -1  5
TRACE                     -1  5
TRACEDUMP                 -1  5
TRACEFMT                  -1  5
TRACEGET                  -1  5
TREE                      -1  5
TRSPOOL                   -1  5
UNDELETE                  -1  5
UNPACK                    -1  5
UNPACK2                   -1  5
USBRES                    -1  5
VIEW                      -1  5
VIEWDOC                   -1  5
WARP                      -1  5
WELCOME                   -1  5
WPDSACTV                  -1  5
WPDSINIT                  -1  5
XCOPY                     -1  5
XDFCOPY                   -1  5
