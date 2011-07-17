# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile to copy modified source files to the appropriate cmpile
# subdirectories. All files of this subdirectory tree are copied unmodified.
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id$
#
# ===========================================================================
#
# This file is part of the Netlabs EPM Distribution package and is free
# software.  You can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software
# Foundation, in version 2 as it comes in the "COPYING" file of the
# Netlabs EPM Distribution.  This library is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# ***************************************************************************

# --- include main definitions

BASEDIR=..\..
!include $(BASEDIR)\rules.in

# --- read makefile configuration

!include $(BASEDIR)\configure.in

# --- definitions for this makefile

FILESTOCLEAN=\
 $(NLSCOPY_FLAGFILE)

# --- pseudotargets

ALL: CHECKSRC SRCCOPY

CLEAN:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

CHECKSRC:
   @_srccopy CHECK $(NLSCOPY_FLAGFILE) $(BASEDIR)\src\nls\netlabs

SRCCOPY: $(NLSCOPY_FLAGFILE)

# ---- check if sources from srcdir are updated

$(NLSCOPY_FLAGFILE):
   _srccopy COPY $(NLSCOPY_FLAGFILE) $(BASEDIR)\src\nls\netlabs $(CMPDSTDIR)

