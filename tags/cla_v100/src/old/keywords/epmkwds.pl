@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.pl
@
@ Copyright (c) Netlabs EPM Distribution Project 2002
@
@ $Id: epmkwds.pl,v 1.1 2002-10-03 22:01:52 cla Exp $
@
@ ===========================================================================
@
@ This file is part of the Netlabs EPM Distribution package and is free
@ software.  You can redistribute it and/or modify it under the terms of the
@ GNU General Public License as published by the Free Software
@ Foundation, in version 2 as it comes in the "COPYING" file of the
@ Netlabs EPM Distribution.  This library is distributed in the hope that it
@ will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
@ of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
@ General Public License for more details.
@
@ **************************************************************************/

@ ------------------------------------------------------------------
@ Format of the file - see NEPMD.INF
@ ------------------------------------------------------------------
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start   Color Color  End     Escape
@ string  bg    fg     string  character
  /*       -1     13   */
  #        -1     13
  "        -1      2   "       \
  '        -1     10   '       \
  `        -1     10   `       \
@
@SPECIAL
@
{  -1  12
}  -1  12
;  -1  12
,  -1  12
?  -1  12
:  -1  12
$  -1  12
@  -1  12
%  -1  12
<  -1  12
>  -1  12
*  -1  12
@
@CHARSET
@
abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
@
@KEYWORDS
@
@ -------------------- Perl language constructs ---------------------------
auto		-1	5
accept		-1	5
alarm		-1	5
atan2		-1	5
bind		-1	5
binmode		-1	5
caller		-1	5
chdir		-1	5
chmod		-1	5
chop		-1	5
chown		-1	5
chroot		-1	5
close		-1	5
closedir	-1	5
connect		-1	5
continue	-1	5
cos		-1	5
crypt		-1	5
dbmopen		-1	5
dbmclose	-1	5
defined		-1	5
delete		-1	5
die		-1	5
do		-1	5
dump		-1	5
each		-1	5
else		-1	5
elsif		-1	5
endgrent	-1	5
endhostent	-1	5
endnetent	-1	5
endprotoent	-1	5
endpwent	-1	5
endservent	-1	5
eof		-1	5
eval		-1	5
exec		-1	5
exit		-1	5
exp		-1	5
fcntl		-1	5
fileno		-1	5
flock		-1	5
for		-1	5
foreach		-1	5
fork		-1	5
format		-1	5
getc		-1	5
getgid		-1	5
getgrent	-1	5
getgrgid	-1	5
getgrnam	-1	5
gethostbyaddr	-1	5
gethostbyname	-1	5
gethostent	-1	5
getlogin	-1	5
getnetbyaddr	-1	5
getnetbyname	-1	5
getnetent	-1	5
getpeername	-1	5
getpgrp		-1	5
getpid		-1	5
getppid		-1	5
getpriority	-1	5
getprotobyname	-1	5
getprotobynumber -1	5
getprotoent	-1	5
getpwent	-1	5
getpwnam	-1	5
getpwuid	-1	5
getservbyname	-1	5
getservbyport	-1	5
getservent	-1	5
getsockname	-1	5
getsockopt	-1	5
getuid		-1	5
gmtime		-1	5
goto		-1	5
grep		-1	5
hex		-1	5
if		-1	5
include		-1	5
index		-1	5
int		-1	5
ioctl		-1	5
join		-1	5
keys		-1	5
kill		-1	5
last		-1	5
length		-1	5
link		-1	5
listen		-1	5
local		-1	5
localtime	-1	5
log		-1	5
lstat		-1	5
m		-1	5
mkdir		-1	5
msgctl		-1	5
msgget		-1	5
msgrcv		-1	5
msgsnd		-1	5
next		-1	5
oct		-1	5
open		-1	5
opendir		-1	5
ord		-1	5
pack		-1	5
package		-1	5
pipe		-1	5
pop		-1	5
print		-1	5
printf		-1	5
push		-1	5
q		-1	5
qq		-1	5
qx		-1	5
rand		-1	5
read		-1	5
readdir		-1	5
readlink	-1	5
recv		-1	5
redo		-1	5
rename		-1	5
require		-1	5
reset		-1	5
return		-1	5
reverse		-1	5
rewinddir	-1	5
rindex		-1	5
rmdir		-1	5
s		-1	5
scalar		-1	5
seek		-1	5
seekdir		-1	5
select		-1	5
semctl		-1	5
semget		-1	5
semop		-1	5
send		-1	5
setgrent	-1	5
sethostent	-1	5
setnetent	-1	5
setpgrp		-1	5
setpriority	-1	5
setprotoent	-1	5
setpwent	-1	5
setservent	-1	5
setsockopt	-1	5
shift		-1	5
shmctl		-1	5
shmget		-1	5
shmread		-1	5
shmwrite	-1	5
shutdown	-1	5
sin		-1	5
sleep		-1	5
socket		-1	5
socketpair	-1	5
sort		-1	5
splice		-1	5
split		-1	5
sprintf		-1	5
sqrt		-1	5
srand		-1	5
stat		-1	5
study		-1	5
sub		-1	5
substr		-1	5
symlink		-1	5
syscall		-1	5
sysread		-1	5
system		-1	5
syswrite	-1	5
tell		-1	5
telldir		-1	5
time		-1	5
times		-1	5
tr		-1	5
truncate	-1	5
umask		-1	5
undef		-1	5
unless		-1	5
unlink		-1	5
unpack		-1	5
unshift		-1	5
until		-1	5
utime		-1	5
values		-1	5
vec		-1	5
wait		-1	5
waitpid		-1	5
wantarray	-1	5
warn		-1	5
while		-1	5
write		-1	5
y		-1	5
