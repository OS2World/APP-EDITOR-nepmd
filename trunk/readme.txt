; $Id: readme.txt,v 1.3 2002-04-19 14:51:53 cla Exp $

Netlabs EPM Distribution package readme
=======================================

Requirements:
-------------
- pkunzip2 (is part of MPTS)
  -> required because newer versions of unzip.exe do not work
     for some files - shrink method not supported!

- zip.exe of info-zip - used as standard unzip tool
  -> required because "deflated" method used for
     txt files in epm603.zip are not supported
      by pkunzip2 of MPTS

- wget for download of original zip files, if not present
  (tested: v1.7)

- when sitting behind a firewall, create/modify
  a wget resource file in order to use an FTP proxy

    --- required entries in %home%\.wgetrc ---
    ftp_proxy=http://<proxyname>:<proxyport>
    proxy_user=<proxy_userid>
    proxy_passwd=<proxy_password>
    ------------------------------------------

- WarpIn installed (tested: 0.9.18)
  WarpIn dir in PATH and (BEGIN)LIBPATH

- IBM Developers Toolkit for OS/2 Warp3/4
  or IPFC compiler and NMAKE.EXE of that

- HyperText/2 preprocessor for to compile the online help file
  see http://hobbes.nmsu.edu/cgi-bin/h-search?key=htext

- REXX2EXE compiler

- grep utility in PATH


Proceed as follows
------------------
- edit configure.in to your needs
- run makefile

