/****************************** Module Header *******************************
*
* Module Name: recomp.e
*
* This macro is used by recomp to query names and cursor positions of loaded
* files within active EPM windows and for to reposition the cursor within
* reloaded files. The compiled macro is attached to recomp.exe as a resource.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: recomp.e,v 1.6 2003-09-01 01:34:51 aschn Exp $
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

/* ----------- Symbols used in common.h and recomp.e ----------- */
/*                        KEEP IN SYNC !                         */

/* Delimter character for the file list    */
FILE_DELIMITER = '|';

/* special tokens for filelist handling */
TOKEN_MAXCOUNT_FILELIST = "MAXCOUNT:";
TOKEN_FILEINFO          = "FILE:";
TOKEN_END_OF_FILELIST   = "COMPLETE:";
TOKEN_UNSAVED           = "UNSAVED:"
TOKEN_ERROR             = "ERROR:"

/* ------------------------------------------------------------- */

defc recomp =

   /* If CurEditCmd was set to 'SETPOS', then the pos will not be */
   /* restored from EA 'EPM.POS' at defload (LOAD.E).             */
   /* Usually CurEditCmd is set to doscmdline (MAIN.E), but file  */
   /* loading via DDE doesn't use the 'edit' cmd.                 */
   universal CurEditCmd
   CurEditCmd = ''

   /* check parameters */
   parse arg RecompAction RecompOption;
   RecompAction = translate( RecompAction);
   RecompOption = translate( RecompOption);

   /* select function */
   if (RecompAction = 'CLOSEWINDOW') then
      call recomp_closewindow();

   elseif (RecompAction = 'SETPOS') then
      sayerror 0;
      CurEditCmd = 'SETPOS'
      call prestore_pos( RecompOption);

   elseif (RecompAction = 'GETFILELIST') then

      if (RecompOption = 'DISCARDUNSAVED') then
         call recomp_getfilelist( 1);
      elseif (RecompOption = 'FAILONUNSAVED') then
         call recomp_getfilelist( 0);
      else
         /* invalid option */
         call recomp_send_data( RecompAction, TOKEN_ERROR);
         return;
      endif;

   else
      /* invalid action */
      call recomp_send_data( RecompAction, TOKEN_ERROR);
      return;
   endif;

   return;

/* =========================================================================== */

/* send data via DDE  */

defproc recomp_send_data( DdeItem, DdeData)

   /* EPM DDE BUG: posting the first DDE message seems */
   /* to reset .line to 1 and .cursory to 2 :-(        */
   /* for simplicity we always save and restore it     */
   call psave_pos( save_pos);

   /* append zero byte do data */
   DdeData = DdeData''atoi( 0);
   call windowmessage(1,  getpminfo( 5 ), -- EPMINFO_EDITCLIENT
                      5478,    -- EPM_EDIT_DDE_POST_MSG
                      ltoa( offset( DdeItem) || selector( DdeItem), 10),
                      ltoa( offset( DdeData) || selector( DdeData), 10));

   /* restore pos */
   call prestore_pos( save_pos);
   return

/* =========================================================================== */

/* close EPM window here - do not return any data */

defproc recomp_closewindow()

   getfileid startfid
   do i = 1 to filesinring( 1)  -- 0: only visible files, 1: include also hidden files
      /* turn of modified flag for all files. Unsaved files */
      /* are to be handled by calling GETFILELIST before !  */
      .modify = 0;
      next_file;
      getfileid fid
      if fid = startfid then
         leave
      endif
   enddo;

   /* finally close window */
   'CLOSE';
   return

/* =========================================================================== */

/* return filelist, sending one DDE item per file and handling unsaved files */

defproc recomp_getfilelist( fDiscardUnsaved)

   RecompAction = 'GETFILELIST'

   /* send item #1: send maximum count to allow proper memory allocation in RECOMP */
   MaxFiles = filesinring( 1);  -- 0: only visible files, 1: include also hidden files
   call recomp_send_data( RecompAction, TOKEN_MAXCOUNT_FILELIST''MaxFiles);

   /* save current file id for later restore */
   getfileid firstfid;

   /* select next file, so that previous selected file will be the last one reloaded */
   next_file;

   /* loop thru all files now */
   ResultData = TOKEN_END_OF_FILELIST;
   getfileid startfid;
   do i = 1 to MaxFiles  -- just an upper limit to prevent looping forever

      /* ignore all filenames starting with a period or hidden */
      if ((substr( .filename, 1, 1) <> '.') & .visible) then

         /* bail out here on unsaved files*/
         if (fDiscardUnsaved = 0) then
            if (.modify) then
               ResultData = TOKEN_UNSAVED;
               leave;
            endif;
         endif;

         /* send items #2 to n-1: send info per filename */
         if (.modify = 0) then
            /* send info for this file */
            FileInfo = TOKEN_FILEINFO''.filename''FILE_DELIMITER''.line .col .cursorx .cursory;
            call recomp_send_data( RecompAction, FileInfo);
         endif;

      endif

      next_file;
      getfileid fid
      if fid = startfid then
         leave
      endif

   enddo;

   /* if all is saved well, restore to the file from which we started,          */
   /* otherwise leave unsaved file on top to be at hand after RECOMP complained */
   if (ResultData <> TOKEN_UNSAVED) then
      activatefile firstfid;
   endif;

   /* send item n: send either token for 'end of list' or for 'unsaved' status */
   call recomp_send_data( RecompAction, ResultData);

   return

