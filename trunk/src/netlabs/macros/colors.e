/****************************** Module Header *******************************
*
* Module Name: colors.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: colors.e,v 1.3 2002-08-09 19:57:25 aschn Exp $
*
* ===========================================================================
*
* This file is part of the Netlabs EPM Distribution package and is free
* software.  You can redistribute it and/or modify it under the terms of the
* GNU General Public License as published by the Free Software
* Foundation, in version 2 as it comes in the "COPYING" file of the 
* Netlabs EPM Distribution.  This library is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
****************************************************************************/
/*****************************************************************************/
/*                                                                           */
/* COLORS.E.  Color setting is concentrated here.  This does two things:     */
/*                                                                           */
/* 1. Defines mnemonic constants for the color numbers,                      */
/*    so the rest of the files can refer to "RED" rather than 4.             */
/* 2. Configures the standard colors, by defining mnemonic field names       */
/*    such as STATUSCOLOR.                                                   */
/*                                                                           */
/* To configure your colors, copy the appropriate definitions from the lower */
/* half to your MYCNF.E file, and modify them as desired.  E.g.,             */
/*    define                                                                 */
/*       COMMANDCOLOR             = Light_Cyan + MagentaB                    */
/*       MARKCOLOR                = White + CyanB                            */
/*                                                                           */
/*****************************************************************************/

const
   BLACK          =  0
   BLUE           = 01
   GREEN          = 02
   CYAN           = 03
   RED            = 04
   MAGENTA        = 05
   BROWN          = 06
   LIGHT_GREY     = 07
   DARK_GREY      = 08
   LIGHT_BLUE     = 09
   LIGHT_GREEN    = 10
   LIGHT_CYAN     = 11
   LIGHT_RED      = 12
   LIGHT_MAGENTA  = 13
   YELLOW         = 14
   WHITE          = 15
   BLACKB         =  0
   BLUEB          = 16
   GREENB         = 32
   CYANB          = 48
   REDB           = 64
   MAGENTAB       = 80
   BROWNB         = 96
   GREYB          =112
   LIGHT_GREYB    =112       -- on a CGA.  We assume if you're running OS/2, you
   DARK_GREYB     =128       -- have a better monitor.  If you are actually
   LIGHT_BLUEB    =144       -- running OS/2 on a CGA, be sure that you specify
   LIGHT_GREENB   =160       -- BROWNB or GREYB instead of YELLOWB or WHITEB, or
   LIGHT_CYANB    =176       -- you'll get blinking characters.
   LIGHT_REDB     =192
   LIGHT_MAGENTAB =208
   YELLOWB        =224
   WHITEB         =240

   BLINK          =128        /* qualities */
   UNDERLINE      =  1
   HIGH_INTENSITY =  8
   NORMAL         =  7
   INVERSE        =112
   INVISIBLE      =  0


/*********************** Standard color definitions. *************************/
; These are DEFINEs rather than CONSTs, so that they can be overridden in
; MYCNF.E, if desired.

; Note:  COMMANDCOLOR is used for the status line and filename in zoom
;        window style 3.  (E3 and EOS2)
define
   STATUSCOLOR              = WHITEB
 compile if EVERSION >= '5.60'
   DESKTOPCOLOR             = LIGHT_GREY
 compile endif
   MONOSTATUSCOLOR          = NORMAL
   FILENAMECOLOR            = NORMAL
   MONOFILENAMECOLOR        = NORMAL
   COMMANDCOLOR             = WHITE+BROWNB
   MONOCOMMANDCOLOR         = INVERSE
   FUNCTIONKEYTEXTCOLOR     = CYAN
   MONOFUNCTIONKEYTEXTCOLOR = NORMAL
   WINDOWCOLOR              = LIGHT_GREY + BLUEB
   MONOWINDOWCOLOR          = NORMAL
   BOXCOLOR                 = YELLOW
   MONOBOXCOLOR             = NORMAL
   CURSORCOLOR              = BLACK + BROWNB
   MONOCURSORCOLOR          = UNDERLINE + HIGH_INTENSITY
   MARKCOLOR                = BLUE + GREYB
   MONOMARKCOLOR            = INVERSE
   MESSAGECOLOR             = LIGHT_RED + WHITEB
   MONOMESSAGECOLOR         = NORMAL

;  E3 and EOS2 use all the above.  EPM only uses MARKCOLOR, TEXTCOLOR, STATUSCOLOR
;  and MESSAGECOLOR (TEXTCOLOR is the same as WINDOWCOLOR).
   TEXTCOLOR                = WHITEB
   DRAGCOLOR                = YELLOW + MAGENTAB

   MODIFIED_WINDOWCOLOR = WHITE + BLUEB
   MODIFIED_MARKCOLOR = BLUE + WHITEB
   MODIFIED_FILENAMECOLOR = FILENAMECOLOR%16 * 16 + RED  -- Red on same background.
   MODIFIED_MONOFILENAMECOLOR = UNDERLINE
   MODIFIED_FKTEXTCOLOR = BLACK + CYANB

