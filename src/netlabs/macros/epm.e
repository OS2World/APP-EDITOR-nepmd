define INCLUDING_FILE = 'EPM.E'

include 'e.e'       -- This is the main file for all versions of E.

compile if EVERSION >= '6.00c'
 compile if EXTRA_EX
   compiler_msg EXTRA_EX is set; not needed for EPM 6.00.  You might want to modify
   compiler_msg your MYCNF.E.  Don't forget to recompile EXTRA if appropriate.
 compile endif
 compile if LINK_HOST_SUPPORT
   compiler_msg LINK_HOST_SUPPORT is set; not needed for EPM 6.00.  You might want to
    compiler_msg modify your MYCNF.E.
  compile if HOST_SUPPORT = 'EMUL'
    compiler_msg Don't forget to recompile E3EMUL if appropriate.
  compile elseif HOST_SUPPORT = 'SRPI'
    compiler_msg Don't forget to recompile SLSRPI if appropriate.
  compile else
    compiler_msg Don't forget to recompile your host support if appropriate.
  compile endif
 compile endif
compile endif
