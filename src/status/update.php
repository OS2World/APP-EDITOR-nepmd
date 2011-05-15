<? /*************************** Module Header *******************************
*
* Module Name: update.php
*
* Script being called by edit.php to store entries of form
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
*************************************************************************/ ?>

<? include( "filedb.inc") ?>
<html>
<body text="#000000" bgcolor=#FFFFFF link=#CC6633 vlink=#993300 alink=#6666CC>


<?

// save file
$file = $_POST[ "file"];
$comment = $_POST[ "comment"];
if ($comment == "")
   {
   echo "<br>error: <b>no commit comment specified !</b><p>";
   echo "press the Back button and enter a commit comment."; 
   }
else if ($file != "")
   {
   // read file contents
   $hfile = fopen( $file, "w");

   // write data
   fputs( $hfile, "CATEGORY: ".$_POST[ "category"]."\r\n");
   fputs( $hfile, "TITLE: ".stripslashes( trim( $_POST[ "title"]))."\r\n");
   fputs( $hfile, "PRIO: ".$_POST[ "prio"]."\r\n");
   fputs( $hfile, "STATUS: ".$_POST[ "status"]."\r\n");
   fputs( $hfile, "FILES: ".stripslashes( trim( $_POST[ "filelist"]))."\r\n");
   fputs( $hfile, "UPDATED: ".trim( $_POST[ "updated"])."\r\n");
   fputs( $hfile, "\r\n");
   fputs( $hfile, stripslashes( $_POST[ "details"]));
   fclose( $hfile);

   // write comment to comment file
   $hfile = fopen( filedb_getcommitfile( $file), "w");
   fputs( $hfile, stripslashes( stripslashes( $comment)));
   fclose( $hfile);

   // update
   echo "Data was saved successfully !<p>";

   // autoload details window again
   echo "<meta http-equiv=\"refresh\" content=\"0; URL=details.php?file=".$file."\">";

   // refresh list window
   echo "<script type=\"text/javascript\"><!-- \n parent.ListWindow.location.reload();\n--></script>";

   }
else
   {
   echo "Internal error: could not save data !<br>";
   }

?>


</body>
</html>
