/****************************** Module Header *******************************
*
* Module Name: macros.h
*
* Debug and PM related macros.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: macros.h,v 1.1 2002-06-03 22:27:07 cla Exp $
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
****************************************************************************/

#ifndef MACROS_H
#define MACROS_H

#ifdef DEBUG
#define FUNCENTER  printf( "%s: ->\n", __FUNCTION__)
#define FUNCEXIT   printf( "%s: <-\n", __FUNCTION__)
#define FUNCEXITRC printf( "%s: <- rc=%u/0x%p\n", __FUNCTION__, rc, rc)
#define DPRINTF(p) printf p
#define DMARK      printf( "%s: (%u)\n", __FUNCTION__, __LINE__)

#include <malloc.h>

#define CHECKMEM   fprintf( stderr, "\n%s(%u) : checkmem in %s()\n\n", __FILE__, __LINE__, __FUNCTION__); \
                   fflush( stderr);                                                      \
                   _set_crt_msg_handle( 1);                                     \
                   _dump_allocated( 128);                                       \
                   fprintf( stderr, "\n%s(%u) : heapchk %s()returns %u\n\n", __FILE__, __LINE__, __FUNCTION__, _heapchk());

#else
#define FUNCENTER
#define FUNCEXIT
#define FUNCEXITRC
#define DPRINTF(p)
#define DMARK
#define CHECKMEM
#endif


#define CR      "\r"
#define LF      "\n"
#define NEWLINE LF
#define MAX(a,b)        (a > b ? a : b)
#define MIN(a,b)        (a < b ? a : b)

// some string handling
// internal macro to display a message
#define NEXTSTR(s)               (s+strlen(s)+1)
#define ENDSTR(s)                (s+strlen(s))
#define _EOS(s)                  ((PSZ)s + strlen( s))
#define _EOSSIZE(s)              (sizeof( s) - strlen( s))

// some basic PM stuff
#define CURRENTHAB                          WinQueryAnchorBlock(HWND_DESKTOP)
#define LASTERROR                           ERRORIDERROR( WinGetLastError( CURRENTHAB))
#define SHOWFATALERROR(h,s)                 WinMessageBox( HWND_DESKTOP, h, s, __APPNAME__" - Fatal Error !", -1, MB_CANCEL | MB_ERROR | MB_MOVEABLE)
#define SHOWERROR(s)                        WinMessageBox( HWND_DESKTOP, hwnd, s, __APPNAME__, -1, MB_CANCEL | MB_ERROR | MB_MOVEABLE)
#define SETFOCUS(hwnd,id)                   (WinSetFocus( HWND_DESKTOP, WinWindowFromID( hwnd, id)))

// set pointer
#define SETSYSPTR(id)                       (WinSetPointer( HWND_DESKTOP, WinQuerySysPointer( HWND_DESKTOP, id, FALSE)))

// query dialog info
#define WINDOWID(hwnd)                      (WinQueryWindowUShort( hwnd, QWS_ID))
#define CLIENTWINDOWID(hwnd)                (WinQueryWindowUShort( WinWindowFromID( hwnd, FID_CLIENT), QWS_ID))

// query dialog items
#define EXISTSWINDOW(hwnd,id)               (WinWindowFromID ( hwnd, id))

// enable/show dialog item
#define ENABLEWINDOW(hwnd,id,flag)          (WinEnableWindow(  WinWindowFromID( hwnd, id), flag))
#define SHOWWINDOW(hwnd,id,flag)            (WinShowWindow(  WinWindowFromID( hwnd, id), flag))
#define ENABLEWINDOWUPDATE(hwnd,id,flag)    (WinEnableWindowUpdate(  WinWindowFromID( hwnd, id), flag))

// query dialog item values
#define QUERYTEXTVALUE(hwnd,id,buf)         (WinQueryDlgItemText( hwnd, id, sizeof(buf), (PSZ)buf))
#define QUERYTEXTVALUE2(hwnd,id,buf,len)    (WinQueryDlgItemText( hwnd, id, len, (PSZ)buf))
#define QUERYCHECKVALUE(hwnd,id)            ((USHORT) WinSendDlgItemMsg( hwnd, id, BM_QUERYCHECK, 0L, 0L))
#define DLGQUERYSPINNUMVALUE(hwnd,id,pf)    (WinSendDlgItemMsg( hwnd, id, SPBM_QUERYVALUE, MPFROMP( pf), MPFROM2SHORT( 0, SPBQ_ALWAYSUPDATE)))


