EXTPROC CHECKPRG
: ***************************** Module Header ******************************\
:
: Module Name: required.cmd
:
: Checks for all required programs for compiling the Netlabs EPM
: Distribution.
:
: Requires external command processor checkprg.cmd.
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: required.cmd,v 1.1 2002-06-05 22:20:57 cla Exp $
:
: ===========================================================================
:
: This file is part of the Netlabs EPM Distribution package and is free
: software.  You can redistribute it and/or modify it under the terms of the
: GNU General Public License as published by the Free Software
: Foundation, in version 2 as it comes in the "COPYING" file of the
: Netlabs EPM Distribution.  This library is distributed in the hope that it
: will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
: of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
: General Public License for more details.
:
: **************************************************************************/

INI:USER  WarpIN:Path   WarpIN Installer for OS/2
ENV:PATH  IPFC.EXE      IBM C Compiler
ENV:PATH  DLGEDIT.EXE   Toolkit for OS/2 Warp
ENV:PATH  IPFC.EXE      IPF Compiler
ENV:PATH  PKUNZIP2.EXE  PKUnzip for OS/2 V1.11 (as part of MPTS)
ENV:PATH  GREP.EXE      Grep Utility
ENV:PATH  UNZIP.EXE     UNZIP.EXE of Info-ZIP
ENV:PATH  WGET.EXE      WGet Utility
ENV:PATH  HTEXT.CMD     HyperText/2 Preprocessor
ENV:PATH  REXX2EXE.EXE  REXX2EXE Compiler
ENV:PATH  FASTDEP.EXE   Fast Dependency Scanner

