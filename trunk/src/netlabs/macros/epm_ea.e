/****************************** Module Header *******************************
*
* Module Name: epm_ea.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epm_ea.e,v 1.2 2002-07-22 19:00:17 cla Exp $
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
; Various routines used for manipulating extended attributes.  Used by EPM.

const
   EAT_ASCII    = \253\255    -- FFFD
   EAT_MVMT     = \223\255    -- FFDF

;  Returns 1 if attribute name exists; sets VAR args.  EA_SEG, EA_OFS =
; start of EA buffer.  EA_PTR1, 2 = pointers to start of entry and value,
; respectively, if name was found.  EA_LEN, EA_ENTRYLEN, EA_VALUELEN = length
; of EA area, of entry, and of value, respectively.
; Dependencies:  None
defproc find_ea(name, var ea_seg, var ea_ofs, var ea_ptr1, var ea_ptr2, var ea_len, var ea_entrylen, var ea_valuelen) =
   ea_long = atol(.eaarea)
;  ea_seg = itoa(rightstr(ea_long,2),10)
   ea_seg = ltoa(rightstr(ea_long,2)\0\0,10)
;  ea_ofs = itoa(leftstr(ea_long,2),10)
   ea_ofs = ltoa(leftstr(ea_long,2)\0\0,10)
   if not .eaarea then return ''; endif
   ea_len  = ltoa(peek(ea_seg, ea_ofs, 4),10)
   ea_end = ea_ofs + ea_len
   ea_ptr1 = ea_ofs + 4                     -- Point past length of FEAList
   do while ea_ptr1 < ea_len
;     ea_flag = itoa(peek(ea_seg, ea_ptr1, 1)\0,16)
compile if EVERSION < '6.00'
      ea_namelen  = asc(peek(ea_seg, ea_ptr1+1, 1))
      ea_valuelen = ltoa(peek(ea_seg, ea_ptr1+2, 2)\0\0,10)
      ea_entrylen = ea_namelen + 5 + ea_valuelen
      if name = peekz(ea_seg, ea_ptr1+4) then
         ea_ptr2 = ea_ptr1+5+ea_namelen  -- Point to start of EA value
         return 1
      endif
compile else
      ea_namelen  = asc(peek(ea_seg, ea_ptr1+5, 1))
      ea_valuelen = ltoa(peek(ea_seg, ea_ptr1+6, 2)\0\0,10)
;     ea_entrylen = ltoa(peek(ea_seg, ea_ptr1, 4),10)
;     if not ea_entrylen then
;        ea_entrylen = ea_len - ea_ptr1
;     endif
      ea_entrylen = (ea_namelen + 12 + ea_valuelen)%4*4  -- ((namelen+9+valuelen)+3)%4*4
      if name = peekz(ea_seg, ea_ptr1+8) then
         ea_ptr2 = ea_ptr1+9+ea_namelen  -- Point to start of EA value
         return 1
      endif
compile endif
      ea_ptr1 = ea_ptr1 + ea_entrylen       -- Point to start of next entry
   enddo


; Dependencies:  None
defc addea, add_ea =                 -- Adds a single name / value pair to an existing EA list
   parse arg name data
   if name='' then
      sayerror 'ADD_EA <name> <value> adds the extended attribute value specified to the current file.'
      return
   endif
   name_len = length(name)
   data_len = length(data)
compile if EPM32
   ea_len_incr = ((16 + name_len + data_len)%4)*4;  -- align on 32bit boundary (+13 for overhead +3 for rounding)
compile else
   ea_len_incr = 9 + name_len + data_len
compile endif
   if .eaarea then
      ea_long = atol(.eaarea)
;     ea_seg = itoa(rightstr(ea_long,2),10)
      ea_seg = ltoa(rightstr(ea_long,2)\0\0,10)
;     ea_ofs = itoa(leftstr(ea_long,2),10)
      ea_ofs = ltoa(leftstr(ea_long,2)\0\0,10)
      ea_old_len  = ltoa(peek(ea_seg, ea_ofs, 4),10)
compile if EPM32
      call dynalink32(E_DLL,
                      'myrealloc',
                      ea_long ||
                      atol(ea_old_len+ea_len_incr) ||
                      atol(0),
                      2)

      r = 0
compile else
      r =  dynalink('DOSCALLS',           -- Dynamic link library name
               '#38',                     -- DosReAllocSeg
               atoi(ea_old_len+ea_len_incr) ||  -- Number of bytes requested
               rightstr(ea_long,2) )
compile endif  -- EPM32
      ea_ptr = ea_seg
   else
compile if EPM32
      ea_ptr = atol(dynalink32(E_DLL,
                               'mymalloc',
                               atol(ea_len_incr+4), 2))
;compile if not POWERPC
      ea_ptr  = ltoa(substr(ea_ptr, 3, 2)\0\0, 10)
;compile endif
      r = -270 * (ea_ptr = 0)
compile else
      ea_buffer = "00"                    -- Initialize string pointer.
      r =  dynalink('DOSCALLS',           -- Dynamic link library name
               '#34',                     -- DosAllocSeg
               atoi(ea_len_incr+4)    ||  -- Number of bytes requested
               address(ea_buffer)     ||
               atoi(0) )                  -- Share information
;     ea_ptr = itoa(ea_buffer,10)
      ea_ptr = ltoa(ea_buffer\0\0,10)
compile endif  -- EPM32
      ea_ofs = 0
      ea_old_len  = 4           -- Point past length field
   endif

   if r then sayerror ERROR__MSG r ALLOC_HALTED__MSG; stop; endif
   poke ea_ptr, ea_ofs, atol(ea_old_len+ea_len_incr)
   ea_ofs = ea_ofs + ea_old_len
compile if EVERSION < '6.00'
   poke ea_ptr, ea_ofs  , \0              -- Start of EA:  flag byte
   poke ea_ptr, ea_ofs+1, chr(name_len)
   poke ea_ptr, ea_ofs+2, atoi(data_len + 4)     -- Value length = len(data) + len(data_type) + len(data_len)
   poke ea_ptr, ea_ofs+4, name
   poke ea_ptr, ea_ofs+4+name_len, \0     -- Null byte after name
   poke ea_ptr, ea_ofs+5+name_len, EAT_ASCII
   poke ea_ptr, ea_ofs+7+name_len, atoi(data_len)
   poke ea_ptr, ea_ofs+9+name_len, data
compile else
 compile if 0  -- C code does this internally, when saving.
   -- we need to make sure the last entry is marked with zero length
   --   to find the last entry, just look for
   --   a bogus entry.  "\1\2\4\3\5" seems pretty unlikely.
   call find_ea("\1\2\4\3\5", xx_seg, xx_ofs, xx_ptr1, xx_ptr2, xx_len, xx_entrylen, xx_valuelen);
   if (xx_len>4) and xx_entrylen then
      poke ea_ptr, xx_len-xx_entrylen, atol(xx_entrylen);
   endif

   poke ea_ptr, ea_ofs+0, atol(0) -- Start of EA:  size (last one is always marked as zero)
 compile else

   poke ea_ptr, ea_ofs, atol(ea_len_incr) -- Start of EA:  size
 compile endif

   poke ea_ptr, ea_ofs+4, \0              -- flag byte
   poke ea_ptr, ea_ofs+5, chr(name_len)
   poke ea_ptr, ea_ofs+6, atoi(data_len + 4)     -- Value length = len(data) + len(data_type) + len(data_len)
   poke ea_ptr, ea_ofs+8, name
   poke ea_ptr, ea_ofs+8+name_len, \0     -- Null byte after name
   poke ea_ptr, ea_ofs+9+name_len, EAT_ASCII
   poke ea_ptr, ea_ofs+11+name_len, atoi(data_len)
   poke ea_ptr, ea_ofs+13+name_len, data
compile endif
   .eaarea = mpfrom2short(ea_ptr,0)


; Dependencies:  find_ea
defproc get_EAT_ASCII_value(name) =  -- Returns the value for a given attribute name
   if find_ea(name, ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen) then
      stuff = peek(ea_seg, ea_ptr2, min(ea_valuelen,4))
      if leftstr(stuff,2) = EAT_ASCII & ea_valuelen > 4 then
         return peek(ea_seg, ea_ptr2+4, min(itoa(substr(stuff,3,2),10),MAXCOL))
      endif
   endif


; Dependencies:  find_ea()
defproc delete_ea(name) =
   parse arg name .
   if not find_ea(name, ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen) then
      return
   endif
   newlen = ea_len - ea_entrylen
   poke ea_seg, ea_ofs, atol(newlen)
compile if EVERSION < '5.21'
   junk = 'junk'  -- Avoid problem due to bug in MEMCPYX in EPM 5.20
compile endif
   if ea_ptr1+ea_entrylen < ea_len then  -- If in the middle, close it up
      call memcpyx(atoi(ea_ptr1) || atoi(ea_seg), atoi(ea_ptr1+ea_entrylen) || atoi(ea_seg), ea_len - ea_ptr1 - ea_entrylen)
   endif
compile if EPM32
--   call dynalink32('DOSCALLS',
--                   '#305',                -- DosSetMem
--                   atol(ea_seg\0\0) ||
--                   atol(.eaarea) ||
--                   atol(newlen)  ||
--                   atol(19) )             -- PAG_READ | PAG_WRITE | PAG_COMMIT
   call dynalink32(E_DLL,
                  'myrealloc',
                  \0\0 || atoi(ea_seg) ||
                  atol(newlen) ||
                  atol(0),
                  2)
compile else
   call dynalink('DOSCALLS',           -- Dynamic link library name
            '#38',                     -- DosReAllocSeg
            atoi(newlen)           ||  -- Number of bytes requested
            atoi(ea_seg) )
compile endif  -- EPM32


; Dependencies:  find_ea(), delete_ea(), add_ea
defc type =
   found = find_ea('.TYPE', ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen)
   if not found | ea_valuelen=0 then
      answer = winmessagebox(TYPE_TITLE__MSG, NO_FILE_TYPE__MSG, 16388) -- YESNO + MOVEABLE
   elseif peek(ea_seg, ea_ptr2, 2)=EAT_ASCII then
;     type = peek(ea_seg, ea_ptr2+4, min(itoa(peek(ea_seg, ea_ptr2+2, 2), 10), MAXCOL))
      type = peek(ea_seg, ea_ptr2+4, min(ltoa(peek(ea_seg, ea_ptr2+2, 2)\0\0, 10), MAXCOL))
      answer = winmessagebox(TYPE_TITLE__MSG, ONE_FILE_TYPE__MSG\13 type\13\13CHANGE_QUERY__MSG, 16388) -- YESNO + MOVEABLE
   elseif peek(ea_seg, ea_ptr2, 2)=EAT_MVMT then
;     ea_numentries = itoa(peek(ea_seg, ea_ptr2+4, 2),10)
      ea_numentries = ltoa(peek(ea_seg, ea_ptr2+4, 2)\0\0,10)
      if ea_numentries=1 then
         type = ONE_FILE_TYPE__MSG
      else
         type = MANY_FILE_TYPES__MSG
      endif
      ea_entry_ofs = ea_ptr2+6
      do i=1 to ea_numentries
;        ea_entrylen = itoa(peek(ea_seg, ea_entry_ofs+2, 2),10)
         ea_entrylen = ltoa(peek(ea_seg, ea_entry_ofs+2, 2)\0\0,10)
         if peek(ea_seg, ea_entry_ofs, 2)=EAT_ASCII then
            type = type\13 || peek(ea_seg, ea_entry_ofs+4,min(ea_entrylen,MAXCOL))
         else
            type = type\13 || NON_ASCII__MSG
         endif
         ea_entry_ofs = ea_entry_ofs + ea_entrylen + 4
      enddo
      answer = winmessagebox(TYPE_TITLE__MSG, type\13\13CHANGE_QUERY__MSG, 16388) -- YESNO + MOVEABLE
   else
      answer = winmessagebox(TYPE_TITLE__MSG, NON_ASCII_TYPE__MSG\13CHANGE_QUERY__MSG, 16388) -- YESNO + MOVEABLE
   endif
   if answer=6 then
compile if EVERSION < 5.21
      newtype = listbox(SELECT_TYPE__MSG, TYPE_LIST__MSG)
      if newtype then
compile else
      parse value listbox(TYPE_TITLE__MSG, TYPE_LIST__MSG, '/'SET__MSG'/'CANCEL__MSG'/'HELP__MSG, 0, 0, 0, 0,
 compile if EVERSION >= 5.60
                          gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(6040) ||
 compile else
                          atoi(1) || atoi(1) || atoi(6040) || gethwndc(APP_HANDLE) ||
 compile endif
                          SELECT_TYPE__MSG) with button 2 newtype \0
      if newtype & (button=\1) then
compile endif  -- EVERSION < 5.21
         if found then call delete_ea('.TYPE'); endif
         'add_ea .TYPE' newtype
      endif
   endif


; Dependencies:  find_ea(), delete_ea(), add_ea
defc subject =
compile if EPATH = 'LAMPATH'
   universal inboxpath
   parse value .userstring with '(' spid ')'
   if spid='' then
compile endif -- EPATH = 'LAMPATH'
      subj = ''
compile if EPATH = 'LAMPATH'
   else
      subj = find_subj()
   endif
compile endif -- EPATH = 'LAMPATH'
   found = find_ea('.SUBJECT', ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen)
   if arg(1)='' then
      max_len = MAXCOL - length(SUBJECT_IS__MSG) - length(CHANGE_QUERY__MSG) - 5
      if not found | ea_valuelen=0 then
compile if EPATH = 'LAMPATH'
         if subj='' | upcase(subj)='NO SUBJECT' then
compile endif -- EPATH = 'LAMPATH'
            answer = winmessagebox(SUBJ_TITLE__MSG, NO_SUBJECT__MSG, 16388) -- YESNO + MOVEABLE
compile if EPATH = 'LAMPATH'
         else
            newsubj = subj
            if length(subj)>max_len then
               newsubj = leftstr(subj, max_len-3)'...'
            endif
            answer = winmessagebox(SUBJ_TITLE__MSG, SUBJECT_IS__MSG\13 newsubj\13\13||CHANGE_QUERY__MSG, 16388) -- YESNO + MOVEABLE
         endif
compile endif -- EPATH = 'LAMPATH'
      elseif peek(ea_seg, ea_ptr2, 2)=EAT_ASCII then
         subj = peek(ea_seg, ea_ptr2+4, min(ltoa(peek(ea_seg, ea_ptr2+2, 2)\0\0, 10), MAXCOL))
         newsubj = subj
         if length(subj)>max_len then
            newsubj = leftstr(subj, max_len-3)'...'
         endif
         answer = winmessagebox(SUBJ_TITLE__MSG, SUBJECT_IS__MSG\13 newsubj\13\13||CHANGE_QUERY__MSG, 16388) -- YESNO + MOVEABLE
      else
         answer = winmessagebox(SUBJ_TITLE__MSG, NON_ASCII_SUBJECT__MSG\13||CHANGE_QUERY__MSG, 16388) -- YESNO + MOVEABLE
      endif
   else  -- arg(1) not null
      answer = 6
   endif
   if answer=6 then
compile if EVERSION < 5.21  -- The old way
      if arg(1)='' then
         newsubj = entrybox(SELECT_SUBJECT__MSG, '', subj, 40, 230)
      else
         newsubj = arg(1)
      endif
      if newsubj then
compile else
      if arg(1)='' then
         parse value entrybox(SUBJ_TITLE__MSG, '/'SET__MSG'/'CANCEL__MSG'/'HELP__MSG, subj, 40,
 compile if EVERSION >= 5.60 -- long strings
                260,
 compile else
                230,  -- 255 limit on strings; must leave room for 'add_ea...'
 compile endif
                atoi(1) || atoi(6050) || gethwndc(APP_HANDLE) || SELECT_SUBJECT__MSG) with button 2 newsubj \0
      else
         newsubj = arg(1)
         button = \1
      endif
      if newsubj & (button=\1) then
compile endif
         if found then call delete_ea('.SUBJECT'); endif
         'add_ea .SUBJECT' newsubj
compile if EPATH = 'LAMPATH'
         if spid<>'' then
            if not .modify then 'save /q'; endif  -- If file not modified, save new EA, otherwise, let user save it.
            i = lastpos('\',spid)
            if not i then                -- Unexpected error
               sayerror 'Bad spoolid.'
               return
            endif
            getfileid startid
            path = upcase(leftstr(spid,i-1))
            if path=inboxpath then
               indxname = path'\inbox.ndx'
            else
               indxname = path'.ndx'
            endif
            display -2
            success = lock_index(indxname)
            display 2
            if not success then
               sayerror 'Failed to lock index file.'
               return
            endif
            if rc=sayerror('New file') or rc=sayerror('Lines truncated') or (not rc & not .last) then
               call free_index()
               return
            endif
            getfileid fid
            if rc then
               if startid<>fid then call free_index(); endif
               return
            endif
            getsearch oldsearch
            call psave_mark(savemark)
            0
            call pset_mark(1, .last, 28, 44, 'BLOCK', fid)
            parse value substr(spid,i+1) with filename '.' filetype
            display -2
            'xcom l /'leftstr(filename,8) leftstr(filetype,8)'/cm'
            lrc = rc
            display 2
            call prestore_mark(savemark)
            setsearch oldsearch
            retval = ''
            if not lrc then
               getline line
               subjstart = pos('', line, 84)
               subjend = pos('', line, subjstart+1)
               if subjstart & subjend then
 compile if EVERSION >= 5.60
                  line = insertstr(newsubj, delstr(line, subjstart+1, subjend-subjstart-1), subjstart)
 compile else  -- Must limit index line to 255 characters.
                  line = insertstr(newsubj, delstr(line, subjstart+1, subjend-subjstart-1), subjstart, min(length(newsubj), 255-length(line)+(subjend-subjstart-1)))
 compile endif
                  replaceline line, .line
                  call fn2spoolid(startid.filename, spoolid)
                  call LAM_SPOOL_CMD(5505, spoolid, line)   -- x1581; LAM VIEWED
                  sayerror 'Subject updated in index file.'
               endif
            endif
            call free_index()
            activatefile startid
         endif  -- spid<>''
compile endif -- EPATH = 'LAMPATH'
      endif  -- newsubj
   endif  -- answer = 'YES'
