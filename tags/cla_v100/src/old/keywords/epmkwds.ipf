@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.ipf
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
@ Keywords highlighting feature of EPM, for Information Presentation Facility.
@ The tags which can accept parameters are entered as delimiters,
@ so that everything from the : to the . will be highlighted.
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIMI
@
@ Start   Color Color  End     Escape
@ string  bg    fg     string  character   Col.
  .*        14     0      @       @         1
  &         -1     9   .
  :acviewport -1  13   .
  :artwork  -1    13   .
  :caution  -1    13   .
  :color    -1    13   .
  :ctrl     -1    13   .
  :ddf      -1    13   .
  :dl       -1    13   .
  :docprof  -1    13   .
  :font     -1    13   .
  :fn       -1    13   .
  :h1       -1    13   .
  :h2       -1    13   .
  :h3       -1    13   .
  :h4       -1    13   .
  :h5       -1    13   .
  :h6       -1    13   .
  :hide     -1    13   .
  :i1       -1    13   .
  :i2       -1    13   .
  :isyn     -1    13   .
  :lines    -1    13   .
  :link     -1    13   .
  :lm       -1    13   .
  :note     -1    13   .
  :nt       -1    13   .
  :ol       -1    13   .
  :parml    -1    13   .
  :pbutton  -1    13   .
  :rm       -1    13   .
  :sl       -1    13   .
  :table    -1    13   .
  :ul       -1    13   .
  :warning  -1    13   .
@CHARSET
@
abcdefghijklmnopqrstuvwxyz_$#ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.
@
@BREAK
:
;   -1 12
@
@END
.
@
@INSENSITIVE
@
:artlink.     -1 13
:c.           -1 13
:cgraphic.    -1 13
:ctrldef.     -1 13
:dd.          -1 13
:ddhd.        -1 13
:dt.          -1 13
:dthd.        -1 13
:eartlink.    -1 13
:ecaution.    -1 13
:ecgraphic.   -1 13
:ectrldef.    -1 13
:edl.         -1 13
:efig.        -1 13
:efn.         -1 13
:ehide.       -1 13
:ehp1.        -1 13
:ehp2.        -1 13
:ehp3.        -1 13
:ehp4.        -1 13
:ehp5.        -1 13
:ehp6.        -1 13
:ehp7.        -1 13
:ehp8.        -1 13
:ehp9.        -1 13
:elines.      -1 13
:elink.       -1 13
:ent.         -1 13
:eol.         -1 13
:eparml.      -1 13
:esl.         -1 13
:etable.      -1 13
:eul.         -1 13
:euserdoc.    -1 13
:ewarning.    -1 13
:exmp.        -1 13
:fig.         -1 13
:figcap.      -1 13
:hp1.         -1 13
:hp2.         -1 13
:hp3.         -1 13
:hp4.         -1 13
:hp5.         -1 13
:hp6.         -1 13
:hp7.         -1 13
:hp8.         -1 13
:hp9.         -1 13
:icmd.        -1 13
:li.          -1 13
:lp.          -1 13
:p.           -1 13
:pd.          -1 13
:pt.          -1 13
:row.         -1 13
:title.       -1 13
:userdoc.     -1 13
:xmp.         -1 13
@
@ LAM:  Because the following start with an END character, we can't have
@ them as part of INSENSITIVE, so we'll have to call them SPECIAL.
@
@SPECIALI
@
@  IPFCPREP macros
@
.config    -1 5
.imd       -1 5
.nameit    -1 5
.when      -1 5
@
@ IPF control words
@
.br     -1 3
.im     -1 3
