@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.f90
@
@ Copyright (c) Netlabs EPM Distribution Project 2002
@
@ $Id: epmkwds.f90,v 1.1 2002-10-03 22:01:51 cla Exp $
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
@ The following is a file that will syntax color EPM 6.03 editor for OS2
@ Warp for Fortran 90 program.  Hope you find it useful.
@
@ Jason Liao
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start      Color Color  End     Escape
@ string     bg    fg     string  character  Col.
     ! -1 15
  real(kind= -1    9      )
  (len=      -1    9      )
@
@SPECIAL
@
::                  -1 9
bit_size            -1 3
selected_int_kind   -1 3
selected_real_kind  -1 3
dot_product         -1 3
random_number       -1 3
random_seed         -1 3
data_and_time       -1 3
len_trim            -1 3
set_exponent        -1 3
system_clock        -1 3
@
@CHARSET
@
abcdefghijklmnopqrstuvwxyz_#ABCDEFGHIJKLMNOPQRSTUVWXYZ012345678-1 3=*!.
@
@INSENSITIVE
@
@ -------------------- compile-time keywords ---------------------------
allocatable -1 9
allocate    -1 9
if          -1 9
go          -1 9
backspace   -1 9
call        -1 9
case        -1 9
character   -1 9
close       -1 9
contains    -1 9
continue    -1 9
cycle       -1 9
data        -1 9
deallocate  -1 9
type        -1 9
dimension   -1 9
do          -1 9
else        -1 9
else        -1 9
elsewhere   -1 9
end         -1 9
endfile     -1 9
exit        -1 9
external    -1 9
format      -1 9
function    -1 9
if          -1 9
implicit    -1 9
inquire     -1 9
integer     -1 9
intent      -1 9
interface   -1 9
intrinsic   -1 9
module      -1 9
namelist    -1 9
none        -1 9
nullify     -1 9
open        -1 9
optional    -1 9
parameter   -1 9
pointer     -1 9
print       -1 9
private     -1 9
program     -1 9
public      -1 9
read        -1 9
result      -1 9
return      -1 9
rewind      -1 9
save        -1 9
select      -1 9
sequence    -1 9
stop        -1 9
subroutine  -1 9
target      -1 9
then        -1 9
to          -1 9
type        -1 9
use         -1 9
where       -1 9
write       -1 9
@ -------------------- functions ---------------------------
abs         -1 3
achar       -1 3
acos        -1 3
adjustl     -1 3
adjustr     -1 3
aimag       -1 3
aint        -1 3
all         -1 3
allocated   -1 3
amint       -1 3
any         -1 3
asin        -1 3
associated  -1 3
atan        -1 3
atan2       -1 3
btest       -1 3
ceiling     -1 3
char        -1 3
cmplx       -1 3
conjg       -1 3
cos         -1 3
cosh        -1 3
count       -1 3
cshift      -1 3
dble        -1 3
digits      -1 3
dim         -1 3
dprod       -1 3
eoshift     -1 3
epsilon     -1 3
exp         -1 3
exponent    -1 3
floor       -1 3
fraction    -1 3
huge        -1 3
iachar      -1 3
iand        -1 3
ibclr       -1 3
ibits       -1 3
ibset       -1 3
ichar       -1 3
ieor        -1 3
index       -1 3
int         -1 3
ior         -1 3
ishft       -1 3
ishftc      -1 3
kind        -1 3
lbound      -1 3
len         -1 3
lge         -1 3
lgt         -1 3
lle         -1 3
llt         -1 3
log         -1 3
log1        -1 3
logical     -1 3
matmul      -1 3
max         -1 3
maxexponent -1 3
maxloc      -1 3
maxval      -1 3
merge       -1 3
min         -1 3
minexponent -1 3
minloc      -1 3
minval      -1 3
mod         -1 3
mvbits      -1 3
nearest     -1 3
mint        -1 3
not         -1 3
pack        -1 3
precision   -1 3
present     -1 3
product     -1 3
radix       -1 3
range       -1 3
real        -1 3
repeat      -1 3
reshape     -1 3
prspacing   -1 3
scale       -1 3
scan        -1 3
shape       -1 3
sign        -1 3
sin         -1 3
sinh        -1 3
size        -1 3
spacing     -1 3
spread      -1 3
sqrt        -1 3
sum         -1 3
tan         -1 3
tanh        -1 3
tiny        -1 3
transfer    -1 3
transpose   -1 3
trim        -1 3
ubound      -1 3
unpack      -1 3
verify      -1 3
