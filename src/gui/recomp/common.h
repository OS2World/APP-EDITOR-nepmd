/****************************** Module Header *******************************
*
* Module Name: common.h
*
* Header with common values used by all source files.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: common.h,v 1.1 2002-06-03 22:27:06 cla Exp $
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

#ifndef COMMON_H
#define COMMON_H

#ifdef DEBUG
#include <malloc.h>
#endif

#define __APPNAME__                    "RECOMP"
#define __PROGSTEM__                   "recomp"
#define __VERSION__                    "V1.00"
#define __YEAR__                       "2002"
#define __HOMEPAGE__                   "http://nepmd.netlabs.org"

// define parameters
#define PARM_START             "Start"
#define PARM_DISCARDUNSAVED    "Discardunsaved"
#define PARM_NORELOADFILES     "NOReloadfiles"
#define PARM_NOLOG             "NOLog"
#define PARM_HELP              "?"
#define PARM_HELP2             "Help"


// control compilation
#define SUPPORT_LOCAL_COMPILE          0

// language selection of NEPMD project from OS2.INI
#define NEPMD_INI_APPNAME              "NEPMD"
#define NEPMD_INI_KEYNAME_LANGUAGE     "Language"

#define NLSMODULE_LANGUAGEMASK         "rec%s.nls"

// some values
#define SEMNAME                        "\\SEM32\\"__PROGSTEM__"\\ACTIVE"
#define EXENAME_MACROCOMPILER          "ETPM.EXE"

#define EPM_SOURCENAME                 "epm.e"
#define EPM_TARGETNAME                 "epm.ex"
#define EPM_COMPILELOG                 __PROGSTEM__".log"

#define MAX_EPM_CLIENTS                64

#define RELOAD_WAITBEFORERELOAD        1000
#define RELOAD_MAXTRIES                3
#define RELOAD_MAXTWAITPERTRY          3
#define RELOAD_WAITPERIOD              1000

/* ----------- Symbols used in common.h and recomp.e ----------- */
/*                        KEEP IN SYNC !                         */

/* EPM DDE support seems not to zero terminate the result string */
/* Therefore we append a with special end-of-data-byte           */
#define END_OF_DATA_CHAR ''

/* Delimter character for the file list    */
#define FILE_DELIMITER   '|'

/* special tokens for filelist handling */
#define TOKEN_MAXCOUNT_FILELIST "MAXCOUNT:"
#define TOKEN_FILEINFO          "FILE:"
#define TOKEN_END_OF_FILELIST   "COMPLETE:"
#define TOKEN_UNSAVED           "UNSAVED:"
#define TOKEN_ERROR             "ERROR:"

/* ------------------------------------------------------------- */

#endif // COMMON_H

