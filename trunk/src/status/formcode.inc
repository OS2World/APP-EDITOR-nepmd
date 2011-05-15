<? /*************************** Module Header *******************************
*
* Module Name: formcode.php
*
* HTML form using the fields of edit.php and new.php
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

<html>
<body text=#000000 bgcolor=#FFFFFF link=#CC6633 vlink=#993300 alink=#6666CC>

<form action="update.php" name="EditDbFile" method="post" enctype="text/plain">
<table width=90% border=0>
<input name=file type=hidden value="<?=$file?>">

<tr><td align=right valign=center bgcolor=#dddddd>
file:
</td><td valign=center bgcolor=#dddddd>
<? echo "$file &nbsp;&nbsp;"; if ($newfile) echo "(new file)"; ?>
</td></tr>

<tr><td align=right>
title:
</td><td>
<input name=title size=70 maxlength=256 value="<?=$title?>">
</td></tr>

<tr><td align=right bgcolor=#dddddd><font size=-1>
category:
</font></td><td bgcolor=#dddddd><font size=-1>
<select name=category size=1>
<? addoptions( $category, "category.lst"); ?>
</select>

 prio:
<select name=prio size=1>
<? addoptions( $prio, "prio.lst"); ?>
</select>

 status:
<select name=status size=1>
<? addoptions( $status, "status.lst"); ?>
</select>


 files:
<input name=filelist size=60 maxlength=256 value="<? echo trim( $filelist) ?>">
</font></td></tr>

<input name=updated type=hidden value="<?=$updated?>">

<tr><td valign=top align=right><font size=-1>
details:
</font></td><td><font size=-1>
<textarea name=details rows=6 cols=100>
<?=$details?>
</textarea>
</font></td></tr>

<tr><td valign=top align=right bgcolor=#dddddd><font size=-1>
commit comment:
</font></td><td bgcolor=#dddddd><font size=-1>
<textarea name=comment rows=2 cols=100 <? if ($newfile) echo "readonly"; ?>>
<?=$comment?>
</textarea>
</font></td></tr>

<tr><td>
</td><td><font size=-1>
<input type=submit value="Apply">
&nbsp;
<input type=reset value="Undo">
&nbsp;
<input type=button value="Cancel" onClick="self.location.href='details.php?file=<?=$entryfile?>'">
</font></td></tr>

</table>
</body>
</html>

