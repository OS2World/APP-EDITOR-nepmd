# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for the EPM call utility
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.9 2002-08-13 15:41:53 cla Exp $
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
PKGDIR=epmcall
DEF=epmcall.def
LXLITE=1
LIBS=$(BINDIR)\common.lib
MT=1

# include main definitions
BASEDIR=..\..\..
!include $(BASEDIR)\rules.in

# --- some file definitions for this makefile

DEPENDFILE=$(CMPDIR)\epmcall.dep
NLSPATH=..\..\nls

FILESTOCLEAN=$(DEPENDFILE) \
 $(BINDIR)\epmcall.obj \
 $(BINDIR)\epmcall.exe \
 $(BINDIR)\epmcall.map

INCLUDE=..\common;$(CMPDIR);$(INCLUDE)

# --- general pseudo targets

all: exe

run: all
   @start $(BINBINDIR)\epm.exe

clean:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# --- special pseudo targets

exe: $(BINBINDIR)\epm.exe $(BINBINDIR)\epm.env

rel:
   @$(MAKE) /nologo NDEBUG=1 MAKELEVEL=1

dep:
   makedep $(BINDIR) $(DEPENDFILE)

copy: all
   copy $(BINBINDIR)\epm.exe c:\os2\

# --- include dependencies - create dependency file if not present

!if [@dir $(DEPENDFILE) >NUL 2>&1 || makedep $(BINDIR) $(DEPENDFILE)]
!endif
!include $(DEPENDFILE)

# --- copy executable to netlabs directory below binary directory

$(BINBINDIR)\epm.exe: $(BINDIR)\epmcall.exe
     @COPY $(BINDIR)\epmcall.exe $(BINBINDIR)\epm.exe >NUL

# --- copy env file to $(BINDIR) to allow debugging
$(BINBINDIR)\epm.env: epmcall.env
     @COPY epmcall.env $(BINDIR)\ >NUL

# --- build program

$(BINDIR)\epmcall.exe: $(BINDIR)\epmcall.obj $(OBJS) $(DEF)

