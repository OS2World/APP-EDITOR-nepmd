<? /*************************** Module Header *******************************
*
* Module Name: details.php
*
* Script to edit details of a status entry
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
<? include( "formrt.inc") ?>

<?
// load file
$file = $_GET[ "file"];
if ($file != "")
   {
   // read database
   $aentry = filedb_read( $file);
   list( , $entryfile) = each( $aentry);
   list( , $category)  = each( $aentry);
   // --- other not required

   // determine some fields
   $title    = "- please specify new title -";
   $prio     = "1";
   $status   = "open";
   $filelist = "";

   $updated  = "\$";     // two lines here, so that CVS will not touch it
   $updated  = $updated."Id: \$";

   $modified = "";
   $details  = "- please add details here";

   // determine first commit comment
   $comment = "First revision";

   // determine name of newfile
   $file = newfile( $file);

   // include HTML form for adding a new file
   $newfile = 1;
   include( "formcode.inc");
   }

?>

