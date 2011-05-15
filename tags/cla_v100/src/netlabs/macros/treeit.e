/****************************** Module Header *******************************
*
* Module Name: treeit.e
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
const
   NOT_TREE__MSG = "This is not a tree file.  You must be in a tree buffer to invoke TREE."
   NO_TREEIT_CMD__MSG = "You must provide the command that you want to invoke against the tree'd files."

EA_comment 'This defines the TREEIT command; it can be linked in or executed directly.'

--------------------- End of MRI for translation ----------------------------

defproc replace_str(from_str, to_str, source_str)
   do forever
      p = pos(from_str, source_str)
      if not p then leave; endif
      source_str=insertstr(to_str, delstr(source_str, p, length(from_str)), p-1)
   enddo
   return source_str

defc treeit
   getfileid treefileid
;; if .last<2 then
;;    sayerror "This is not a tree file.  You must be in a tree buffer to invoke TREE."
;;    return
;; endif
;; getline content, 2
;; -- if line two isn't a bunch of underlines, something is wrong.
;; if leftstr(content, 33) /== "ออออออออออ  ออออออออ  อออออออออ  " then
   if .filename <> '.tree' then
      sayerror NOT_TREE__MSG
      return
   endif
; Fileman uses:
; /o   /e   /n   /f        /p      /d  /q    /l   /+ /           //
; omit ext  name name.ext  \path\  d:  quiet list +  everything   literal '/'
   arg1 = arg(1)
   if upcase(word(arg1,1))='/D' then
      include_dirs = 1
      arg1 = subword(arg1, 2)
   else
      include_dirs = 0
   endif
   if arg1=="" then
      sayerror NO_TREEIT_CMD__MSG
      return
   endif
   p1 = pos('%', arg1)  -- Loop invariant
   firstline = 1; lastline = .last   -- Could be 3 to (.last-1), but allow for user editing file.
   if leftstr(marktype(), 1)='L' then
      getmark l1, l2, c1, c2, markfid
      if markfid = treefileid then
         firstline = l1; lastline = l2
      endif
   endif
   display -1
   for linenum = firstline to lastline
      getline content, linenum, treefileid
      filenamex = substr(content, 52)
      if pos(substr(filenamex,2,1), ":\.") then
         if substr(content, 46, 1) = 'D' & not include_dirs then
            iterate
         endif
         if not p1 then   -- No %'s ?
            arg1 filenamex  -- Default is to append full name to command
         else
            filenamex = translate(filenamex, \0, '%')  -- Get rid of %'s in filename.
            if substr(filenamex,2,1)==":" then
               drive = leftstr(filenamex, 2)
            elseif leftstr(filenamex, 1)=="." then
               drive = leftstr(directory(), 2)
            else
               drive = ''
            endif
            if leftstr(filenamex,1)='.' then
               slash1 = 1
            else
               slash1 = pos('\', filenamex)
            endif
            slashn = lastpos('\', filenamex)
            path = substr(filenamex, slash1, slashn - slash1 + 1)
            nameext = substr(filenamex, slashn+1)
            dot = lastpos('.', nameext)
            if dot then
               name = leftstr(nameext, dot-1)
               ext = substr(nameext, dot+1)
            else
               name = nameext
               ext = ''
            endif
            cmd = replace_str("%%", \0, arg1)      -- Change all %% to nulls
            cmd = replace_str("%x", filenamex, cmd)  -- %x = d:\path\name.ext
            cmd = replace_str("%f", nameext, cmd)    -- %f = name.ext
            cmd = replace_str("%p", path, cmd)       -- %p = \path\
            cmd = replace_str("%d", drive, cmd)      -- %d = d:
            cmd = replace_str("%n", name, cmd)       -- %n = name
            cmd = replace_str("%e", ext, cmd)        -- %e = ext
            cmd = replace_str("%", filenamex, cmd)   -- %  = d:\path\name.ext
            cmd = replace_str(\0, "%", cmd)      -- Change all nulls back to %
            cmd                                  -- Execute the resulting command.
         endif
      endif
   endfor
   display 1
   activatefile treefileid

defmain
   "treeit" arg(1)

