;  DRAWKEY.E
;  Taken from DRAW.E, to make it separately compilable.
;
def F6=
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
compile if EVERSION < 5
   cursor_command
   'draw'
compile else
 compile if WANT_DBCS_SUPPORT
   if ondbcs then
      sayerror DRAW_ARGS_DBCS__MSG
   else
 compile endif
      sayerror DRAW_ARGS__MSG
 compile if WANT_DBCS_SUPPORT
   endif
 compile endif
   'commandline draw '
compile endif
