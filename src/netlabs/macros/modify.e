;  MODIFY.E                                              Bryan Lewis 12/31/88
;
;  New in EPM.  This DEFMODIFY event is triggered when a file's number of
;  modifications (.modify):
;  -  goes from zero to nonzero (first modification, so we can change the
;     textcolor or title to indicate that the file needs to be saved;
;  -  goes from nonzero to zero (so we can return to the safe textcolor,
;     usually after a save);
;  -  goes from less than .autosave to greater than or equal to .autosave.
;
;
;  Note:  .modify does not always increase smoothly, one increment at a time.
;  For instance, changing a line and hitting Enter increases .modify by 2,
;  because it registers the change to the previous line as well as the new
;  line.  So we can't expect .modify to be exactly 1; we have to look for
;  a transition from zero to nonzero.
;
;  Note 2:  E will not retrigger this event while the event is in
;  progress, to protect against infinite recursion.  So if you make a lot
;  of changes to a file in the process of autosaving it, it won't get autosaved
;  twice.
;
;  We've provided three methods of showing the modified status.
;  1. The COLOR method changes the window color, for a very obvious indicator.
;  2. The FKTEXTCOLOR method changes the color of the bottom line of the
;     screen, for EOS2 only.
;  3. The TITLE method does one of two things.  For EOS2 it changes the color
;     of the filename.  For EPM it adds the string " (mod)" to the title bar.
;     This isn't as obvious as COLOR, but you can check it even when the file
;     is shrunk to an icon by clicking on the icon.
;
;  You, the macro writer, can add to or replace this behavior.
;  1. You can write defmodify procedures anywhere in your MYSTUFF.E or
;     MYKEYS.E files.  All defmodify procedures will be executed in sequence,
;     just as definit preocedures are.  The pieces can be anywhere.
;  2. Or you can write a DEFMODIFY event in a linked module, and it will
;     replace this one entirely.  For example, create a file NEWMOD.E with
;     your defmodify proc; compile it separately (ETPM NEWMOD); add a link
;     statement (link 'newmod') to your MYKEYS.E or MYSTUFF.E file.
;

compile if SHOW_MODIFY_METHOD = 'COLOR'

defmodify
 compile if EPM
   universal  appname, app_hini
 compile else
   universal comsfileid
 compile endif
 compile if WPS_SUPPORT
   universal wpshell_handle
 compile endif

   getfileid fileid
   if .autosave and .modify>=.autosave then
 compile if EPM
      if leftstr(.filename,1,1) <> '.' | .filename = UNNAMED_FILE_NAME then
  compile if EVERSION >= '5.50'
         sayerror AUTOSAVING__MSG
  compile else
         sayatbox(AUTOSAVING__MSG)
  compile endif
 compile else
      if fileid <> comsfileid & substr(.filename,1,1) <> '.' then
 compile endif
 compile if EVERSION >= '5.50'
         'xcom save "'MakeTempName()'"'
 compile else
         'xcom save 'MakeTempName()
 compile endif
         .modify=1                  /* Reraise the modify flag. */
 compile if EVERSION >= '5.50'
         sayerror 0
 compile endif
      endif
   endif
 compile if EVERSION < 5
   fids = fileidfromanchorblock(.anchorblock)  -- Get list of fileids
   do while fids <> ''
      parse value fids with fileid fids
      if .modify then
         fileid.markcolor  = MODIFIED_MARKCOLOR
         fileid.windowcolor= MODIFIED_WINDOWCOLOR
      else -- if .modify==0 then
         fileid.markcolor  = MARKCOLOR
         fileid.windowcolor= WINDOWCOLOR
      endif
   end  -- do while
 compile else                   -- EPM
   if .modify then
      .markcolor= MODIFIED_MARKCOLOR
      .textcolor= MODIFIED_WINDOWCOLOR
   else -- if .modify==0 then
compile if WANT_APPLICATION_INI_FILE
      mc = MARKCOLOR
      tc = TEXTCOLOR
 compile if WPS_SUPPORT
      if wpshell_handle then
; Key 4
         tc = peekz(peek32(wpshell_handle, 16, 4))
; Key 5
         mc = peekz(peek32(wpshell_handle, 20, 4))
      else
 compile endif
      tempstr= queryprofile( app_hini, appname, INI_STUFF)
      if tempstr<>'' & tempstr<>1 then
         parse value tempstr with tc mc .
      endif
 compile if WPS_SUPPORT
      endif  -- wpshell_handle
 compile endif
      .markcolor= mc
      .textcolor= tc
compile else
      .markcolor= MARKCOLOR
      .textcolor= TEXTCOLOR
compile endif
   endif
   refresh
   repaint_window()
 compile endif
compile endif -- COLOR


compile if SHOW_MODIFY_METHOD = 'TITLE'
 compile if EVERSION >= 5
const
   -- This is what we'll append to the file title.
  compile if not defined(SHOW_MODIFY_TEXT)   -- If user didn't define in MYCNF:
   SHOW_MODIFY_TEXT = ' (mod)'
  compile endif

defmodify
   if .autosave and .modify>=.autosave then
      getfileid fileid
      if leftstr(.filename,1,1) <> '.' | .filename = UNNAMED_FILE_NAME then
  compile if EVERSION >= '5.50'
         sayerror AUTOSAVING__MSG
  compile else
         sayatbox(AUTOSAVING__MSG)
  compile endif
  compile if EVERSION >= '5.50'
         'xcom save "'MakeTempName()'"'
  compile else
         'xcom save 'MakeTempName()
  compile endif
         .modify=1                  /* Reraise the modify flag. */
  compile if EVERSION >= '5.50'
          sayerror 0
  compile elseif EPM
         refresh
         call repaint_window()
  compile endif
      endif
   endif
   settitletext(.filename) -- This procedure adds the SHOW_MODIFY_TEXT.
 compile else   -- Not EPM
   -- When the file is modified, change the color of the filename.
defmodify
   universal comsfileid
   if .autosave and .modify>=.autosave then
      getfileid fileid
      if fileid <> comsfileid & substr(.filename,1,1) <> '.' then
         'xcom save 'MakeTempName()
         .modify=1                  /* Reraise the modify flag. */
      endif
   endif
   fids = fileidfromanchorblock(.anchorblock)  -- Get list of fileids
   do while fids <> ''
      parse value fids with fileid fids
      if .modify then
         fileid.filenamecolor= MODIFIED_FILENAMECOLOR
         fileid.monofilenamecolor= MODIFIED_MONOFILENAMECOLOR
      else -- if .modify==0 then
         fileid.filenamecolor= FILENAMECOLOR
         fileid.monofilenamecolor= MONOFILENAMECOLOR
      endif
   end  -- do while
 compile endif  -- not EPM
compile endif  -- title


compile if SHOW_MODIFY_METHOD = 'FKTEXTCOLOR'
defmodify
   universal comsfileid
   if .autosave and .modify>=.autosave then
      getfileid fileid
      if fileid <> comsfileid & substr(.filename,1,1) <> '.' then
         'xcom save 'MakeTempName()
         .modify=1                  /* Reraise the modify flag. */
      endif
   endif
   fids = fileidfromanchorblock(.anchorblock)  -- Get list of fileids
   do while fids <> ''
      parse value fids with fileid fids
      if .modify then
         fileid.functionkeytextcolor= MODIFIED_FKTEXTCOLOR
      else -- if .modify==0 then
         fileid.functionkeytextcolor= FUNCTIONKEYTEXTCOLOR
      endif
   end  -- do while
compile endif  -- statuscolor


compile if SHOW_MODIFY_METHOD = ''  -- No change in display, just do AUTOSAVE.
defmodify
 compile if not EPM
   universal comsfileid
 compile endif
   if .autosave and .modify>=.autosave then
      getfileid fileid
 compile if EPM
      if leftstr(.filename,1,1) <> '.' | .filename = UNNAMED_FILE_NAME then
  compile if EVERSION >= '5.50'
         sayerror AUTOSAVING__MSG
  compile else
         sayatbox(AUTOSAVING__MSG)
  compile endif
 compile else
      if fileid <> comsfileid & substr(.filename,1,1) <> '.' then
 compile endif
  compile if EVERSION >= '5.50'
         'xcom save "'MakeTempName()'"'
  compile else
         'xcom save 'MakeTempName()
  compile endif
         .modify=1                  /* Reraise the modify flag. */
 compile if EVERSION >= '5.50'
          sayerror 0
 compile elseif EPM
         refresh
         call repaint_window()
 compile endif
      endif
   endif
compile endif  -- No display change.

compile if INCLUDE_BMS_SUPPORT  -- Put this at the end, so it will be included in any of the above
   if isadefproc('BMS_defmodify_exit') then
      call BMS_defmodify_exit()
   endif
compile endif
