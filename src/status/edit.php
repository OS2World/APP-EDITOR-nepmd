<? /*************************** Module Header *******************************
*
* Module Name: details.php
*
* Script to edit details of a status entry
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: edit.php,v 1.1 2002-07-18 22:02:00 cla Exp $
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
function addoptions(  $default, $aoptions)
{

$default_upper = strtoupper( trim($default));
for ($i = 0; $i < count( $aoptions); $i++)
   {
   $option = $aoptions[ $i];
   $option_upper = strtoupper( trim( $option));
   $selected = (strcmp( $option_upper, $default_upper) == 0);
   if ($selected)
      echo "<option selected>".$option;
   else
      echo "<option>".$option;
   }
}

// load file
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

   echo "<form action=\"update.php\" name=\"EditDbFile\" method=post enctype=\"text/plain\">";
   echo "<table width=70% border=0>";
   echo "<input name=file type=hidden value=\"".$file."\">";

   echo "<tr><td align=right bgcolor=#dddddd>";
   echo "file:";
   echo "</td><td bgcolor=#dddddd>";
   echo $file;
   echo "</td></tr>";

   echo "<tr><td align=right >";
   echo "title:";
   echo "</td><td>";
   echo "<input name=title size=70 maxlength=256 value=\"".$title."\">";
   echo "</td></tr>";

   echo "<tr><td align=right bgcolor=#dddddd>";
   echo "category:";
   echo "</td><td bgcolor=#dddddd>";
   echo "<select name=category size=1>";
   addoptions( $category, array( "Bug", "Compile", "Feature", "File handling", "Formatting", "EPM info", "Locate/Select", "Misc", "Tagging", "Toolbar"));
   echo "</select>";

   echo " prio: ";
   echo "<select name=prio size=1>";
   addoptions( $prio, array( "1", "2", "3", "4", "5"));
   echo "</select>";

   echo " status: ";
   echo "<select name=status size=1>";
   addoptions( $status, array( "open", "started", "coding", "testing", "completed"));
   echo "</select>";
   echo "</td></tr>";

   echo "<input name=filelist type=hidden value=\"".$filelist."\">";
   echo "<input name=updated type=hidden value=\"".$updated."\">";

   echo "<tr><td valign=top align=right>";
   echo "details:";
   echo "</td><td>";
   echo "<textarea name=details rows=6 cols=100>";
   echo $details;
   echo "</textarea>";
   echo "</td></tr>";

   echo "<tr><td>";
   echo "</td><td>";
   echo "<input type=reset value=\"Undo\">";
   echo "&nbsp;";
   echo "<input type=submit value=\"Save to disk\">";
   echo "</td></tr>";

   echo "</table>";
   }

?>
</html>