// set dialog item values
#define SETCHECKVALUE(hwnd,id,check)        (WinSendMsg( WinWindowFromID( hwnd,id), BM_SETCHECK, (MPARAM) (check != 0), 0L))
#define SETTEXTVALUE(hwnd,id,buf)           (WinSetDlgItemText( hwnd,id, buf))
#define SETTITLETEXT(hwnd, buf)             (WinSetWindowText( WinWindowFromID( WinQueryWindow( hwnd, QW_PARENT), FID_TITLEBAR), buf))
#define SETDLGTITLETEXT(hwnd, buf)          (WinSetWindowText( WinWindowFromID( hwnd, FID_TITLEBAR), buf))
#define SETTEXTLIMIT(hwnd,id,buf)           ((BOOL) WinSendDlgItemMsg( hwnd, id, EM_SETTEXTLIMIT, MPFROMSHORT(sizeof(buf)), 0L))
#define SETREADONLY(hwnd,id,flag)           ((BOOL) WinSendDlgItemMsg( hwnd, id, EM_SETREADONLY, MPFROMSHORT( flag), 0L))
#define SETTEXTLIMIT_S(hwnd,id,size)        ((BOOL) WinSendDlgItemMsg( hwnd, id, EM_SETTEXTLIMIT, MPFROMSHORT(size), 0L))
#define DLGINITSPIN(hwnd,id,high,low)       (WinSendDlgItemMsg( hwnd, id, SPBM_SETLIMITS, MPFROMLONG(high), MPFROMLONG(low)))
#define DLGSETSPIN(hwnd,id,value)           (WinSendDlgItemMsg( hwnd, id, SPBM_SETCURRENTVALUE, MPFROMLONG(value), 0L))

// simple listbox macros
#define INSERTITEM(hwnd,id,text)            ((ULONG) WinSendDlgItemMsg( hwnd, id, LM_INSERTITEM,      MPFROMSHORT( LIT_END), (MPARAM) text))
#define INSERTITEM_S(hwnd,id,text)          ((ULONG) WinSendDlgItemMsg( hwnd, id, LM_INSERTITEM,      MPFROMSHORT( LIT_SORTASCENDING), (MPARAM) text))
#define DELETEITEM(hwnd,id,item)            (        WinSendDlgItemMsg( hwnd, id, LM_DELETEITEM,      MPFROMSHORT( item), 0L))
#define DELETEALLITEMS(hwnd,id)             (        WinSendDlgItemMsg( hwnd, id, LM_DELETEALL,       0L, 0L))
#define SETITEMTEXT(hwnd,id,item,text)      (        WinSendDlgItemMsg( hwnd, id, LM_SETITEMTEXT,     MPFROMSHORT( item), (MPARAM) text))
#define QUERYITEMTEXT(hwnd,id,item,buf)     (        WinSendDlgItemMsg( hwnd, id, LM_QUERYITEMTEXT,   MPFROM2SHORT(item,sizeof(buf)), (MPARAM) buf))
#define QUERYSELECTION(hwnd,id,item)        ((ULONG) WinSendDlgItemMsg( hwnd, id, LM_QUERYSELECTION,  MPFROMSHORT( item), 0L))
#define SETSELECTION(hwnd,id,item)          (        WinSendDlgItemMsg( hwnd, id, LM_SELECTITEM,      MPFROMSHORT(item),MPFROMSHORT(TRUE)))
#define QUERYITEMCOUNT(hwnd,id)             ((ULONG) WinSendDlgItemMsg( hwnd, id, LM_QUERYITEMCOUNT,  0L, 0L))
#define SETITEMHANDLE(hwnd,id,item,handle)  (        WinSendDlgItemMsg( hwnd, id, LM_SETITEMHANDLE,   MPFROMSHORT( item), (MPARAM) handle))
#define QUERYITEMHANDLE(hwnd,id,item)       ((PVOID) WinSendDlgItemMsg( hwnd, id, LM_QUERYITEMHANDLE, MPFROMSHORT( item), 0L))
#define SEARCHITEM(hwnd,id,text)            ((ULONG) WinSendDlgItemMsg( hwnd, id, LM_SEARCHSTRING,    MPFROM2SHORT( 0, LIT_FIRST), (MPARAM) text))
#define QUERYTOPITEM(hwnd,id)               ((ULONG) WinSendDlgItemMsg( hwnd, id, LM_QUERYTOPINDEX,   0, 0))

// menu macros
#define FRAMEWINDOW(h)                      WinQueryWindow( h, QW_PARENT)
#define FRAMEMENU(h)                        WinWindowFromID( WinQueryWindow( h, QW_PARENT), FID_MENU)
#define ENABLEMENUITEM(h,i,c)               WinSendMsg( h, MM_SETITEMATTR, MPFROM2SHORT( i, TRUE), MPFROM2SHORT( MIA_DISABLED, (c) ? ~MIA_DISABLED : MIA_DISABLED))
#define NODISMISSMENUITEM(h,i)              WinSendMsg( h, MM_SETITEMATTR, MPFROM2SHORT( i, TRUE), MPFROM2SHORT( MIA_NODISMISS, MIA_NODISMISS))
#define DELETEMENUITEM(h,i)                 WinSendMsg( h, MM_DELETEITEM, MPFROM2SHORT( i, TRUE), 0)
#define SETMENUCHECKVALUE(h,i,c)            WinSendMsg( h, MM_SETITEMATTR, MPFROM2SHORT( i, TRUE), MPFROM2SHORT( MIA_CHECKED, (c) ? MIA_CHECKED : ~MIA_CHECKED))

#endif //MACROS_H

