<? /*************************** Module Header *******************************
*
* Module Name: list.php
*
* Script to create a status list out of the db\* files
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: list.php,v 1.6 2002-07-19 15:17:03 cla Exp $
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

<!--$url-minder-ignore$-->
<html>
<body text="#000000" bgcolor=#FFFFFF link=#CC6633 vlink=#993300 alink=#6666CC>

<table cellspacing=1 cellpadding=2 border=0>
  <tr>
    <th align=center>
       #
    </th>
    <th align=left>
       prio
    </th>
    <th align=left>
       category
    </th>
    <th align=left>
       title
    </th>
    <th align=left>
       status
    </th>
    <th align=left>
       last modified
    </th>
  </tr>


<?
// read filenames
$aaentry = filedb_queryentries( "db");

// sort here (not yet implemented)
// ...

// display sorted rows
for ($i = 1; $i < count( $aaentry);$i++)
   {

   // select background color
   if ($i % 2 == 1)
      $bgcolor = "#dddddd";
   else
      $bgcolor = "#ffffff";

   // get values of entry
   $aentry = $aaentry[ $i];
   list( , $entryfile) = each( $aentry);
   list( , $category)  = each( $aentry);
   list( , $title)     = each( $aentry);
   list( , $prio)      = each( $aentry);
   list( , $status)    = each( $aentry);
   list( , $filelist)  = each( $aentry);
   list( , $updated)   = each( $aentry);
   list( , $modified)  = each( $aentry);
   list( , $details)   = each( $aentry);

   // display entry
   echo "<tr>";
   echo "<td align=right bgcolor=".$bgcolor.">";
   echo $i;
   echo "</td>";
   echo "<td align=center bgcolor=".$bgcolor.">";
   echo $prio;
   echo "</td>";
   echo "<td bgcolor=".$bgcolor.">";
   echo $category;
   echo "</td>";
   echo "<td bgcolor=".$bgcolor.">";
   echo "<a href=\"details.php?file=".$entryfile."\" target=\"DetailsWindow\">".$title."</a>";
   echo "</td>";
   echo "<td bgcolor=".$bgcolor.">";
   echo $status;
   echo "</td>";
   echo "<td bgcolor=".$bgcolor.">";
   echo $modified;
   echo "</td>";
   echo "</tr>";
   }
?>

</table>
<p>
<font size=-1> <b><?=$NOTE?></b>:<br><?=$NOTETEXT?></font>

</center>

<br>
</html>
<!--$/url-minder-ignore$-->
