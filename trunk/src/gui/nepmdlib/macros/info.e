/****************************** Module Header *******************************
*
* Module Name: info.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: info.e,v 1.1 2002-08-23 15:53:59 cla Exp $
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

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdInfo =

 InfoFile = '.NEPMD_INFO'

 /* determine messsage file and messages required */
 MessageFile = NepmdGetInstValue( 'MESSAGE');
 parse value MessageFile with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'error: cannot determine NEPMD messagefile, rc='rc;
    return;
 endif

 InfoHeader = NepmdGetTextMessage( MessageFile, 'MSG_INFO_HEADER');
 /* InfoBody   = NepmdGetTextMessage( MessageFile, 'MSG_INFO_BODY'); */
 
 /* edit new file and disable autosave */
 'xcom e /c 'InfoFile;
 .autosave = 0;
 
 /* inset data */
 insertline InfoHeader;

 /* let it be easily discardable */
 .modify = 0;
 

