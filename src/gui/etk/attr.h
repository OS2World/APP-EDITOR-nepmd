/****************************** Module Header *******************************
*
* Module Name: attr.h
*
* Original E Toolkit header file from the EPMBBS package
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

#ifndef ATTR_INCLUDED
   #define ATTR_INCLUDED
   typedef unsigned char   ATTRIBCLASSTYPE;
   typedef signed long     ATTRIBVALUETYPE;
   #define INVALIDCLASS    ((ATTRIBCLASSTYPE)0)
   #define COLORCLASS      ((ATTRIBCLASSTYPE)1)
   #define MAXCOLOR        ((ATTRIBVALUETYPE)255)
   #define FLOWCLASS       ((ATTRIBCLASSTYPE)2)
   #define JUSTIFYCLASS    ((ATTRIBCLASSTYPE)3)
   #define TABCLASS        ((ATTRIBCLASSTYPE)4)
   #define TAB2CLASS       ((ATTRIBCLASSTYPE)5)
   #define PAGEBRK1CLASS   ((ATTRIBCLASSTYPE)6)
   #define FONTCLASS       ((ATTRIBCLASSTYPE)16)
   #define BREAKCLASS      ((ATTRIBCLASSTYPE)17)
   #define LINEBREAKLEVEL  0x10
   #define COLMBREAKLEVEL  0x40
   #define STACKBREAKLEVEL 0x60
   #define DIVNBREAKLEVEL  0x80
   #define HSPACECLASS     ((ATTRIBCLASSTYPE)18)
   #define DIVISIONCLASS   ((ATTRIBCLASSTYPE)19)

   typedef struct ATTRIBRECTYPE {
     USHORT          Col;
     ATTRIBCLASSTYPE Class;
     UCHAR           IsPush;
     ATTRIBVALUETYPE Value;
   } ATTRIBRECTYPE;
   typedef ATTRIBRECTYPE * PATTRIBRECTYPE;
   typedef PATTRIBRECTYPE * PPATTRIBRECTYPE;

   #define MAXATTRBPL       255
   #define MAXATTRBSPACE    (MAXATTRBPL*sizeof(ATTRIBRECTYPE))

   // the following type is allocated by AllocNullAttrString() and freed
   // via FreeAttrString(); The Text will grow from s[0] toward the
   // end of the record and the attributes will positioned so that
   // the last one is flush with the end of the allocated space for
   // this structure.
   typedef struct _ATTRSTRING {
      PATTRIBRECTYPE ALAttr;
      PATTRIBRECTYPE Attrs;
      PCHAR SelfPtr;      // this is a redundant field that points to itself.
                          //   This field is automatically initialized when
                          //   when the attrstring is created.
                          // procedures that receive attrstring's that
                          //   may have been created before the previous
                          //   heap compact should check this field to
                          //   insure that it still points to the Text
                          //   field.  They can do this by using the
                          //   ATTRSTRING_REVALIDATE() macro.  This is
                          //   necessary since the Attrs and ALAttr fields
                          //   become invalid when the heap compacter moves
                          //   the attrstring.
      SHORT  TextLen;
      CHAR   Text[1];
   } ATTRSTRING;
   typedef ATTRSTRING  *PATTRSTRING;
   typedef PATTRSTRING *PPATTRSTRING;
   #define access_as(a)   (*((PPATTRSTRING)(a)))
   #if 1
      /*
      \  Note that ATTRSTRING_REVALIDATE is not thread reentrant.  Therefore
       \ it should only be called in the interpretter thread.  It can also be
       / called from another thread if one can be sure that another copy
      /  is not executing.  A reentrant version could be made easily with
      \  DosEnter/ExitCritSec or with more difficulty via normal C if we
       \ can assume pointer fetch/set is an atomic action.
      */

      #define BUGFIX00236
      #ifdef BUGFIX00236
         /* We only set the high part because if we are using 16bit code, the assignment
         \     is not atomic, so there can be a thread switch between two halfs if the
          \     value is 32bit.  We don't do this for the second assignment because
           \    we know that our 16 bit compiler assigns the low 16 bits first.
           /    Warning: optimizing compilers might strip the first assignment which
          /     renders this locking code useless.
          */
         #define ASREVALSELECTOROF(p)       (((PUSHORT)&(p))[1])

         #define ATTRSTRING_REVALIDATE(ina) \
                { \
                   PATTRSTRING as = *(ina); \
                   if (((PVOID)&(as->SelfPtr))!=(PVOID)as->SelfPtr) { \
                      PCHAR spOld = as->SelfPtr; \
                      ASREVALSELECTOROF(as->SelfPtr) = 0; \
                      as->Attrs  = (PATTRIBRECTYPE) ((PCHAR)&(as->SelfPtr) + ((PCHAR)as->Attrs  - spOld)); \
                      as->ALAttr = (PATTRIBRECTYPE) ((PCHAR)&(as->SelfPtr) + ((PCHAR)as->ALAttr - spOld)); \
                      as->SelfPtr= (PCHAR)&(as->SelfPtr); \
                   } /* endif */ \
                }
      #else
         #define ATTRSTRING_REVALIDATE(ina) \
                { \
                   PATTRSTRING as = *(ina); \
                   if (((PVOID)&(as->SelfPtr))!=(PVOID)as->SelfPtr) { \
                      as->Attrs  = (PATTRIBRECTYPE) ((PCHAR)&(as->SelfPtr) + ((PCHAR)as->Attrs  - as->SelfPtr)); \
                      as->ALAttr = (PATTRIBRECTYPE) ((PCHAR)&(as->SelfPtr) + ((PCHAR)as->ALAttr - as->SelfPtr)); \
                      as->SelfPtr= (PCHAR)&(as->SelfPtr); \
                   } /* endif */ \
                }
      #endif


   #endif
#endif

