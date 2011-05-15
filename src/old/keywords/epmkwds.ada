@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.ada
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
@  This file is used by EPM to figure out which keywords to highlight
@  It contains all the ISO 8652:95 Ada keywords.
@  (Contributed by Geert Bosch)
@  EPM looks for this file along the EPMPATH.
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start   Color Color  End     Escape
@ string  bg    fg     string  character
  --       -1     13
  "        -1     12   "
  %        -1     12   %
@
@CHARSET
@
abcdefghijklmnopqrstuvwxyz_'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
@
@INSENSITIVE
@
@ -------------------- Ada keywords ---------------------------
abort           -1      5
abs             -1      5
abstract        -1      5
accept          -1      5
access          -1      5
aliased         -1      5
all             -1      5
and             -1      5
array           -1      5
at              -1      5
begin           -1      5
body            -1      5
case            -1      5
constant        -1      5
declare         -1      5
delay           -1      5
delta           -1      5
digits          -1      5
do              -1      5
else            -1      5
elsif           -1      5
end             -1      5
entry           -1      5
exception       -1      5
exit            -1      5
for             -1      5
function        -1      5
generic         -1      5
goto            -1      5
if              -1      5
in              -1      5
is              -1      5
limited         -1      5
loop            -1      5
mod             -1      5
new             -1      5
not             -1      5
null            -1      5
of              -1      5
or              -1      5
others          -1      5
out             -1      5
package         -1      5
pragma          -1      5
private         -1      5
procedure       -1      5
protected       -1      5
raise           -1      5
range           -1      5
record          -1      5
rem             -1      5
renames         -1      5
requeue         -1      5
return          -1      5
reverse         -1      5
select          -1      5
separate        -1      5
subtype         -1      5
tagged          -1      5
task            -1      5
terminate       -1      5
then            -1      5
type            -1      5
until           -1      5
use             -1      5
when            -1      5
while           -1      5
with            -1      5
xor             -1      5
