# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for creating a WarpIn package for EPM.
#
# Configure by editing ..\..\configure.in before executing
#
# WARNING:
# Do not call this makefile directly when the other makefiles from
# within the directory tree src have not yet been called, because
# it relies on the files created and copied by these to the temporary
# "compile" subdirectory. In order to make sure that everyhing is
# processed in the correct order, execute
#    nmake all
# in the project working root directory instead.
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.5 2002-06-10 22:04:54 cla Exp $
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

# --- do not allow execution from within this directory

!ifndef CALLED
!error in wis\makefile: This makefile is to be called from the main makefile only !
!endif

# --- include main definitions

BASEDIR=..\..
!include $(BASEDIR)\rules.in

# --- read special makefile configuration

!include $(BASEDIR)\configure.in
SCRIPTFILE=$(STEM).wis
LISTFILE=$(STEM).lst
WPIFILE=$(STEM)$(VERSION).wpi

# --- extend path for creating WPI file from basedir

PATH=bin;$(PATH)

# --- definitions for this makefile

FILESTOCLEAN=\
 $(CMPDIR)\$(SCRIPTFILE) \
 $(BINDIR)\$(WPIFILE) \
 $(CMPDIR)\prepare.log \
 $(BINDIR)\create.log


# --- parameters for to patch into the WarpIn script

WISPARMS= \
 ID_VERSION_NEPMD=$(ID_VERSION_NEPMD) \
 ID_VERSION_REQ_WARPIN=$(ID_VERSION_REQ_WARPIN)

CREATEPARMS=\
 UNZIPPEDDIR=$(UNZIPPEDDIR)\
 BINDIR_NAME=$(BINDIR_NAME)\
 CMPDIR_NAME=$(CMPDIR_NAME)

# --- pseudotargets

ALL: PREPARE CREATE

INST: ALL
  warpin.env start warpin $(BINDIR)\$(WPIFILE)

# ---

PREPARE: $(UNZIPPEDDIR)\prepare.log

CREATE:  $(BINDIR)\$(WPIFILE)

CLEAN:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

CHECK: PREPARE
   @ECHO Checking prepared files for errors during unpack:
   -@grep SYS....: $(UNZIPPEDDIR)\prepare.log
   @ECHO Checking prepared files for zero byte files:
   -@dir $(UNZIPPEDDIR) /s | grep " 0           0"

# ---- unpack and maintain the original zip packages
#      may require internet connection, see env.cmd
#      also copy logfile

$(UNZIPPEDDIR)\prepare.log: $(BASEDIR)\bin\prepare.cmd
   prepare $(UNZIPPEDDIR)\prepare.log $(BASEURL) $(ZIPSRCDIR) $(UNZIPPEDDIR)
   -@COPY $(UNZIPPEDDIR)\*.log $(CMPDIR) >NUL 2>&1

# ---- create WPI package

$(BINDIR)\$(WPIFILE): PREPARE $(CMPDIR)\$(SCRIPTFILE) $(WPIDEPLIST) $(LISTFILE)
   @CD $(BASEDIR)
   mkwpi src\wis\$(LISTFILE) $(BINDIR_NAME)\create.log $(CMPDIR_NAME)\$(SCRIPTFILE) $(BINDIR_NAME)\$(WPIFILE) $(CREATEPARMS)

# --- create customized WarpIn script file
$(CMPDIR)\$(SCRIPTFILE): $(SCRIPTFILE)
   parseenv $(SCRIPTFILE) $(CMPDIR)\$(SCRIPTFILE) $(WISPARMS)

