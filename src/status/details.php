<? /*************************** Module Header *******************************
*
* Module Name: details.php
*
* script to display details of a status entry
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: details.php,v 1.3 2002-07-18 19:27:09 cla Exp $
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
   list( , $modified)  = each( $aentry);
   list( , $details)   = each( $aentry);

   echo "<br>";
   echo "<table width=70% border=0>";
   echo "<tr>";
   echo "<td bgcolor=#dddddd><font size=+1><b>".$title."</b></font></td>";
   echo "<td width=50 align=right bgcolor=#dddddd><img src=\"edit.gif\"></td>";
   echo "</tr>";
   echo "</table>";
   echo "<table width=70% border=0>";
   echo "<tr>";
   echo "<td width=25% bgcolor=#dddddd >category</td>";
   echo "<td width=10% bgcolor=#dddddd >prio</td>";
   echo "<td width=15% bgcolor=#dddddd >status</td>";
   echo "<td width=50% bgcolor=#dddddd >last modified</td>";
   echo "</tr>";
   echo "<tr>";
   echo "<td>".$category."</b></td>";
   echo "<td>".$prio."</b></td>";
   echo "<td>".$status."</b></td>";
   echo "<td>".$modified."</b></td>";
   echo "</tr>";
   echo "</table>";

   echo "<font size=+1><xmp>";
   echo $details;
   echo "</xmp></font>";

   }

?>
</html>
