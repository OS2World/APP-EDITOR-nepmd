@ECHO OFF
 SETLOCAL
 SET EPMPATH=%EPMPATH%;macros;..\..\..\compile\base\netlabs\ex;

 start epm *.e *.c
