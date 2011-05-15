# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile to copy modified source files to the appropriate compile
# subdirectories. All files of this subdirectory tree are copied unmodified.
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
#     keep this in sync with exfiles.lst!
EMODULELIST=\
$(CMPEXDIR)\epm.ex \
$(CMPEXDIR)\all.ex\
$(CMPEXDIR)\alt_1.ex\
$(CMPEXDIR)\assist.ex\
$(CMPEXDIR)\backup.ex\
$(CMPEXDIR)\bookmark.ex\
$(CMPEXDIR)\box.ex\
$(CMPEXDIR)\dict.ex\
$(CMPEXDIR)\draw.ex\
$(CMPEXDIR)\epmcomp.ex\
$(CMPEXDIR)\epmlex.ex\
$(CMPEXDIR)\epmshell.ex\
$(CMPEXDIR)\fevshmnu.ex\
$(CMPEXDIR)\file.ex\
$(CMPEXDIR)\finddef.ex\
$(CMPEXDIR)\ftpload.ex\
$(CMPEXDIR)\ftpsave.ex\
#$(CMPEXDIR)\get.ex\
$(CMPEXDIR)\help.ex\
$(CMPEXDIR)\indentblock.ex\
$(CMPEXDIR)\kwhelp.ex\
$(CMPEXDIR)\keys.ex\
$(CMPEXDIR)\locate.ex\
$(CMPEXDIR)\maketags.ex\
$(CMPEXDIR)\modecnf.ex\
$(CMPEXDIR)\modeexec.ex\
$(CMPEXDIR)\mozkeys.ex\
$(CMPEXDIR)\newmenu.ex\
$(CMPEXDIR)\next_win.ex\
$(CMPEXDIR)\ovshmenu.ex\
$(CMPEXDIR)\popup.ex\
#$(CMPEXDIR)\put.ex\
$(CMPEXDIR)\recode.ex\
$(CMPEXDIR)\recompile.ex\
$(CMPEXDIR)\reflowmail.ex\
$(CMPEXDIR)\showu.ex\
$(CMPEXDIR)\singlespace.ex\
$(CMPEXDIR)\stdmenu.ex\
$(CMPEXDIR)\tags.ex\
$(CMPEXDIR)\testkeys.ex\
$(CMPEXDIR)\toolbar.ex\
$(CMPEXDIR)\treeit.ex\
$(CMPEXDIR)\unhtml.ex\
$(CMPEXDIR)\wordproc.ex\


# --- list for toolbar modules
#     keep this in sync with actions.lst!
TEMODULELIST=\
$(CMPEXDIR)\commands.ex\
$(CMPEXDIR)\fonts.ex\
$(CMPEXDIR)\groups.ex\
$(CMPEXDIR)\jot.ex\
$(CMPEXDIR)\makeactn.ex\
$(CMPEXDIR)\newbar.ex\
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

