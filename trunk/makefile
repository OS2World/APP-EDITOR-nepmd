# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for creating a WarpIn package for EPM
#
# Configure by editing configure.in before executing
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.13 2002-04-24 15:16:04 cla Exp $
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

# --- read makefile configuration

!include configure.in
SCRIPTFILE=$(STEM).wis
WPIFILE=$(STEM)$(VERSION).wpi

# --- common definitions

.SUFFIXES: .src .ipf .inf .ipp .hlp .exe .log
INCLUDE=$(INCLUDE);src\ipf;src\ipf\bmp;

!IFDEF NDEBUG
!UNDEF DEBUG
!ENDIF

!IFDEF DEBUG
CDEBUG=-Ti+ -DDEBUG
CLINK=/CO
!ELSE
CDEBUG=-Ti- -DNDEBUG
!ENDIF

# ---- create required directories

CMPDIR=compile
!if [@md $(CMPDIR) 2> NUL]
!endif

DSTDIR=$(CMPDIR)\netlabs
!if [@md $(DSTDIR) 2> NUL]
!endif

INFDIR=$(DSTDIR)\book
!if [@md $(INFDIR) 2> NUL]
!endif

EXCDIR=$(DSTDIR)\install
!if [@md $(EXCDIR) 2> NUL]
!endif

# --- set some compiler dependant values

!ifdef CPPLOCAL
LL=ilink
LFLAGS_VISUAL=/NOFREE
CWARNINGS=-W3 -Wcnd-
!else
LL=link386
LFLAGS_VISUAL=
CWARNINGS=-W3
!endif


!ifdef DEBUG
CFLAGS=-q $(CWARNINGS) -Ss+ -Sp1 -Gm+ -Tm -c -I.;$(GUISRCDIR); -Ti+ -DDEBUG -O-
RCFLAGS=-DDEBUG
PMPRINTF=$(BINDIR)\printf.obj
!else
CFLAGS=-q $(CWARNINGS) -Ss+ -Sp1 -Gm+ -c -I.;$(GUISRCDIR); -Ti- -DNDEBUG
PMPRINTF=
PMPRINTF=$(BINDIR)\printf.obj
!endif

CFLAGS_DLL=-Ge- $(CFLAGS)

LFLAGS_PM=$(LFLAGS_VISUAL) /A:4 /L:2 /E /NOI /NOL /NOE /NOLOGO /CO /BASE:0X10000 /PM:PM
!ifdef DEBUG
LFLAGS_PM=$(LFLAGS_PM) /CO
!endif

# --- pseudotargets ****************

HELP: bin\makefile.inf
  @start view bin\makefile.inf "Making"

# ---

ALL: INF PREPARE CREATE

SHOW: INF
  @start view $(INFDIR)\nepmd.inf Netlabs

INST: ALL
  @start warpin $(CMPDIR)\$(WPIFILE)

# ---

PREPARE: $(UNZIPPEDDIR)\prepare.log

CREATE: NEPMD $(CMPDIR)\$(WPIFILE)

NEPMD: CHECKSRC SRCCOPY NLSETUP INF

INF: $(INFDIR)\nepmd.inf

# ---

CHECKSRC:
   @bin\_srccopy CHECK $(CMPDIR)\srccopy.txt src\netlabs

SRCCOPY: $(CMPDIR)\srccopy.txt


CHECK: PREPARE
   @ECHO Checking prepared files for errors during unpack:
   -@grep SYS....: $(UNZIPPEDDIR)\prepare.log
   @ECHO Checking prepared files for zero byte files:
   -@dir $(UNZIPPEDDIR) /s | grep " 0           0"

NLSETUP: $(EXCDIR)\nlsetup.exe

# ---

CLEAN:
  @echo cleanin up
  -@bin\kd $(CMPDIR)

# ---- generate INF

$(INFDIR)\nepmd.inf: src\ipf\nepmd.txt src\ipf\*.inc src\ipf\bmp\*
   HTEXT /N src\ipf\nepmd.txt $(CMPDIR)\nepmd.ipf $(INFDIR)\nepmd.inf


# ---- check if sources from srcdir are updated

$(CMPDIR)\srccopy.txt:
   bin\_srccopy COPY $(CMPDIR)\srccopy.txt src\netlabs $(DSTDIR)

# ---- unpack and maintain the original zip packages
#      may require internet connection, see env.cmd

$(UNZIPPEDDIR)\prepare.log: bin\prepare.cmd
   bin\prepare $(UNZIPPEDDIR)\prepare.log $(BASEURL) $(ZIPSRCDIR) $(UNZIPPEDDIR)
   -@COPY $(UNZIPPEDDIR)\*.log $(CMPDIR) >NUL 2>&1

# ---- create EXE version or frame REXX bacthfile

$(EXCDIR)\nlsetup.exe: src\rexx\nlsetup.cmd
   rexx2exe src\rexx\nlsetup.cmd $(EXCDIR)\nlsetup.exe /P > $(CMPDIR)\nlsetup.log

# ---- create WPI package

$(CMPDIR)\$(WPIFILE): PREPARE INF src\wis\$(SCRIPTFILE) bin\create.cmd $(CMPDIR)\srccopy.txt
   bin\create $(CMPDIR)\create.log src\wis\$(SCRIPTFILE) $(CMPDIR)\$(WPIFILE) $(UNZIPPEDDIR)

# ---- create makefile help INF

bin\makefile.inf: src\ipf\makefile.txt src\ipf\*.inc
  htext /N src\ipf\makefile.txt compile\makefile.ipf bin\makefile.inf

