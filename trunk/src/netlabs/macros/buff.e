;
;  Test macros for the buffer() opcode.      Bryan Lewis 8/1/88.
;
;Changes 8/29 -- look for change marker '|'.
;* Can specify a buffer to be private, non-shared.  This allows a process
;  to create any number of buffers for internal use, without running into the
;  OS/2 limit of 30 shared buffers.
;* New format option FINAL_NULL to append a null at end of buffer, as needed
;  for clipboard format.

compile if not defined(SMALL)
 include 'stdconst.e'
 define INCLUDING_FILE = 'BUFF.E'
 tryinclude 'MYCNF.E'

 compile if not defined(SITE_CONFIG)
    const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
    tryinclude SITE_CONFIG
 compile endif

 compile if not defined(NLS_LANGUAGE)
   const NLS_LANGUAGE = 'ENGLISH'
 compile endif
 include NLS_LANGUAGE'.e'
compile endif

definit
   universal format, bufname, bufhndl
   format = 0     -- Initialize.  Zero will give standard CR-LF format.
   bufname = 'EBUF'
   bufhndl = 0    -- Always set bufhndl to zero if no buffer is active.
                  -- E will safely reject a zero bufhndl, but has no way of
                  -- knowing whether other arbitrary bufhndl's are valid.

define
compile if EVERSION < '5.21'
   MSGC = '.messagecolor'
compile else
   MSGC = 'vMESSAGECOLOR'
compile endif

defc buffhelp =
   universal vMESSAGECOLOR
   sayat leftstr(CREATEBUF_HELP__MSG ,72), 1, 4, $MSGC
   sayat leftstr(PUTBUF_HELP__MSG    ,72), 2, 4, $MSGC
   sayat leftstr(GETBUF_HELP__MSG    ,72), 3, 4, $MSGC
   sayat leftstr(FREEBUF_HELP__MSG   ,72), 4, 4, $MSGC


--| New optional argument:  GETBUF 1 means a private buffer.
--| Means don't try to open and close a named buffer; just use current bufhndl.
defc getbuf    -- Gets entire buffer into current file.
               -- Buffer must have been precreated.
               -- Opens the buffer before the get, closes it afterward.
               -- Note:  if we were only doing this from the same E session
               --        as where we created the buffer, we wouldn't need the
               --        open.  But we might get from another session!
   universal format, bufname
   universal bufhndl --| We use the previous bufhndl if private.

   private = 0                   --| new option to create non-shared buffer
   if arg(1) then
      private = 1
   endif
   if not private then
      bufhndl = buffer(OPENBUF, bufname)
      if not bufhndl then sayerror 'OPENBUF' ERROR_NUMBER__MSG RC; stop; endif
   endif

   noflines = buffer(GETBUF,bufhndl)
   if not noflines then
      if rc then
         sayerror 'GETBUF' ERROR_NUMBER__MSG RC
      else
         sayerror EMPTYBUF_ERROR__MSG
      endif
      stop
   endif
   usedsize = buffer(USEDSIZEBUF,bufhndl)   -- Get these for info.
   maxsize  = buffer(MAXSIZEBUF,bufhndl)

   if not private then  --|
      success  = buffer(FREEBUF,  bufhndl)
      if not success then sayerror 'FREEBUF' ERROR_NUMBER__MSG RC; stop; endif
   endif

   sayerror GOT__MSG usedsize BYTES_FROM_A__MSG maxsize || BYTE_BUFFER__MSG'.  'noflines LINES__MSG

defc putbuf    -- Puts current file from current line on.
               -- Buffer must be created first.
   universal format, bufhndl

   -- From current line to end of file.
   noflines = buffer(PUTBUF,   bufhndl, .line, 0, format)
   if not noflines then sayerror 'PUTBUF' ERROR_NUMBER__MSG RC; stop; endif
   usedsize = buffer(USEDSIZEBUF,bufhndl)   -- Get these for info.
   maxsize  = buffer(MAXSIZEBUF,bufhndl)
   sayerror PUT__MSG usedsize BYTES_TO_A__MSG maxsize || BYTE_BUFFER__MSG'.  'noflines LINES__MSG

--| New optional argument:  CREATEBUF 1 means a private buffer.
defc createbuf -- Creates the buffer of default size.
   universal bufname, bufhndl
   private = 0                   --| new option to create non-shared buffer
   if arg(1) then
      private = 1
   endif
   bufhndl = buffer(CREATEBUF, bufname, MAXBUFSIZE, private )  --|
   if not bufhndl then sayerror 'CREATEBUF' ERROR_NUMBER__MSG RC; stop; endif
   sayerror CREATED__MSG

defc freebuf
   universal bufhndl
   success = buffer(FREEBUF, bufhndl)
   if not success then sayerror 'FREEBUF' ERROR_NUMBER__MSG RC; stop; endif
   sayerror FREED__MSG
   bufhndl = 0             -- Reset to no-buffer value.

defproc put_shared_text(buffer_name, firstline, lastline)
   if buffer_name='' then
      sayerror MISSING_BUFFER__MSG
      stop
   endif
   -- Try to open the buffer.  If it doesn't exist, create it.
   bufhndl = buffer(OPENBUF, buffer_name)
   if bufhndl then
      opened = 1
   else
      -- Make a 64K buffer... memory's plentiful.  Easily changed.
      bufsize = MAXBUFSIZE
      bufhndl = buffer(CREATEBUF, buffer_name, bufsize)
      opened = 0
   endif
   if not bufhndl then
      sayerror CAN_NOT_OPEN__MSG buffer_name '-' ERROR_NUMBER__MSG RC
      stop
   endif
   noflines = buffer(PUTBUF, bufhndl, firstline, lastline)
   if opened then
      call buffer(FREEBUF, bufhndl)
   endif
   if noflines < lastline-firstline+1 then
      sayerror ONLY_ACCEPTED__MSG noflines LINES__MSG
      stop
   endif

defproc get_shared_text(buffer_name)
   if buffer_name='' then
      sayerror MISSING_BUFFER__MSG
      stop
   endif
   -- Try to open the buffer.  If it doesn't exist, create it.
   bufhndl = buffer(OPENBUF, buffer_name)
   if bufhndl then
      opened = 1
   else
      -- Make a 64K buffer... memory's plentiful.  Easily changed.
      bufsize = MAXBUFSIZE
      bufhndl = buffer(CREATEBUF, buffer_name, bufsize)
      opened = 0
   endif
   if not bufhndl then
      sayerror CAN_NOT_OPEN__MSG buffer_name '-' ERROR_NUMBER__MSG RC
      stop
   endif
   noflines = buffer(GETBUF, bufhndl)
   if opened then
      call buffer(FREEBUF, bufhndl)
   endif

defc pt= -- Put text to buffer.  Argument = noflines.
   noflines = arg(1)
   firstline = .line
   if not noflines then          -- no argument means current line only
      lastline = firstline
   endif
   if noflines='*' then          -- '*' means to end of file
      lastline = .last
   endif
   buffer_name='EXSESS'          -- buffer name:  E across sessions
   call put_shared_text(buffer_name, firstline, lastline)

defc gt= -- Get text from buffer.  No argument.
   buffer_name='EXSESS'          -- buffer name:  E across sessions
   call get_shared_text(buffer_name)
