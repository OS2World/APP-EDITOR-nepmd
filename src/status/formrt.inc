<? /*************************** Module Header *******************************
*
* Module Name: formrt.php
*
* Generic routines for supporting the HTML form
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

function newfile(  $file)
{
$basename = basename( $file);
$basedir  = substr( $file, 0, strlen( $file) - strlen( $basename) - 1);
$namepart = substr( $basename, 0, strlen( $basename) - 3);
$numpart  = substr( $basename, strlen( $namepart));

// determine the number of the first file not existing
$newfile = $basedir."/".$namepart.$numpart;
while (file_exists( $newfile))
   {
   $numpart = str_pad(  $numpart + 1, 3, "0", STR_PAD_LEFT);
   $newfile = $basedir."/".$namepart.$numpart;
   }

return $newfile;
}

?>

