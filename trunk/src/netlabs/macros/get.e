;  For linking version, GET can be an external module.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled.
 define INCLUDING_FILE = 'GET.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
    const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
    tryinclude SITE_CONFIG
 compile endif

const
 compile if EVERSION >= 5
  compile if not defined(WANT_BOOKMARKS)
   WANT_BOOKMARKS = 'LINK'
  compile endif
 compile else
   WANT_BOOKMARKS = 0
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
include NLS_LANGUAGE'.e'

defmain     -- External modules always start execution at DEFMAIN.
   'get' arg(1)

 compile if EVERSION >= 6
   EA_comment 'This defines the GET command; it can be linked, or executed directly.'
 compile endif
compile endif  -- not defined(SMALL)

defc get=
   universal default_edit_options
   get_file = strip(arg(1))
   if get_file='' then sayerror NO_FILENAME__MSG 'GET'; stop endif
   if pos(argsep,get_file) then
      sayerror INVALID_OPTION__MSG
      stop
   endif
   call parse_filename(get_file,.filename)
   getfileid fileid
   s_last=.last
compile if EVERSION < 5
   'e /q /h /d' default_edit_options get_file
compile else
   display -1
   'e /q /d' get_file
compile endif
   editrc=rc
   getfileid gfileid
   if editrc = -282 | not .last then   -- -282 = sayerror('New file')
      'q'
compile if EVERSION > 5
      display 1
compile endif
      if editrc = -282 then
         sayerror FILE_NOT_FOUND__MSG':  'get_file
      else
         sayerror FILE_IS_EMPTY__MSG':  'get_file
      endif
      stop
   endif
   if editrc & editrc<>-278 then  -- -278  sayerror('Lines truncated') then
compile if EVERSION > 5
      display 1
compile endif
      sayerror editrc
      stop
   endif
   call psave_mark(save_mark)
compile if WANT_BOOKMARKS
   if not .levelofattributesupport then
      'loadattributes'
   endif
compile endif
compile if EVERSION > 5
   get_file_attrib = .levelofattributesupport
compile endif
   top
   mark_line
   bottom
   if rightstr(textline(.last), 1) = \26 then  -- Ends with EOF?
      getline line
      replaceline leftstr(line, length(line)-1)
      .modify = 0
   endif
   mark_line
   activatefile fileid
   rc=0
   copy_mark
   copy_rc=rc           -- Test for memory too full for copy_mark.
   activatefile gfileid
   'q'
   parse value save_mark with s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt
   if fileid=s_mkfileid then           -- May have to move the mark.
      diff=fileid.last-s_last          -- (Adjustment for difference in size)
      if fileid.line<s_firstline then s_firstline=s_firstline+diff; endif
      if fileid.line<s_lastline then s_lastline=s_lastline+diff; endif
   endif
   call prestore_mark(s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt)
   activatefile fileid
compile if EVERSION > 5
   if get_file_attrib // 2 then
      call attribute_on(1)  -- Colors flag
   endif
 compile if EVERSION >= 5.50  -- GPI has font support
  compile if EVERSION >= '6.01b'
   if get_file_attrib bitand 4 then
  compile else
   if get_file_attrib % 4 - 2 * (get_file_attrib % 8) then
  compile endif
      call attribute_on(4)  -- Mixed fonts flag
   endif
 compile endif
  compile if EVERSION >= '6.01b'
   if get_file_attrib bitand 8 then
  compile else
   if get_file_attrib % 8 - 2 * (get_file_attrib % 16) then
  compile endif
      call attribute_on(8)  -- "Save attributes" flag
   endif
   display 1
compile endif
   if copy_rc then
      sayerror NOT_2_COPIES__MSG get_file
compile if EVERSION < 5
   else
      call message(1)
compile endif
   endif
compile if EVERSION < 5
   call select_edit_keys()
compile else
;  refresh
;  call repaint_window()
compile endif
