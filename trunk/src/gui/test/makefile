# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for the test utility
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.5 2002-09-12 15:25:43 cla Exp $
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

# - create utilitiy
#   NOTE: compile with multithread support,
#         because common.lib is compiled MT also
LIBS=$(BINDIR)\common.lib
MT=1

# include main definitions
BASEDIR=..\..\..
!include $(BASEDIR)\rules.in

# --- some file definitions for this makefile

DEPENDFILE=$(CMPDIR)\test.dep

FILESTOCLEAN=$(DEPENDFILE) \
 $(BINDIR)\test.obj \
 $(BINDIR)\test.exe \
 $(BINDIR)\test.map

INCLUDE=..\common;$(CMPDIR);$(INCLUDE)

# --- set tesffile

NEPMD_TMFTESTFILE=..\nepmdlib\nepmdlib.tmf


# --- general pseudo targets

all: exe

# --- pseudo targets for testcases

run: all
  $(BINDIR)\test.exe $(ARG)

tmf:
   @(SET NEPMD_TMFTESTFILE=$(NEPMD_TMFTESTFILE) & $(BINDIR)\test.exe tmf)

instval: all
   $(BINDIR)\test.exe instval

reset:
   eautil /s $(NEPMD_TMFTESTFILE) NUL



clean:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# --- special pseudo targets

exe: $(BINDIR)\test.exe

dep:
   makedep $(BINDIR) $(DEPENDFILE)

# --- include dependencies - create dependency file if not present

!if [@dir $(DEPENDFILE) >NUL 2>&1 || makedep $(BINDIR) $(DEPENDFILE)]
!endif
!include $(DEPENDFILE)

$(BINDIR)\test.exe: $(LIBS)

