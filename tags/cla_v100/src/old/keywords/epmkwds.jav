@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.jav
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
@  This file contains JAVA keywords only.
@  Update:  The size has been cut in half by converting spaces to tabs.
@           If you don't use a monospaced font, things will appear misaligned.
@           The Extended Attribute EPM.TABS was used to ensure that tab stops
@           are set at every 8 columns.
@  EPM looks for this file along the EPMPATH.
@  The loading time can be reduced by removing some keywords from the list.
@  The format to follow is described below.
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start   Color Color  End     Escape
@ string  bg    fg     string  character
  /*       -1     13   */
  //       -1     13
@ Caution:  Only enable the following if you always leave a space after a //
@ - otherwise, it will cause some comments to not be highlighted.
@ //todo   14     12
@ //Todo   14     12
@ //ToDo   14     12
@ //TODO   14     12
  "        -1      2   "       \
  '        -1     10   '       \
@
@SPECIAL
@
{  -1  12
}  -1  12
;  -1  12
,  -1  12
?  -1  12
:  -1  12
@
@CHARSET
@
abcdefghijklmnopqrstuvwxyz_#ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
@
@KEYWORDS
@
@ -------------------- C/Java/C++ language constructs ---------------------------
abstract	-1	5
boolean		-1	5
break		-1	5
byte		-1	5
@ byvalue	-1	5
case		-1	5
catch		-1	5
char		-1	5
class		-1	5
@ const		-1	5
continue	-1	5
default 	-1	5
do		-1	5
double		-1	5
@ enum		-1	5
else		-1	5
extends		-1	5
@ extern		-1	5
false		-1	5
final		-1	5
finally		-1	5
float		-1	5
for		-1	5
@ goto		-1	5
if		-1	5
implements	-1	5
import		-1	5
instanceof	-1	5
int		-1	5
interface	-1	5
long		-1	5
@ main		-1	5
native		-1	5
new		-1	5
null		-1	5
package		-1	5
private		-1	5
protected	-1	5
public		-1	5
@ register	-1	5
return		-1	5
short		-1	5
@ signed		-1	5
@ sizeof		-1	5
static		-1	5
@ struct		-1	5
super		-1	5
switch		-1	5
synchronized	-1	5
this		-1	5
threadsafe	-1	5
throw		-1	5
transient	-1	5
true		-1	5
try		-1	5
@ typedef 	-1	5
@ union		-1	5
@ unsigned	-1	5
void		-1	5
@ volatile	-1	5
while		-1	5
