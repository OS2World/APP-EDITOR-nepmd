# ***************************** Module Header *******************************
#
# Module Name: makefile
#
# global makefile for creating a WarpIn package for EPM
#
# Configure the makefile process by editing configure.in before executing
#
# NOTE: calling without target will bring up the makefile.inf
#
# Copyright (c) Netlabs EPM Distibution Project 2002
#
# $Id: makefile,v 1.25 2002-08-21 14:36:26 cla Exp $
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

BASEDIR=.
!include $(BASEDIR)\rules.in

# --- module list
#     NOTE:
#      - module names must be identical to the subdirectory below
#        src directory
#      - keep module gui\common before all other gui submodules
#      - keep module wis last in order to have all required
#        files available !

GUIMODULELIST=gui\common gui\recomp gui\epmcall gui\nepmdlib
MODULELIST=ipf rexx netlabs nls $(GUIMODULELIST) wis

# --- default targets

# - generic default target for building a module

!ifdef MODULE
SPACER=--------------
STARTMSG=\makefile starts
ENDMSG=\makefile ends

VERBOSE:
  @cd src\$(MODULE)
  @echo $(SPACER) $(MODULE)$(STARTMSG) $(SPACER)
  @$(MAKE) /nologo $(ARG) CALLED=1
  @echo $(SPACER) $(MODULE)$(ENDMSG) $(SPACER)
  @echo.
  @cd $(MAKEDIR)

QUIET:
  @cd src\$(MODULE)
  @$(MAKE) /nologo $(ARG) CALLED=1
  @cd $(MAKEDIR)

!else

# - default target for to set languagwe

!ifdef NLS
DEFAULT:
  @setnls $(NLS)
!else

# - default target for normal operation

DEFAULT: HELP
!endif
!endif

# --- other pseudotargets

ALL:
  @for %%a in ($(MODULELIST)) do @$(MAKE) $(ARG) MODULE=%%a ARG=ALL

GUI:
  @for %%a in ($(GUIMODULELIST)) do @$(MAKE) $(ARG) MODULE=%%a ARG=ALL

RUNGUI: GUI
  @$(MAKE) QUIET ARG=RUN MODULE=gui\recomp CALLED=1

REL:
  @for %%a in ($(MODULELIST)) do @$(MAKE) $(ARG) MODULE=%%a NDEBUG=1 ARG=ALL

HELP:
  @$(MAKE) QUIET ARG=HELP MODULE=ipf CALLED=1

SHOW:
  @$(MAKE) QUIET ARG=NEPMD MODULE=ipf CALLED=1

INF:
  @$(MAKE) QUIET MODULE=ipf CALLED=1

INST: ALL
  @$(MAKE) QUIET ARG=INST MODULE=wis CALLED=1

REMOVE:
  @$(MAKE) QUIET ARG=REMOVE MODULE=wis CALLED=1

CLEAN:
  @echo cleaning up directories ...
  @for %%a in ($(DIRSTOCLEAN)) do @kd %%a

NLS:
 @setnls $(NLS)

