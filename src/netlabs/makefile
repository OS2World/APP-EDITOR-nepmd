# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile to copy modified source files to the appropriate cmpile
# subdirectories. All files of this subdirectory tree are copied unmodified.
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.2 2002-07-23 11:41:36 cla Exp $
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
SCRIPTFILE=$(STEM).wis
WPIFILE=$(STEM)$(VERSION).wpi

# --- definitions for this makefile

FILESTOCLEAN=\
 $(SRCCOPY_FLAGFILE)


# --- pseudotargets

ALL: CHECKSRC SRCCOPY EPMEX

CLEAN:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1
   @kd $(CMPINSTDIR)

EPMEX: $(CMPEXDIR)\epm.ex

CHECKSRC:
   @_srccopy CHECK $(SRCCOPY_FLAGFILE) $(BASEDIR)\src\netlabs

SRCCOPY: $(SRCCOPY_FLAGFILE)

# ---- check if sources from srcdir are updated

$(SRCCOPY_FLAGFILE):
   _srccopy COPY $(SRCCOPY_FLAGFILE) $(BASEDIR)\src\netlabs $(CMPDSTDIR)

# ---- compile NEPMD version of EPM.EX
$(CMPEXDIR)\epm.ex: mkex.cmd
   mkex $(CMPEXDIR)

