/****************************** Module Header *******************************
*
* Module Name: epmdefassocs.cmd
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmdefassocs.cmd,v 1.2 2007-03-02 04:16:19 jbs Exp $
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
call RxFuncAdd 'SysLoadFuncs', 'REXXUTIL', 'SysLoadFuncs'
call SysLoadFuncs
call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
call WPToolsLoadFuncs

signal on novalue                                  /* for debug purposes */

GlobalVars = 'Objs. Assocs. AssocTypes action ERROR. env TRUE FALSE Redirection interactive action defaultoption';

call Init                                          /* Initialize variables */

tracevar =  value('DEFASSOCTRACE',, env)           /* for debug purposes */
if tracevar == "" then
   tracevar = 'n'
trace value tracevar

parse arg args                                     /* Process parameters, if any */
call ProcessArgs args

call GetAssocs                                     /* Get association for selected objects */

do o = 1 to Objs.0
   ObjHandle = GetObjHandle(Objs.o.ID)
Relist:
   option = defaultoption
   i = 0
   ActionList = ''
   outline = ''
   do t = 1 to words(AssocTypes)
      AssocType = word(AssocTypes, t)
      do a = 1 to Objs.o.Assocs.AssocType.0
         if words(Objs.o.Assocs.AssocType.a.AssocObjs) > 0 then
            if (action == 'SET' & word(Objs.o.Assocs.AssocType.a.AssocObjs, 1) \= ObjHandle) | ,
               (action == 'RESET' & word(Objs.o.Assocs.AssocType.a.AssocObjs, 1) == ObjHandle) then
               do
                  ActionList = ActionList AssocType a
                  if interactive = TRUE then
                     do
                        if i == 0 then
                           call ShowHeading Objs.o.Title, Objs.o.type.list, Objs.o.filter.list
                        if i // Objs.o.Assocs.Number_per_line == 0 then
                           do
                              say outline
                              outline = ''
                           end
                        i = i + 1
                        outline = outline || right(i, 2) || ') ' || left(Objs.o.Assocs.AssocType.a, Objs.o.Assocs.Maxlen)
                     end
               end
      end
   end

   if interactive == TRUE & words(ActionList) > 0 then
      do
         if length(outline) \= 0 then
            say outline
         say
         say 'To remove a type or filter from the list, enter its number.'
         if action == 'SET' then
            say 'To make 'Objs.o.Title' the default for all these types and filters, type ''Y''.'
         else
            say 'To remove 'Objs.o.Title' as the default for all these types and filters, type ''Y''.'
         if action == 'SET' then
            say 'Type ''N'' to reject making 'Objs.o.Title' the default application.'
         else
            say 'Type ''N'' to keep 'Objs.o.Title' as the default application.'
         say
         option = translate(strip(linein()))
         if datatype(option) == 'NUM' then
            if option <= i then
               do
                  t = word(ActionList, 2 * option - 1)
                  a = word(ActionList, 2 * option)
                  Objs.o.Assocs.t.a.AssocObjs = delword(Objs.o.Assocs.t.a.AssocObjs, wordpos(ObjHandle, Objs.o.Assocs.t.a.AssocObjs), 1)
                  if action == 'SET' then
                     Objs.o.Assocs.t.a.AssocObjs = ObjHandle Objs.o.Assocs.t.a.AssocObjs
                  else
                     Objs.o.Assocs.t.a.AssocObjs = Objs.o.Assocs.t.a.AssocObjs ObjHandle
                  signal Relist
               end
            else
               nop
         else
            if wordpos(option, 'Y N') == 0 then
               option = defaultoption
      end
/*
   else
      say '"'Objs.o.Title'" is already set to be the default application for all types and filters.'
*/

   if option == 'Y' then
      do t = 1 to words(AssocTypes)
         AssocType = word(AssocTypes, t)
         do a = 1 to Objs.o.Assocs.AssocType.0
            wp = wordpos(ObjHandle, Objs.o.Assocs.AssocType.a.AssocObjs)
            if action == 'SET' then
               do
                  if wp == 0 then
                     Objs.o.Assocs.AssocType.a.AssocObjs = ObjHandle Objs.o.Assocs.AssocType.a.AssocObjs
                  else
                     Objs.o.Assocs.AssocType.a.AssocObjs = ObjHandle delword(Objs.o.Assocs.AssocType.a.AssocObjs, wp, 1)
                  rcx = SysIni(, 'PMWP_ASSOC_' || AssocType, Objs.o.Assocs.AssocType.a, translate(Objs.o.Assocs.AssocType.a.AssocObjs, '00'x, ' '))
                  if rcx \= '' then
                     say 'Set default error for 'Objs.o.Assocs.AssocType.a': 'rcx
               end
            else
               do
                  /* Reset only if this is the default and there is more than one association */
                  if (wp == 1 & words(Objs.o.Assocs.AssocType.a.AssocObjs) > 1) then
                        Objs.o.Assocs.AssocType.a.AssocObjs = substr(Objs.o.Assocs.AssocType.a.AssocObjs, wordindex(Objs.o.Assocs.AssocType.a.AssocObjs, 2)) || ObjHandle
                        rcx = SysIni(, 'PMWP_ASSOC_' || AssocType, Objs.o.Assocs.AssocType.a, translate(Objs.o.Assocs.AssocType.a.AssocObjs, '00'x, ' '))
                        if rcx \= '' then
                           say 'Reset default error for 'Objs.o.Assocs.AssocType.a': 'rcx
                     end
               end

         end
      end
