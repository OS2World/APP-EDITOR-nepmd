@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.rex
@
@ Copyright (c) Netlabs EPM Distribution Project 2002
@
@ $Id: epmkwds.rex,v 1.1 2002-10-03 22:01:53 cla Exp $
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
@ This file is a subset of the EPMKWDS.CMD provided by Richard Moore
@ and Neil Suffiel.  The TSO Rexx functions were deleted.  Their
@ package also adds support for toggling the color support from the
@ toolbar.  A copy of their package may be obtained (by IBM internal
@ users) by executing the VM command:
@    REQUEST RxColor from 86664603 at HONE
@ or
@    REQUEST RxColor from 86693454 at EHONE
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start   Color Color  End     Escape
@ string  bg    fg     string  character
  /*      -1     1     */
@ (       -1    10     )
  "       -1     2     "
  '       -1     2     '
@
@SPECIAL
@
( -1 0
) -1 0
; -1 0
: -1 0
, -1 0
= -1 0
- -1 0
+ -1 0
\ -1 0
/ -1 0
* -1 0
ª -1 0
< -1 0
> -1 0
% -1 0
& -1 0
@ -1 0
@
@CHARSET
@
.abcdefghijklmnopqrstuvwxyz_!?ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
@
@INSENSITIVE
@
@ -------------------OS2 REXX Utility Functions
RxMessageBox              -1  4
RxFuncAdd                 -1  4
RxFuncDrop                -1  4
RxFuncQuery               -1  4
RxQueue                   -1  4
SysCls                    -1  4
SysCreateObject           -1  4
SysCurPos                 -1  4
SysCurState               -1  4
SysDeregisterObjectClass  -1  4
SysDestroyObject          -1  4
SysDriveInfo              -1  4
SysDriveMap               -1  4
SysDropFuncs              -1  4
SysFileDelete             -1  4
SysFileTree               -1  4
SysFileSearch             -1  4
SysGetEA                  -1  4
SysGetKey                 -1  4
SysGetMessage             -1  4
SysIni                    -1  4
SysMkDir                  -1  4
SysOS2Ver                 -1  4
SysPutEA                  -1  4
SysQueryClassList         -1  4
SysRegisterObjectClass    -1  4
@ ---------------SAA  REXX Keywork Instructions
address                   -1  4
arg                       -1  4
call                      -1  4
do                        -1  4
drop                      -1  4
end                       -1  4
else                      -1  4
exit                      -1  4
expose                    -1  4
if                        -1  4
interpret                 -1  4
iterate                   -1  4
leave                     -1  4
nop                       -1  4
numeric                   -1  4
options                   -1  4
otherwise                 -1  4
parse                     -1  4
procedure                 -1  4
pull                      -1  4
push                      -1  4
queue                     -1  4
return                    -1  4
say                       -1  4
select                    -1  4
signal                    -1  4
then                      -1  4
trace                     -1  4
when                      -1  4
@ ----------------SAA REXX Functions
abbrev                    -1  4
abs                       -1  4
address                   -1  4
api                       -1  4
arg                       -1  4
bitand                    -1  4
bitor                     -1  4
bitxor                    -1  4
b2x                       -1  4
center                    -1  4
centre                    -1  4
compare                   -1  4
condition                 -1  4
copies                    -1  4
c2d                       -1  4
c2x                       -1  4
datatype                  -1  4
date                      -1  4
delstr                    -1  4
delword                   -1  4
digits                    -1  4
d2c                       -1  4
d2x                       -1  4
errortext                 -1  4
form                      -1  4
format                    -1  4
fuzz                      -1  4
insert                    -1  4
lastpos                   -1  4
left                      -1  4
length                    -1  4
max                       -1  4
min                       -1  4
overlay                   -1  4
pos                       -1  4
queued                    -1  4
random                    -1  4
reverse                   -1  4
right                     -1  4
sign                      -1  4
sourceline                -1  4
space                     -1  4
strip                     -1  4
substr                    -1  4
subword                   -1  4
symbol                    -1  4
time                      -1  4
trace                     -1  4
translate                 -1  4
trunc                     -1  4
value                     -1  4
verify                    -1  4
word                      -1  4
wordindex                 -1  4
wordlength                -1  4
wordpos                   -1  4
words                     -1  4
xrange                    -1  4
x2b                       -1  4
x2c                       -1  4
x2d                       -1  4
@ ----------------- OS2 Functions
beep                      -1  4
setlocal                  -1  4
endlocal                  -1  4
filespec                  -1  4
directory                 -1  4
linein                    -1  4
lineout                   -1  4
lines                     -1  4
charin                    -1  4
charout                   -1  4
chars                     -1  4
stream                    -1  4

