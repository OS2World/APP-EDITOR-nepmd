# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for the library for generic routines
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.1 2002-06-03 22:19:58 cla Exp $
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

OBJS=\
#$(BINDIR)\common.obj\
 $(BINDIR)\ddeutil.obj\
 $(BINDIR)\eas.obj\
 $(BINDIR)\file.obj\
 $(BINDIR)\pmres.obj\
 $(BINDIR)\process.obj \
 $(PMPRINTF)

# include main definitions
BASEDIR=..\..\..
!include $(BASEDIR)\rules.in

# --- some file definitions for this makefile

DEPENDFILE=$(BASEDIR)\compile\common.dep
DEPENDPATH=E:\SRC\nepmd\WORK\src\gui\common

FILESTOCLEAN=$(DEPENDFILE) \
 $(OBJS)\
 $(BINDIR)\common.lib \
 $(BINDIR)\common.lst


# --- general pseudo targets

all: lib

clean:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# --- special pseudo targets

lib: $(BINDIR)\common.lst

# --- include dependencies - create dependency file if not present

!if [@dir $(DEPENDFILE) >NUL 2>&1 || fastdep -o $(BINDIR) -d $(DEPENDFILE) -e $(DEPENDPATH) -a- *.c]
!endif
!include $(DEPENDFILE)

# --- extend suffix list

.SUFFIXES: .ex

# --- copy executable to netlabs directory below binary directory

$(BINDIR)\common.lib: $(OBJS)
#   !$(CODELIB) /nologo $@ -+$?;
#   @if exist $*.bak del $*.bak

$(BINDIR)\common.lst: $(BINDIR)\common.lib