end

return

ShowHeading: procedure expose (GlobalVars)
   parse arg ObjTitle, Typelist, FilterList
   call SysCls
   say
   say '"'ObjTitle'" is associated with the following types:'
   say
   say TypeList
   say
   say 'and with the following filters:'
   say
   say FilterList
   say
   say
   call charout , '"'ObjTitle'" is '
   if action == 'SET' then
      call charout , 'not '
   say 'currently set as the default application for:'
return

Init: procedure expose (GlobalVars)
   '@ECHO OFF';
   env   = 'OS2ENVIRONMENT';
   TRUE  = (1 = 1);
   FALSE = (0 = 1);
   CrLf  = '0d0a'x;
   Redirection = '>NUL 2>&1';

   /* some OS/2 Error codes */
   ERROR.NO_ERROR           =   0;
   ERROR.INVALID_FUNCTION   =   1;
   ERROR.FILE_NOT_FOUND     =   2;
   ERROR.PATH_NOT_FOUND     =   3;
   ERROR.ACCESS_DENIED      =   5;
   ERROR.NOT_ENOUGH_MEMORY  =   8;
   ERROR.INVALID_FORMAT     =  11;
   ERROR.INVALID_DATA       =  13;
   ERROR.NO_MORE_FILES      =  18;
   ERROR.WRITE_FAULT        =  29;
   ERROR.READ_FAULT         =  30;
   ERROR.SHARING_VIOLATION  =  32;
   ERROR.GEN_FAILURE        =  31;
   ERROR.INVALID_PARAMETER  =  87;
   ERROR.ENVVAR_NOT_FOUND   = 204;

   rc = ERROR.NO_ERROR;

   Objs.      = ''
   AssocTypes = 'TYPE FILTER'
return

ProcessArgs: procedure expose (GlobalVars)
   /* To do: Accept a list of objects as parameters */
   parse upper arg action .                           /* Process parameters, if any */
   /* Hard-coded object id's for now. */
   Objs.1.ID = '<NEPMD_EPM>'
   Objs.2.ID = '<NEPMD_EPM_E>'
   Objs.3.ID = '<NEPMD_EPM_EDIT_MACROFILE>'
   Objs.4.ID = '<NEPMD_EPM_ERX>'
   Objs.5.ID = '<NEPMD_EPM_TEX>'
   Objs.6.ID = '<NEPMD_EPM_BIN>'
   Objs.0    = 6
   action = strip(action)
   interactive = TRUE
   action = 'SET'                                     /* Set default values */
   defaultoption = 'N'
   if action \= '' then
      if wordpos(action, 'SET RESET') > 0 then
         do
            interactive = FALSE
            defaultoption = 'Y'
         end
return

GetAssocs: procedure expose (GlobalVars)
   do o = 1 to Objs.0
      Objs.o.Assocs. = ''
      Objs.o.Assocs.type.0 = 0
      Objs.o.Assocs.filter.0 = 0
      ObjSetup  = GetObjSetup(Objs.o.ID)
      parse var ObjSetup . 'ASSOCTYPE=' Objs.o.type.list ',,;' .
      parse var ObjSetup . 'ASSOCFILTER=' Objs.o.filter.list ',,;' .
      parse var ObjSetup . 'TITLE=' Objs.o.Title ';' .
      Objs.o.Assocs.Maxlen = 0
      i = 0
      t = strip(Objs.o.type.list, 'T', ',')
      do while t \= ''
         i = i + 1
         parse var t Objs.o.Assocs.type.i ',' t
         l = length(Objs.o.Assocs.type.i)
         if l > Objs.o.Assocs.Maxlen then
            Objs.o.Assocs.Maxlen = l
      end
      Objs.o.Assocs.type.0 = i
      i = 0
      t = strip(Objs.o.filter.list, 'T', ',')
      do while t \= ''
         i = i + 1
         parse var t Objs.o.Assocs.filter.i ',' t
         l = length(Objs.o.Assocs.filter.i)
         if l > Objs.o.Assocs.Maxlen then
            Objs.o.Assocs.Maxlen = l
      end
      Objs.o.Assocs.filter.0 = i
      Objs.o.Assocs.Maxlen = Objs.o.Assocs.Maxlen + 2

      parse value SysTextScreenSize() with . cols
      if cols == 0 then
         cols = 80
      Objs.o.Assocs.Number_per_line = trunc(cols / (Objs.o.Assocs.Maxlen + 4))

      do t = 1 to words(AssocTypes)
         AssocType = word(AssocTypes, t)
         App = 'PMWP_ASSOC_' || AssocType
         do a = 1 to Objs.o.Assocs.AssocType.0
            Objs.o.Assocs.AssocType.a.AssocObjs = translate(SysIni(, App, Objs.o.Assocs.AssocType.a), ' ', '00'x)
         end
      end
   end
return

GetObjHandle: procedure expose (GlobalVars)
   parse arg objid
   BinObjHandle = reverse(SysIni(, 'PM_Workplace:Location', objid))
   DecObjHandle = c2d(BinObjHandle)
return DecObjHandle

GetObjSetup: procedure expose (GlobalVars)
   parse arg obj
   call WPToolsQueryObject obj,,, 'setup'
   if right(setup, 1) \= ';' then
      setup = setup || ';'
return setup

novalue:
   say 'Unset value on line 'sigl
   say 'Text: 'sourceline(sigl)
   exit
