<? /*************************** Module Header *******************************
*
* Module Name: filedb.inc
*
* Generic routine to read data from database files
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: filedb.inc,v 1.1 2002-07-18 19:26:23 cla Exp $
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

<?
function filedb_read( $file)
{
// basic defs
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

$details = "";
$line = fgets( $hfile, $maxlinelen);
while (!feof( $hfile))
   {
   $line = fgets( $hfile, $maxlinelen);
   $details = $details." ".$line;
   }

fclose( $hfile);

return array( $file, $category, $title, $prio, $status, $filelist, $modified, $details);
}

?>

