<? /*************************** Module Header *******************************
*
* Module Name:
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: list.php,v 1.1 2002-07-17 15:55:44 cla Exp $
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

<!--$url-minder-ignore$-->
<html>
<body text="#000000" bgcolor=#FFFFFF link=#CC6633 vlink=#993300 alink=#6666CC>

<table cellspacing=1 cellpadding=2 border=0>
  <tr>
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
// read database
$dbdir = "db";
$dir = dir( $dbdir);
while ($entry = $dir->read())
   {
   if (!is_dir( $entry))
      {
      // read file contents
      $entryfile = $dbdir."/".$entry;
      $hfile = fopen( $entryfile, "r");

      // category
      $line = fgets( $hfile, 80);
      list( $tag, $category) = explode( ":", $line, 2);

      // title
      $line = fgets( $hfile, 80);
      list( $tag, $title) = explode( ":", $line, 2);

      // priority
      $line = fgets( $hfile, 80);
      list( $tag, $prio) = explode( ":", $line, 2);

      // status
      $line = fgets( $hfile, 80);
      list( $tag, $status) = explode( ":", $line, 2);

      // filelist
      $line = fgets( $hfile, 80);
      list( $tag, $filelist) = explode( ":", $line, 2);

      // update info
      $line = fgets( $hfile, 80);
      $aline = explode( " ", $line);
      $modified   = $aline[4]." ".$aline[5]." ".$aline[6];


      fclose( $hfile);

      $aentry = array( $entryfile, $category, $title, $prio, $status, $filelist, $modified);

      $aaentry[] = $aentry;
      }
   }

// sort here (not yet implemented)
// ...

// display sorted rows
for ($i = 0; $i < count( $aaentry);$i++)
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
   list( , $modified)  = each( $aentry);

   // display entry
   echo "<tr>";
   echo "<td bgcolor=".$bgcolor.">";
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
