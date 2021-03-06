Library:     WPTOOLS
Description: Henk kelders WPTOOLS.DLL Version 2.12 - October 1999

The http address below is not valid anymore. Henk Kelder has uploaded
all his binaries together with the sources (a library is missing) on
the Netlabs Ftp server:

   ftp://ftp.netlabs.org/pub/misc/hektools.zip

WPTOOLS.DLL is used here to query settings from WPS color palette
objects for configuring EPM's color palette.


                          === DISCLAIMER ===


I allow you to use and distribute WPTOOLS.DLL freely under the condition
that I am in no way responsible for any damage or loss you may suffer.

Henk Kelder
hkelder@capgemini.nl
http://www.os2ss.com/information/kelder/


What is WPTOOLS.DLL:

WPTOOLS.DLL is a Dynamic Link Library that contains code to query the
settings for workplace shell objects. This DLL is used by WPSBKP.EXE but
can also be used from within a REXX program.


The following REXX functions are available:



Function: WPToolsLoadFuncs
Purpose : Make the functions in WPTOOLS.DLL available to REXX.

Usage:

/*  First declare WPToolsLoadFuncs itself to REXX */
call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
/*  Call WPToolsLoadFuncs itself. */
call WPToolsLoadFuncs



Function: WPToolsQueryObject
Purpose : Query objects

Usage  :  rc=WPToolsQueryObject(object, [Class], [Title], [Setup], [Location])

Where:
        object = A fully qualified path name to a file or directory, or
                 An OBJECTID string (e.g. <WP_DESKTOP>), or
                 A string starting with a '#' and being followed
                 by a hexadecimal object handle (See WPToolsFolderContent)

        Class  = The name of a REXX variable, enclosed in quotes,
                 that will be created by WPTOOLS and will contain the
                 class name of the object. This argument is optional.

        Title  = The name of a REXX variable, enclosed in quotes,
                 that will be created by WPTOOLS and will contain the
                 title of the object. This argument is optional.

        Setup  = The name of a REXX variable, enclosed in quotes,
                 that will be created by WPTOOLS and will contain the
                 setup string of the object. This argument is optional.

        Location = The name of a REXX variable, enclosed in quotes,
                 that will be created by WPTOOLS and will contain the
                 location of the object. This argument is optional.

Returns: 1 on success and 0 when a error occurred.

Please note that only the object argument is mandatory. All other arguments
only need to be present when the result is needed. Should you not need one
argument, but need a argument that is after the not needed one, make sure
you enter all comma's. (e.g.: rc = WPToolsQueryObject(object,,,"SetupString")

See Appendix I and II for information about objects and the setup values
this call returns.


Example:

/* REXX must start with a comment line */

call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
call WPToolsLoadFuncs

iRetco = WPToolsQueryObject("<WP_DESKTOP>", "szClass", "szTitle", "szSetupString", "szLocation")
if Iretco Then do
     say 'Class name :' szclass
     say 'Title      :' sztitle
     say 'Location   :' szlocation
     say 'Setupstring:' szsetupstring
  end
else
  say 'Unable to return object settings for <WP_DESKTOP>'

End of Example


Function: WPToolsFolderContent
Purpose : Query abstract (non-disk) objects in a specific folder

Usage   : rc=WPToolsFolderContent(folder, stem [,'F'])

