/****************************** Module Header *******************************
*
* Module Name: deleteconfigvalue.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: deleteconfigvalue.e,v 1.4 2006-03-13 18:25:49 aschn Exp $
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

/*
@@NepmdDeleteConfigValue@PROTOTYPE
rc = NepmdDeleteConfigValue( Handle, ConfPath);

@@NepmdDeleteConfigValue@CATEGORY@CONFIG

@@NepmdDeleteConfigValue@SYNTAX
This function deletes a value from the configuration repository of the
[=TITLE] installation.

@@NepmdDeleteConfigValue@PARM@Handle
This parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdDeleteConfigValue@PARM@ConfPath
This parameter specifies the [.IDPNL_REGISTRY_NAMESPACE path] under which the
configuration value is to be deleted.

@@NepmdDeleteConfigValue@RETURNS
*NepmdDeleteConfigValue* returns an OS/2 error code or zero for no error.

@@NepmdDeleteConfigValue@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdDeleteConfigValue*
  - or
- *DeleteConfigValue*


Executing this command will delete
the configuration value with the pathname
.sl compact
- *\NEPMD\Test\Nepmdlib\TestKey*
.el
from the configuration repository of the [=TILE]
and display the result within the status area.

@@
*/
/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdDeleteConfigValue, DeleteConfigValue =

 rc = NepmdDeleteConfigValue( 0, NEPMD_TEST_CONFIGPATH);

 if (rc > 0) then
    sayerror 'config value not deleted, rc='rc;
    return;
 endif

 sayerror 'config value  "'NEPMD_TEST_CONFIGPATH'" successfully deleted!';

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdDeleteConfigValue                             */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdDeleteConfigValue( Handle, ConfPath);            */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdDeleteConfigValue( HCONFIG hconfig,     */
/*                                          PSZ pszRegPath);     */
/* ------------------------------------------------------------- */

; ---------------------------------------------------------------------------
; Bug in F:\dev\netlabs\nepmd\src\gui\common\LIBREG.C:425:_removeKeyFromContainerList
; Bug in %NEPMD_CVSDIR%\src\gui\common\LIBREG.C:425:_removeKeyFromContainerList  <-- Alt+1 doesn't work here
;
; This always leaves garbage in RegContainer -> \NEPMD\User\SavedRings\1:
; 'delconfig \NEPMD\User\SavedRings\1\Posn1'

; How to reproduce it:
;
; 1. Load 1 or more files in EPM's ring (not .Unnamed).
;    Restart EPM via Restart command or Options -> Macros -> More Restart EPM
;    This creates a correct entry (\0 is changed to . here):
;
;       NEPMD.INI -> RegContainer -> \NEPMD\User\SavedRings\1 ->
;       Entries.File1.hwnd.Posn1.WorkDir.
;
;    because a workaround is used in LINKCMDS.E:132:RingWriteFilePosition.
;
; 2. Execute the following defc:
;
;       DelConfig \NEPMD\User\SavedRings\1\Posn1
;
;    Then the RegContainer entry turns to garbage:
;
;       Entries.File1.hwndPosn1.WorkDir.
;
;    Entries and File1 are both deletable correctly. Trying to delete WorkDir
;    deletes only the leading \0, as with Posn1.
;
;    Note: The bug apparently applies only to the first sublevel of the entire
;          container path, in the given example not to \NEPMD\User\SavedRings,
;          but to \NEPMD\User\SavedRings\1.
/*
defc DelConfig
   KeyPath = arg(1)
   if KeyPath = '' then
      return
   endif
   rc = NepmdDeleteConfigValue( 0, KeyPath)
   if (rc > 0) then
      sayerror 'Config value "'KeyPath'"not deleted, rc='rc
   endif
*/
; ---------------------------------------------------------------------------

compile if 1
; ---------------------------------------------------------------------------
; Use a workaround until this bug is fixed:
; Difference for the syntax: nepmd_hini is always used as handle now,
;                            ignoring what is specified as first arg.
defproc NepmdDeleteConfigValue( Handle, ConfPath)
   universal nepmd_hini
   -- Handle is not used here

   -- Delete ConfPath = Path'\'Key
   rc = SetProfile( nepmd_hini, 'RegKeys', ConfPath, '')

   -- Remove Key from container entry. Remove container itself from its
   -- parent container, if Key was the last entry.
   NextPath = ConfPath
   do forever
      -- Remove entry from parent path
      lp = lastpos( '\', NextPath)
      Key = substr( NextPath, lp + 1)
      if lp = 0 then
         leave
      else
         ParentPath = substr( NextPath, 1, lp - 1)
      endif
      Containers = QueryProfile( nepmd_hini, 'RegContainer', ParentPath)
      next = Containers
      -- Although Container elements are prepended with a zeros, enquoting
      -- with zeros is required to not find the wrong Key
      p = pos( \0''Key\0, \0''Containers\0)
      if p > 0 then
         next = substr( Containers, 1, p - 1) ||
                substr( Containers, p + length( Key) + 1)
         --sayerror 'Containers = ('translate( Containers, '|', \0)'),' ||
         --         ' Key ['Key'] removed from 'ParentPath' = ['translate( next, '|', \0)']'
         call SetProfile( nepmd_hini, 'RegContainer', ParentPath, next)
      else
         --sayerror 'Containers = ('translate( Containers, '|', \0)'),' ||
         --         ' Key ['Key'] not found in 'ParentPath' = ['translate( next, '|', \0)']'
      endif
      if next > '' then
         -- Container has some more entries, so it can't be removed from
         -- its parent.
         leave
      else
         -- Last key removed from container, so process next path level
         -- above to remove the container itself from its parent container.
         NextPath = ParentPath
      endif
   enddo

   return rc

compile else
; ---------------------------------------------------------------------------
; This uses the buggy function:
defproc NepmdDeleteConfigValue( Handle, ConfPath) =

 /* use zero as handle if none specified */
 if (strip( Handle) = '') then
    Handle = 0;
 endif

 /* prepare parameters for C routine */
 ConfPath  = ConfPath''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdDeleteConfigValue",
                  atol( Handle)      ||
                  address( ConfPath));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;
; ---------------------------------------------------------------------------
compile endif

