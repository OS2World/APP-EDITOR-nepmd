/*      HELP.E       --- Used By EPM  G.C.       */
include 'STDCONST.E'
 define INCLUDING_FILE = 'HELP.E'
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

const
   PAGESIZE = 21

defmain    /* defmain should be used to parse the command line arguments */
   'xcom e 'arg(1)
   prevfile; 'xcom quit'

;  .titletext    = 'EPM Help Browser'
   .titletext    = QUICK_REF__MSG
   .textcolor    =  240            -- WhiteB
   .markcolor    =  240            -- WhiteB
   .tabs         = '1 2 3 4 5 6'
   .margins      = '1 80 1'
   .autosave     = 0
   keys help
   call repaint_window()
   call showwindow('ON')
   'togglecontrol 14 0'     -- Turn cursor off
compile if EVERSION >= '5.50'
   if upcase(rightstr(.filename,8))='DBCS.QHL' then
      .font = registerfont('Mincho', 10, 0)
   else
      .font = registerfont('System Monospaced', 10, 0)
   endif
compile endif
compile if EVERSION < '5.21'
   .statuscolor  =  16+15          -- BlueB + White
   .messagecolor =  16+14          -- BlueB + Yellow
   .statusline=HELP_STATUS__MSG
compile else
   'togglecontrol 26 0'     -- Don't use internal key definitions.
   call windowmessage(1,  getpminfo(EPMINFO_EDITCLIENT),
                      5431,      -- EPM_FRAME_STATUSLINE
compile if EVERSION >= 5.53
                      put_in_buffer(atoi(length(HELP_STATUS__MSG)) || HELP_STATUS__MSG, 0),
compile else
                      put_in_buffer(chr(length(HELP_STATUS__MSG)) || HELP_STATUS__MSG, 0),
compile endif
                      31)        -- BlueB + White

   call windowmessage(1,  getpminfo(EPMINFO_EDITCLIENT),
                      4873,      -- EII_EDIT_REFRESHSTATUSLINE
                      1, 1);
 compile if EVERSION < 5.53
   'togglecontrol 23 1'     -- Move status & message line to top
 compile else
   call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),
                      5907,            -- EFRAMEM_TOGGLECONTROL
                      32 + 2 * 65536,  -- Move extra window to top
                      0)
 compile endif
compile endif
;  mouse_setpointer 12
   .cursory = 1
   '0'

defc e =  -- Only called by someone else posting a command to us.
   call winmessagebox(QUICK_REF__MSG, NO_DROP__MSG, 16454) -- CANCEL + ICONHAND + MOVEABLE

defkeys help base clear

def pgup=
   .cursory = 1
   PAGESIZE * (max(.line-1,0) % PAGESIZE)

def pgdn=
   .cursory = 1
   PAGESIZE * (min(.line+PAGESIZE,.last) % PAGESIZE)

def home, c_Home = .cursory=1; '0'

def end, c_End = .cursory=1; .last % PAGESIZE * PAGESIZE

def esc,F3=  -- 'close'
; defc close=
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      41,                 -- WM_CLOSE
                      0,
                      0)

defproc max(a,b)  -- Support as many arguments as E3 will allow.
   maximum=a
   do i=2 to arg()
      if maximum<arg(i) then maximum=arg(i); endif
   end
   return maximum

defproc min(a,b)  -- Support as many arguments as E3 will allow.
   minimum=a
   do i=2 to arg()
      if minimum>arg(i) then minimum=arg(i); endif
   end
   return minimum

/* allows the edit window to become invisible or visible  */
defproc showwindow
   call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT),
                      5385,
                      upcase(arg(1))<>'OFF', -- 0 if OFF, else 1
                      0)

/*
旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
� what's it called: repaint_window                                           �
�                                                                            �
� what does it do : send a paint message to the editor.                      �
�                                                                            �
읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
*/
defproc repaint_window()
   call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT), 35, 0, 0)   -- WM_PAINT

defc togglecontrol
   forceon=0
   parse arg controlid fon
   if fon<>'' then
      forceon=(fon+1)*65536
   endif

   call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),   -- Post message to frame
                      5388,               -- EPM_EDIT_CONTROLTOGGLE
                      controlid + forceon,
                      0)

defc PROCESSDRAGDROP
   parse arg cmdid hwnd .
