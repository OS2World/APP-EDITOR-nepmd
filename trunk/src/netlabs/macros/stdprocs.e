compile if EVERSION >= 4 & EVERSION < '5.51'  -- 5.51 & above define this internally.
defproc address(var varname) =
   return selector(varname) || offset(varname)
compile endif

; A useful subroutine:  asks "Are you sure (Y/N)?" (same as DOS's prompt
; after "erase *.*") and returns uppercase keystroke.
; If called with a string parameter, displays it at start of prompt, e.g.
;   usersays = askyesno("About to erase.")
;   ==>   "About to erase. Are you sure (Y/N)? "
; EPM 5.12B:  Now enabled for EPM, using entrybox().  Optional second argument
; is a flag to prevent the "Are you sure" from being appended.
; EPM 5.15:  Now uses WinMessageBox to get Yes, No buttons.  [\toolktxx\c\include\pmwin.h]
; 93/12/15:  Added optional 3rd arg for messagebox title.
defproc askyesno
   prompt=arg(1)
compile if EVERSION < 5
   if not arg(2) then
      prompt=prompt || ARE_YOU_SURE_YN__MSG
   endif
   return upcase(mgetkey(prompt))     /* Accept key from macro. */
compile else
   if not arg(2) then
      prompt=prompt\13 || ARE_YOU_SURE__MSG
   endif
   return substr(YES_CHAR || NO_CHAR, winmessagebox(arg(3), prompt, 16388) - 5, 1)  -- YESNO + MOVEABLE
compile endif


compile if EVERSION >= 4
; Does an atol of its argument, then a word reversal and returns the result.
defproc atol_swap(num)
   hwnd=atol(num)
 compile if EVERSION >= '5.17'
   return rightstr(hwnd,2) || leftstr(hwnd,2)
 compile else
   return substr(hwnd,3,2) || substr(hwnd,1,2)
 compile endif
compile endif


defproc checkmark()        /* Common routine, save space.  from Jim Hurley.*/
  if marktype()='' then
compile if EPM
    sayerror NO_MARK_HERE__MSG
compile else
    sayerror NO_MARK__MSG
compile endif
    stop
  endif

; Routine to tell if a mark is visible on the screen.  (Actually, only on the
; current window; if the window is less than full size, a mark could be visible
; in an inactive window without our being able to tell.)  Also, if a character
; mark begins above the top of the window and ends below the bottom, and the
; window contains only blank lines, then this routine will return 1 (since the
; mark spans the window) even though no sign of the mark will be visible.
defproc check_mark_on_screen =
   if marktype() = '' then return 0; endif  -- If no mark, then not on screen.
   getmark first_mark_line, last_mark_line, first_mark_col, last_mark_col
   first_screen_line = .line - .cursory + 1
   last_screen_line = .line - .cursory + .windowheight
   if last_mark_line < first_screen_line then return 0; endif
   if first_mark_line > last_screen_line then return 0; endif
   no_char_overlap = marktype()<>'CHAR' or first_mark_line=last_mark_line
   if last_mark_col < .col - .cursorx + 1 and
      (no_char_overlap or last_mark_line=first_screen_line)
   then return 0; endif
   if first_mark_col > .col - .cursorx + .windowwidth and
      (no_char_overlap or first_mark_line=last_screen_line)
   then return 0; endif
   return 1

; Tests whether the "filename" is actually a printer
; device, so we'll know whether to test printer readiness first.
; Called by savefile() in SAVELOAD.E.  Returns 0 if not, else printer number.
defproc check_for_printer(name)
   if not name then return 0; endif
compile if EVERSION >= '5.50'
   if leftstr(name,1)='"' & rightstr(name,1)='"' then
      name=substr(name,2,length(name)-2)
   endif
compile endif
compile if EVERSION >= '5.17'
   if rightstr(name,1) = ':' then  -- a device
      name = leftstr(name,length(name)-1)
compile else
   if substr(name,length(name),1) = ':' then  -- a device
      name = substr(name,1,length(name)-1)
