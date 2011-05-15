/****************************** Module Header *******************************
*
* Module Name: pmprintf.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
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

/*
@@NepmdPmPrintf@PROTOTYPE
NepmdPmPrintf( Message);

@@NepmdPmPrintf@CATEGORY@INTERACT

@@NepmdPmPrintf@SYNTAX
This function pipes a message to an external PmPrintf utility.

@@NepmdPmPrintf@PARM@Message
Message can be any string in quotes or doublequotes.

@@NepmdPmPrintf@RETURNS
*NepmdPmPrintf* returns nothing and doesn't change rc.

@@NepmdPmPrintf@REMARKS
The processing is much faster than the sayerror statement and works even on
EPM startup. A large amount of NepmdPmPrintf calls will slow down processing
or even crash EPM.

If you don't have a PmPrintf utility, download it from Dennis Bareis' site:
.sl compact
- [http://www.labyrinth.net.au/~dbareis/freeos2.htm]
.el

It is recommanded to prepend your message by the current defc or defproc
or by the macro filename, e.g.:
.sl
- PmPrintf( 'MYCOMMAND: Executing mystep, myvar = 'myvar)

@@NepmdPmPrintf@TESTCASE
You can test this function from the *EPM* commandline by
starting a PmPrintf utility with
.sl
- start pmprintf
.el
and executing:
.sl
- *NepmdPmPrintf* [.IDPNL_EFUNC_NEPMDPMPRINTF_PARM_ENVNAME This is my message.]
  - or
- *PmPrintf* [.IDPNL_EFUNC_NEPMDPMPRINTF_PARM_ENVNAME This is my message.]

Executing this command will
generate a line with the text #This is my message.# in the window of a
PmPrintf utility.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdPmPrintf, PmPrintf =

   Text = arg( 1)
   if (Text = '') then
      sayerror 'Error: no text specified.'
      return
   endif

   call NepmdPmPrintf( Text)

   return

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdPmPrintf                                      */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    NepmdPmPrintf( Text);                                      */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdPmPrintf( PSZ pszText);                 */
/* ------------------------------------------------------------- */

defproc NepmdPmPrintf( Text)

   -- save previous rc
   -- (required for not to change rc by helperNepmdCheckliberror)
   saved_rc = rc

   -- prepare parameters for C routine
   Text = Text\0;

   -- call C routine
   LibFile = helperNepmdGetlibfile()
   ret = dynalink32( LibFile,
                     'NepmdPmPrintf',
                     address( Text))

   -- The following sets rc to the value of its 2nd param
   helperNepmdCheckliberror( LibFile, ret)   -- not required anymore

   rc = saved_rc

   return

