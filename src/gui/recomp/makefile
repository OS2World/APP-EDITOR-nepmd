# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for the recompilation utility
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

# --- set EPMPATH to use sourcefiles only  in this directory
EPMPATH=.

# --- select between creating a separate NLS DLL

!ifdef NLS

# - create DLL

OBJS=
DEF=resource.def
RES=$(BINDIR)\rec$(NLS).res
DLLEXT=.nls

!else

# - create recomp utilitiy

NLS=eng
OBJS=\
 $(BINDIR)\frame.obj\
 $(BINDIR)\client.obj\
 $(BINDIR)\dde.obj\
 $(BINDIR)\ddereload.obj\
 $(BINDIR)\ddelog.obj\
 $(BINDIR)\job.obj\

DEF=recomp.def
RES=$(BINDIR)\receng.res
MT=1
PMPRINTF=1

!endif

# --- list of available source for separate NLS modules

NLSSUPPORTED=deu

# --- some defs for all compilations

PKGDIR=recomp
LXLITE=1
LIBS=$(BINDIR)\common.lib

# include main definitions
BASEDIR=..\..\..
!include $(BASEDIR)\rules.in

# --- some file definitions for this makefile

DEPENDFILE=$(CMPDIR)\recomp.dep
NLSPATH=..\..\nls

FILESTOCLEAN=$(DEPENDFILE) \
 $(BINDIR)\*.obj \
 $(BINDIR)\recomp.exe \
 $(BINDIR)\rec*.nls \
 $(BINDIR)\rec*.map \
 $(BINDIR)\rec*.res \
 $(CMPDIR)\recomp.ex \
 $(BINBINDIR)\recomp.exe \
 $(BINBINDIR)\rec*.nls \
 $(CMPDIR)\tc.ex

INCLUDE=..\common;$(CMPDIR);$(INCLUDE)

# --- general pseudo targets

all: exe nls

run: all
   @start $(BINBINDIR)\recomp.exe

level: all
  @for %%a in ($(BINDIR)\*.exe $(BINDIR)\*.nls) do @BLDLEVEL %%a

clean:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# --- special pseudo targets

exe: $(BINBINDIR)\recomp.exe

nls:
    @for %%a in ($(NLSSUPPORTED)) do @$(MAKE) /nologo buildnls NLS=%%a

rel:
   @$(MAKE) /nologo NDEBUG=1 MAKELEVEL=1

res: $(RES)

ex: $(CMPDIR)\recomp.ex

buildnls: $(BINBINDIR)\rec$(NLS).nls

testcase: $(CMPDIR)\tc.ex

dep:
   makedep $(BINDIR) $(DEPENDFILE)

# --- include dependencies - create dependency file if not present

!if [@dir $(DEPENDFILE) >NUL 2>&1 || makedep $(BINDIR) $(DEPENDFILE)]
!endif
!include $(DEPENDFILE)

# --- copy executable to netlabs directory below binary directory

$(BINBINDIR)\recomp.exe: $(BINDIR)\recomp.exe
     @COPY $(BINDIR)\recomp.exe $(BINBINDIR)\recomp.exe >NUL

# --- build program

$(BINDIR)\recomp.exe: $(BINDIR)\recomp.obj $(OBJS) $(DEF) $(RES) $(LIBS) $(PMPRINTF)

$(BINDIR)\rec$(NLS).res: rec$(NLS).rc $(NLSPATH)\nls$(NLS).rch $(NLSPATH)\recomp\rec$(NLS).rch recomp.rc recomp.rch recomp.dlg recomp.men $(CMPDIR)\recomp.ex

$(CMPDIR)\recomp.ex: recomp.e

$(CMPDIR)\tc.ex: tc.e

# --- copy executable to netlabs directory below binary directory

$(BINBINDIR)\rec$(NLS).nls: $(BINDIR)\rec$(NLS).nls ..\..\nls\nlseng.rch
     @COPY $(BINDIR)\rec$(NLS).nls $(BINBINDIR)\rec$(NLS).nls >NUL

# --- build resource dll

$(BINDIR)\rec$(NLS).nls: $(BINDIR)\rec$(NLS).obj $(OBJS) $(OBJS1) $(DEF) $(RES) $(CMPDIR)\recomp.ex

# --- keep the implicit DLL rule happy: make obj name identical to dll name

$(BINDIR)\rec$(NLS).obj: $(BINDIR)\resource.obj
     @copy $(BINDIR)\resource.obj $(BINDIR)\rec$(NLS).obj >NUL 2>&1

