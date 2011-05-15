<? /*************************** Module Header *******************************
*
* Module Name: list.php
*
* Script to create a status list out of the db\* files
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

<!--$url-minder-ignore$-->
<html>
<body text="#000000" bgcolor=#FFFFFF link=#CC6633 vlink=#993300 alink=#6666CC>


<?

// some basic default values
$bgcolor_bright   = "#ffffff";
$bgcolor_dark     = "#dddddd";
$bgcolor_header   = "#bbbbbb";
$bgcolor_selected = $bgcolor_dark;


// check for any commit file
$commit = filedb_querycommitstatus( "db");
$commit_color = filedb_getstatuscolor( $commit);

// read filenames
$aaentry = filedb_queryentries( "db");

// define background colors for header line
$bgcolor_u = $bgcolor_header;
$bgcolor_t = $bgcolor_header;
$bgcolor_p = $bgcolor_header;
$bgcolor_c = $bgcolor_header;
$bgcolor_s = $bgcolor_header;
$bgcolor_m = $bgcolor_header;

// sort here
$sort = $_GET[ "sort"];
if ($sort == "t")
   {
   $bgcolor_t = $bgcolor_selected;
   usort( $aaentry, "filedb_sorttitle");
   }
else if ($sort == "p")
   {
   $bgcolor_p = $bgcolor_selected;
   usort( $aaentry, "filedb_sortprio");
   }
else if ($sort == "c")
   {
   $bgcolor_c = $bgcolor_selected;
   usort( $aaentry, "filedb_sortcategory");
   }
else if ($sort == "s")
   {
   $bgcolor_s = $bgcolor_selected;
   usort( $aaentry, "filedb_sortstatus");
   }
else if ($sort == "m")
   {
   $bgcolor_m = $bgcolor_selected;
   usort( $aaentry, "filedb_sortmodified");
   }

?>


<table cellspacing=1 cellpadding=2 border=0>
  <tr>
    <th bgcolor=<?=$bgcolor_u?>>
       <a href="list.php?sort=">#</a>
    </th>
    <th align=left bgcolor=<?=$bgcolor_p?>>
       <a href="list.php?sort=p">prio</a>
    </th>
    <th align=left bgcolor=<?=$bgcolor_c?>>
       <a href="list.php?sort=c">category</a>
    </th>
    <th align=left bgcolor=<?=$bgcolor_t?>>
       <a href="list.php?sort=t">title</a>
    </th>
    <th bgcolor=<?=$bgcolor_s?>>
       <a href="list.php?sort=s">status</a>
    </th>
    <th bgcolor=<?=$bgcolor_header?>>
       <font color=<?=$commit_color?>>CVS</font>
    </th>
    <th align=left bgcolor=<?=$bgcolor_m?>>
       <a href="list.php?sort=m">last modified</a>
    </th>
  </tr>


<?
// display sorted rows
for ($i = 0; $i < count( $aaentry);$i++)
   {

   // select background color
   if ($i % 2 == 1)
      $bgcolor = $bgcolor_dark;
   else
      $bgcolor = $bgcolor_bright;

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

   // check if commit file exists
   if (file_exists( filedb_getcommitfile( $entryfile)))
      $cvsstat = "<font color=".filedb_getstatuscolor( "COMMIT").">commit</font>";
   else
      $cvsstat = "<font color=".filedb_getstatuscolor( "CURRENT").">current</font>";

   // display entry
   echo "<tr>";
   echo "<td align=right bgcolor=".$bgcolor.">";
   echo $i + 1;
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
   echo "<td bgcolor=".$bgcolor." align=center>";
   echo $status;
   echo "</td>";
   echo "<td bgcolor=".$bgcolor." align=center>";
   echo $cvsstat;
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
