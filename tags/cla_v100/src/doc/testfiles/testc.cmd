@ECHO OFF
 GOTO end
 
: this file is to be used with installed NEPMD
: It will not show correct highlighting with EPMBBS files

Comment - DEFAULT BLUE
======================
REM this is a comment */

Literal - DEFAULT GREEN
==========================
"this is a literal" 'this is a literal'

special characters - DEFAULT RED
=====================================
% & ( ) * , / < > @ \ | ª

OS/2 keywords - DEFAULT MAGENTA
================================
BREAK DATE ON SETLOCAL

external executables of OS/2 and MDOS - DEFAULT RED
===================================================
CHKDSK EAUTIL SETBOOT VIEW

:end
