/****************************** Module Header *******************************
*
* Module Name: autolink.e
*
* This module is executed by load.e and is responsible to load
* all modules found in <UserDir>\autolink
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: autolink.e,v 1.9 2006-11-12 13:13:45 jbs Exp $
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

defc Autolink
   call Autolink()

defproc Autolink

    -- determine autolink directory
    UserDir = NepmdQueryInstValue( 'USERDIR')
    parse value UserDir with 'ERROR:'rc
    if (rc > '') then
       return rc
    endif
    AutoLinkDir = UserDir'\autolink'

    -- loop through all .ex files

    Handle          = GETNEXT_CREATE_NEW_HANDLE    -- always create a new handle!
    AddressOfHandle = address( Handle)
    FileMask        = AutoLinkDir'\*.ex'

    do while (1)
       Filename = NepmdGetNextFile( FileMask, AddressOfHandle)
       parse value Filename with 'ERROR:'rc
       if (rc > '') then
          leave
       endif

       --'link' Filename;
       link Filename  -- message would slow startup down
    enddo
    rc = 0  -- no error from here

    return rc

