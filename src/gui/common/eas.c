/****************************** Module Header *******************************
*
* Module Name: eas.c
*
* Generic routines for accessing simple string extended attributes
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: eas.c,v 1.1 2002-06-03 22:19:57 cla Exp $
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

#define INCL_DOS
#define INCL_ERRORS
#include <os2.h>

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

#include "eas.h"

// set to 1 to activate
// #define USE_EAMVMT 1

#define MAX(a,b)   (a > b ? a : b)
#define MAX(a,b)   (a > b ? a : b)
#define NEXTSTR(s) (s+strlen(s) + 1)

// ------------------------------------------------------------------------------

APIRET WriteStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszEaValue)
{

         APIRET         rc     = NO_ERROR;
         PFEA2LIST      pfea2l = NULL;
         PEASVST        peasvst;
         PEAMVMT        peamvmt;
         ULONG          ulEAListLen;
         ULONG          ulValueLen;
         EAOP2          eaop2;
         PSZ            pszValue;

do
   {
   // check parameters
   if ((!pszFileName) ||
       (!pszEaName)   ||
       (!*pszEaName)  ||
       (!pszEaValue))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // write EAs
   ulValueLen  = strlen( pszEaValue) +

#ifdef USE_EAMVMT
                 sizeof( EAMVMT);
#else
                 sizeof( EASVST);
#endif

   ulEAListLen = strlen( pszEaName)  +
                 sizeof( FEA2LIST)   +
                 ulValueLen;

   // get memory for FEA2LIST
   if ((pfea2l = malloc( ulEAListLen)) == 0)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }

   // init FEA2LIST
   eaop2.fpGEA2List = NULL;
   eaop2.fpFEA2List = pfea2l;
   memset( pfea2l, 0, ulEAListLen);

   // write timeframe EA
   pfea2l->cbList = ulEAListLen;
   pfea2l->list[ 0].cbName  = strlen( pszEaName);
   strcpy( pfea2l->list[ 0].szName, pszEaName);

   // delete attribute if value empty
   if (strlen( pszEaValue) == 0)
      pfea2l->list[ 0].cbValue = 0;
   else
      {

      pfea2l->list[ 0].cbValue = ulValueLen;

#ifdef USE_EAMVMT
      // multi value multi type
      peamvmt = (PEAMVMT) NEXTSTR( pfea2l->list[ 0].szName);
      peamvmt->usType      = EAT_MVMT;
      peamvmt->usCodepage  = 0;
      peamvmt->usEntries   = 1;
      peamvmt->usEntryType = EAT_ASCII;
      peamvmt->usEntryLen  = strlen( pszEaValue);
      memcpy( &peamvmt->chEntry[0], pszEaValue, peamvmt->usEntryLen);
#else
      // single value single type
      peasvst = (PEASVST) NEXTSTR( pfea2l->list[ 0].szName);
      peasvst->usType      = EAT_ASCII;
      peasvst->usEntryLen  = strlen( pszEaValue);
      memcpy( &peasvst->chEntry[0], pszEaValue, peasvst->usEntryLen);
#endif
      }

   // set the new EA value
   rc = DosSetPathInfo( pszFileName,
                        FIL_QUERYEASIZE,
                        &eaop2,
                        sizeof( eaop2),
                        0);

   } while (FALSE);

// cleanup
if (pfea2l)         free( pfea2l);
return rc;
}

// ------------------------------------------------------------------------------

APIRET ReadStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszBuffer, PULONG pulBuflen)
{

         APIRET         rc     = NO_ERROR;
         FILESTATUS4    fs4;

         EAOP2          eaop2;
         PGEA2LIST      pgea2l = NULL;
         PFEA2LIST      pfea2l = NULL;

         PGEA2          pgea2;
         PFEA2          pfea2;

         ULONG          ulGea2Len = 0;
         ULONG          ulFea2Len = 0;

         PEASVST        peasvst;
         PEAMVMT        peamvmt;

         ULONG          ulRequiredLen;
do
   {
   // check parameters
   if ((!pszFileName) ||
       (!pszEaName)   ||
       (!*pszEaName)  ||
       (!pulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // initialize target buffer
   if (pszBuffer)
      memset( pszBuffer, 0, *pulBuflen);

   // get EA size
   rc = DosQueryPathInfo( pszFileName,
                          FIL_QUERYEASIZE,
                          &fs4,
                          sizeof( fs4));
   if (rc != NO_ERROR)
      break;

   // no eas here ?
   if (fs4.cbList == 0)
      {
      pulBuflen = 0;
      break;
      }

   // determine required space
   // - for ulFea2Len use at least 2 * Gea2Len because
   //   buffer needs at least to be Geal2Len even for an empty
   //   attribute, otherwise rc == ERROR_BUFFER_OVERFLOW !
   ulGea2Len = sizeof( GEA2LIST) + strlen( pszEaName);
   ulFea2Len = 2 * MAX(fs4.cbList, ulGea2Len);

   // get memory for GEA2LIST
   if ((pgea2l = malloc(  ulGea2Len)) == 0)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pgea2l, 0, ulGea2Len);

   // get memory for FEA2LIST
   if ((pfea2l = malloc( ulFea2Len)) == 0)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pfea2l, 0, ulFea2Len);

   // init ptrs and do the query
   memset( &eaop2, 0, sizeof( EAOP2));
   eaop2.fpGEA2List = pgea2l;
   eaop2.fpFEA2List = pfea2l;
   pfea2l->cbList = ulFea2Len;
   pgea2l->cbList = ulGea2Len;

   pgea2 = &pgea2l->list[ 0];
   pfea2 = &pfea2l->list[ 0];


   pgea2->oNextEntryOffset  = 0;
   pgea2->cbName            = strlen( pszEaName);
   strcpy( pgea2->szName, pszEaName);

   rc = DosQueryPathInfo( pszFileName,
                          FIL_QUERYEASFROMLIST,
                          &eaop2,
                          sizeof( eaop2));
   if (rc != NO_ERROR)
      break;

   // check first entry only
   peamvmt = (PEAMVMT) ((PBYTE) pfea2->szName + pfea2->cbName + 1);

   // is it MVMT ? then adress single EA !
   if (peamvmt->usType == EAT_MVMT)
      {
      peasvst = (PEASVST) &peamvmt->usEntryType;
      }
   else
      peasvst = (PEASVST) peamvmt;


   // is entry empty ?
   if (peasvst->usEntryLen == 0)
      {
      rc = ERROR_INVALID_EA_NAME;
      break;
      }

   // is it ASCII ?
   if (peasvst->usType != EAT_ASCII)
      {
      rc = ERROR_INVALID_DATA;
      break;
      }

   // check buffer and hand over value
   ulRequiredLen = peasvst->usEntryLen + 1;
   if (*pulBuflen < ulRequiredLen)
      {
      *pulBuflen = ulRequiredLen;
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over len
   *pulBuflen = ulRequiredLen;

   // hand over value
   if (pszBuffer)
      memcpy( pszBuffer, peasvst->chEntry, peasvst->usEntryLen);

   } while (FALSE);

// cleanup
if (pgea2l) free( pgea2l);
if (pfea2l) free( pfea2l);
return rc;
}