Where   :

        folder = A fully qualified path name to a directory, or
                 an OBJECTID string for a folder (e.g. <WP_DESKTOP>

        stem   = The name of a REXX stem variable that, on successful
                 return, will contain all abstract objects present
                 in a specific folder. Each returned entry will either
                 be an OBJECTID (when an OBJECTID has been set for
                 the returned object) or a string starting with a '#' and
                 followed by the hexadecimal object handle.

        'F'    =  If specified, WPToolsFolderContent will return all
                  filesystem objects as well.

Returns: 1 on success and 0 when a error occurred.

Example:

/* REXX must start with a comment line */

call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
call WPToolsLoadFuncs

iRetco = WPToolsFolderContent("<WP_DESKTOP>", "list.")
if iRetco = 0 Then Do
   exit
End

say 'Abstract objects on <WP_DESKTOP>:'
do iObject = 1 to list.0
  Iretco=WPToolsQueryObject(list.Iobject, "szclass", "sztitle", "szsetupstring", "szlocation")
  if Iretco Then do
     say '"'szClass'", "'szTitle'", "'szSetupString'", "'szLocation'"'
  end
end

End of Example

Function: WPToolsSetObjectData
Purpose : Change the settings of an existing object

Usage   : rc=WPToolsSetObjectData(object, setup)

Where   :
        object = A fully qualified path name to a file or directory, or
                 An OBJECTID string (e.g. <WP_DESKTOP>), or
                 A string starting with a '#' and being followed
                 by a hexadecimal object handle (See WPToolsFolderContent)

        setup  = A WinCreateObject setup string

Returns: 1 on success and 0 when a error occurred.

NOTE: This function is equal to SysSetObjectData with one difference that
      beside a file name or OBJECTID also a '#' followed by an hexadecimal
      object handle can be specified. This makes it posible that the outcome
      if WPToolsFolderContant can be used.



Function: WPToolsVersion
Purpose : Query version of WPTOOLS.DLL

Usage  :  version=WPToolsVersion()

Example:

/* REXX must start with a comment line */

call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
call WPToolsLoadFuncs

Version = WPToolsVersion()
say 'WPTOOLS.DLL is of version' version

End of Example

APPENDIX I - The workplace shell class tree

      WPObject                       Base object class
        ��� WPAbstract               Base abstract object class
        �     ��� WPClock
        �     ��� WPCountry
        �     ��� WPDisk
        �     ��� WPLaunchPad
        �     ��� WPKeyboard
        �     ��� WPMouse
        �     ��� WPPalette
        �     �     ��� WPColorPalette
        �     �     ��� WPFontPalette
        �     �     ��� WPSchemePalette
        �     ��� WPPower
        �     ��� WPPrinter
        �     ��� WPProgram
        �     ��� WPShadow
        �     �      ��� WPNetLink
        �     ��� WPShredder
        �     ��� WPSound
        �     ��� WPSpecialNeeds
        �     ��� WPSpool
        �     ��� WPSystem
        ��� WPFileSystem
        �     ��� WPDataFile
        �     �      ��� WPBitmap
        �     �      ��� WPIcon
        �     �      ��� WPMet
        �     �      ��� WPPif
        �     �      ��� WPPointer
        �     �      ��� WPProgramFile
        �     �             ��� WPCommandFile
        �     ��� WPFolder
        �     �      ��� WPDesktop
        �     �      ��� WPDrives
        �     �      ��� WPMinWinViewer
        �     �      ��� WPNetgrp
        �     �      ��� WPNetwork
        �     �      ��� WPRootFolder
        �     �      ��� WPServer
        �     �      ��� WPSharedDir
        �     �      ��� WPStartup
        �     �      ��� WPTemplates
        �     ��� WPWinConfig
        ��� WPTransient
              ��� WPJob
              ��� WPPort
              ��� WPPdr
              ��� WPQdr


APPENDIX II

WPToolsQueryObject has code to support (almost) all object classes for
which object setup strings are defined, being:

Class             Setup strings returned
-----             ----------------------

WPObject          CCVIEW, DEFAULTVIEW, HELPPANEL, HIDEBUTTON, MINWIN, NOCOPY,
                  NODELETE, NODRAG, NODROP, NOLINK, NOMOVE, NOPRINT, NORENAME,
                  NOSETTINGS, NOSHADOW, NOTVISIBLE, OBJECTID, TITLE
WPAbstract        TEMPLATE
WPProgram         ASSOCFILTER, ASSOCTYPE, EXENAME, MAXIMIZED, MINIMIZED,
                  NOAUTOCLOSE, PARAMETERS, PROGTYPE, SET, STARTUPDIR
WPShadow          SHADOWID
WPRPrinter        NETID (1)
WPPrint           APPDEFAULT, JOBDIALOGBEFOREPRINT, OUTPUTTOFILE, PORTNAME,
                  PRINTDRIVER, PRINTERSPECIFICFORMAT, PRINTWHILESPOOLING,
                  QSTARTTIME, QSTOPTIME, QUEUENAME, QUEUEDRIVER, SEPARATORFILE
WPServer          NETID (2)
WPNetgrp          NETID (2)
WPDisk            DRIVENUM
WPFontPalette     FONTS, XCELLCOUNT, YCELLCOUNT, XCELLWIDTH, XCELLHEIGHT,
                  XCELLGAP, YCELLGAP
WPColorPalette    COLORS, XCELLCOUNT, YCELLCOUNT, XCELLWIDTH, XCELLHEIGHT,
                  XCELLGAP, YCELLGAP
WPFileSystem      MENU (3)
WPProgramFile     ASSOCFILTER, ASSOCTYPE, EXENAME, MAXIMIZED, MINIMIZED,
                  NOAUTOCLOSE, PARAMETERS, PROGTYPE, SET, STARTUPDIR
WPFolder          ALWAYSSORT, BACKGROUND, DETAILSCLASS, DETAILSFONTS,
                  ICONFONT, TREEFONT, ICONNFILE, ICONVIEW, SORTCLASS,
                  TREEVIEW, DETAILSVIEW, WORKAREA,
WPLaunchPad       All documented setup strings.

(1) Along with all settings for WPPrint.
(2) These settings cannot be used to recreate the object.
(3) MENU doesn't work when applying.

For each object, WPToolsQueryObject returns setup string values not only for the object
itself (when supported) but also for all parent classes. When, for example,
one uses WPToolsQueryObject against the Desktop (class WPDesktop) setup strings
will be returned from the classes WPFolder, WPFileSystem and WPObject.

I did not build any support for WPSchemePalette because the setup string
for this class do not support settings the colors on an individual basis but
instead one should specify a color scheme name that is already present
in the INI files.


HISTORY:

Version 1.00 - Initial release

Version 1.01 - Added support for the Launchpad.
               Added a new REXX API call: WPToolsVersion

Version 1.02/1.19 - Not released

Version 1.20 - Increased several internal buffers to accommodate OS/2
               Warp Version 4 (Merlin) GAMMA.

Version 1.21 - Changed the return code from WPToolsFolderContent for '0' to '1'
               when a folder does not contain any abstract objects.

Version 1.32 - Enlarged an internal buffer to overcome a buffer too
               small error for tag 12.

Version 1.33 - Added WPToolsSetObjectData as new REXX API call.
               Modified WPToolsFolderContent so it will, optionally,
               return all filesystem objects as well.

Version 1.34 - Corrected WPHost to return a proper password.

Version 1.35 - Added logic for the WarpCenter.

Version 1.37 - Corrected one of the internal functions for a possible
               problem.

Version 2.00 - Corrected a problem because internal objecthandles with
               their HIWORD being 0x0004 were not recoqnized as file system
               objects.

Version 2.01 - Corrected a problem in an internal routine for retrieving data
               from the ini's. These routine failed if the key didn't contain
               any data.

Version 2.11 - Changed to compiler to VAC 3.0.

Version 2.12 - Did some internal changes.
