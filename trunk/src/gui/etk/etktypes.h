#ifndef ETKTYPES_INCLUDED
  #define ETKTYPES_INCLUDED

  /* as of June 1992, we are still using lstrings with      */
  /* byte length fields.  We expect this to change shortly. */
  /* When this change occurs, LSTRINGLENTYPELEN will also   */
  /* change.                                                */

  #define  LSTRINGLENTYPELEN 2


  #if LSTRINGLENTYPELEN == 1
     #define  LSTRINGLENTYPE UCHAR
     // CPLSZ is Constant PLSTRING PSZ string
     #define MAKECPLSZ(l,s) l s
     #ifndef MAXCOL
        #define MAXCOL 255
     #endif
  #elif LSTRINGLENTYPELEN == 2
     #define  LSTRINGLENTYPE USHORT
     #define MAKECPLSZ(l,s) l "\0" s
     #ifndef MAXCOL
        #define MAXCOL 1600
     #endif
  #else
     #error New macro definition needed!
  #endif
  #define CONSTPLSTRING(l,s) ((PLSTRING)(MAKECPLSZ(l,s)))

  #define LSTRINGSTRUCT(dlength) \
     struct { \
        LSTRINGLENTYPE lsLength; \
        unsigned char  Data[dlength]; \
     }


  typedef LSTRINGSTRUCT(MAXCOL)
  LSTRING, *PLSTRING, **PPLSTRING;

  #define sizeofLSTRING(len) ((len)+sizeof(LSTRINGLENTYPE))
  #define MAXCOLP1x sizeofLSTRING(MAXCOL)

  //#define sizeofLSTRING(len) sizeof(LSTRINGSTRUCT(len))


  /* LSTRLOCDECL(name,charlen) provides a way to create a local LSTRING variable       */
  /*   of arbitrary size that is known at compile time. This approach is a bit kludgy  */
  /*   but it seems necessary since C does not provide for variable length structures. */

  #define LSTRLOCDECL(name,charlen)  CHAR name##XXXXX [sizeofLSTRING(charlen)]; PLSTRING const name = (PLSTRING) name##XXXXX


   //The following flags are used for the EFRAMEM_QUERYFILEINFO &
   //                                     EPM_EDIT_QUERYFILEINFO messages
   #define QF_MODIFY      1
   #define QF_NAME        2
   #define QF_MARKTYPE    3
   #define QF_POINTER     4
   #define QF_HWND        5
   #define QF_TITLETEXT   6
   #define QF_FILESINRING 7
   #define QF_FILESIZE    8
   #define QF_ICONTEXT    9
   #define QF_MARKSIZE   10

   typedef struct {
     USHORT Message;
     MPARAM Mp1;
     MPARAM Mp2;
   } EIQMESSAGE, *PEIQMESSAGE;

   //structure used for EFRAMEM_QUERYSTATUSINFO, & EPM_EDIT_QUERYSTATUSINFO
   typedef struct {
      UCHAR insert, modify, zchar, readonly;
      USHORT autosave, views;
      ULONG row, col, size;
   } STATUSINFO, *PSTATUSINFO;




   #if OS2VERSION == 20
     #define PFUNC(CallingConvention, FunctionPtr) (* CallingConvention FunctionPtr)
     #define PFUNCPROT(CallingConvention) (* CallingConvention)
     #define MSG ULONG
   #else
     #define PFUNC(CallingConvention, FunctionPtr)  (CallingConvention * FunctionPtr)
     #define PFUNCPROT(CallingConvention)  (CallingConvention *)
     typedef PVOID *PPVOID;
     #define MSG USHORT
   #endif

   #if OS2VERSION >= 20
      typedef ULONG PascalFunc(VOID);
      #pragma linkage (PascalFunc, far16 pascal)
      typedef ULONG C16Func(VOID);
      #pragma linkage (C16Func, far16 cdecl)
      typedef ULONG SysFunc(VOID);
      #pragma linkage (SysFunc, system)
   #endif

   typedef union {
         #if OS2VERSION < 20
            ULONG   PFUNC(APIENTRY, pPasProcLong)(VOID); // address of function (Pascal) returning a long
            USHORT  PFUNC(APIENTRY, pProc)(VOID);     // address of function (Pascal) returning a short
            ULONG   PFUNC(cdecl,    cProcLong)(VOID); // address of function (C) returning a long
            USHORT  PFUNC(cdecl,    cProc)(VOID);     // address of function (C) returning a short
         #else
            //ULONG   (*  pProcLong)(VOID); // address of function (Pascal) returning a long
            PascalFunc *pPasProcLong;
            C16Func *pC16ProcLong;
            SysFunc *pSysProcLong;
            USHORT  (* _System pProc)(VOID);     // address of function (Pascal) returning a short
            ULONG   (* _System cProcLong)(VOID); // address of function (C) returning a long
            USHORT  (* _System cProc)(VOID);     // address of function (C) returning a short
            PVOID _Seg16    pv16;
         #endif
         ULONG   ul;
         PVOID           pv;
         #ifdef USE_NO_ASSEMBLER
            ULONG   (* _System SysProc0)(VOID);
            ULONG   (* _System SysProc1)(ULONG);
            ULONG   (* _System SysProc2)(ULONG, ULONG);
            ULONG   (* _System SysProc3)(ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc4)(ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc5)(ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc6)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc7)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc8)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc9)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc10)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc11)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG);
            ULONG   (* _System SysProc12)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG);
            ULONG   (* _System SysProc13)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc14)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc15)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc16)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc17)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc18)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc19)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
            ULONG   (* _System SysProc20)(ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG,
                                          ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG, ULONG);
         #endif
   } PROCCONV;

   // The following type is used to define the parameters needed when
   // executing a procedure using a procedure address.   JAC 8/90
   typedef struct _EPROC {
      PROCCONV ProcConv;
      USHORT  StackSize;                      // stack size in bytes
      USHORT  PascalC;                        // pascal or C convention.

      PCHAR   Stack;                          // pointer to the stack data
      USHORT  NumberOfReturnWords;            // number of return words in RC
      USHORT  StackRC;                        // TRUE if error in number of parameters
      ULONG   RC;                             // return value of proc
   } EPROC, *PEPROC;

   typedef struct _EPROC2 {
      EPROC   eproc;
      PSZ     pszModule;
      PSZ     pszProc;
      LONG    Flags;
           #define EDED_RESOLVEPROC_FLAG 1
           #define EDED_FREESEG_FLAG 2
           #define EDED_FREEMEM_FLAG 4
   } EPROC2, *PEPROC2;

#if OS2VERSION >= 20
   #define MYUINT ULONG
#else
   #define MYUINT USHORT
#endif

   #define  min(a,b)        (((a) < (b)) ? (a) : (b))
   #define  max(a,b)        (((a) > (b)) ? (a) : (b))

#endif
