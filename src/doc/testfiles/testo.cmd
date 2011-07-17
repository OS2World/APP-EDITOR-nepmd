EXTPROC objgen

; this file is to be used with installed NEPMD
; It will not show correct highlighting with EPMBBS files


CLASS         WPFolder
TITLE         Demo folder
LOCATION      <WP_DESKTOP>
ID            <DEMO_FOLDER>
OPTION        UPDATE

CLASS         WPProgram
TITLE         show files in this dir
LOCATION      <DEMO_FOLDER>
ID            <DEMO_EXEC_OPEN>
OPTION        UPDATE
PROGTYPE      WINDOWABLEVIO
MAXIMIZED     YES
EXENAME       *
PARAMETERS    /C DIR
STARTUPDIR    %CALLDIR%

