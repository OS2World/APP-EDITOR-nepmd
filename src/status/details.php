<? /*************************** Module Header *******************************
*
* Module Name:
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: details.php,v 1.1 2002-07-17 15:55:43 cla Exp $
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
<html>
<body text="#000000" bgcolor=#FFFFFF link=#CC6633 vlink=#993300 alink=#6666CC>

<?

// load file
if ($file != "")
   {
   $maxlinelen = 256;

   // read file contents
   $hfile = fopen( $file, "r");

   // category
   $line = fgets( $hfile, $maxlinelen);
   list( $tag, $category) = explode( ":", $line, 2);

   // title
   $line = fgets( $hfile, $maxlinelen);
   list( $tag, $title) = explode( ":", $line, 2);

   // priority
   $line = fgets( $hfile, $maxlinelen);
   list( $tag, $prio) = explode( ":", $line, 2);

   // status
   $line = fgets( $hfile, $maxlinelen);
   list( $tag, $status) = explode( ":", $line, 2);

   // filelist
   $line = fgets( $hfile, $maxlinelen);
   list( $tag, $filelist) = explode( ":", $line, 2);

   // update info
   $line = fgets( $hfile, $maxlinelen);
   $aline = explode( " ", $line);
   $modified   = $aline[4]." ".$aline[5]." ".$aline[6];




   echo "<br>";
   echo "<font size=+1><b>".$title."</b></font><p>";
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

   echo "<xmp>";
   $line = fgets( $hfile, $maxlinelen);
   while (!feof( $hfile))
      {
      $line = fgets( $hfile, $maxlinelen);
      echo $line;
      }
   echo "</xmp>";
   fclose( $hfile);

   }

?>
</html>
