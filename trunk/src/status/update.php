<? /*************************** Module Header *******************************
*
* Module Name: update.php
*
* Script being called by edit.php to store entries of form
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: update.php,v 1.1 2002-07-18 22:02:00 cla Exp $
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
*************************************************************************/ ?>

<? include( "filedb.inc") ?>

<?

// read file contents
$hfile = fopen( $file, "w");

// write data
fputs( $hfile, "CATEGORY: ".$category."\r\n");
fputs( $hfile, "TITLE: ".stripslashes( trim( $title))."\r\n");
fputs( $hfile, "PRIO: ".$prio."\r\n");
fputs( $hfile, "STATUS: ".$status."\r\n");
fputs( $hfile, "FILES: ".stripslashes( trim( $filelist))."\r\n");
fputs( $hfile, "UPDATED: ".trim( $updated)."\r\n");
fputs( $hfile, "\r\n");
fputs( $hfile, stripslashes( $details));
fclose( $hfile);

?>
<p>
Data was saved successfully !

</html>
