<? /*************************** Module Header *******************************
*
* Module Name: details.php
*
* Script to edit details of a status entry
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: edit.php,v 1.4 2002-07-19 15:36:42 cla Exp $
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
function addoptions(  $default, $optionfile)
{
// read all options from file
$aoptions = file( $optionfile);

// search default in options
$default_upper = strtoupper( trim($default));
for ($i = 0; $i < count( $aoptions); $i++)
   {
   // read entry, ignore empty lines and comments
   $option = trim( $aoptions[ $i]);
   if (strlen( $option) == 0)
      continue;
   if (strlen( strpos( $option, ":")) > 0)
      continue;

   // ckeck if option should be selected
   $option_upper = strtoupper( trim( $option));
   $selected = (strcmp( $option_upper, $default_upper) == 0);
   if ($selected)
      echo "<option selected>".$option;
   else
      echo "<option>".$option;
   }
}

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

   echo "<form action=\"update.php\" name=\"EditDbFile\" method=\"post\" enctype=\"text/plain\">";
   echo "<table width=90% border=0>";
   echo "<input name=file type=hidden value=\"".$file."\">";

   echo "<tr><td align=right valign=center bgcolor=#dddddd>";
   echo "file:";
   echo "</td><td valign=center bgcolor=#dddddd>";
   echo $file;
   echo "</td></tr>";

   echo "<tr><td align=right>";
   echo "title:";
   echo "</td><td>";
   echo "<input name=title size=70 maxlength=256 value=\"".$title."\">";
   echo "</td></tr>";

   echo "<tr><td align=right bgcolor=#dddddd><font size=-1>";
   echo "category:";
   echo "</font></td><td bgcolor=#dddddd><font size=-1>";
   echo "<select name=category size=1>";
   addoptions( $category, "category.lst");
   echo "</select>";

   echo " prio: ";
   echo "<select name=prio size=1>";
   addoptions( $prio, "prio.lst");
   echo "</select>";

   echo " status: ";
   echo "<select name=status size=1>";
   addoptions( $status, "status.lst");
   echo "</select>";


   echo " files: ";
   echo "<input name=filelist size=60 maxlength=256 value=\"".trim( $filelist)."\">";
   echo "</font></td></tr>";

   echo "<input name=updated type=hidden value=\"".$updated."\">";

   echo "<tr><td valign=top align=right><font size=-1>";
   echo "details:";
   echo "</font></td><td><font size=-1>";
   echo "<textarea name=details rows=6 cols=100>";
   echo $details;
   echo "</textarea>";
   echo "</font></td></tr>";

   echo "<tr><td>";
   echo "</td><td><font size=-1>";
   echo "<input type=submit value=\"Apply\">";
   echo "&nbsp;";
   echo "<input type=reset value=\"Undo\">";
   echo "&nbsp;";
   echo "<input type=button value=\"Cancel\" onClick=\"self.location.href='details.php?file=".$file."'\">";
   echo "</font></td></tr>";

   echo "</table>";
   }

?>
</body>
</html>
