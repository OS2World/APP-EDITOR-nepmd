<? /*************************** Module Header *******************************
*
* Module Name: filedb.inc
*
* Generic routine to read data from database files
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: filedb.inc,v 1.5 2002-07-22 10:35:30 cla Exp $
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

// read header lines here
$headerended = 0;
while (!feof( $hfile))
   {
   $line = fgets( $hfile, $maxlinelen);
   if ($headerended == 0)
      {
      list( $tag, $value) = explode( ":", $line, 2);

      if ($tag == "CATEGORY")
         $category = $value;

      else if ($tag == "TITLE")
         $title = $value;

      else if ($tag == "PRIO")
         $prio = $value;

      else if ($tag == "STATUS")
         $status = $value;

      else if ($tag == "FILES")
         $filelist = $value;

      else if ($tag == "UPDATED")
         {
         $updated = $value;
         $aline = explode( " ", $line);
         $modified   = $aline[4]." ".$aline[5]." ".$aline[6];
         }
      else
         $headerended = 1;
      }
   else
      $details = $details.$line;
   }

fclose( $hfile);

return array( $file, $category, $title, $prio, $status, $filelist, $updated, $modified, $details);
}

// --------------------------------------------------------------------

function filedb_queryentries( $dbdir)
{
// read database
$dir = dir( $dbdir);
while ($entry = $dir->read())
   {
   if (!is_dir( $entry))
      {
      // read file contents
      $entryfile = $dbdir."/".$entry;

      $aentry = filedb_read( $entryfile);

      if ($aentry[ 1] != "")
         $aaentry[] = $aentry;
      }
   }

return $aaentry;
}

// --------------------------------------------------------------------

function filedb_querycommitstatus( $dbdir)
{

$commit = "CURRENT";

// read database
$dir = dir( $dbdir);
while ($entry = $dir->read())
   {
   if (!is_dir( $entry))
      {
      // read file contents
      $entryfile = $dbdir."/".$entry;

      // check for commit files
      if ( substr( $entry, strlen( $entry) - 7) == ".commit")
         $commit = "COMMIT";
      }
   }

return $commit;
}

// --------------------------------------------------------------------

function filedb_sorttitle( $aa, $ab)
{   
$index = 2;
$a = $aa[ $index];
$b = $ab[ $index];

return strcmp( strtoupper( $a), strtoupper( $b));

return $result;
}

// --------------------------------------------------------------------

function filedb_sortcategory( $aa, $ab)
{   
$index = 1;
$a = $aa[ $index];
$b = $ab[ $index];

return strcmp( strtoupper( $a), strtoupper( $b));

return $result;
}

// --------------------------------------------------------------------

function filedb_sortprio( $aa, $ab)
{   
$index = 3;
$a = $aa[ $index];
$b = $ab[ $index];

if ($a == $b)
   $result = 0;
else
   $result = ($a > $b) ? 1 : -1;
return $result;
}

// --------------------------------------------------------------------

function filedb_sortstatus( $aa, $ab)
{   
$index = 4;
$a = $aa[ $index];
$b = $ab[ $index];

return strcmp( strtoupper( $a), strtoupper( $b));

return $result;
}

// --------------------------------------------------------------------

function filedb_sortmodified( $aa, $ab)
{   
$index = 7;
$a = $aa[ $index];
$b = $ab[ $index];

// reverse order !
return strcmp( strtoupper( $b), strtoupper( $a));

return $result;
}

// --------------------------------------------------------------------

function filedb_getcommitfile( $file)
{
return $file.".commit";
}

// --------------------------------------------------------------------

function filedb_getstatuscolor( $status)
{
$status = strtoupper( trim( $status));
if ($status == "COMMIT")
   return "#aa0000";
else
   return "#007700";
}

?>
