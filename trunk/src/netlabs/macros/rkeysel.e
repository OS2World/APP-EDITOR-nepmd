;      An if-block that gets included into select_edit_keys().
   if ext='BAT' | ext='CMD' | ext='EXC' | ext='EXEC' | ext='XEDIT' then
      getline line,1
      if substr(line,1,2)='/*' or (line='' & .last = 1) then
         keys   rexx_keys
         'tabs' REXX_TABS
         'ma'   REXX_MARGINS
      endif
   endif
