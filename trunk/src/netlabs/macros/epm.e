/****************************** Module Header *******************************
*
* Module Name: epm.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epm.e,v 1.2 2002-07-22 18:59:58 cla Exp $
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
define INCLUDING_FILE = 'EPM.E'

include 'e.e'       -- This is the main file for all versions of E.

compile if EVERSION >= '6.00c'
 compile if EXTRA_EX
   compiler_msg EXTRA_EX is set; not needed for EPM 6.00.  You might want to modify
   compiler_msg your MYCNF.E.  Don't forget to recompile EXTRA if appropriate.
 compile endif
 compile if LINK_HOST_SUPPORT
   compiler_msg LINK_HOST_SUPPORT is set; not needed for EPM 6.00.  You might want to
    compiler_msg modify your MYCNF.E.
  compile if HOST_SUPPORT = 'EMUL'
    compiler_msg Don't forget to recompile E3EMUL if appropriate.
  compile elseif HOST_SUPPORT = 'SRPI'
    compiler_msg Don't forget to recompile SLSRPI if appropriate.
  compile else
    compiler_msg Don't forget to recompile your host support if appropriate.
  compile endif
 compile endif
compile endif