compile endif
   else       -- Might be a full pathspec, C:\EDIT\PRN, and still go to a device!
      indx = lastpos('\',name)
      if not indx then indx = lastpos(':',name) endif
      if indx then name=substr(name,indx+1) endif
      indx = pos('.',name)
      if indx then name=substr(name,1,indx-1) endif
   endif
   if upcase(name)='PRN' then return 1; endif
compile if EVERSION >= 4  -- Check_for_printer always returns true, so we don't need to distinguish COMn.
   return (4+pos('.'upcase(name)'.','.LPT1.LPT2.LPT3.LPT4.LPT5.LPT6.LPT7.LPT8.LPT9.COM1.COM2.COM3.COM4.')) % 5
compile else
   return (4+pos('.'upcase(name)'.','.LPT1.LPT2.LPT3.')) % 5
compile endif

compile if WANT_WINDOWS
; This proc is called only by DEFC EDIT in messy-desk mode.
defproc create_window_for_each_file(emptyfileid)
   fileidlist=''
   activatefile emptyfileid /* Start list at beginning so we get 'em all.    */
   nextfile                 /* Except first one, can leave one in each ring. */
   loop
      nextfile
      .box=1
      getfileid fileid
      if fileid=emptyfileid then
         leave
      endif
      fileidlist=fileidlist fileid
   endloop
   rest=fileidlist
   loop
      parse value rest with fileid rest
      if fileid='' then
         leave
      endif
      rc=0
      newwindow fileid
      if rc then leave endif
      getfileid cur_fileid
      activatefile fileid
      quitview
      activatefile cur_fileid
   endloop
compile endif


COMPILE IF EVERSION >= 4
defproc dec_to_string(string)    -- for dynalink usage
   line = ''
   for i = 1 to length(string)
     line= line || asc(substr(string,i,1)) || ' '
   endfor
   return line
COMPILE ENDIF

defproc default_printer
compile if defined(my_printer)
   return MY_PRINTER
compile elseif EPM
   parse value queryprofile(HINI_PROFILE, 'PM_SPOOLER', 'PRINTER') with printername ';'
   if printername<>'' then
      parse value queryprofile(HINI_PROFILE, 'PM_SPOOLER_PRINTER', printername) with dev ';'
      if dev<>'' then return dev; endif
   endif
compile endif
   return 'LPT1'

;  Returns DOS version number, multiplied by 100 so we can treat
;  it as an integer string.  That is, DOS 3.2 is reported as "320".
;  Needed by DEFPROC SUBDIR.

defproc dos_version()
compile if E3
   parse value int86x(DOS_INT,DOS_GET_VERSION,'') with ax .
   major = ax // 256                  /* AL = major version number */
;  minor = (ax - major) % 256
   return 100*major + (ax - major) % 256
compile elseif EPM32
      verbuf = copies(\0,8)
      res= dynalink32('DOSCALLS',          /* dynamic link library name */
                     '#348',              /* ordinal for DOS32QuerySysInfo */
                     atol(11)         ||  -- Start index (Major version number)
                     atol(12)         ||  -- End index (Minor version number)
                     address(verbuf)  ||  -- buffer
                     atol(8),2)           -- Buffer length
;     major = ltoa(leftstr(verbuf,4),10)
;     minor = ltoa(rightstr(verbuf,4),10)
      return 100*ltoa(leftstr(verbuf,4),10) + ltoa(rightstr(verbuf,4),10)
compile else
      verbuf = 'nn'
      res= dynalink('DOSCALLS',          /* dynamic link library name */
                    '#92',               /* ordinal for DOSGETVERSION */
                    address(verbuf))
;     major = asc(substr(verbuf,2,1))
;     minor = asc(substr(verbuf,1,1))
      return 100*asc(substr(verbuf,2,1)) + asc(substr(verbuf,1,1))
compile endif


compile if WANT_ET_COMMAND     -- Let user omit ET command.
defproc ec_position_on_error(tempfile)   /* load file containing error */
   'xcom e 'tempfile
   if rc then    -- Unexpected error.
      sayerror ERROR_LOADING__MSG tempfile
      if rc=-282 then 'xcom q'; endif  -- sayerror('New file')
      return
   endif
   if .last<=4 then
      getline msg,.last
      'xcom q'
   else
      getline msg,2
compile if EPM
      if leftstr(msg,3)='(C)' then  -- 5.20 changed output
         getline msg,4
      endif
compile endif
      getline temp,.last
      parse value temp with 'col= ' col
      getline temp,.last-1
      parse value temp with 'line= ' line
      getline temp,.last-2
      parse value temp with 'filename=' filename
      'xcom q'
      'e 'filename               -- not xcom here, respect user's window style
      if line<>'' and col<>'' then
compile if EPM
         .cursory=min(.windowheight%2,.last)
compile else
         .cursory=15
compile endif
         if col>0 then
            .col=col
            line
         else
            .line=line-1   /* sometimes the compiler is off by 1 */
            getline s
            .col=length(s) /* position cursor at end of previous line */
         endif
      endif
   endif
   sayerror msg
compile endif

defproc einsert_line
   insert
   up
   getline line
   parse value pmargins() with leftcol . paracol .
   if line='' or not .line then
      .col=paracol
   else
      call pfirst_nonblank()
      if .col=paracol then .col=leftcol; endif
   endif
   down

compile if ENHANCED_ENTER_KEYS
defproc enter_common(action)
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
   if stream_mode then
 compile endif
 compile if WANT_STREAM_MODE
      if .line then
  compile if WANT_CUA_MARKING
   compile if WANT_CUA_MARKING = 'SWITCH'
         if CUA_marking_switch then
   compile endif
            if not process_mark_like_cua() and   -- There was no mark
               not insert_state() then           -- & we're in replace mode
               delete_char    -- Delete the character, to emulate replacing the
            endif             -- marked character with a newline.
   compile if WANT_CUA_MARKING = 'SWITCH'
         endif
   compile endif
  compile endif  -- WANT_CUA_MARKING
  compile if WANT_STREAM_INDENTED
         call splitlines()
         call pfirst_nonblank()
         down
  compile else
         split
         .col=1
         down
  compile endif -- WANT_STREAM_INDENTED
      else
         insert
         .col=1
      endif
      return
 compile endif  -- WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   endif
 compile endif
 compile if WANT_STREAM_MODE <> 1
   is_lastline = .line=.last
   if is_lastline  & (action=3 | action=5) then  -- 'ADDATEND' | 'DEPENDS+'
      call einsert_line()
      down                       -- This keeps the === Bottom === line visible.
      return
   endif
;     'NEXTLINE' 'ADDATEND'                        'DEPENDS'  'DEPENDS+'
   if action=2 | action=3 | (not insert_state() & (action=4 | action=5)) then
      down                          -- go to next line
      begin_line
      return
   endif
   if action=6 then
      call splitlines()
      call pfirst_nonblank()
      down
;;    refresh
      return
   endif
   if action=7 | action=8 then
      insert
      parse value pmargins() with leftcol . paracol .
      if textline(.line-1)='' or .line=1 or action=8 then
         .col=paracol
      else
         .col=leftcol
      endif
      if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
      return
   endif
   if action=9 then
      insert
      begin_line
      if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
      return
   endif
   call einsert_line()           -- insert a line
   if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
 compile endif  -- WANT_STREAM_MODE <> 1
compile endif

;  Erasetemp erases a file quietly (no "File not found" message) on both DOS
;  and OS/2.  Thanks to Larry Margolis.  Returns 0 if successful erase, or
;  the error code (if on DOS) which will usually be 2 for 'file not found'.
defproc erasetemp(filename)
   asciiz = filename\0
compile if E3
   call free()    -- Keep variables from moving around before int86x.
   parse value int86x(DOS_INT,DOS_UNLINK 0 0 ofs(asciiz), seg(asciiz)) with ax . . . . . cf ',' .
   -- Most callers will ignore error code, don't care file doesn't exist.
   -- if cf then sayerror 'DOS error code' ax endif
   if cf then return ax; endif
compile elseif EPM32
   return dynalink32('DOSCALLS',          /* dynamic link library name */
                    '#259',               /* ordinal value for DOSDELETE */
                    address(asciiz) )
compile else
   return dynalink('DOSCALLS',          /* dynamic link library name */
                   '#60',               /* ordinal value for DOSDELETE */
                   address(asciiz) ||
                   atoi(0)         ||   /* reserved                  */
                   atoi(0))             /* reserved                  */
compile endif

compile if EPM
defproc find_token(var startcol, var endcol)  -- find a token around the cursor.
   if arg(3)='' then
      token_separators = ' ~`!%^&*()-+=][{}|\:;?/><,''"'\t
   else
      token_separators = arg(3)
   endif
   if arg(4)='' then
      diads = '-> ++ -- << >> <= >= && || += -= *= /= %= ª= &= |= :: /* */'
   else
      diads = arg(4)
   endif
   getline line
   len = length(line)
   if .col>len | pos(substr(line, .col, 1), ' '\t) then
      return  -- Past end of line, or over whitespace
   endif
   endcol = verify(line, token_separators, 'M', .col)
   if endcol = .col then  -- On an operator.
      startcol = endcol
      if wordpos(substr(line, startcol, 2), diads) then
         endcol = endcol + 1  -- On first character
      elseif .col > 1 then
         if wordpos(substr(line, endcol-1, 2), diads) then
            startcol = startcol - 1  -- -- On last character
         endif
      endif
      return 2
   endif
   if endcol then
      endcol = endcol - 1
   else
      endcol = len
   endif
   startcol = verify(reverse(line), token_separators, 'M', len - .col + 1)
   if startcol then
      startcol = len - startcol + 2
   else
      startcol = 1
   endif
   return 1
compile endif

; Note on a speed trick:  The following routine is used to both verify that
; an external program exists, and to get its path.  After that first search,
; the exact path location of the routine is known; it can be remembered so that
; all future calls can supply the exact location to avoid the path search.
; See SUBDIR for an example of its use.

defproc find_routine(utility)  -- Split from SUBDIR
   parse arg util opts         -- take first word, so can pass options too.
   findfile fully_qualified,util,'PATH','P'
   if rc then return -1 endif
compile if E3
   if dos_version() < 300 then
      return utility             --DOS 2 can't handle the path
   endif                         --in front of the command.
compile endif
   return fully_qualified opts

compile if EVERSION >='5.50'    -- For GPI version, we must manage the cursor ourself
defproc fixup_cursor()
 compile if DYNAMIC_CURSOR_STYLE
   universal cursordimensions
   parse value word(cursordimensions, insert_state()+1) with cursorw '.' cursorh
 compile else
  compile if UNDERLINE_CURSOR
   cursorh = 3 - 67*insert_state()         -- 0 -> 3; 1 -> -64
   cursorw = '-128'
  compile else
   cursorw = 2 - 130*(not insert_state())  -- 0 -> -128; 1 -> 2
   cursorh = '-128'
  compile endif
 compile endif
   cursor_dimensions cursorw, cursorh
compile endif

; Highlight a "hit" after a Locate command or Repeat_find operation
compile if defined(HIGHLIGHT_COLOR)
defproc highlight_match(search_len)
   if not rc then
 compile if EVERSION < '5.50'
      refresh
      sayat '', .cursory, .cursorx, HIGHLIGHT_COLOR, min(search_len, .windowwidth - .cursorx + 1)
 compile elseif EVERSION >= '6.02'
      col = getpminfo(EPMINFO_SEARCHPOS)
      circleit LOCATE_CIRCLE_STYLE, .line, col, col+getpminfo(EPMINFO_LSLENGTH)-1, LOCATE_CIRCLE_COLOR1, LOCATE_CIRCLE_COLOR2
 compile elseif EVERSION >= '5.60'
      circleit LOCATE_CIRCLE_STYLE, .line, .col, .col+getpminfo(EPMINFO_LSLENGTH)-1, LOCATE_CIRCLE_COLOR1, LOCATE_CIRCLE_COLOR2
 compile elseif EVERSION >= '5.51'
      circleit LOCATE_CIRCLE_STYLE, .line, .col, .col+getpminfo(EPMINFO_LSLENGTH)-1, HIGHLIGHT_COLOR
 compile else
      circleit LOCATE_CIRCLE_STYLE, .line, .col, .col+search_len-1, HIGHLIGHT_COLOR
;     refresh
 compile endif
   endif
compile endif

compile if EVERSION < 5
defproc init_operation_on_commandline
   universal comsfileid,oldline
   if command_state() then
      activatefile comsfileid
      oldline=.line
      getcommand line,col,scrollpos
      insertline line,.last+1
      .cursorx=col-scrollpos+1
      .col=col
      bottom
   endif
compile endif

; Returns true if parameter given is a number.
; Leading and trailing spaces are ignored.
defproc isnum
   zzi=pos('-',arg(1))           -- Optional minus sign?
   if zzi then                   -- If there is one,
      parse arg zz1 '-' zz zz2   --   zz1 <- before it, zz <- number, zz2 <- after
   else
      parse arg zz zz1 zz2       --   zz <- number; zz1, zz2 <- after it
   endif
   zz=strip(zz)                  -- Delete leading & trailing spaces.
   if zz1||zz2 <> '' or          -- If there were more tokens on the line
      zz==''                     -- or if the result is null
   then return 0 endif           -- then not a number.
compile if EVERSION >= 4         -- OS/2 version - real numbers
   if pos(DECIMAL,zz) <> lastpos(DECIMAL,zz) then return 0 endif
                                 -- Max. of one decimal point.
   return not verify(zz,'0123456789'DECIMAL)
compile else                        -- DOS version - integers only
   return not verify(zz,'0123456789')
compile endif

defproc isoption(var cmdline,optionletter)
   i=pos(argsep||upcase(optionletter),upcase(cmdline))
   if i then
compile if EPM
      cmdline=delstr(cmdline,i,2)
compile else
      cmdline=substr(cmdline,1,i-1)||substr(cmdline,i+2)
compile endif
      return 1
   endif

defproc joinlines()
   if .line<.last and .line then
compile if EPM           -- Can't use REPLACELINE because it wipes out attributes.
      oldcol = .col
      down                   -- ensure one space at start of second line
      call pfirst_nonblank()
      col2 = .col
      .col = 1
      getsearch savesearch
      if col2 >= 2 then       -- Shift line left if >2, or replace possible leading tab w/ space if ==2.
;           LAM:  Following line is wrong now that pfirst_nonblank() also skips tabs.
;        'xcom c/'copies(' ',col2-2)'//'  -- Change first n-1 blanks to null
         'xcom c/'leftstr(textline(.line), col2-1)'/ /'  -- Change leading blanks/tabs to a single space
      elseif col2=1 then     -- Shift line right
;        'xcom c/^/ /g'         -- insert a space at beginning of line
         i=insert_state()
         if not i then insert_toggle endif
         keyin ' '
         if not i then insert_toggle endif
      endif
      setsearch savesearch
      up                     -- ensure no spaces at end of first line
      .col = length(strip(textline(.line),'T')) + 1
      erase_end_line
      .col = oldcol
compile else           -- E3 and EOS2 can still use the old, simple way.
      /* remove all but one trailing space of current line */
      getline line
      replaceline strip(line,'T')' '
      /* remove all leading spaces of next line */
      getline line,.line+1
      replaceline strip(line),.line+1
compile endif
      join
   endif

compile if EVERSION < 5
defproc leave_last_command
   if (not arg() or arg(2)) and arg(1) then
      cursor_command
      up
      for i = 1 to arg(1)-1
         right
      endfor
   endif
compile endif

compile if EVERSION < '5.17'  -- Provide leftstr() macro for easier back-porting of EPM macros
defproc leftstr(argstring, len)
   return substr(argstring, 1, len, substr(arg(3),1,1))
compile endif

compile if WANT_LAN_SUPPORT
defproc lock
   file=.filename\0
 compile if EPM32
   newhandle='????'
   actiontaken=atol(1)   -- File exists
   result = dynalink32('DOSCALLS',
                      '#273',                     /* dos32open          */
                      address(file)         ||
                      address(newhandle)    ||
                      address(actiontaken)  ||
                      atol(0)    ||       -- file size
                      atol(0)    ||       -- file attribute
                      atol(17)   ||       -- open flag; open if exists, else create
                      atol(146)  ||       -- openmode; deny Read/Write
                      atol(0),2)
 compile else
   newhandle='??'
   actiontaken=atoi(1)   -- File exists
   result = dynalink('DOSCALLS',
                     '#70',                     /* dosopen          */
                     address(file)        ||
                     address(newhandle)   ||
                     address(actiontaken) ||
                     atol(0)              || -- file size
                     atoi(0)              || -- file attribute
                     atoi(17)             || -- open flag; open if exists, else create
                     atoi(146)            || -- openmode; deny Read/Write
                     atol(0))
 compile endif
   if result then
;     'quit'  /* quit since the file could not be locked */
      messageNwait('DOSOPEN' ERROR__MSG result NOT_LOCKED__MSG)
      return result
   endif
 compile if EPM32
   if newhandle = \0\0\0\0 then  -- Handle of 0 - bad news
      newhandle2=\255\255\255\255
      result = dynalink32('DOSCALLS',
                         '#260',                     /* Dos32DupHandle     */
                         newhandle ||
                         address( newhandle2 ), 2)
      call dynalink32('DOSCALLS',    -- Free the original handle
                     '#257',                    -- dos32close
                     newhandle, 2)
      if result then
         messageNwait('DosDupHandle' ERROR__MSG result NOT_LOCKED__MSG)
         return result
      endif
      newhandle = newhandle2
   endif
   .lockhandle=ltoa(newhandle,10)
 compile else
   if newhandle = \0\0 then  -- Handle of 0 - bad news
      newhandle2=atoi(65535)
      result = dynalink('DOSCALLS',
                        '#61',                     /* DosDupHandle     */
                        newhandle ||
                        address( newhandle2 ))
      call dynalink('DOSCALLS',    -- Free the original handle
                    '#59',                    -- dosclose
                    newhandle)
      if result then
         messageNwait('DosDupHandle' ERROR__MSG result NOT_LOCKED__MSG)
         return result
      endif
      newhandle = newhandle2
   endif
   .lockhandle=itoa(newhandle,10)
 compile endif
compile endif

defproc max(a,b)  -- Support as many arguments as E3 will allow.
   maximum=a
   do i=2 to arg()
      if maximum<arg(i) then maximum=arg(i); endif
   end
   return maximum

compile if E3
definit  /* Keep this definit close to the proc it serves. */
   universal lines_entered
   lines_entered=0

defproc maybe_autosave    -- For E3 users, this routine increments the autosave
   universal autosave,lines_entered  -- counter, and does an autosave if necessary.
   if autosave then
      lines_entered = lines_entered +1
      if lines_entered >= autosave then
         'xcom save' MakeTempName()  -- Don't worry about HPFS files in E3.
         if rc=-2  then  -- sayerror('File not found') -> Invalid filename
            'xcom save' MakeTempName('BAD-NAME')
         endif
         .modify=1                  /* Reraise the modify flag. */
         lines_entered =0
      endif
   endif
compile endif


compile if BACKUP_PATH <> ''
;  Procedure to pick a filename for backup purposes, like STDPROCS.E$.
defproc MakeBakName
   name = arg(1)
   if name = '' then   /* if no arg given, default to current filename */
      name = .filename
   endif
   -- Change name as little as possible, but enough to identify it as
   -- a noncritical file.  Replace the last character with '$'.
   ext = filetype(name)
   if length(ext)=3 then
      ext = substr(ext,1,2)'$'
   else
      ext = ext'$'
   endif
   -- We still use MakeTempName() for its handling of host names.
   bakname = MakeTempName(name)
   i=lastpos('\',bakname)       -- but with a different directory
   if i then
      bakname = substr(bakname,i+1)
   endif
   parse value bakname with fname'.'.
 compile if BACKUP_PATH = '='
   bakname = fname'.'ext
   i=lastpos('\',name)       -- Use original file's directory
   if i then
      bakname = substr(name,1,i) || bakname
   endif
 compile else
   bakname = BACKUP_PATH || fname'.'ext
 compile endif
   return bakname
compile endif


;  Procedure to pick a temporary filename like ORIGNAME.$$1.
;  First argument is the filename, 2nd is the fileid.  Both are optional,
;  default to the current filename and fileid if absent.
;  Revised by BTTUCKER to catch all cases and work with E3EMUL.
defproc MakeTempName
   universal vAUTOSAVE_PATH
   TempName  = arg(1)
   extension = arg(2)
   if TempName = '' then   /* if no arg given, default to current filename */
      TempName = .filename
   endif
   if TempName = '' then
      TempName = '$'       /* new file? o.k. then $  */
   else /* We want only PC file name, VM filename, or MVS firstname          */
        /* These next statements will strip everything else off...           */
     p = lastpos('\',TempName)                      /* PC filename with path */
     if p then TempName=substr(TempName,p+1) endif
     p = pos('.',TempName)                          /* PC or MVS filename    */
     if p then TempName=substr(TempName,1,p-1) endif
     p = pos(' ',TempName)                          /* VM filename (or HPFS) */
     if p then TempName=substr(TempName,1,p-1) endif
     p = pos(':',TempName)                          /* VM or MVS filename    */
     if p then TempName=substr(TempName,p+1) endif
     p = pos("'",TempName)                          /* MVS filename          */
     if p then TempName=substr(TempName,p+1) endif
     if length(tempname)>8 then tempname=substr(tempname,1,8); endif  /* HPFS names */
   endif

   -- TempName might still be blank, as for '.Unnamed file'.
   if TempName='' then TempName='$'; endif

   TempName = vAUTOSAVE_PATH || TempName
   if extension='' then            /* default is current fileid              */
      getfileid extension
   endif
compile if EVERSION < 5
   extension = '$$' || extension
compile else
   /* In EPM we can have the same filename in multiple edit windows without
    * knowing it, because different edit windows are actually separate
    * instances of the editor.  So try to make the tempname unique by
    * combining the window handle with the fileid.  Combine two middle
    * digits of the window handle with the last digit of the fileid.
    */
   extension = substr(getpminfo(EPMINFO_EDITCLIENT),2,2) || extension
compile endif
   if length(extension)>3 then     /* could be >one digit, or something else */
      extension=substr(extension,2,3)
   endif
   return TempName'.'extension

defproc message
   getfileid fileid
   sayerror arg(1)
   activatefile fileid

; Print message and wait for a key press.
; Preserve active file and activate ring.
; Note:  There is no need to use "call" to invoke this procedure,  since it
; returns the null string.  Execution of a null string does nothing
defproc messageNwait
   getfileid zzfileid
compile if EPM
   display -4                    -- Force a messagebox popup from the SAYERROR
 compile if EVERSION >= '5.60b'
   display 32                    -- Force a messagebox popup from the SAYERROR
 compile endif
compile endif
   sayerror arg(1)
compile if EVERSION < 5
   call getkey()
compile else
 compile if EVERSION >= '5.60b'
   display -32
 compile endif
   display 4
compile endif
   activatefile zzfileid

compile if EVERSION < 5
; Mgetkey() acts the same as a call to getkey(), but first checks
; whether we're in mid-execution of a key-string (Ctrl-R/Ctrl-T).
; If so it gets the next key from the string.  Call this in place of
; getkey() if you want the user to be able to record the response.
; Don't call this for unusual inputs, such as messageNwait after errors.

; Optional argument is prompt string, will be displayed on status line.

defproc mgetkey()
   universal Kstring,inKstring          /* See c_r in STDKEYS.E. */
   prompt=arg(1)
   if prompt<>'' and inKstring<=0 then
      sayerror prompt
   endif
   if inKstring=0 then     /* If not recording or replaying, normal input. */
      k=getkey()
   elseif inKstring=-1 then /* If recording, stash key in string.          */
      k=getkey()
      Kstring=Kstring||k   /* Trust that it doesn't get longer than 255.   */
   else           /* inKstring>0 ==> replaying; get next key from Kstring. */
      k=substr(Kstring,inKstring,1)
      ksize=1
      if k==substr(esc,1,1) then       /* extended key ? */
         k=substr(Kstring,inKstring,2) /* Yes, 2 bytes for extended key.   */
         ksize=2
      endif
      inKstring=inKstring+ksize        /* bump index AFTER execution */
   endif
   if prompt<>'' and inKstring<=0 then
      sayerror 0
   endif
   return k
compile endif

defproc min(a,b)  -- Support as many arguments as E3 will allow.
   minimum=a
   do i=2 to arg()
      if minimum>arg(i) then minimum=arg(i); endif
   end
   return minimum

compile if EVERSION < 5
defproc move_results_to_commandline
   universal oldline
   if command_state() then
      getline line
      deleteline
      setcommand line,.col,.col-.cursorx+1
      oldline
   endif
compile endif

; The following two routines (from Larry Margolis) let the
; user decide what action should be taken when the Enter and Ctrl-Enter
; keys are pressed.  The possible values for the action constants are
; defined in STDCNF.

compile if C_ENTER_ACTION & not ENHANCED_ENTER_KEYS  -- If null, don't define - user will supply.
defproc my_c_enter
   compile if C_ENTER_ACTION = 'ADDATEND' | C_ENTER_ACTION = 'DEPENDS+'
   if .line = .last then         -- If we're on the last line, then add a line.
compile if EVERSION < '4.12'
      call maybe_autosave()
compile endif
      call einsert_line()
      down                       -- This keeps the === Bottom === line visible.
   else
   compile endif

   compile if C_ENTER_ACTION = 'DEPENDS' | C_ENTER_ACTION = 'DEPENDS+'
   if insert_state() then        -- DEPENDS means if insertstate() then ...
   compile endif

   compile if C_ENTER_ACTION = 'NEXTLINE' | C_ENTER_ACTION = 'DEPENDS' |
              C_ENTER_ACTION = 'ADDATEND' | C_ENTER_ACTION = 'DEPENDS+'
   down                          -- go to next line
   begin_line
   compile endif

   compile if C_ENTER_ACTION = 'DEPENDS' | C_ENTER_ACTION = 'DEPENDS+'
   else                          -- otherwise ...
   compile endif

   compile if C_ENTER_ACTION = 'ADDLINE' | C_ENTER_ACTION = 'DEPENDS' | C_ENTER_ACTION = 'DEPENDS+'
compile if EVERSION < '4.12'
   call maybe_autosave()
compile endif
   call einsert_line()           -- insert a line
   compile endif

   compile if C_ENTER_ACTION = 'DEPENDS' | C_ENTER_ACTION='ADDATEND' | C_ENTER_ACTION = 'DEPENDS+'
   endif
   compile endif

   compile if C_ENTER_ACTION = 'DEPENDS+'
   endif
   compile endif

   compile if C_ENTER_ACTION = 'STREAM'
   call splitlines()
   call pfirst_nonblank()
   down
    compile if EPM
   refresh
    compile endif
   compile endif
compile endif

compile if not ENHANCED_ENTER_KEYS & ENTER_ACTION   -- If null, don't define - user will supply.
defproc my_enter
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
 compile if EVERSION < 5
   if command_state() then
      execute
 compile else
   if 0 then   -- EPM has no command_state()
 compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   elseif stream_mode then
 compile elseif WANT_STREAM_MODE = 1
   elseif 1 then
 compile endif
 compile if WANT_STREAM_MODE
      if .line then
  compile if WANT_STREAM_INDENTED
         call splitlines()
         call pfirst_nonblank()
         down
  compile else
         split
         .col=1
         down
  compile endif -- WANT_STREAM_INDENTED
      else
         insert
         .col=1
      endif
      return
 compile endif
 compile if WANT_STREAM_MODE <> 1
 compile if ENTER_ACTION = 'ADDATEND' | ENTER_ACTION = 'DEPENDS+'
   elseif .line = .last then     -- If we're on the last line, then add a line.
compile if EVERSION <= '4.12'
      call maybe_autosave()
compile endif
      call einsert_line()
      down                       -- This keeps the === Bottom === line visible.
 compile endif
   else
      compile if ENTER_ACTION = 'DEPENDS' | ENTER_ACTION = 'DEPENDS+'
      if insert_state() then     -- DEPENDS means if insertstate() then ...
      compile endif

      compile if ENTER_ACTION = 'ADDLINE' | ENTER_ACTION = 'DEPENDS' | ENTER_ACTION = 'DEPENDS+'
compile if EVERSION < '4.12'
      call maybe_autosave()
compile endif
      call einsert_line()        -- insert a line
      compile endif

      compile if ENTER_ACTION = 'DEPENDS' | ENTER_ACTION = 'DEPENDS+'
      else                       -- otherwise ...
      compile endif

      compile if ENTER_ACTION = 'NEXTLINE' | ENTER_ACTION = 'DEPENDS' |
                 ENTER_ACTION = 'ADDATEND' | ENTER_ACTION = 'DEPENDS+'
      down                       -- go to next line
      begin_line
      compile endif

      compile if ENTER_ACTION = 'DEPENDS' | ENTER_ACTION = 'DEPENDS+'
      endif
      compile endif

      compile if ENTER_ACTION = 'STREAM'
      if .line then
         if .col<=length(textline(.line)) then
            split
            .col=1
         else
            split
            call pfirst_nonblank()
         endif
         down
      else
         insert
         .col=1
      endif
       compile if EPM
      refresh
       compile endif
      compile endif
 compile endif  -- WANT_STREAM_MODE <> 1
   endif
compile endif


;  A common routine to parse an argument string containing a mix of
;  options and DOS file specs.  The DOS file specs can contain an "=" for the
;  path or the fileid, which will be replaced by the corresponding part of the
;  previous file (initially, the current filename).
defproc parse_file_n_opts(argstr)
   prev_filename = .filename
   output = ''
   do while argstr<>''
compile if EVERSION >= '5.50'
      parse value argstr with filename rest
      if leftstr(filename,1)='"' then
         parse value argstr with '"' filename '"' argstr
         filename = '"'filename'"'
      else
         argstr = rest
      endif
compile else
      parse value argstr with filename argstr
compile endif
      if substr(filename,1,1)<>'/' then
         call parse_filename(filename,prev_filename)
         prev_filename = filename
      endif
      output = output filename
   end
   return substr(output,2)

;  A common routine to parse a DOS file name.  Optional second argument
;  gives source for = when used for path or fileid.  RC is 0 if successful, or
;  position of "=" in first arg if no second arg given but was needed.
defproc parse_filename(var filename)
compile if EVERSION >= '5.50'
   if leftstr(filename,1)='"' & rightstr(filename,1)='"' then
      return 0
   endif
compile endif
   sourcefile = strip(arg(2))
   if sourcefile='' | sourcefile=UNNAMED_FILE_NAME then return pos('=',filename) endif

   if filename='=' then filename=sourcefile; return 0; endif

   lastsep = lastpos('\',sourcefile)
   if not lastsep & substr(sourcefile,2,1) = ':' then lastsep=2; endif

   /* E doesn't handle the = prefix if it's on the first file given on      */
   /* the E command line.  This replaces = with path of current file.  LAM  */
   if substr(filename,1,1) = '=' & lastsep then
      if substr(filename,2,1) = '.' & not pos('\', filename) then filename='='filename endif
      filename=substr(sourcefile,1,lastsep) || substr(filename,2)
   endif

   /* Also accept '=' after the pathspec, like 'c:\bat\=', */
   /* or c:\bat\=.bat or c:\doc\new.=                      */
   p = pos('=',filename)
   if p > 1 then
      sourcefileid=substr(sourcefile,max(lastsep+1,1))
      parse value sourcefileid with sourcefilename '.' sourcefileext
      lastsep2 = lastpos('\',filename)
      if not lastsep2 & substr(filename,2,1) = ':' then lastsep2=2; endif
      dot1=pos('.',filename,max(lastsep2,1))
      firstpart=substr(filename,1,p-1)
      if dot1 then
         if dot1<p then  -- filename.=
            filename= firstpart || sourcefileext
         else            -- =.ext
            filename= firstpart || sourcefilename || substr(filename,dot1)
         endif
      else            -- d:\path\         ||        filename.ext
         filename= firstpart || sourcefileid
      endif -- dot1
   endif -- p > 1
   return 0

;  This proc is called by DEFC EDIT.
;  Does *not* assume all options are specified before filenames.
defproc parse_leading_options(var rest,var options)
   options=''
   loop
      parse value rest with wrd more
      if substr(wrd,1,1)='/' then
         options = options wrd
         rest = more
      else
         leave
      endif
   endloop


; PBEGIN_MARK: this procedure moves the cursor to the first character of the
; mark area.  If the mark area is not in the active file, the marked file is
; activated.
defproc pbegin_mark
   call checkmark()
   getmark  firstline,lastline,firstcol,lastcol,fileid
   activatefile fileid
compile if EVERSION < 5
   cursor_data
compile endif
   firstline
   if marktype()<>'LINE' then
      .col=firstcol
   endif


; PBEGIN_WORD: moves the cursor to the beginning of the word if the cursor is on
; this word.  If it's not on a word, it's moved to the beginning of the first
; word on the left.  If there is no word on the left it's moved to the beginning
; of the word on the right.  If the line is empty the cursor doesn't move.
defproc pbegin_word
   getline line,.line
   if  substr(line,.col,1)=' ' then
      p=verify(line,' ')       /* 1st case: the cursor on a space */
      if p>=.col then
         .col=p
      else
         if p then
            q=p
            loop
               p=verify(line,' ','M',p)
               if not p or p>.col then leave endif
               p=verify(line,' ','',p)
               if not p or p>.col then leave endif
               q=p
            endloop
            .col=q
         endif
      endif
   else
      if .col<>1 then          /* 2nd case: not on a space */
         .col=lastpos(' ',line,.col)+1
      endif
   endif


; PBLOCK_REFLOW: reflow the text in the marked area.  Then the destination block
; area must be selected and a second call to this procedure reflow the source
; block in the destination block.  The source block is fill with spaces.
;   option=0 saves the marked block in temp file
;   option=1 reflow temp file text and copies it to marked area
defproc pblock_reflow(option,var spc,var tempofid)
   call checkmark()
   if not option then
      usedmk=marktype()
      getmark  firstline1,lastline1,firstcol1,lastcol1,fileid1
      /* move the source mark to a temporary file */
compile if EPM
      'xcom e /c .tempo'
      if rc<>sayerror('New file') then
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return rc
      endif
      .visible = 0                                  -- Make hidden
compile else
      'xcom e 'argsep'q 'argsep'n 'argsep'h .tempo'
      if rc & rc<>sayerror('New file') then
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG
         return rc
      endif
      sayerror 1
compile endif
      getfileid tempofid
      activatefile tempofid
      call pcopy_mark()
      activatefile fileid1
compile if EVERSION < 5
      cursor_data
compile endif
      call pset_mark(firstline1,lastline1,firstcol1,lastcol1,usedmk,fileid1)
      if usedmk='LINE' then
         begin_line
      endif
      spc=usedmk firstline1 lastline1 firstcol1 lastcol1 fileid1
      return 0
   else
      getfileid startfid
      if marktype() <> 'BLOCK' then
         sayerror NEED_BLOCK_MARK__MSG
         /* release tempo */
         rc=0
         activatefile tempofid
         if rc then return rc; endif
         .modify=0
         'xcom q'
         activatefile startfid
         return 1
      endif
compile if EPM  -- Make sure temp file is good before deleting current file's text.
      rc=0
      activatefile tempofid
      if rc then return rc; endif
      activatefile startfid
compile endif
      parse value spc with usedmk firstline1 lastline1 firstcol1 lastcol1 fileid1
      getmark  firstline2,lastline2,firstcol2,lastcol2,fileid2
      /* fill source with space */
      if usedmk='LINE' then
         for i = firstline1 to lastline1
            replaceline '',i,fileid2
         endfor
      else
         call pset_mark(firstline1,lastline1,firstcol1,lastcol1,usedmk,fileid1)
         call pfill_mark(' ')
      endif
      call pset_mark(firstline2,lastline2,firstcol2,lastcol2,'BLOCK',fileid2)
      delete_mark
      /* let's reflow in the hidden file */
      activatefile tempofid
      width = lastcol2+1-firstcol2
      height = lastline2+1-firstline2
compile if EVERSION < '4.12'
      savemargins= pmargins()
compile endif
      'xcom ma 1 'width
      unmark; mark_line; bottom; mark_line
      reflow
compile if EVERSION < '4.12'
      'xcom ma 'savemargins
compile endif
      nbl = .last
      /* go back to the destination */
      activatefile fileid2
      if nbl > height then
         fix = nbl-height
         getline line,lastline2
         for i = 1 to fix
            insertline line,lastline2+1
         endfor
      elseif nbl < height then
         fix=0
         for i = nbl+1 to height
            insertline '',tempofid.last+1,tempofid
         endfor
         nbl=height
      else
         fix=0
      endif
      call pset_mark(1,nbl,1,width,'BLOCK',tempofid)
      firstline2; .col=firstcol2; copy_mark; unmark
      call pset_mark(firstline2,lastline2+fix,firstcol2,lastcol2,'BLOCK',fileid2)
      /* release tempo */
      activatefile tempofid
      .modify=0
      'xcom q'
      activatefile fileid2
      sayerror 1
    endif


; PCENTER_MARK: center the strings between the block marks
defproc pcenter_mark
   if  marktype() = 'BLOCK' then
      getmark  firstline,lastline,firstcol,lastcol,fileid
   elseif marktype() = 'LINE' then
      getmark  firstline,lastline,firstcol,lastcol,fileid
      parse value pmargins() with  firstcol lastcol .
   elseif marktype() = '' then
      getfileid fileid
      parse value pmargins() with  firstcol lastcol .
      firstline=.line;lastline=.line
   else
      sayerror CHAR_INVALID__MSG
      stop
   endif
   sz = lastcol+1-firstcol
   for i=firstline to lastline
      getline line,i,fileid
      inblock=strip(substr(line,firstcol,sz))
      if inblock='' then iterate endif
compile if EPM
      replaceline strip(overlay(center(inblock, sz), line, firstcol),'T'), i, fileid
compile else
      replaceline substr(line,1,firstcol-1) ||
         substr(substr('',1,(sz-length(inblock))%2)||inblock,1,sz) ||
         substr(line,lastcol+1) ,i,fileid
compile endif
   endfor


compile if EVERSION < 5
;  A built-in function command_state() is now provided for better
;  efficiency.  This defproc is kept only for compatibility with older macros.
;  Please use command_state() instead.
defproc pcommand_state
   return command_state()


; PCOMMON_TAB_MARGIN: subroutine common to ptabs and pmargins

defproc pcommon_tab_margin(TabOrMargins)
;    the tricky stuff:  execute ma (or tabs) and get the result from coms.e file
   getcommand oldcmd,oldcol,oldscroll    -- Save old cmdline status
   TabOrMargins                          -- Execute the command
   getcommand setting                    -- Get current setting from cmdline
   setcommand oldcmd,oldcol,oldscroll    -- Restore old cmdline status
   parse value setting with . val        -- Get the stuff we want
   return val
compile endif

compile if 0    -- The following two routines are unused; why waste space??  LAM
; PDISPLAY_MARGINS: put the margins mark on the current line

defproc pdisplay_margins()
   i=insert_state()
   if i then insert_toggle endif
   call psave_pos(save_pos)
   insert
   parse value pmargins() with lm rm pm .
   .col=lm;keyin'L';.col=pm;keyin'P';.col=rm;keyin'R'
   begin_line
   call prestore_pos(save_pos)
   if i then insert_toggle endif
   return 0


; PDISPLAY_TABS: put the tab stops on the current line

defproc pdisplay_tabs()
   i=insert_state()
   if i then insert_toggle endif
   call psave_pos(save_pos)
   insert
   tabstops = ptabs()
   do forever
      parse value tabstops with tabx tabstops
      if tabx = '' then leave endif
      .col=tabx
      keyin'T'
   end
   begin_line
   call prestore_pos(save_pos)
   if i then insert_toggle endif
   return 0
compile endif

; PEND_MARK: moves the cursor to the end of the marked area
defproc pend_mark
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
   call checkmark()
   getmark  firstline,lastline,firstcol,lastcol,fileid
   activatefile fileid
compile if EVERSION < 5
   cursor_data
compile endif
   if marktype()<>'LINE' then
      .col=lastcol
compile if WANT_DBCS_SUPPORT
      if ondbcs then
         if .col > lastcol then -- Must have been in the middle of a DBC.
             .col = lastcol - 1
         endif
      endif
compile endif
   endif
   lastline

; PEND_WORD: moves the cursor to the end of the word if the cursor is on this
; word.  If it's not on a word, it's moved to the end of the first word on the
; right.  If there is no word on the right it's moved to the end of the word on
; the left.  If the line is empty the cursor doesn't move.
defproc pend_word
   getline line,.line
   if  substr(line,.col,1)=' '  then
      if substr(line,.col)=' ' then
         if  line<> ' ' then
            for i=.col to 2 by -1
               if substr(line,i-1,1)<>' ' then leave endif
            endfor
           .col=i-1
         endif
      else
         p=verify(line,' ','',.col)
         p=verify(line' ',' ','M',p)
         .col=p-1
      endif
   else
      if .col<>MAXCOL then
         i=pos(' ',line,.col)
         if i then
            .col=i-1
         else
            .col=length(line)
         endif
      endif
   endif


defproc pfile_exists /* Check if file already exists in ring */
   if substr(arg(1),2,1)=':'  then
      /* parse off drive specifier and try again */
      getfileid zzfileid,substr(arg(1),3)
   else
      getfileid zzfileid,arg(1)
   endif
   return zzfileid<>''

defproc pfind_blank_line
   -- Find first blank line after the current one.  Make that the new current
   -- line.  If no such line is found before the end of file, don't change the
   -- current line.
   for i = .line+1 to .last
      getline line,i
      -- Ver 3.11:  Modified to respect GML tags:  stop at first blank line
      -- or first line with a period or a colon (".:") in column 1.
      if line='' or not verify(substr(line,1,1), ".:" ) then
         i
         leave
      endif
   endfor

defproc pfirst_nonblank
   /* different from PE */
   if not .line then .col=1
   else
      getline line
      .col=max(1,verify(line,' '\t))
   endif


; PLOWERCASE: force to lowercase the marked area

defproc plowercase
   call checkmark()
   /* invoke pinit_extract, pextract_string, pput_string_back to do the job */
   call psave_pos(save_pos)
   call pinit_extract()
   do forever
      code = pextract_string(string)
      if code = 1 then leave; endif
      if code = 0 then
         string = lowcase(string)
         call pput_string_back(string)
      endif
   end
   call prestore_pos(save_pos)


; PMARGINS: return the current margins setting. (Uses pcommon_tab_margin)

defproc pmargins
compile if EVERSION < 5
   return pcommon_tab_margin('ma')
compile else
   return .margins
compile endif


; PMARK: mark at the cursor position (mark type received as argument).  Used by
; pset_mark
defproc pmark(mt)
   if mt= 'LINE' then
      mark_line
   elseif mt = 'CHAR' then
      mark_char
   else
      mark_block
   endif


; PMARK_WORD: mark the word pointed at by the cursor.  If the cursor is on a
; space, the word at the right is marked.  If there is no word on the right, the
; word on the left is marked.
defproc pmark_word
   if marktype()<>'' then
      sayerror -279  -- 'Text already marked'
      stop
   endif
   call pend_word()
compile if WORD_MARK_TYPE = 'CHAR'
   mark_char
compile else
   mark_block
compile endif
   call pbegin_word()
compile if WORD_MARK_TYPE = 'CHAR'
   mark_char
compile else
   mark_block
compile endif
compile if EVERSION > 5
  'Copy2SharBuff'       /* Copy mark to shared text buffer */
compile endif


; PRESTORE_MARK: restore the current marks (cannot be used as a stack) See also
; psave_mark
defproc prestore_mark(savemark)
   unmark
   parse value savemark with savefirstline savelastline savefirstcol savelastcol savemkfileid savemt
   if savemt<>'' then
      call pset_mark(savefirstline,savelastline,savefirstcol,savelastcol,savemt,savemkfileid)
   endif


; PRESTORE_POS: restore the cursor position (cannot be used as a stack) See
; also psave_pos()
defproc prestore_pos(save_pos)
   parse value save_pos with svline svcol svcx svcy
   .cursory = svcy                          -- set .cursory
   min(svline, .last)                       -- set .line
   .col = MAXCOL; .col = svcol - svcx + 1   -- set left edge of window
   .col = svcol                             -- set .col


;  Printer_ready( printer_number ) tests whether printer is ready.
;
;  Enter with printer_number = 1 for the first printer (LPT1), 2 for LPT2.
;  No argument at all defaults to LPT1.
;
;  Returns 1 (true)  for printer attached and ready.
;  Returns 0 (false) for printer not attached or not ready.
;
;  Note:  Assumes the standard BIOS responses for an IBM PC.
;  The BIOS responds with AH=90 hex for printer ready.
;  Might not work on clones and other strange machines.
;
;  If we're on OS/2 we don't check because the spooler protects us from
;  a hang if the printer's off-line.  We always return "ready" on OS/2.
;
defproc printer_ready
compile if EVERSION >= 4
   return 1
compile else
   if arg(1)='' then
      printer_number=1
   elseif not isnum(arg(1)) then
      sayerror 'Printer_ready:  'INVALID_NUMBER__MSG
      return 0
   else
      printer_number = arg(1)
   endif
   /* Call BIOS interrupt 17 hex with AH=2, printer status query. */
   parse value int86x(23,512 0 0 printer_number-1,'') with printer_status .
;    IBM PC family returns '90' for printer ready (not busy + selected).
;    Some clones return 'D0' (not busy + acknowledge + selected).
;    Here, we'll accept either value.
;                    hex2dec('9000'):              hex2dec('D000'):
   return (printer_status == -28672) or (printer_status == -12288)
compile endif


; PSAVE_MARK: save the current marks (cannot be used as a stack) See also
; prestore_pos()
defproc psave_mark(var savemark)
   savemt=marktype()
   if savemt then
      getmark  savefirstline,savelastline,savefirstcol,savelastcol,savemkfileid
      unmark
      savemark=savefirstline savelastline savefirstcol savelastcol savemkfileid savemt
   else
      savemark=''
   endif


; PSAVE_POS: save the cursor position (cannot be used as a stack) See also
; prestore_pos()
defproc psave_pos(var save_pos)
   save_pos=.line .col .cursorx .cursory


defproc pset_mark(firstline,lastline,firstcol,lastcol,mt,fileid)
compile if EVERSION >= '5.50'
   setmark firstline,lastline,firstcol,lastcol,wordpos(mt,'LINE CHAR BLOCK CHARG BLOCKG')-1,fileid
compile else
   getfileid actfileid    /* preserve current active fileid */
   rc = 0
   activatefile fileid
 compile if not E3
   if rc=sayerror('Invalid fileid') then stop; endif
 compile endif
   call psave_pos(save_pos)
   unmark
   if lastcol then
      .col=lastcol; lastline
   else
      lastline-1; .col=MAXCOL
   endif
   call  pmark(mt)
   .col=firstcol; firstline
   call pmark(mt)
   call prestore_pos(save_pos)
   activatefile actfileid         /* restore the initial active file */
compile endif

; PTABS: return the current tabs setting. (Uses pcommon_tab_margin)

defproc ptabs
compile if EVERSION < 5
   return pcommon_tab_margin('tabs')
compile else
   return .tabs
compile endif


; PUPPERCASE: force to uppercase the marked area

defproc puppercase
   call checkmark()
   /* invoke pinit_extract, pextract_string, pput_string_back to do the job */
   call psave_pos(save_pos)
   call pinit_extract()
   do forever
      code = pextract_string(string)
      if code = 1 then leave endif
      if code = 0 then
         string = upcase(string)
         call pput_string_back(string)
      endif
   end
   call prestore_pos(save_pos)

;defproc remove_trailing_spaces
;   /* This is no longer used by any file in standard E.  Use strip()  */
;   /* instead.  But left here for compatibility with older procs.     */
;   return strip(arg(1),'T')

compile if EPM
; In E3 and EOS2, we can use a_X to enter the value of any key.  In EPM,
; we can't, so the following routine is used by KEY and LOOPKEY to convert
; from an ASCII key name to the internal value.  It handles shift or alt +
; any letter, or a function key (optionally, with any shift prefix).  LAM
defproc resolve_key(k)
   kl=lowcase(k)
   suffix=\2                           -- For unshifted function keys
   if length(k)>=3 & pos(substr(k,2,1),'_-+') then
      if length(k)>3 then
         if substr(kl,3,1)='f' then     -- Shifted function key
            suffix=substr(\10\34\18,pos(leftstr(kl,1),'sac'),1)  -- Set suffix,
            kl=substr(kl,3)             -- strip shift prefix, and more later...
         elseif wordpos(substr(kl, 3), 'left up right down') then
            suffix=substr(\10\34\18,pos(leftstr(kl,1),'sac'),1)  -- Set suffix,
            kl=substr(kl,3)             -- strip shift prefix, and more later...
         else                        -- Something we don't handle...
            sayerror 'Resolve_key:' sayerrortext(-328)
            rc = -328
         endif
      else                        -- alt+letter or ctrl+letter
         k=substr(kl,3,1) || substr(' ',pos(leftstr(kl,1),'ac'),1)
      endif
   endif
   if leftstr(kl,1)='f' & isnum(substr(kl,2)) then
      k=chr(substr(kl,2)+31) || suffix
   elseif wordpos(kl, 'left up right down') then
      k=chr(wordpos(kl, 'left up right down')+20) || suffix
   endif
   return k
compile endif

compile if EVERSION < 5
defproc restore_command_state(cstate)
   if command_state()<>cstate then
      command_toggle
   endif

defproc save_command_state(var cstate)
   cstate=command_state()
   cursor_data
   refresh            /* Force E to update the cursor position */
compile endif


compile if EVERSION < '5.17'  -- Provide rightstr() macro for easier back-porting of EPM macros
defproc rightstr(argstring, len)
   l = length(argstring)
   if l=len then
      return argstring
   endif
   if l>len then
      return substr(argstring, l-len+1)
   endif
   return substr('', 1, len-l, substr(arg(3),1,1)) || argstring
compile endif


-- 4.10:  Saving with tab compression is built in now.  No need for
-- the make-do proc savefilewithtabs().  DOS version still needs it for
-- people editing MAKE files, but we make it optional via WANT_TABS.

compile if E3 & WANT_TABS
; Note:  This does not tabify the entire file; it just replaces 8 blanks
; in the first column with a tab character.
defproc savefilewithtabs(filename)
   options=arg(2)
   call psave_pos(save_pos)
   getfileid fileid
   unmark;bottom;markline;top;markline
   call prestore_pos(save_pos)
   'xcom e 'argsep'n .';deleteline
   if rc and rc<>-282 then  -- sayerror("new file")
      return rc
   endif
   rc=0
   copymark
   if rc then return rc endif
   unmark
   top;.col=1;markblock;bottom;.col=8;markblock
   .col=1;top
   'c/        /'\t'/m*'     /* replace first column 8 spaces with tab */
   sayerror 1  /* Turn off pending messages */
   unmark
   savestatus=savefile(filename,options)
   .modify=0
   'xcom q'
   if savestatus then return savestatus endif
   activatefile fileid
   if filename=.filename then
      .modify=0
   endif
   return 0
compile endif

define
compile if EVERSION < '5.21'
   MSGC = '.messagecolor'
compile elseif EVERSION < '5.50'
   MSGC = 'vMESSAGECOLOR'
compile else            -- GPI version
   MSGC = 'color'
compile endif

; Paste up a message in a box, using SAYAT's.  Useful for "Processing..." msgs.
defproc sayatbox
compile if EVERSION >= '5.21'
   universal vMESSAGECOLOR
compile endif
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif

compile if EVERSION >= '5.50'  -- GPI version; doesn't use background color in SAYATs.
   color = sayat_color()
compile endif
compile if WANT_DBCS_SUPPORT
   if ondbcs then
      middle = substr('',1,length(arg(1)),\x06)
      sayat '  '\x01\x06||middle||\x06\x02'  ',1,2, $MSGC
      sayat '  '\x05' 'arg(1)' '\x05'  ',2,2, $MSGC
      sayat '  '\x03\x06||middle\x06\x04'  ',3,2, $MSGC
   else
compile endif
      middle = substr('',1,length(arg(1)),'Í')
      sayat '  ÉÍ'middle'Í»  ',1,2, $MSGC
      sayat '  º 'arg(1)' º  ',2,2, $MSGC
      sayat '  ÈÍ'middle'Í¼  ',3,2, $MSGC
compile if WANT_DBCS_SUPPORT
   endif
compile endif

compile if EVERSION >= '5.50'
defproc sayat_color =          -- Pick a color for SAYAT that doesn't conflict w/ foreground or background color.
   universal vMESSAGECOLOR
   if vMESSAGECOLOR // 16 <> .textcolor // 16 & vMESSAGECOLOR // 16 <> .textcolor % 16 then
      return vMESSAGECOLOR       -- Preference is the message color.
   endif
   if vMESSAGECOLOR // 16 <> LIGHT_RED then
      return LIGHT_RED           -- Second choice is light red.
   endif
   if .textcolor // 16 <> LIGHT_BLUE & .textcolor % 16 <> LIGHT_BLUE then
      return LIGHT_BLUE          -- If that's used, then how about light blue
   endif
   return GREEN                  -- Final fallback is green.
compile endif

defproc splitlines()
   if .line then
      split
      oldcol=.col
      call pfirst_nonblank()
compile if EPM           -- Can't use REPLACELINE because it wipes out attributes.
      blanks = leftstr(textline(.line), .col - 1)
      down
      getsearch savesearch
      .col = 1
 compile if EPM32  -- Can use Extended GREP
      'xcom c/^[ \t]*/'blanks'/x'
 compile else      -- GREP would skip a blank line in the first case...
      if textline(.line) /== '' then
         'xcom c/^[ \t]*/'blanks'/g'
      else
         'xcom c/^/'blanks'/g'
      endif
 compile endif  -- EPM32
      setsearch savesearch
      up
compile else           -- E3 and EOS2 can still use the old, simple way.
      getline line,.line+1
      replaceline substr('',1,.col-1) ||    -- indent like previous line
         strip(line,'L'),                   -- (remove leading spaces)
         .line+1
compile endif
      .col=oldcol
   endif


; Note on a speed trick:  subdir_present is initialized to null at start-up.
; This causes defproc subdir(), the first time it's called, to execute a
; FINDFILE (by way of find_routine) to search the path for the subdir program.
; (See DEFC HELP for another example of findfile.)
; After that first search the exact path location of subdir is known; it's
; remembered in the universal variable subdir_present.  All future calls supply
; the exact location (as in "C:\UTIL\SUBDIR.COM") to avoid the path search.

compile if EPM32  -- Only runs on OS/2 2.0 or above, so no question as to what to use...
defproc subdir
   quietshell 'dir /b /s /a:-D' arg(1)

compile else
definit  /* Keep this definit close to the proc it serves. */
   universal subdir_present
   subdir_present=''

defproc subdir
   universal subdir_present
   if subdir_present='' then  -- First time; look for the program
 compile if E3
      subdir_present=find_routine('SUBDIR /Q')
      if subdir_present == -1 then      -- Not found
         if Dos_Version() >= 500 then   -- If DOS version is 5, can use DIR
            subdir_present='dir /b /s'  -- (SUBDIR preferable for leading wildcards)
         endif
      endif
 compile else
      if Dos_Version() >= 2000 then   -- If OS/2 2.0 or above, use DIR
         subdir_present='dir /b /s'   -- (OS/2 DIR supports leading wildcards)
      else
         subdir_present=find_routine('FILEFIND')
      endif
 compile endif
      if subdir_present == -1 then     -- Not found, try ATTRIB
         subdir_present=find_routine('ATTRIB /S')
      endif
   endif
   if subdir_present == -1 then
      sayerror CANT_FIND_PROG__MSG 'ATTRIB'
      stop
   endif
   quietshell subdir_present arg(1)
compile endif -- EPM32

compile if EVERSION >= 4
defproc swapwords(num)
   return substr(num,3,2) || substr(num,1,2)
compile endif


compile if E3 or (EPM & not (EVERSION >= '5.17'))
;  EOS2 & EPM have a TEXTLINE() function built in.  This is added here so that
;  E3 macro programmers can use TEXTLINE also, if they like.
defproc textline(linenum)
   getline line,linenum; return line
compile endif

-- Standard text reflow, moved from Alt+P definition in STDKEYS.E.
-- Only called from Alt+P if no mark exists; users wishing to call
-- this from their own code must save & restore the mark themselves
-- if that's desired.
defproc text_reflow
   if .line then
      getline line
      if line<>'' then  -- If currently on a blank line, don't reflow.
         oldcursory=.cursory;oldcursorx=.cursorx; oldline=.line;oldcol=.col;
         unmark;mark_line
         call pfind_blank_line()
         -- Ver 3.11:  slightly revised test works better with GML sensitivity.
         if .line<>oldline then
            up
         else
            bottom
         endif
         mark_line
         reflow

compile if REFLOW_LIKE_PE   /* position on next paragraph (like PE) */
         down                       /* Thanks to Doug Short. */
         for i=.line+1 to .last
            getline line,i
            if line<>'' then i; leave; endif
         endfor
compile else
         /* or like old E */
         getmark firstline,lastline
         firstline
         .cursory=oldcursory;.cursorx=oldcursorx; oldline;.col=oldcol
compile endif
         unmark
      endif
   endif

;  A truncate function to maintain compatibility of macros between this
;  version and the OS/2 version which will have floating point.  Two
;  functions in DOSUTIL.E need this.
;
;  If we're passed a floating point number with a decimal point in it,
;  like "4.0", drop the decimal part.
;  If we're passed an exponential-format number like "6E3", fatal error.
defproc trunc(num)
   if not verify('E',upcase(num)) then
      sayerror NO_FLOAT__MSG num
      stop
   endif
   parse value num with whole'.'.
   return whole

compile if WANT_LAN_SUPPORT
defproc unlock(fileid)
   if fileid.lockhandle = 0 then
      sayerror fileid.filename NOT_LOCKED__MSG
      return 1
   endif
 compile if EPM32
   result = dynalink32('DOSCALLS',    -- Free the original handle
                       '#257',                    -- dos32close
                       atol(fileid.lockhandle), 2)
 compile else
   result = dynalink('DOSCALLS',
                     '#59',                    /* dosclose */
                     atoi(fileid.lockhandle))
 compile endif
   if result then
      sayerror 'DOSCLOSE' ERROR_NUMBER__MSG result
   else
      fileid.lockhandle = 0
   endif
   return result
compile endif

