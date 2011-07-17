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
   list( , $title)     = each( $aentry);
   list( , $prio)      = each( $aentry);
   list( , $status)    = each( $aentry);
   list( , $filelist)  = each( $aentry);
   list( , $updated)   = each( $aentry);
   list( , $modified)  = each( $aentry);
   list( , $details)   = each( $aentry);

   // read commit comment if exists
   $comment = "";
   $commentfile = filedb_getcommitfile( $file);
   if (file_exists( $commentfile))
      {
      $acomment = file( $commentfile);
      for ($i = 0; $i < count( $acomment); $i++)
         {
         $comment .= $acomment[ $i];
         }
      }

   // include HTML form for editing an existing file
   // but comment may result out of an uncommitted add operation
   $newfile = ($comment == "First revision");
   include( "formcode.inc");
   }

?>

