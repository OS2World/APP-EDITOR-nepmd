# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# makefile for creating the NEPMD readme inf file
#
# This is automatically called by the main makefile with target HELP if that
# is called without a target.
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.13 2002-11-05 20:27:29 cla Exp $
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

# select english as default language
!ifndef NLS
NLS=eng
!endif

# include main definitions
BASEDIR=..\..

!include $(BASEDIR)\rules.in

# --- definitions for this makefile
#     NOTE: Don't cleanup makefile.inf as this is always
#           to be available in the bin subdirectory !

FILESTOCLEAN= \
 $(CMPDIR)\functions_.txt \
 $(CMPDIR)\functions.log \
 $(CMPDIR)\makefile.ipf \
 $(CMPDIR)\neusr$(NLS).ipf \
 $(CMPINFDIR)\neusr$(NLS).inf \
 $(CMPDIR)\neprg$(NLS).ipf \
 $(CMPINFDIR)\neprg$(NLS).inf \
 $(CMPDIR)\nefld$(NLS).ipf \
 $(CMPHLPDIR)\nefld$(NLS).hlp

INCLUDE=$(INCLUDE);bmp;

# --- some private definitions

ESRCPATH=..\gui\nepmdlib
LIMITPATH=$(ESRCPATH);$(ESRCPATH)\macros;
EPMPATH=$(LIMITPATH);%EPMPATH%

!ifndef PANEL
MAKEPANEL="Making"
NEPMDPANEL="Netlabs"
!else
MAKEPANEL=$(PANEL)
NEPMDPANEL=$(PANEL)
!endif

# --- pseudotargets ****************

ALL: HELPINF NEUSRINF NEPRGINF NEFLDHLP

SHOW: SHOWHELP SHOWNEUSR SHOWNEPRG SHOWNEFLD

NEW: NEWHELP NEWNEUSR NEWNEPRG NEWNEFLD

# --- build in normal make processing

HELPINF: $(BASEDIR)\bin\makefile.inf

NEUSRINF: $(CMPINFDIR)\neusr$(NLS).inf

NEPRGINF: $(CMPINFDIR)\neprg$(NLS).inf

NEFLDHLP: $(CMPHLPDIR)\nefld$(NLS).hlp

# --- show always, rebuild if new

SHOWHELP: HELPINF
   @start view $(BASEDIR)\bin\makefile.inf $(MAKEPANEL)

SHOWNEUSR: NEUSRINF
   @start view $(CMPINFDIR)\neusr$(NLS).inf $(NEPMDPANEL)

SHOWNEPRG: NEPRGINF
  @start view $(CMPINFDIR)\neprg$(NLS).inf $(NEPMDPANEL)

SHOWNEFLD: NEFLDHLP
  @start view $(CMPHLPDIR)\nefld$(NLS).hlp

# --- rebuild outdated, show new INFs only

NEWHELP:
  @$(MAKE) /nologo HELPINF SHOWFILE=1

NEWNEUSR:
  @$(MAKE) /nologo NEUSRINF SHOWFILE=1

NEWNEPRG:
  @$(MAKE) /nologo NEPRGINF SHOWFILE=1

NEWNEFLD:
  @$(MAKE) /nologo NEFLDHLP SHOWFILE=1

# --- cleanup

CLEAN:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# ---- create makefile help INF

$(BASEDIR)\bin\makefile.inf: makefile.txt *.inc
   htext /N makefile.txt $(BASEDIR)\compile\makefile.ipf $(BASEDIR)\bin\makefile.inf
!ifdef SHOWFILE
   @start view $(BASEDIR)\bin\makefile.inf $(MAKEPANEL)
!endif

# ---- generate programming guide INF

$(CMPINFDIR)\neprg$(NLS).inf: neprg$(NLS).txt title$(NLS).inc bmp\* $(CMPDIR)\functions.txt
   htext /N neprg$(NLS).txt $(CMPDIR)\neprg$(NLS).ipf $(CMPINFDIR)\neprg$(NLS).inf
!ifdef SHOWFILE
  @start view $(CMPINFDIR)\neprg$(NLS).inf $(NEPMDPANEL)
!endif

$(CMPDIR)\functions.txt: ..\gui\nepmdlib\nepmdlib.e ..\gui\nepmdlib\macros\*
   esrcscan $(ESRCPATH)\nepmdlib.e $(ESRCPATH) $(CMPDIR) $(LIMITPATH)

# ---- generate user guide INF

$(CMPINFDIR)\neusr$(NLS).inf: neusr$(NLS).txt title$(NLS).inc bmp\*
   htext /N neusr$(NLS).txt $(CMPDIR)\neusr$(NLS).ipf $(CMPINFDIR)\neusr$(NLS).inf
!ifdef SHOWFILE
   @start view $(CMPINFDIR)\neusr$(NLS).inf $(NEPMDPANEL)
!endif

# ---- generate folder help file

$(CMPHLPDIR)\nefld$(NLS).hlp: nefld$(NLS).txt title$(NLS).inc bmp\*
   htext /HLP /N nefld$(NLS).txt $(CMPDIR)\nefld$(NLS).ipf $(CMPHLPDIR)\nefld$(NLS).hlp
!ifdef SHOWFILE
   @start view $(CMPHLPDIR)\nefld$(NLS).hlp $(NEPMDPANEL)
!endif

