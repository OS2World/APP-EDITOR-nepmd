# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for creating an exe out of nlsetup.cmd
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

# --- definitions for this makefile

FILESTOCLEAN= \
 $(CMPINSTDIR)\nlsetup.exe \
 $(CMPDIR)\nlsetup.log

# --- private extension of suffix list
.SUFFIXES: .cmd

# --- private rule

.cmd{$(CMPINSTDIR)}.exe:
   rexx2exe $(@B).cmd $(CMPINSTDIR)\$(@B).exe /P > $(CMPDIR)\$(@B).log


# --- pseudotargets

ALL: NLSETUP NLDEINST

# ---

CLEAN:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# ---

NLSETUP: $(CMPINSTDIR)\nlsetup.exe

NLDEINST: $(CMPINSTDIR)\nldeinst.exe

# ---- create EXE versions of frame REXX batchfiles

$(CMPINSTDIR)\nlsetup.exe: nlsetup.cmd

$(CMPINSTDIR)\nldeinst.exe: nldeinst.cmd

