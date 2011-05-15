/****************************** Module Header *******************************
*
* Module Name: unhtml.e
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

defmain
   'unhtml'

defc unhtml
   call psave_pos(saved_pos)
   'display -2'               /* Turn off messages. */
   '0'                        /* Go to top of file. */
   'c /<[^>]*>// *x'          /* Delete all tags. */
   '0'                        /* Go to top of file. */
   'c /&lt;/</ *'             /* Handle some common symbols... */
   '0'
   'c /&gt;/>/ *'
   '0'
   'c /&amp;/&/ *'
   '0'
   'c /&quot;/"/ *'
   '0'
   'c /&nbsp;/ / *'
   'display 2'                /* Turn messages back on. */
   call prestore_pos(saved_pos)

