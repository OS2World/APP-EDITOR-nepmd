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
# $Id: makefile,v 1.6 2002-08-29 14:53:25 cla Exp $
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

# include main definitions
BASEDIR=..\..

!include $(BASEDIR)\rules.in

# --- definitions for this makefile
#     NOTE: Don't cleanup makefile.inf as this is always
#           to be available in the bin subdirectory !

FILESTOCLEAN= \
 $(CMPDIR)\functions.txt \
 $(CMPDIR)\functions.log \
 $(CMPDIR)\makefile.ipf \
 $(CMPDIR)\nepmd.ipf \
 $(CMPINFDIR)\nepmd.inf


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

ALL: HELPINF NEPMDINF

HELPINF: $(BASEDIR)\bin\makefile.inf

NEPMDINF: $(CMPINFDIR)\nepmd.inf

HELP: HELPINF
  @start view $(BASEDIR)\bin\makefile.inf $(MAKEPANEL)

NEPMD: NEPMDINF
  @start view $(CMPINFDIR)\nepmd.inf $(NEPMDPANEL)


CLEAN:
   @echo cleaning up files ...
   -@for %%a in ($(FILESTOCLEAN)) do @del %%a /N >NUL 2>&1

# ---- create makefile help INF

$(BASEDIR)\bin\makefile.inf: makefile.txt *.inc
  htext /N makefile.txt $(BASEDIR)\compile\makefile.ipf $(BASEDIR)\bin\makefile.inf

# ---- generate project documentation INF

$(CMPINFDIR)\nepmd.inf: nepmd.txt *.inc bmp\* $(CMPDIR)\functions.txt
   htext /N nepmd.txt $(CMPDIR)\nepmd.ipf $(CMPINFDIR)\nepmd.inf

$(CMPDIR)\functions.txt: ..\gui\nepmdlib\nepmdlib.e ..\gui\nepmdlib\macros\*
   esrcscan $(ESRCPATH)\nepmdlib.e $(ESRCPATH) $(CMPDIR) $(LIMITPATH)

