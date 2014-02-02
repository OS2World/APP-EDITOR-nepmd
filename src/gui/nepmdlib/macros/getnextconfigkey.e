/****************************** Module Header *******************************
*
* Module Name: getnextconfigkey.e
*
* E wrapper routine to access the NEPMD library DLL.
* Include of nepmdlib.e.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
@@NepmdGetNextConfigKey@PROTOTYPE
Flag = NepmdGetNextConfigKey( Handle, RegPath, SearchOpts, NextKey)

@@NepmdGetNextConfigKey@CATEGORY@CONFIG

@@NepmdGetNextConfigKey@SYNTAX
This function queries a container lookup for key containers
in the configuration repository of the [=TITLE].
For that it needs to be
[.IDPNL_EFUNC_NEPMDGETNEXTCONFIGKEY_EXAMPLE called in a loop].

@@NepmdGetNextConfigKey@PARM@Handle
This parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdGetNextConfigKey@PARM@RegPath
This parameter specifies the pathname of the container.

@@NepmdGetNextConfigKey@PARM@SearchOpts
This parameter specifies the search options in a logical
combination of the following:
.pl compact bold break=none tsize=3
- K
= search keys only
- C
= search containers only
- B
= search entries being either a container or a key or both

Note that a container #may# also have a key value, but does not
necessarily have one.

@@NepmdGetNextConfigKey@PARM@NextKey
This parameter must be a variable. It specifies either
.ul compact
- an empty string to query the first key of the container or
- the previously returned key in order to query the next key.

If a key is specified, it must exist in the key list, otherwise
*NepmdGetNextConfigKey* will return an error.

The next found key is stored in this parameter.

@@NepmdGetNextConfigKey@EXAMPLE
The following code searches both keys and subcontainers within the container *\NEPMD*:
.fo text
 universal nepmd_hini

 Handle        = nepmd_hini
 RegPath       = '\NEPMD'
 SearchOptions = 'B'
 NextKey       = ''

 -- Search all files
 do while NepmdGetNextConfigKey( Handle, RegPath, SearchOptions, NextKey)
    -- Process key - here as a sample we display a popup
    messagenwait( 'Key found:' NextKey)
 enddo
.fo on

@@NepmdGetNextConfigKey@RETURNS
*NepmdGetNextConfigKey* returns either
.ul compact
- *0* (zero), if no more keys exist or on error
- *1*, if next config key was queried successfully.

The next key returned by the key search is stored in the
[.IDPNL_EFUNC_NEPMDGETNEXTCONFIGKEY_PARM_NEXTKEY NextKey] parameter.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.
rc is set to 18 = ERROR__NO__MORE__FILES if key was not found.

@@NepmdGetNextConfigKey@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetNextConfigKey*
  - or
- *GetNextConfigKey*

Executing this command will
open up a virtual file and
write all keys found for the container *\NEPMD* to it.

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

 compile if 1
; 1) Use the standard handle of the NEPMD config repository
defc NepmdGetNextConfigKey, GetNextConfigKey
   universal nepmd_hini

   Handle        = nepmd_hini
   RegPath       = '\NEPMD'
   SearchOptions = 'B'
   NextKey       = ''

   -- Create virtual file
   helperNepmdCreateDumpfile( 'NepmdGetNextConfigKey', RegPath)

   -- Search all keys
   do while NepmdGetNextConfigKey( Handle, RegPath, SearchOptions, NextKey)
      insertline( '-' NextKey)
   enddo
   insertline ''
   .modify = 0

/*
   rc = 0
   do while not rc
      Flag = NepmdGetNextConfigKey( Handle, RegPath, SearchOptions, NextKey)
      dprintf( 'rc = 'rc', Flag = 'Flag', NextKey = 'NextKey)
   enddo
*/

 compile else
; 2) Get a new handle for the already opened NEPMD config repository
defc NepmdGetNextConfigKey, GetNextConfigKey

   do i = 1 to 1

      RegPath       = '\NEPMD'
      SearchOptions = 'B'
      NextKey       = ''

      -- Open up the configuration repository
      Handle = NepmdOpenConfig()
      if rc then
         sayerror 'Configuration repository could not be opened, rc = 'rc'.'
         leave
      endif

      -- Create virtual file
      helperNepmdCreateDumpfile( 'NepmdGetNextConfigKey', RegPath)

      -- Search all keys
      do while NepmdGetNextConfigKey( Handle, RegPath, SearchOptions, NextKey)
         insertline( '-' NextKey)
      enddo
      insertline ''
      .modify = 0

      -- Close the configuration repository
      call NepmdCloseConfig( Handle)

   enddo

 compile endif
compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdGetNextConfigKey
; ---------------------------------------------------------------------------
; E syntax:
;    Handle  = 0
;    Flag = NepmdGetNextConfigKey( Handle, RegPath, SearchOpts, NextKey)
;
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdGetNextConfigKey( HCONFIG hconfig,
;                                           PSZ   pszRegPath,
;                                           PSZ   pszPreviousKey,
;                                           PSZ   pszBuffer,
;                                           ULONG ulBuflen);
;
; ---------------------------------------------------------------------------

compile if not defined( NEPMD_MAXLEN_ESTRING) then
   include 'STDCONST.E'
compile endif

defproc NepmdGetNextConfigKey( Handle, RegPath, SearchOpts, var NextKey)

   -- Use zero as handle if none specified. Zero means that the config
   -- repository is opened and closed by the C routine at each call, which
   -- might be much slower when being called in a loop.
   -- The usual parameter is the handle returned by NepmdInitConfig.
   if (strip( Handle) = '') then
      Handle = 0
   endif

   -- Prepare parameters for C routine
   -- Don't touch the handle parameter, as we must report
   -- the address of the original var of the caller.
   RegPath      = RegPath\0
   PreviousKey  = NextKey\0
   SearchOpts   = SearchOpts\0
   BufLen       = NEPMD_MAXLEN_ESTRING
   NextKey      = copies( \0, BufLen)

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    'NepmdGetNextConfigKey',
                    atol( Handle)                ||
                    address( RegPath)            ||
                    address( PreviousKey)        ||
                    address( SearchOpts)         ||
                    address( NextKey)            ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)
   if rc then
      Flag = 0
      NextKey = ''
   else
      Flag = 1
      NextKey = makerexxstring( NextKey)
   endif
   return Flag

