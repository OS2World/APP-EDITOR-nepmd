/****************************** Module Header *******************************
*
* Module Name: epmchgpal.cmd
*
* Change EPM''s standard 16-color palette for keyword hiliting
*
* Copyright (c) Netlabs EPM Distribution Project 2003
*
* $Id: epmchgpal.cmd,v 1.2 2003-12-12 20:17:08 aschn Exp $
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

/* REXX */

call RxFuncAdd 'SysLoadFuncs', 'REXXUTIL', 'SysLoadFuncs'
call SysLoadFuncs

call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
call WPToolsLoadFuncs

parse source . . CmdFile
CmdFile = strip(CmdFile)
CmdFilename = filespec( 'N', CmdFile)
lp = lastpos( '\', CmdFile)
CmdFileDir = substr( CmdFile, 1, max( lp - 1, 0))

say
say CmdFileName' - Change EPM''s standard 16-color palette for keyword hiliting.'

env                = 'OS2ENVIRONMENT'
DllName            = 'etke603.dll'
Signature          = 'GpiCreatePS failed'
SaveFileExt        = 'sav'
ColorIniName       = 'EPMColor.ini'
NetlabsBinDir      = value( 'NEPMD_ROOTDIR', , env)'\netlabs\bin'
MyepmBinDir        = value( 'NEPMD_ROOTDIR', , env)'\myepm\bin'
WorkDir            = MyepmBinDir  /* Where palettes and ColorIni is located or will be created */
TmpDir             = MyepmBinDir'\tmp'  /* Better use a unique name in %TMP%? */
PalTitlePrefix     = 'EPM color palette - '
ObjectIdPrefix     = 'EPM_PAL_'
StandardName       = 'Standard'
MyColorsName       = 'MyColors'
DefaultPalNameList = StandardName' 'MyColorsName
StandardColors     = ,
   '0x808080,0x0000FF,0x00FF00,0x00FFFF,0xFF0000,0xFF00FF,0xFFFF00,0xFFFFFF,' ||,
   '0x000000,0x000099,0x009900,0x009999,0x990000,0x990099,0x999900,0xCCCCCC'
/* The OS/2 color palette starts with the bottom line. So exchange the 8 top colors */
/* with the 8 bottom colors. The index used here goes from 1 to 16 to make it easy  */
/* for use with the words and wordpos functions. Note that the predefined values go */
/* from 0 to 15. In the docs LIGHT_GREY is called 'pale grey'. That is not defined. */
PalIndexList       = ,
   '9 10 11 12 13 14 15 16' ||,
   ' 1 2 3 4 5 6 7 8'
ColorList          = ,
   'BLACK BLUE GREEN CYAN RED MAGENTA BROWN LIGHT_GREY' ||,
   ' DARK_GREY LIGHT_BLUE LIGHT_GREEN LIGHT_CYAN LIGHT_RED LIGHT_MAGENTA YELLOW WHITE'
SysSleepAmount = 0.4

parse arg args
args = strip(args)
Step = args

if Step = '' then
   do
      say
      say 'Requirements:'
      say '  -  ETKE603.DLL of EPM 603b (no other version tested)'
      say '  -  LXLITE.EXE, LXLITE.CFG and UNLOCK.EXE of lxLite by Andrew Pavel Zabolotny'
      say '  -  WPTOOLS.DLL by Henk Kelder'
      say 'The method is stolen from the EPMPAL package, available e.g. at Hobbes.'
      say 'How does it work:'
      say '  Either edit 'ColorIniName' and run step 3 only'
      say '  or use palette objects (run this script 3 times to change your EPM colors):'
      say '  1  Two or more color palettes will be created, depending on 'ColorIniName'.'
      say '  -  Then change the 'MyColorsName' palette to your needs (by hand).'
      say '  2  Save the palette(s) to 'ColorIniName'.'
      say '  3  The file 'DllName' will be backuped and patched.'
      say '  -  You must restart the EPM to see any effect.'
      say 'Select one step (can also be submitted as arg for this script):'
      say '  1  CREATEPALETTE   Create palette objects: 'StandardName' and 'MyColorsName
      say '     --> Edit the 'MyColorsName' color palette afterwards.'
      say '  2  SAVEPALETTE     Save colors of all found palettes to 'ColorIniName
      say '  3  PATCHDLL        Read the colors from 'ColorIniName', select one palette,'
      say '                     backup the DLL, copy it to a TmpDir, patch it, unlock the'
      say '                     DLL and overwrite it with the patched version.'
      say 'Your choice (1...3 or the keywords or Ctrl+C to cancel):'
      pull answer
      Step = strip(answer)
   end

select
   when abbrev( 'C', Step) then Step = 'CREATEPALETTE'
   when abbrev( 'S', Step) then Step = 'SAVEPALETTE'
   when abbrev( 'P', Step) then Step = 'PATCHDLL'
   when Step = 1           then Step = 'CREATEPALETTE'
   when Step = 2           then Step = 'SAVEPALETTE'
   when Step = 3           then Step = 'PATCHDLL'
otherwise
   do
      say 'Unknown option "'answer'".'
      return
   end
end

say
say 'Executing step = 'Step

call Cleanup
call SysMkDir WorkDir
call SysMkDir TmpDir
call directory WorkDir

/* Check presence of extended environment first */
if value( 'NEPMD_ROOTDIR', , env) = '' then
   do
      'NEPMD''s extended environment must be set to run this script.'
      'Either run it from an EPM command window or shell or run epmenv.cmd first.'
   end

if stream( MyepmBinDir'\'ColorIniName, 'C', 'QUERY EXISTS' ) = '' then
   do
      say 'Copying Netlabs'' 'ColorIniName' to 'MyepmBinDir
      rc = SysCopyObject( NetlabsBinDir'\'ColorIniName, MyepmBinDir)
   end

select
   when Step = 'CREATEPALETTE' then
      do
         call CreatePalettes
      end
   when Step = 'SAVEPALETTE' then
      do
         call SavePalettes
      end
   when Step = 'PATCHDLL' then
      do
/*
         rc = SavePalettes()
         if rc = 0 then
*/
         rc = BackupDll()
         if rc = 0 then
            rc = PatchDll()
         if rc = 0 then
            do
               '@pause'
               call OverwriteDll
               call Cleanup
            end
      end
otherwise
   nop
end

return


Cleanup:
   SavedDir = directory()
   call directory WorkDir
   call SysFileTree TmpDir'\*', 'Found.', 'FO'
   do f = 1 to Found.0
      call SysFileDelete Found.f
      call SysFileDelete Found.f
   end
   call SysFileTree TmpDir'\*', 'Found.', 'DO'
   do f = 1 to Found.0
      call SysRmDir Found.f
   end
   call SysRmDir TmpDir
   call directory SavedDir
   return

GetUpdateReplaceFail: procedure expose ColorIniName
   ObjectId           = arg(1)
   PalName            = arg(2)
   StandardColorsFlag = arg(3)
   UpdateReplaceFail = 'F'
   rc = SysSetObjectData( ObjectId, '')
   if rc = 1 then /* if exists */
      do
         rc = WPToolsQueryObject( ObjectId, 'Class', 'Title', 'Setup', 'Location')
         if rc = 1 then
            do
               say 'Color palette "'PalName'" with ObjectId 'ObjectId' already exists'
               say 'in Location "'Location'".'
            end
         else
            say Object '"'PalName'" with ObjectId 'ObjectId' already exists.'
         do until answer = 'Y' | answer = 'N'
            if StandardColorsFlag = 1 then
               say 'Reset it to Standard EPM colors? (Y/N)'
            else
               say 'Overwrite it with colors just read from 'ColorIniName'? (Y/N)'
            pull answer
         end
         answer = strip(answer)
         if answer = 'Y' then
            UpdateReplaceFail = 'R'
      end
/*
   else
      say PalName' not found. It will be created now.'
*/
   return UpdateReplaceFail


CreatePalettes:
   PalNameList = GetPalNameListFromIni()  /* read PalNames from ColorIni */
   if PalNameList = '' then
      PalNameList = DefaultPalNameList

   AbstractObj.0 = 0
   rc = WPToolsFolderContent( WorkDir, AbstractObj)
   do a = 1 to AbstractObj.0
      rc = WPToolsQueryObject( AbstractObj.a, 'Class', 'Title', 'Setup', 'Location')
      if Class = 'WPColorPalette' then
         do
            parse value Setup with 'OBJECTID='ObjectId
            parse value ObjectId with ObjectId','
            parse value ObjectId with ObjectId';'
            parse value Title with (PalTitlePrefix) PalName
            do i = 1 to words(PalNameList)
               if PalName = word( PalNameList, i) then
                  do
                     if ObjectId = '' then  /* no ObjectId set, do it now */
                        do
                           ObjectId  = '<'ObjectIdPrefix''translate(PalName)'>'
                           rc = WPToolsSetObjectData( AbstractObj.a, 'OBJECTID='ObjectId';')
                           AsynchronFlag = 0
                           rc = SysSaveObject( ObjectId, AsynchronFlag)
                           leave i
                        end
                  end
            end /* do i */
         end
      end

   do i = 1 to words(PalNameList)
      PalName = word( PalNameList, i)
      PalTitle  = PalTitlePrefix''PalName
      ObjectId  = '<'ObjectIdPrefix''translate(PalName)'>'
      if PalName = StandardName then
         do
            Colors = StandardColors
            UpdateReplaceFail = 'R'
         end
      else
         do
            StandardColorsFlag = 0
            HexFlag = 1
            Colors = ReadColorsFromIni(PalName, HexFlag)  /* read colors from ColorIni */
            if Colors = '' then                           /* e.g. if ColorIni doesn't exist */
               do
                  Colors = StandardColors                 /* set Colors to StandardColors */
                  StandardColorsFlag = 1
               end
            UpdateReplaceFail = GetUpdateReplaceFail( ObjectId, PalName, StandardColorsFlag)
         end
      PalClass    = 'WPColorPalette'
      PalSetup = ,
         'XCELLCOUNT=8;'        ||,
         'YCELLCOUNT=2;'        ||,
         'XCELLWIDTH=48;'       ||,
         'YCELLHEIGHT=51;'      ||,
         'XCELLGAP=9;'          ||,
         'YCELLGAP=13;'         ||,
         'COLORS='Colors';'     ||,
         'TITLE='PalTitle';'    ||,
         'NOPRINT=YES;'         ||,
         'HIDEBUTTON=DEFAULT;'  ||,
         'MINWIN=DEFAULT;'      ||,
         'CCVIEW=DEFAULT;'      ||,
         'DEFAULTVIEW=DEFAULT;' ||,
         'OBJECTID='ObjectId';'
      rc = SysCreateObject( PalClass, PalTitle, WorkDir, PalSetup, UpdateReplaceFail)
      if rc = 1 then
         say 'Creating color palette "'PalTitle'".'
      AsynchronFlag = 0
      rc = SysSaveObject(ObjectId, AsynchronFlag)
   end
   return


GetPalNameListFromIni: procedure expose WorkDir ColorIniName
   PalNameList = ''
   ColorIni = WorkDir'\'ColorIniName
   rc = stream( ColorIni, 'C', 'OPEN READ')
   if rc <> 'READY:' then
      return ''
   do while chars(ColorIni) > 0
      line = linein(ColorIni)
      parse value line with '['nextApplication']'
      select
         when left( line, 1) = ';' then
            nop
         when strip(line) = '' then
            nop
         when nextApplication <> '' then
            PalNameList = PalNameList' 'nextApplication
      otherwise
         nop
      end  /* select */
   end  /* do while */
   rc = stream( ColorIni, 'C', 'CLOSE')
   PalNameList = strip(PalNameList)
   return PalNameList


/* Get colors from ColorIni */
/* arg(1)  = PalName (optional), default = 'MyColors' */
/* Returns = ColorString (without the keyword COLORS=) or empty */
ReadColorsFromIni: procedure expose MyColorsName WorkDir ColorIniName ColorList PalIndexList ColorIni
   PalName = arg(1)
   if arg(1) = '' then
      PalName = MyColorsName
   HexFlag = arg(2)
   ColorIni = WorkDir'\'ColorIniName
   rc = stream( ColorIni, 'C', 'OPEN READ')
   if rc <> 'READY:' then
      return ''
   Application = ''
   RGBhex.0 = 0
   BGRchr.0 = 0
   do while chars(ColorIni) > 0
      line = linein(ColorIni)
      select
         when left( line, 1) = ';' then
            nop
         when strip(line) = '' then
            nop
         when left( line, 1) = '[' then
            do
               p2 = pos( ']', line)
               if p2 > 0 then
                  do
                     nextApplication = substr( line, 2, p2 - 2)
                     if nextApplication = PalName then
                        Application = nextApplication  /* PalName found as Application */
                     else
                        Application = ''  /* nextApplication is other, reset Application */
                  end
            end
      otherwise
         do
            parse value line with nextKey '=' nextEntry
            /* it must be a 'Key = Entry' line */
            nextKey   = strip(nextKey)
            nextEntry = strip(nextEntry)
            if Application = '' then
               iterate
            if nextKey = '' then
               iterate
            if wordpos( nextKey, ColorList) > 0 then
               do
                  ColorName = nextKey
                  red       = word( nextEntry, 1)
                  green     = word( nextEntry, 2)
                  blue      = word( nextEntry, 3)
                  redhex    = right( d2x(red), 2, '0')
                  greenhex  = right( d2x(green), 2, '0')
                  bluehex   = right( d2x(blue), 2, '0')
                  n   = wordpos( ColorName, ColorList)
                  idx = wordpos( n, PalIndexList)      /* idx = 1...16 */
                  RGBhex.idx = '0x'redhex''greenhex''bluehex
                  BGRchr.n = x2c(bluehex)''x2c(greenhex)''x2c(redhex)'00'x
                  RGBhex.0 = RGBhex.0 + 1
                  BGRchr.0 = RGBhex.0
               end
         end
      end  /* select */
   end  /* do while */
   rc = stream( ColorIni, 'C', 'CLOSE')
   Colors = ''
   if HexFlag = 1 then
      do idx = 1 to RGBhex.0
         if idx = 1 then
            Colors = RGBhex.idx
         else
            Colors = Colors','RGBhex.idx
      end
   else
     do n = 1 to BGRchr.0
        Colors = Colors''BGRchr.n
     end
   return Colors


SavePalettes:
   ColorIni = WorkDir'\'ColorIniName
   /* Get PalNames from all palette objects */
   rc = WPToolsFolderContent( WorkDir, AbstractObj)
   i = 0
   do a = 1 to AbstractObj.0
      rc = WPToolsQueryObject( AbstractObj.a, 'Class', 'Title', 'Setup', 'Location')
      if Class = 'WPColorPalette' then
         do
            parse value Setup with ';COLORS='Colors';' .
            parse value Title with (PalTitlePrefix) PalName
            if Colors <> '' & PalName <> '' then
               do
                  if wordpos( PalNameList, PalName) > 0 then
                     do
                        'Color palette "'PalTitle'" found multiple times in 'WorkDir'.'
                        'Correct the error by deleting the superfluos one.'
                        return 1
                     end
                  i = i + 1
                  PalName.0 = i
                  if PalName = StandardName then
                     say 'Found standard palette: 'PalName
                  else
                     say 'Found user palette    : 'PalName
                  PalName.i = PalName
                  Colors.i  = Colors
                  PalNameList = PalNameList' 'PalNameList
               end

         end
   end

   if PalName.0 > 0 then
      do
         if stream( ColorIni, 'C', 'QUERY EXISTS') <> '' then
            do
               say '"'ColorIni'" already exists.'
               say 'It will be overwritten with the settings from the color palette(s).'
               answer = ''
               do while (answer <> 'Y' & answer <> 'N')
                  say 'Press ''Y'' to continue or ''N'' to cancel.'
                  pull answer
                  answer = translate(answer)
               end
               if answer = 'N' then
                  do
                     say 'Restart this script and select another parameter.'
                     return 1
                  end
            end
         call SysFileDelete ColorIni
      end
   do s = 1 to 3
      if stream( ColorIni, 'C', 'QUERY EXISTS') = '' then
         leave
      else
         call SysSleep SysSleepAmount
   end /* do s */

   do i = 1 to PalName.0
      PalName = PalName.i
      Colors  = Colors.i
      call lineout ColorIni, '['PalName']'
      call lineout ColorIni, left( '; Name in EPM', 13)'   -R- -G- -B-'
      rest = Colors
      n = 0
      ColorName.0 = 0
      ColorValues. = ''
      do while rest <> ''
         parse value rest with '0x'next','rest
         parse value next with redhex +2 greenhex +2 bluehex
         if redhex = '' | greenhex = '' | bluehex = '' then
            return 1
         red   = x2d(redhex)
         green = x2d(greenhex)
         blue  = x2d(bluehex)
         n = n + 1
         ColorName.n = word( ColorList, n)
         ColorName.0 = n
         idx = word( PalIndexList, n)
         ColorValues.idx = right( red, 3)' 'right( green, 3)' 'right( blue, 3)
      end
      do n = 1 to ColorName.0
         call lineout ColorIni, left( ColorName.n, 13)' = 'ColorValues.n
      end
      call lineout ColorIni, ''
   end
   rc = stream( ColorIni, 'C', 'CLOSE')
   say 'Saved 'PalName.0' color palettes to 'ColorIni'.'
   return 0


BackupDll:

   DllFullName = FindLibPath(DllName)
   if DllFullName = '' then
      do
         say DllName 'not found in LIBPATH.'
         return 1
      end

   WorkDllFullName = TmpDir'\'DllName
   if translate(DllFullName) <> translate(WorkDllFullName) then
      do
/*
         /* not required, copy does it itself */
         call SysFileDelete WorkDllFullName /* delete it first, otherwise it will be found first if '.' is in LIBPATH */
         do s = 1 to 3
            if stream( WorkDllFullName, 'C', 'QUERY EXISTS') = '' then
               leave
            else
               call SysSleep SysSleepAmount
         end /* do s */
*/
      end

   PatchDllDirectly = 0
   if translate(DllFullName) = translate(WorkDllFullName) then
      do forever
         say DLLFullName' is located in WorkDir.'
         say 'Do you really want to patch the DLL found in the WorkDir?'
         say 'If not, typein the path of 'DllName
         say 'or Return -> 'GetBootDrive()'\os2\apps\dll.'
         say 'Otherwise press ''Y'' to continue or Ctrl+C to cancel.'
         parse pull answer
         answer = strip(answer)

         if translate(answer) = 'Y' then
            do
               PatchDllDirectly = 1
               leave
            end

         if answer = '' then
            checkfile = GetBootDrive()'\os2\apps\dll'
         else
            checkfile = answer
         next = stream( checkfile, 'C', 'QUERY EXISTS')
         if next = '' then
            do
               '"'DllFullName'" not found.'
               iterate
            end
         else
            do
               if translate(next) = translate(WorkDllFullName) then
                  do
                     'You have selected the same DLL again.'
                     iterate
                  end
               else
                  do
                     DllFullName = next
                     Found = 1
                     say '"'DllFullName'" selected.'
                     leave
                  end
            end
      end /* do forever */

   if PatchDllDirectly = 1 then
      do
         say 'Patching the DLL directly. We have to unlock it now:'
         'unlock' DllFullName
      end
   else
      do
         'copy' DllFullName WorkDllFullName
         if rc <> 0 then
            do
               say '"'DllFullName'" not copied to "'WorkDir'". rc = 'rc
               return 1
            end
      end
/*
   say 'copy: 'DllFullName' -> 'WorkDir
   rc = SysCopyObject( DllFullName, WorkDir)
   if rc <> 1 then
      do
         say '"'DllFullName'" not copied to "'WorkDir'". rc = 'rc
         return 1
      end
*/

   lp1 = lastpos( '\', DllFullName)
   DllDir = substr( DllFullName, 1, max( lp1 - 1, 0))
   lp2 = lastpos( '.', DllFullName)
   DllBaseName = substr( DllFullName, lp1 + 1, max( lp2 - lp1 - 1, 0))

   BackupName = DllBaseName'.'SaveFileExt
   BackupFullName = stream( DllDir'\'BackupName, 'C', 'QUERY EXISTS')
   if BackupFullName = '' then
      do
         'copy' DllFullName DllDir'\'BackupName
         if rc <> 0 then
            do
               say '"'DllFullName'" not backuped as "'BackupName'". rc = 'rc
               return 1
            end
/*
         say 'copy: 'DllFullName' -> 'DllDir'\'BackupName
         rc = SysCopyObject( DllFullName, DllDir'\'BackupName)
         if rc <> 1 then
            do
               say '"'DllFullName'" not backuped as "'BackupName'". rc = 'rc
               return 1
            end
*/
         do s = 1 to 3
            BackupFullName =  stream( DllDir'\'BackupName, 'C', 'QUERY EXISTS')
            if BackupFullName <> '' then
               leave
            else
               call SysSleep SysSleepAmount
         end /* do s */
      end
   else
      do
         say DllDir'\'Backupname 'already exists. No backup required.'
      end
   call SysSetObjectData BackupFullName, 'TITLE='BackupName';'
   return 0


FindLibPath:
   DllName = arg(1)
   DllFullName = ''
   BootDrive = GetBootDrive()
   LibPathDirs = GetIniValue( BootDrive'\config.sys', '', 'LIBPATH')
   rest = LibPathDirs
   do while rest <> ''
      parse value rest with Dir';'rest
      next = stream( Dir'\'DllName, 'C', 'QUERY EXISTS')
      if next <> '' then
         do
            DllFullName = next
            leave
         end
   end
   say 'Found Dll in Libpath: 'DllFullName
   return DllFullName


GetBootDrive:
   GetOS2BootDrive: procedure
   signal on syntax name GetBootDrive2
   BootDrive = SysBootDrive()
GetBootDrive2:
   if BootDrive = '' then
      do
         Path = value( 'PATH', , env)
         parse upper value Path with '\OS2\SYSTEM' -2 BootDrive +2
      end
   return BootDrive


GetIniValue:
   File                = arg(1)
   ApplicationList     = arg(2)
   if ApplicationList  = '' then
      ApplicationList  = 'ALL:'
   Key                 = arg(3)

   Application = ''
   rc = stream( File, 'C', 'OPEN READ')
   do while chars(File) > 0
      line = linein(File)
      select
         when left( line, 1) = ';' then
            nop
         when strip(line) = '' then
            nop
         when left( line, 1) = '[' then
            do
               p2 = pos( ']', line)
               if p2 > 0 then
                  do
                     nextApplication = substr( line, 2, p2 - 2)
                     if wordpos( nextApplication, ApplicationList) > 0 | ApplicationList = 'ALL:' then
                        Application = nextApplication
                     else
                        Application = ''  /* nextApplication is other, reset Application */
                  end
            end
      otherwise
         do
            parse value line with nextKey '=' nextEntry
            /* it must be a 'Key = Entry' line */
            nextKey   = strip(nextKey)
            nextEntry = strip(nextEntry)
            if ApplicationList <> 'ALL:' & Application = '' then
               iterate
            if nextKey = '' then
               iterate
            else
               do
                  if nextKey = Key then
                     do
                        Entry = nextEntry
                        leave /* key found */
                     end
               end
         end /* do */
      end /* select */
   end /* do while */
   rc = stream( File, 'C', 'CLOSE')
   return Entry



PatchDll:
   PalNameList = GetPalNameListFromIni()  /* read PalNames from ColorIni */

   do i = 1 to words( PalNameList)
      PalName.i = word( PalNameList, i)
      PalName.0 = i
   end
   if PalName.0 = 0 then
      do
         say 'No color palettes found in 'ColorIniName
         return 1
      end
   if PalName.0 = 1 then
      PalName = PalNameList
   else
     do
        say 'Multiple color palettes found in "'ColorIniName'".'
        say 'Select one by the index (index = 1...'PalName.0'):'
        do i = 1 to PalName.0
           say i'  'PalName.i
        end
        pull answer
        do while answer < 1 | answer > PalName.0
           say 'Select one by the index (index = 1...'PalName.0'):'
           pull answer
        end
        PalName = PalName.answer
     end

   HexFlag = 0
   ColorString = ReadColorsFromIni( PalName, HexFlag)

   WorkDll = WorkDllFullName
   'lxlite /x' WorkDll
   if rc <> 0 then
      do
         say 'lxLite exits with rc = 'rc
         return 1
      end

   say 'Patching the Dll "'WorkDll'"...'
   len = chars(WorkDll)
   Contents = charin( WorkDll, , len)
   call stream WorkDll, 'C', 'CLOSE'
   p2 = pos( Signature, Contents)
   if p2 = 0 then
      do
         say 'Signature "'Signature'" not found in 'WorkDllFullName
         return 1
      end
   p1 = p2 - 64  /* Get the 64 chars before the signature */
/*
   say 'Col(p1) = 619 - 65 = '619 - 64  /* Col no in DLL, loaded as Text in EPM. Line = 3184 */
   /* for testing: show Colors from Dll */
   ColorString = substr( Contents, p1, 64)
   rest = ColorString
   say ColorString
   n = 0
   do while rest <> ''
      parse value rest with B +1 G +1 R +1 Z +1 rest
      n = n + 1
      ColorName = word( ColorList, n)
      ColorValues = right( c2x(R), 2, '0')''right( c2x(G), 2, '0')''right( c2x(B), 2, '0')
      say left( n, 2)': 'left( Colorname, 13)' = 0x'ColorValues' length(rest) = 'length(rest)
      '@pause'
   end
*/
   Contents = overlay( ColorString, Contents, p1)
   call SysFileDelete WorkDll
   do s = 1 to 3
      if stream( WorkDll, 'C', 'QUERY EXISTS') = '' then
         leave
      else
         call SysSleep SysSleepAmount
   end /* do s */
   call charout WorkDll, Contents
   call stream WorkDll, 'C', 'CLOSE'
   'lxlite' WorkDll
   if rc <> 0 then
      do
         say 'lxLite exits with rc = 'rc
         return 1
      end
   return 0


OverwriteDll:

   if PatchDllDirectly = 1 then
      do
         say 'Patch applied. Restart EPM to see the colors changed.'
         return 0
      end

   OriDll = DllFullName
   WorkDll = WorkDllFullName
   if stream( WorkDll, 'C', 'QUERY EXISTS') = '' then
      do
         say 'Work file "'WorkDll'" doesn''t exist and can''t be used to overwrite'
         say ' the real DLL "'OriDll'".'
      end
   else
   'unlock' OriDll
   if rc <> 0 then
      return 1
   else
      do
         call SysFileDelete OriDll
         do s = 1 to 3
            if stream( OriDll, 'C', 'QUERY EXISTS') = '' then
               leave
            else
               call SysSleep SysSleepAmount
         end /* do s */
         'copy' WorkDll OriDll
         if rc <> 0 then
            do
               say '"'WorkDll'" not copied to "'OriDir'". rc = 'rc
               return 1
            end
/*
         lp = lastpos( '\', OriDll)
         OriDir = substr( OriDll, 1, max( lp - 1, 0))
         say 'copy: 'WorkDll' -> 'OriDir
         rc =  SysCopyObject( WorkDll OriDir)
         if rc <> 1 then
            do
               say '"'WorkDll'" not copied to "'OriDir'". rc = 'rc
               return 1
            end
*/
      end
   say 'Patch applied and DLL copied over. Restart EPM to see the colors changed.'
   return 0


