/*
 * Name         sortdll
 *
 * Author       Ralph Yozzo
 *
 * Function     This application provides an interface to the QISRTMEM
 *              dynamic link library, which is contained in QISRTDLL PACKAGE
 *              on PCTOOLS.
 *
 * Acknowledgements
 *              Some of the functions here are derived from the SORTE.E
 *              and BUFF.E file created by Bryan Lewis.  Many thanks are due to
 *              Bryan.  Rewritten for efficiency by Larry Margolis.
 */
compile if EPM32
   *** You should have SORT_TYPE = 'EPM' in your MYCNF.E; SORT_TYPE = 'DLL' no longer supported.
compile endif


defproc sort(firstline,lastline,firstcol,lastcol,fileid)
;  Revers=0
;  if arg() > 5 then  /* if sixth argument was passed ... */
;     Revers=not verify('R',upcase(arg(6)))       /* R anywhere */
;  endif  -- 19 bytes shorter to omit "Revers=0", "If ...", & "endif".  -LAM
compile if EVERSION >= 5.50  -- Reverse, case Insensitive, Collating order
   Revers=not verify('R',upcase(arg(6))) + 2*(not verify('I',upcase(arg(6)))) + 4*(not verify('C',upcase(arg(6))))
compile else
   Revers=not verify('R',upcase(arg(6)))       /* R anywhere */
compile endif
   getfileid SORT_fileid
   activatefile fileid
   buffer_handle=SORT_find_buffer('DLLSORT0')
   noflines = buffer(PUTBUF, buffer_handle, firstline, lastline)
   if noflines < lastline-firstline+1 then
      call buffer(FREEBUF, buffer_handle)
      sayerror ONLY_ACCEPTED__MSG noflines LINES__MSG
      stop
   endif
   size = buffer(USEDSIZEBUF, buffer_handle)
   result_handle = SORT_find_buffer('DLLSORT1')
   rc = 0
compile if EPM32
   result_length = dynalink32(E_DLL,
                             'SORT_qrsortmemorystable',
                             atoi(32)               ||  -- offset
                             atoi(buffer_handle)    ||  -- selector
                             atol(size)             ||
                             atoi(32)               ||  -- offset
                             atoi(result_handle)    ||  -- selector
                             atol(MAXBUFSIZE)       ||
                             atol(firstcol-1)       ||
                             atol(lastcol-1)        ||
                             atol(Revers)             ,
                             2)
compile else
 compile if EPM  -- EPM now includes this function in its own library:
   result_length = dynalink(E_DLL,
 compile else    -- EOS2 needs it from the QISRTDLL package:
   result_length = dynalink('QISRTMEM',
 compile endif
                            'SORT_QRSORTMEMORYSTABLE',
                            atoi(buffer_handle)    ||
                            atoi(32)               ||
                            atol_swap(size)        ||
                            atoi(result_handle)    ||
                            atoi(32)               ||
                            atol_swap(MAXBUFSIZE)  ||
                            atol_swap(firstcol-1)  ||
                            atol_swap(lastcol-1)   ||
                            atol_swap(Revers)        ,
                            2)
compile endif
   stop_on_rc
   call buffer(FREEBUF, buffer_handle)
   poke result_handle, 2, substr(atol(result_length),1,2)
   poke result_handle, 4, atoi(3)
   poke result_handle, 6, lastline

   call psave_pos(savepos)

compile if RESTORE_MARK_AFTER_SORT
   call psave_mark(savemark)
compile endif
   call pset_mark(firstline,lastline,firstcol,lastcol,'LINE',fileid)
   delete_mark
   call prestore_pos(savepos)
   /* jbl 12/30/88:  don't try to set .line if .last=0, file is empty.*/
   if .last then firstline-1; endif                     -- Set .line
   noflinesback = buffer(GETBUF, result_handle)
   call buffer(FREEBUF, result_handle)

compile if EOS2    -- EPM's implementation fixed the bug that returns an extra line
   deleteline lastline+1
compile endif

   call prestore_pos(savepos)

compile if RESTORE_MARK_AFTER_SORT
   call prestore_mark(savemark)
compile endif

   activatefile SORT_fileid
   if noflines<>noflinesback then
      sayerror 'Sort:' PUT__MSG noflines SORT_ERROR1__MSG noflinesback SORT_ERROR2__MSG
   endif

defc SORTDLL,sort =
   TypeMark=marktype()
   if TypeMark='' then  /* if no mark, default to entire file */
      getfileid fileid
      firstline=1 ; lastline=.last ; firstcol=1; lastcol = 40
   else
      getmark firstline,lastline,firstcol,lastcol,fileid
   endif

   /* If it was a line mark, the LastCol value can be 255.  Can't */
   /* imagine anyone needing a key longer than 40.                */
   if TypeMark='LINE' then lastcol=40 endif

   sayerror SORTING__MSG lastline-firstline+1 LINES__MSG'...'

   /* Pass the sort switches "rc", if any, as a sixth argument to sort().    */
   call sort(firstline,lastline,firstcol,lastcol,fileid, arg(1) )

   sayerror 0

defproc SORT_find_buffer(buffer_name)
   bufhndl = buffer(OPENBUF, buffer_name)
   if not bufhndl then
      -- Make a 64K buffer... memory's plentiful.  Easily changed.
      bufhndl = buffer(CREATEBUF, buffer_name, MAXBUFSIZE)
   endif
   if bufhndl then
      return bufhndl
   endif
   sayerror CAN_NOT_OPEN__MSG buffer_name '-' ERROR_NUMBER__MSG RC
   stop
