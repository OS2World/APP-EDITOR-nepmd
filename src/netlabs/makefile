# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile to copy modified source files to the appropriate cmpile
# subdirectories. All files of this subdirectory tree are copied unmodified.
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.15 2004-02-29 22:51:22 aschn Exp $
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

# --- extend EPMPATH and search macro sources in subdirectory
#     (MACRODIR used by project.in)
MACRODIR=macros
EPMPATH=$(MACRODIR)

# --- set DPATH to nothing in order to prevent to include
#     any my*.e files
DPATH=;

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

# --- list for standalone modules
EMODULELIST=\
$(CMPEXDIR)\epm.ex \
$(CMPEXDIR)\bookmark.ex\
$(CMPEXDIR)\box.ex\
$(CMPEXDIR)\draw.ex\
$(CMPEXDIR)\epmcomp.ex\
$(CMPEXDIR)\epmlex.ex\
$(CMPEXDIR)\fonts.ex\
$(CMPEXDIR)\ftpload.ex\
$(CMPEXDIR)\ftpsave.ex\
$(CMPEXDIR)\get.ex\
$(CMPEXDIR)\help.ex\
$(CMPEXDIR)\kwhelp.ex\
$(CMPEXDIR)\maketags.ex\
$(CMPEXDIR)\next_win.ex\
$(CMPEXDIR)\put.ex\
$(CMPEXDIR)\showu.ex\
$(CMPEXDIR)\tags.ex\
$(CMPEXDIR)\testkeys.ex\
$(CMPEXDIR)\treeit.ex\
$(CMPEXDIR)\wordproc.ex\
$(CMPEXDIR)\wrap.ex


# --- list for toolbar modules
TEMODULELIST=\
$(CMPEXDIR)\commands.ex\
$(CMPEXDIR)\groups.ex\
$(CMPEXDIR)\jot.ex\
$(CMPEXDIR)\makeactn.ex\
$(CMPEXDIR)\reflow.ex\
$(CMPEXDIR)\sampactn.ex\
$(CMPEXDIR)\stylebut.ex\
$(CMPEXDIR)\tagsactn.ex\
$(CMPEXDIR)\tree.ex


# --- pseudotargets

ALL: CHECKSRC SRCCOPY $(EMODULELIST) $(TEMODULELIST)

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


$(CMPEXDIR)\epm.ex: macros\*

