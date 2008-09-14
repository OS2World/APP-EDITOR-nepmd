/****************************** Module Header *******************************
*
* Module Name: makeactn.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: makeactn.e,v 1.5 2008-09-14 15:32:40 aschn Exp $
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
; This is a Toolbar Actions file.  You add a line to your ACTIONS.LST:
;    makeactn
; to indicate that this should be invoked to build the list of defined
; actions when the user asks for a list.

const
   WANT_DYNAMIC_PROMPTS = 1  -- Force definition of menu prompts in ENGLISH.E.
include 'stdconst.e'
include 'english.e'

const
   makeactn_msgbox_title = 'Make Actions'
   a_build_PROMPT = 'Creates a shell and start a build in it.'
   a_build2_PROMPT = '  Parameters are a key name for the project, a path in which to start the build, and a command to start the build.  E.g.,  "projfoo d:\foo nmake -f foo.mak"'
   a_makeme_PROMPT = 'Creates a shell and start a build of the current MAKE file in it.'
;  Following string too long for UCMENU support; gets truncated at '*'...
;  a_makeme2_PROMPT = '  Parameters are a key name for the project, a path in which to start the build (use "=" for path of cur. file), and a command to start the build.  Current filename will be appended to end of*command.'
   a_makeme2_PROMPT = '  Parameters are a key name for the project, a path to start the build in (use "=" for path of cur. file), and a command to start the build.  Current filename will be appended to end of cmd.'
   a_view_PROMPT = 'Parse the lines of the build shell and store the error information.'
   a_view2_PROMPT = '  Optional parameter is the project''s key name; default is to extract it from the current'
   a_view3_PROMPT = 'shell window.'
   a_file3_PROMPT = 'file.'
;; a_next_err_PROMPT = 'Move to next compiler error'
;; a_prev_err_PROMPT = 'Move to previous compiler error'
   a_descr_PROMPT = 'Display the current error.'

; Here is the <file_name>_ACTIONLIST command that adds the action commands
; to the list.

defc makeactn_actionlist
   universal ActionsList_FileID  -- This is the fileid that gets the lines

   insertline "makea_build"a_build_PROMPT || a_build2_PROMPT"makeactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "makea_makeme"a_makeme_PROMPT || a_makeme2_PROMPT"makeactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "makea_view_err"a_view_PROMPT || a_view2_PROMPT a_view3_PROMPT"makeactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "makea_next_err"NEXT_COMPILER_MENUP__MSG'.'a_view2_PROMPT a_file3_PROMPT"makeactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "makea_prev_err"PREV_COMPILER_MENUP__MSG'.'a_view2_PROMPT a_file3_PROMPT"makeactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "makea_curr_descr"a_descr_PROMPT || a_view2_PROMPT a_file3_PROMPT"makeactn", ActionsList_FileID.last+1, ActionsList_FileID

defc makea_build
   makea_common_action(arg(1), 'MK_BUILD', a_build_PROMPT)

defc makea_makeme
   parse arg action_letter index path build_command
   if action_letter = 'I' then       -- button Initialized
      'SayHint' a_makeme_PROMPT
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0
      if path='=' then
         path = leftstr(.filename, lastpos('\', .filename)-1)
      endif
      if .modify then
         result = winmessagebox("MakeMe", MODIFIED_PROMPT__MSG, MB_YESNOCANCEL + MB_ICONQUESTION + MB_MOVEABLE)
         if result=MBID_YES then
            'save'
         elseif result=MBID_NO then
            -- nop
         else
            return
         endif
      endif

      if not exist(.filename) then
         sayerror '"'.filename'"' NOT_ON_DISK__MSG
         return
      endif

      'MK_BUILD' index path build_command .filename
   elseif action_letter = 'H' then   -- button Help
      call winmessagebox(makeactn_msgbox_title, a_makeme_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc makea_view_err
   makea_common_action(arg(1), 'MK_VIEW_ERROR', a_view_PROMPT)

defc makea_next_err
   makea_common_action(arg(1), 'MK_NEXT_ERR', substr(NEXT_COMPILER_MENUP__MSG, 2))

defc makea_prev_err
   makea_common_action(arg(1), 'MK_PREV_ERR', substr(PREV_COMPILER_MENUP__MSG, 2))

defc makea_curr_descr
   makea_common_action(arg(1), 'MK_CUR_DESCR', a_descr_PROMPT)

defproc makea_common_action(arg1, command, prompt)
   parse value arg1 with action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' prompt
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0
      command parms
   elseif action_letter = 'H' then   -- button Help
      call winmessagebox(makeactn_msgbox_title, prompt, MB_OK + MB_INFORMATION + MB_MOVEABLE)
;; elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

-- Set of macros to build programs in the EPM shell
-- and displaye the errors.
-- for the users :
--    mk_build
--    mk_view_error
--    mk_next_err
--    mk_prev_err
--    mk_cur_err
--    mk_view_shell
-- used internally only :
--    mk_bringfile
--    mk_parse_errline_default
-- procedure used if defined by the user
--    mk_parse_errline

; Buildargs, saved in the build_array, indexed by the key, are:
;  parse value buildargs with build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
; build_drive ('c:') the drive to switch to before doing the build
; build_dir ('c:\thisdir') the directory to switch to before doing the build
; build_shellid (1) the shell ID in which the builds for this index are being executed
; build_command ('nmake foo.mak') the command to execute to kick off the build
; build_cur_err (12) the current error number we're on in the build output
; build_start_line (123) the line number of the shell file on which the current build started
; build_number (1) the number of times we've run a build of this index in this window
; build_error_num (12) the number of errors found in the output of this build

const MK_ERROR_MARKTYPE = 5

---------------------------------------------------------------------------------------

-- Proc called to try to extract error informations from a line
-- It works for error lines generated by the IBM C/set++ compiler
-- This procedure is called by default, but if mk_parse_errline is defined it is
--  called instead of mk_parse_errline_default
-- It allows the users to extract error informations for other compilers
-- errorline : line to check for error informations
-- error_level : 0 if the line contained no error information, 1 if Info; 2 if Warning;
--               3 if Error; 4 if Severe Error; 5 if Fatal Error; 9 if looked like an error but we don't know which class
-- FileName : name of the file where the error is
-- LineNum : line of the error in the file
-- ColumnNum : column of the error in the file
-- ErrorMsg : message describing the error
-- Line : the line number in the shell file; used for determining the column number for Java output.
defproc mk_parse_errline_default( errorline, VAR FileName, VAR LineNum, VAR ColumnNum, VAR ErrorMsg, VAR error_level, line )
   parse value errorline with Filename '(' LineNum ')'  ErrorMsg
   parse value LineNum with LineNum ':' ColumnNum
   if not isnum(linenum) then  -- Try JavaC format?
      if substr(errorline, 2, 1) = ':' then
         col = pos(':', errorline, 3)
         if col then
            Filename = leftstr(errorline, col-1)
            parse value substr(errorline, col+1) with LineNum ':' ErrorMsg
         endif
      else
         parse value errorline with Filename ':' LineNum ':'  ErrorMsg
      endif
      if (FileName<>'' & isnum(LineNum) & ErrorMsg<>'' & line+2 <= .last) then
         getline templine, line+2
         col = pos('^', templine)
         if col>0 then
            ColumnNum = col
         endif
      endif
   endif
   if ColumnNum='' then
      ColumnNum = 1
   endif
   if not (FileName<>'' & isnum(LineNum) & isnum(ColumnNum) & ErrorMsg<>'') then
      error_level = 0
      return
   endif
   if word(errorMsg, 1)=':' then
        ErrorMsg = subword(ErrorMsg, 2)
   endif
   w1 = upcase(word(ErrorMsg, 1))
   if rightstr(w1, 1) = ':' then
      w1 = leftstr(w1, length(w1)-1)
   endif
   if abbrev('INFORMATIONAL', w1, 4) then
      error_level = 1
   elseif w1 = 'WARNING' then
      error_level = 2
   elseif w1 = 'ERROR' then
      error_level = 3
   elseif w1 = 'SEVERE' then
      error_level = 4
   elseif w1 = 'CRITICAL' | w1 = 'FATAL' then
      error_level = 5
   else
      error_level = 9  -- Unknown ???
   endif
   return error_level
---------------------------------------------------------------------------------------

-- Brings a file to the edit window (load it if necessary)
-- Sets up the error bookmarks if necessary
defc mk_bringfile
   parse arg myFileName build_drive build_dir build_number build_error_num Errors_array_ID index
   getfileid myfileid, myFileName
   dir = directory()
   call directory( build_drive||build_dir )
   'e 'myFilename
   call directory( dir )
   parse value .userstring with foo''file_build_number
   if myfileid='' OR file_build_number<>build_number then
      -- The file was not already loaded or the bookmarks are for a previous build
      if myfileid<>'' then  -- Remove previous temp bookmarks
         'deletebmclass' MK_ERROR_MARKTYPE
      endif
      -- set bookmarks
      for i = 1 to build_error_num
         --do_array 3, Errors_array_id, i, Error_parms
         rc = get_array_value( Errors_array_id, i, Error_parms )
--       parse value Error_parms  with FileName''LineNum''ColumnNum''ErrorMsg''ShellLine
         parse value Error_parms  with FileName''LineNum''ColumnNum''foo
         if FileName = myFileName then
            sayerror 'setting bookmark #'i
            markname = 'Error_'index'_'i MK_ERROR_MARKTYPE LineNum ColumnNum
            'setmark' markname
         endif
      endfor
      -- set index
      .userstring = index''build_number
   endif

---------------------------------------------------------------------------------------


-- Creates a shell and start a build in it
-- index     : name given to this build environment, used as a key ( eg projfoo )
-- path      : path in which to start the build ( eg d:\foo )
-- command   : command to start the build ( eg nmake -f foo.mak )
defc MK_build
   universal shell_index -- used to get the id of a created shell
   universal Build_array_id
   universal EPM_Utility_array_ID -- used to retrieve the fileid of a shell form its shellid
   parse arg index path command
   if command='' then
      sayerror 'Missing required arguments.'
      return
   endif
   -- if the array of build environments doesn't exist, create it
   do_array 1, Build_array_id, "Build environments"
   -- look if there is an entry for the given index
   display -2
   --do_array 3, Build_array_id, index, buildargs
   rc = get_array_value( Build_array_id, index, buildargs )
   display 2
   if buildargs='' then
      -- if not do as if it was found (in both cases we'll save it after using it)
      buildargs = '0'
   endif

   parse value buildargs with build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num

   if path='=' then
      path = leftstr(.filename, lastpos('\', .filename)-1)
   endif

;  if path <> '' then
      parse value path with build_drive':'build_dir
      build_drive = build_drive':'
;  endif

;  if command <> '' then
      build_command = command
;  endif

  -- Check if there is an active shell for this build env
  display -2
  --do_array 3, EPM_Utility_array_ID, 'Shell_f'build_shellid, shell_fileid
  rc = get_array_value( EPM_Utility_array_ID, 'Shell_f'build_shellid, shell_fileid )
  rc = 0
  activatefile shell_fileid
  display 2
   build_number = build_number + 1
  if rc=-260 then
     -- activatefile failed -> invalid fileid
     'shell new'
     build_shellid = shell_index
     .userstring = index''build_number -- store the build envir associated to this shell
   endif
   -- go to the chosen directory
   'shell_write' build_shellid build_drive
   'shell_write' build_shellid ' cd ' build_dir
   -- save the shell line in which the build begins
   --do_array 3, EPM_Utility_array_ID, 'Shell_f'build_shellid, build_shell_fileid
   rc = get_array_value( EPM_Utility_array_ID, 'Shell_f'build_shellid, build_shell_fileid )
   build_start_line = build_shell_fileid.last
   -- actually start the build
   'shell_write' build_shellid build_command
   -- save the build environment parameters
   buildargs    = build_drive''build_dir''build_shellid''build_command''build_start_line''build_number''build_error_num
   do_array 2, Build_array_id, index, buildargs
   -- Erase any previous array of errors for this build environment.
   Errors_array_name = 'Errors_'index
   display -2
   do_array 6, Errors_array_id, Errors_array_name
   display 2
   if Errors_array_id<>-1 then
      -- Eradicate this array
      getfileid startid
      activatefile Errors_array_id
      'xcom quit'
      activatefile startid
   endif


---------------------------------------------------------------------------------------

-- Used after mk_build has been called
-- Parse the lines of the build shell and store the error informations
-- If the cursor is on an error line, display this error
-- Else display the first error
-- If an argument is given, it must be the index of the build environment
-- If no argument is given, the build environment is retrieved from the current file .userstring
--  (-> it must have been loaded by the mk_* macros)
defc MK_view_error
   universal Build_array_id
   universal EPM_Utility_array_ID

   -- save the current line
   myline = .line
   parse arg index
   if index='' then
      -- retrieve the environment index we stored in .userstring
      parse value .userstring with index''foo
   endif
   if index='' then
      sayerror 'MK_Build must be called before MK_View_Error.'
      return
   endif
   -- get the environment informations
   --do_array 3, Build_array_id, index, buildargs
   rc = get_array_value( Build_array_id, index, buildargs )
   parse value buildargs with build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
   myerror_num = 0
   ------------------------------------------------------------
   -- If the errors array for this env doesn't exist, create it
   ------------------------------------------------------------
   Errors_array_name = 'Errors_'index
   display -2
   do_array 6, Errors_array_id, Errors_array_name
   display 2
   if Errors_array_id=-1 then
      do_array 1, Errors_array_id, 'Errors_'index
      build_error_num   = 0
      --do_array 3, EPM_Utility_array_id, 'Shell_f'build_shellid, build_shell_fileid
      rc = get_array_value( EPM_Utility_array_id, 'Shell_f'build_shellid, build_shell_fileid )
      for line = build_start_line to build_shell_fileid.last
         getline errorline, line, build_shell_fileid
         if isadefproc( 'mk_parse_errline' ) then
            call mk_parse_errline( errorline, FileName, LineNum, ColumnNum, ErrorMsg, error_level, line )
         else
            call mk_parse_errline_default( errorline, FileName, LineNum, ColumnNum, ErrorMsg, error_level, line )
         endif
         -- was it actually an error line?
         if error_level then
            build_error_num = build_error_num + 1
            Error_parms = FileName''LineNum''ColumnNum''error_level''ErrorMsg''line
            do_array 2, Errors_array_id,  build_error_num, Error_parms
            if line=myline then
               myerror_num = build_error_num
               myErrormsg  = Errormsg
               myfilename  = FileName
            endif
         endif
      endfor
   else
      -- browse the array of errors to find our line
      for i = 1 to build_error_num
         --do_array 3, Errors_array_id, i, Error_parms
         rc = get_array_value( Errors_array_id, i, Error_parms )
         parse value Error_parms with FileName''LineNum''ColumnNum''error_level''ErrorMsg''ShellLine
         if ShellLine=myline then
               myerror_num = i
               myErrormsg  = Errormsg
               myfilename  = FileName
         endif
      endfor
   endif
   ------------------------------------------------------------
   -- End of errors array creation
   ------------------------------------------------------------

   if myerror_num=0 then
      -- The cursor was not on an error line, so display the first error
      --  get MyFileName myerrornum and myerrormsg
      myerror_num = 1
      --do_array 3, Errors_array_id,  myerror_num, Error_parms
      rc = get_array_value( Errors_array_id,  myerror_num, Error_parms )
      parse value Error_parms with myFileName''myLineNum''myColumnNum'' ''myErrorMsg''ShellLine
   endif


   'mk_bringfile' myFileName build_drive build_dir build_number build_error_num Errors_array_id index

   markname = 'Error_'index'_'myerror_num
   'gomark'  markname
   sayerror myErrormsg
   -- set the current error in the environment array
   build_cur_err = myerror_num
   buildargs = build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
   do_array 2, Build_array_id, index, buildargs

---------------------------------------------------------------------------------------

-- Used after mk_build and mk_view_error have been called
-- Display the next error
-- If an argument is given, it must be the index of the build environment
-- If no argument is given, the build environment is retrieved from the current file .userstring
--  (-> it must have been loaded by the mk_* macros)
defc MK_next_err
   universal Build_array_id

   parse arg index min_level
   if index='' | index='=' then
      -- retrieve the environment index we stored in .userstring
      parse value .userstring with index''foo
   endif
   if index='' then
      sayerror 'MK_Build and MK_View_Error must be called before MK_Next_Err.'
      return
   endif
   --do_array 3, Build_array_id, index, buildargs
   rc = get_array_value( Build_array_id, index, buildargs )
   parse value buildargs with build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
   do forever
      build_cur_err = build_cur_err + 1
      Errors_array_name = 'Errors_'index
      do_array 6, Errors_array_id, Errors_array_name
      --do_array 3, Errors_array_id, build_cur_err, error_parms
      rc = get_array_value( Errors_array_id, build_cur_err, error_parms )
      parse value error_parms with FileName''line''column''error_level''Error_msg''ShellLine
      if min_level = '' | error_parms = '' then
         leave
      endif
      if error_level >= min_level then
         leave
      endif
   enddo
   if error_parms<>'' then
      'mk_bringfile' FileName build_drive build_dir build_number build_error_num Errors_array_id index
      markname = 'Error_'index'_'build_cur_err
      'gomark'  markname
      sayerror Error_msg
      -- update build_cur_err
      buildargs = build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
      do_array 2, Build_array_id, index, buildargs
   else
      sayerror ' ------- no more errors ---------- '
   endif

----------------------------------------------------------------------------------------------------

-- Used after mk_build and mk_view_error have been called
-- Display the previous error
-- If an argument is given, it must be the index of the build environment
-- If no argument is given, the build environment is retrieved from the current file .userstring
--  (-> it must have been loaded by the mk_* macros)
defc MK_prev_err
   universal Build_array_id

   parse arg index min_level
   if index='' | index='=' then
      -- retrieve the environment index we stored in .userstring
      parse value .userstring with index''foo
   endif
   if index='' then
      sayerror 'MK_Build and MK_View_Error must be called before MK_Prev_Err.'
      return
   endif
   --do_array 3, Build_array_id, index, buildargs
   rc = get_array_value( Build_array_id, index, buildargs )
   parse value buildargs with build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
   do forever
      build_cur_err = build_cur_err - 1
      Errors_array_name = 'Errors_'index
      do_array 6, Errors_array_id, Errors_array_name
      --do_array 3, Errors_array_id, build_cur_err, error_parms
      rc = get_array_value( Errors_array_id, build_cur_err, error_parms )
      parse value error_parms with FileName''line''column''error_level''Error_msg''ShellLine
      if min_level = '' | error_parms = '' then
         leave
      endif
      if error_level >= min_level then
         leave
      endif
   enddo
   if error_parms<>'' then
      'mk_bringfile' FileName build_drive build_dir build_number build_error_num Errors_array_id index
      markname = 'Error_'index'_'build_cur_err
      'gomark'  markname
      sayerror Error_msg
      -- update cur_err
      buildargs = build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
      do_array 2, Build_array_id, index, buildargs
   else
      sayerror ' ------- no errors before ---------- '
   endif

----------------------------------------------------------------------------------------------------

-- Used after mk_build and mk_view_error have been called
-- Display the current error
-- If an argument is given, it must be the index of the build environment
-- If no argument is given, the build environment is retrieved from the current file .userstring
--  (-> it must have been loaded by the mk_* macros)
defc MK_cur_descr
   universal Build_array_id

   parse arg index min_level
   if index='' | index='=' then
      -- retrieve the environment index we stored in .userstring
      parse value .userstring with index''foo
   endif
   if index='' then
      sayerror 'MK_Build and MK_View_Error must be called before MK_Cur_Descr.'
      return
   endif
   --do_array 3, Build_array_id, index, buildargs
   rc = get_array_value( Build_array_id, index, buildargs )
   parse value buildargs with build_drive''build_dir''build_shellid''build_command''build_cur_err''build_start_line''build_number''build_error_num
   Errors_array_name = 'Errors_'index
   do_array 6, Errors_array_id, Errors_array_name
   --do_array 3, Errors_array_id, build_cur_err, error_parms
   rc = get_array_value( Errors_array_id, build_cur_err, error_parms )
   if error_parms<>'' then
      parse value error_parms with FileName''line''column''error_level''Error_msg''ShellLine
      'mk_bringfile' FileName build_drive build_dir build_number build_error_num Errors_array_id index
      markname = 'Error_'index'_'build_cur_err
      'gomark'  markname
      sayerror Error_msg
   else
      sayerror ' ------- no current error ---------- '
   endif

EA_comment 'This is a toolbar "actions" file which lets you run a MAKE in a shell and parse the output.'