;  hwnd=atol_swap(hwnd)

   if cmdid=10 then
      sayerror PRINTING__MSG .filename
      'xcom save /q lpt1'
   elseif cmdid=1 and hwnd<>getpminfo(EPMINFO_EDITCLIENT) and leftstr(.filename,1)<>'.' then
      call PostCmdToEditWindow('e '.filename,hwnd,9,2)
   elseif cmdid=3 then                       -- Open
      call windowmessage(0,  getpminfo(APP_HANDLE),
                         5386,                   -- EPM_EDIT_NEWFILE
                         put_in_buffer(name,2),  -- share = GETable
                         9)                      -- EPM does a GET first & a FREE after.
   elseif cmdid=4 then
      call winmessagebox(SYS_ED__MSG,SYS_ED1__MSG\10'   :-)', 16406) -- CANCEL + ICONQUESTION
   endif

defproc PostCmdToEditWindow(cmd,winhndl)
;; if arg(3)<>'' then mp2=arg(3); else mp2=1; endif
   call windowmessage(0,  winhndl,
                      5377,               -- EPM_EDIT_COMMAND
                      put_in_buffer(cmd,arg(4)),
                      arg(3))

defproc put_in_buffer(string)
;; if arg(2)='' then share=0; else share=arg(2); endif

compile if POWERPC  -- Temp. kludge because they don't support tiled memory
  if not arg(2) then
     strbuffer = atol(dynalink32(E_DLL,
                                  'mymalloc',
                                  atol(length(string)+1), 2))
     r = -270 * (strbuffer = 0)
  else
compile endif
compile if EPM32
   if not arg(2) then share=83;  -- PAG_READ | PAG_WRITE | PAG_COMMIT | OBJ_TILE
   else share=arg(2); endif
   strbuffer = "????"                  -- Initialize string pointer.
   r =  dynalink32('DOSCALLS',          -- Dynamic link library name
            '#299',                    -- Dos32AllocMem
            address(strbuffer)     ||
            atol(length(string)+1) ||  -- Number of bytes requested
            atol(share))               -- Share information
 compile if POWERPC  -- Temp. kludge because they don't support tiled memory
  endif
 compile endif
compile else
   strbuffer = "??"                    -- Initialize string pointer.
   r =  dynalink('DOSCALLS',           -- Dynamic link library name
            '#34',                     -- DosAllocSeg
            atoi(length(string)+1) ||  -- Number of bytes requested
            address(strbuffer)     ||
            atoi(arg(2)) )             -- Share information
compile endif  -- EPM32

   if r then sayerror ERROR__MSG r ALLOC_HALTED__MSG; stop; endif
compile if 0 -- POWERPC
   -- Leave strbuffer as a long
   strbuffer = ltoa(strbuffer,10)
compile elseif EPM32
   strbuffer = itoa(substr(strbuffer,3,2),10)
compile else
   strbuffer = itoa(strbuffer,10)
compile endif  -- EPM32
   poke strbuffer, 0, string\0  -- Copy string to new allocated buf
   return mpfrom2short(strbuffer,0)    -- Return a long pointer to buffer

defproc winmessagebox(caption, text)

; msgtype = 4096                                        -- must be system modal.
; if arg(3) then
;    msgtype=arg(3) + 4096 * (1 - (arg(3)%4096 - 2 * (arg(3)%8192)))  -- ensure x'1000' on
; endif
  if arg(3) then
     msgtype=arg(3)
  else
     msgtype = 0
  endif
  caption = caption\0
  text    = text\0
compile if EPM32
  return dynalink32( 'PMWIN',
                     '#789',      -- WINMESSAGEBOX
                     atol(1) ||   -- Parent
                     atoi(1) ||   -- Owner
                     address(text)     ||   -- Text
                     address(caption)  ||   -- Title
                     atol(0)           ||   -- Window
                     atol(msgtype) )        -- Style
compile else
  return dynalink( 'PMWIN',
                   'WINMESSAGEBOX',
                   atoi(0) || atoi(1) ||   -- Parent
                   atoi(0) || atoi(1) ||   -- Owner
                   address(text)      ||   -- Text
                   address(caption)   ||   -- Title
                   atoi(0)            ||   -- Window
                   atoi(msgtype) )         -- Style
compile endif  -- EPM32

defproc mpfrom2short(mphigh, mplow)
   return ltoa( atoi(mplow) || atoi(mphigh), 10 )

defc processendscroll

compile if EVERSION >= 6
   EA_comment 'This is a simple base .ex file for use by the Quick Reference browser.'
compile endif
