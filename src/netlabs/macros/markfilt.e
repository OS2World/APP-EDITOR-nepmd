/****************************** Module Header *******************************
*
* Module Name: markfilt.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
/*
  This file provides procedures for filtering a block,line or character mark

 pinit_extract() initializes the extraction

 pextract_string(var string)
   OUTPUT
     sets string to the next line in marked text and returns
     code 0 if ok ,1 if last line, -1 if blank line

 pput_string_back(string)
     put string back into marked text

*/
defproc pinit_extract()
   universal zzline_ptr,zzline,zzfirstline,zzlastline,zzfirstcol,zzlastcol,zzfileid,zzleftchr,zzrightchr

   getmark zzfirstline,zzlastline,zzfirstcol,zzlastcol,zzfileid
   zzline_ptr = zzfirstline - 1

defproc pextract_string(var string)
   universal zzline_ptr,zzline,zzfirstline,zzlastline,zzfirstcol,zzlastcol, zzfileid,zzleftchr,zzrightchr

   /* return value: 0 if ok ,1 if last line, -1 if blank line */
   if zzline_ptr = zzlastline | (zzline_ptr=(zzlastline-1) & not zzlastcol) then
      return 1
   endif
   zzline_ptr = zzline_ptr + 1
   getline zzline,zzline_ptr,zzfileid
   if marktype() = 'LINE' then
      string = zzline           /* for a line mark it's easy */
   else
      if marktype() = 'BLOCK' then
         zzleftchr = zzfirstcol; zzrightchr = zzlastcol
      else
         zzline_ptr
         zzlastchr = length(zzline)
         if zzline_ptr = zzfirstline then
            zzleftchr = zzfirstcol
            if zzline_ptr = zzlastline then
               zzrightchr = zzlastcol
            else
               if zzlastchr then
                  zzrightchr = zzlastchr
               else
                  zzrightchr = zzfirstcol
               endif
            endif
         else
            if zzline_ptr = zzlastline then
               zzleftchr = 1; zzrightchr = zzlastcol
            else
               if not zzlastchr then return -1; endif
               zzleftchr = 1
               zzrightchr = zzlastchr
            endif
         endif
      endif
      string = substr(zzline,zzleftchr,zzrightchr-zzleftchr+1)
   endif
;; if string='' then            -- Following saves 9 bytes.
;;    return -1
;; endif
;; return 0
   return (string<>'') - 1


defproc pput_string_back(string)
   universal zzline_ptr,zzline,zzfirstline,zzlastline,zzfirstcol,zzlastcol,zzfileid,zzleftchr,zzrightchr

   if marktype() = 'LINE' then
      zzline = string
   else
      zzline = substr(zzline,1,zzleftchr-1)||string||substr(zzline,zzrightchr+1)
   endif
   replaceline zzline,zzline_ptr,zzfileid
