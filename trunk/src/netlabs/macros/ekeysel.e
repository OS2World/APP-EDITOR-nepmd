/****************************** Module Header *******************************
*
* Module Name: ekeysel.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ekeysel.e,v 1.2 2002-07-22 18:59:49 cla Exp $
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
;      An if-block that gets included into select_edit_keys().
if ext='E' then
   keys e_keys
endif
