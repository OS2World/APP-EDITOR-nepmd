# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for the library for generic routines
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

OBJS= \
 $(BINDIR)\common.obj\
 $(BINDIR)\ddeutil.obj\
 $(BINDIR)\eas.obj\
 $(BINDIR)\file.obj\
 $(BINDIR)\pmres.obj\
 $(BINDIR)\process.obj\
 $(BINDIR)\epmenv.obj\
 $(BINDIR)\tmf.obj\
 $(BINDIR)\instval.obj\
 $(BINDIR)\module.obj\
 $(BINDIR)\libreg.obj\
 $(BINDIR)\init.obj\
 $(BINDIR)\mmf.obj\
 $(BINDIR)\hilite.obj\
 $(BINDIR)\mode.obj

MT=1

# include main definitions
BASEDIR=..\..\..
!include $(BASEDIR)\rules.in

# --- some file definitions for this makefile

DEPENDFILE=$(CMPDIR)\common.dep

FILESTOCLEAN=$(DEPENDFILE) \
 $(OBJS)\
 $(BINDIR)\common.lib \
 $(BINDIR)\common.lst


# --- general pseudo targets

all: lib pmprintf

clean:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# --- special pseudo targets

lib: $(BINDIR)\common.lst

pmprintf: $(BINDIR)\printf.obj

dep:
   makedep $(BINDIR) $(DEPENDFILE)

# --- include dependencies - create dependency file if not present

!if [@dir $(DEPENDFILE) >NUL 2>&1 || makedep $(BINDIR) $(DEPENDFILE)]
!endif
!include $(DEPENDFILE)

# --- extend suffix list

.SUFFIXES: .ex

# --- copy executable to netlabs directory below binary directory

$(BINDIR)\common.lib: $(OBJS)

$(BINDIR)\common.lst: $(BINDIR)\common.lib


