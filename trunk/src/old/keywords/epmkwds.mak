@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.mak
@
@ Copyright (c) Netlabs EPM Distribution Project 2002
@
@ $Id: epmkwds.mak,v 1.1 2002-10-03 22:01:52 cla Exp $
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
@ EPM Keyword Highlighting for NMAKE Makefiles:
@
@ By: Michael Cadek
@     IBM Vienna Solutions Development Center, Austria
@
@     Internet:   cadekm@vnet.ibm.com
@     VNet:       CADEK at SDFVM1
@
@ Suggestions, enhancements and bug reports are all welcome!
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start   Color Color  End     Escape
@ string  bg    fg     string  character
  #       -1     9
  "       -1     2     "       \
  $(      -1    12     )
@
@SPECIAL
@
:     -1     3
=     -1     3
;     -1     3
{     -1     3
}     -1     3
[     -1     3
]     -1     3
<<    -1     3
^     -1     3
@ -------------------- Special macros -------------------------------------
$@    -1    12
$*    -1    12
$**   -1    12
$?    -1    12
$<    -1    12
$$@   -1    12
@
@CHARSET
@
abcdefghijklmnopqrstuvwxyz!.ABCDEFGHIJKLMNOPQRSTUVWXYZ
@
@INSENSITIVE
@
@ -------------------- NMAKE directives -----------------------------------
!CMDSWITCHES   -1    5
!ELSE          -1    5
!ENDIF         -1    5
!ERROR         -1    5
!IF     	      -1	   5
!IFDEF  	      -1	   5
!IFNDEF        -1	   5
!INCLUDE       -1    5
!UNDEF         -1    5
@ -------------------- NMAKE pseudotargets --------------------------------
.IGNORE        -1    4
.PRECIOUS      -1    4
.SILENT        -1    4
.SUFFIXES      -1    4
