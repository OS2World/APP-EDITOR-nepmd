<? /*************************** Module Header *******************************
*
* Module Name: details.php
*
* script to display details of a status entry
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: details.php,v 1.10 2002-09-09 15:36:00 cla Exp $
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
// load file
$file = $_GET[ "file"];
if ($file == "")
   {
   $aaentry = filedb_queryentries( "db");
   $aentry = $aaentry[ 0];

   }
else
   {
   // read database
   $aentry = filedb_read( $file);
   }

list( , $file)      = each( $aentry);
list( , $category)  = each( $aentry);
list( , $title)     = each( $aentry);
list( , $prio)      = each( $aentry);
list( , $status)    = each( $aentry);
list( , $filelist)  = each( $aentry);
list( , $updated)   = each( $aentry);
list( , $modified)  = each( $aentry);
list( , $details)   = each( $aentry);

$commentfile = filedb_getcommitfile( $file);
if (file_exists( $commentfile))
   $gifbdcolor= filedb_getstatuscolor( "COMMIT");
else
   $gifbdcolor= filedb_getstatuscolor( "CURRENT");

echo "<table width=90% border=0 cellpadding=1 cellspacing=1>";
echo "<tr>";
echo "<td bgcolor=#dddddd width=100%>";
echo $title;
echo "</td><td align=right bgcolor=".$gifbdcolor.">";
echo "<a href=\"edit.php?file=".$file."\"><img src=\"edit.gif\" border=0></a>";
echo "</td>";
echo "</td><td align=right bgcolor=#dddddd>";
echo "<a href=\"new.php?file=".$file."\"><img src=\"edit.gif\" border=0></a>";
echo "</td>";
echo "</tr>";
echo "</table>";
echo "<table width=90% border=0 cellpadding=1 cellspacing=1>";
echo "<tr>";
echo "<td width=10% bgcolor=#dddddd ><font size=-1>category</td>";
echo "<td width=03% bgcolor=#dddddd ><font size=-1>prio</td>";
echo "<td width=10% bgcolor=#dddddd ><font size=-1>status</td>";
echo "<td width=18% bgcolor=#dddddd ><font size=-1>last modified</td>";
echo "<td width=07% bgcolor=#dddddd ><font size=-1>file</td>";
echo "<td width=57% bgcolor=#dddddd ><font size=-1>affected files</td>";
echo "</tr>";
echo "<tr>";
echo "<td valign=top><font size=-1>".$category."</font></td>";
echo "<td valign=top align=center><font size=-1>".$prio."</font></td>";
echo "<td valign=top><font size=-1>".$status."</font></td>";
echo "<td valign=top><font size=-1>".$modified."</font></td>";
echo "<td valign=top><font size=-1>".basename($file)."</font></td>";
echo "<td valign=top><font size=-1>";
if (strlen( trim( $filelist)) == 0)
   echo "- none -";
else
   echo $filelist;
echo "</font></td>";
echo "</tr>";
echo "</table>";

echo "<font size=+1><xmp>";
echo $details;
echo "</xmp></font>";

?>
</body>
</html>
