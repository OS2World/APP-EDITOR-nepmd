/****************************** Module Header *******************************
*
* Module Name: common.h
*
* Header with common values used by all source files.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: common.h,v 1.11 2006-12-23 21:38:34 aschn Exp $
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

#include "nepmd.h"

#define __APPNAME__                    "RECOMP"
#define __APPNAMESHORT__               "RECOMP"  // for title of error msg
#define __PROGSTEM__                   "recomp"
#define __VERSION__                    "v1.12"
#define __YEAR__                       "2006"

// define parameters
#define PARM_START             "Start"
#define PARM_DISCARDUNSAVED    "Discardunsaved"
#define PARM_NORELOADFILES     "NOReloadfiles"
#define PARM_NOLOG             "NOLog"
#define PARM_HELP              "?"
#define PARM_HELP2             "Help"

// help related strings
#define HELP_NEPMDINF          "nepmd.inf"
#define HELP_EXEC              "VIEW.EXE"
#define HELP_ENTRYPANEL        "Netlabs"

// control compilation
#define SUPPORT_LOCAL_COMPILE          0

#define NLSMODULE_LANGUAGEMASK         "rec%s.nls"

// some values
#define SEMNAME                        "\\SEM32\\"__PROGSTEM__"\\ACTIVE"
#define EXENAME_MACROCOMPILER          "ETPM.EXE"

#define EPM_SOURCENAME                 "epm.e"
#define EPM_TARGETNAME                 "epm.ex"
#define EPM_COMPILELOG                 __PROGSTEM__".log"
#define TEST_ALTSOURCENAME             "epm_error.e"

#define MAX_EPM_CLIENTS                64

#define RELOAD_WAITBEFORERELOAD        1000
#define RELOAD_MAXTRIES                3
#define RELOAD_MAXTWAITPERTRY          3
#define RELOAD_WAITPERIOD              1000

// some values used by ddelog.c to parse
// the ETPM log output for error information
#define ETPMLOG_HEADERLINECOUNT        3
#define ETPMLOG_VALIDLINETOKEN         "compiling "
#define ETPMLOG_FILENAMETOKEN          "filename="
#define ETPMLOG_LINETOKEN              "line="
#define ETPMLOG_COLTOKEN               "col="
#define ETPMLOG_NOTFOUNDTOKEN          "Unable to open input file:"

/* ----------- Symbols used in common.h and recomp.e ----------- */
/*                        KEEP IN SYNC !                         */

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

