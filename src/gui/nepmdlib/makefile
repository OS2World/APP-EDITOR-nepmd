# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for the NEPMD library DLL and .ex wrapper file
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

# --- extend EPMPATH to find include files in subdirectory
EPMPATH=macros;$(EPMPATH)

# - create utilitiy
#   NOTE: compile with multithread support,
#         because common.lib is compiled MT also
DLL=1
DEF=nepmdlib.def
MT=1
LXLITE=1
LIBS=$(BINDIR)\common.lib
PMPRINTF=1

# include main definitions
BASEDIR=..\..\..
!include $(BASEDIR)\rules.in

# --- some file definitions for this makefile

DEPENDFILE=$(CMPDIR)\nepmdlib.dep
NLSPATH=..\..\nls

FILESTOCLEAN=$(DEPENDFILE) \
 $(BINDIR)\nepmdlib.obj \
 $(BINDIR)\nepmdlib.dll \
 $(BINDIR)\nepmdlib.map

INCLUDE=..\common;..\etk;$(CMPDIR);$(INCLUDE)

# --- general pseudo targets

all: dll ex


clean:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# --- special pseudo targets

dll: $(BINDLLDIR)\nepmdlib.dll

ex:  $(CMPEXDIR)\nepmdlib.ex

rel:
   @$(MAKE) /nologo NDEBUG=1 MAKELEVEL=1

dep:
   makedep $(BINDIR) $(DEPENDFILE)

ship: dll ex
   _shipfile $(BINDLLDIR)\nepmdlib.dll netlabs\dll
   _shipfile $(CMPEXDIR)\nepmdlib.ex   netlabs\ex

# --- include dependencies - create dependency file if not present

!if [@dir $(DEPENDFILE) >NUL 2>&1 || makedep $(BINDIR) $(DEPENDFILE)]
!endif
!include $(DEPENDFILE)

# --- copy executable to netlabs directory below binary directory

$(BINDLLDIR)\nepmdlib.dll: $(BINDIR)\nepmdlib.dll
     @COPY $(BINDIR)\nepmdlib.dll $(BINDLLDIR)\nepmdlib.dll >NUL

# --- build dll

$(BINDIR)\nepmdlib.dll: $(BINDIR)\nepmdlib.obj $(OBJS) $(DEF) $(RES) $(LIBS) $(PMPRINTF)

# --- build EX file
$(CMPEXDIR)\nepmdlib.ex: nepmdlib.e macros\*

