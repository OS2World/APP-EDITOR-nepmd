/****************************** Module Header *******************************
*
* Module Name: math.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: math.e,v 1.4 2002-11-01 13:45:12 cla Exp $
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
; MATH.E      Combines old MATH.E and EXP.E.
;
;  Linking version for EOS2:  The bulk of the old MATH.E routines are
;  placed in another file MATHLIB.E, which is linked only when needed.
;
define math_link = 0

defc add=
   if marktype()=='' then
      'xcom L /[0-9]/g'      -- find first number
      if rc then
         sayerror "Can't find a number (from cursor position to end of file)"
         return
      endif
      call psave_pos(save_pos)
      markline
      for i=.line+1 to .last  -- find first line without a number
         if not verify(textline(i),'0123456789','M') then
            leave
         endif
      endfor
      .line=i-1; markline
      call column_math('+')
      unmark        -- Started with no mark
      call prestore_pos(save_pos)
   else
      getmark firstline,lastline,firstcol,lastcol,markfileid
      getfileid fileid
      if fileid<>markfileid then
         sayerror OTHER_FILE_MARKED__MSG UNMARK_OR_EDIT__MSG markfileid.filename
         return
      endif
      if not check_mark_on_screen() then
         sayerror MARK_OFF_SCREEN2__MSG
         return
      endif
      call column_math('+')
   endif

defc math=
   call mathcommon(arg(1),'')

defc matho=
   call mathcommon(arg(1),'o')

defc mathx=
   call mathcommon(arg(1),'x')

defc mult=
   call checkmark()
   call column_math('*')

defproc mathcommon(input,suffix)
   if evalinput(result,input,suffix) then
      call experror();stop
   else
      sayerror 'math'suffix input'= 'result  -- no setcommand in epm
   endif

   return

compile if DECIMAL = ','
   define thou_sep = '.'
compile else
   define thou_sep = ','
compile endif

defc mathin  -- Like MATH command, but keys in the result
   if word(arg(1), 1) = thou_sep then
      parse value arg(1) with sep input
   else
      input = arg(1)
      sep = ''
   endif
   if evalinput(result,input,'') then
      call experror(); stop
   endif
   sayerror 'math' input'= 'result  -- no setcommand in epm
   if sep & (result > 9999) then
      -- parse value result with whole (DECIMAL) fract
      p = pos(DECIMAL, result)
      if p then
         whole = leftstr(result, p-1)
         fract = substr(result, p+1)
      else
         whole = result
         fract = ''
      endif
      outstr = ''
      do while length(whole) > 3
         outstr = outstr || thou_sep || rightstr(whole, 3)
         whole = leftstr(whole, length(whole)-3)
      enddo
      result = whole || outstr
      if fract then
         result = result || DECIMAL || fract
      endif
   endif
   keyin result

defc mathxin  -- Like MATHX command, but keys in the result
   input = arg(1)
   if evalinput(result, input, 'x') then
      call experror(); stop
   endif
   sayerror 'mathx' input'= 'result  -- no setcommand in epm
   keyin '0x'rightstr(substr(result, 2), 8, 0)

;  The rest is the same as MATHLIB.E.  Must be compiled into base if we're
;  not running the linking version of EOS2 (unless INCLUDE_MATHLIB set).

defproc column_math
   getmark firstline,lastline,firstcol,lastcol,fileid
   result = arg(1)='*'   -- Result = 1 if '*', or 0 if '+'
;  if arg(1)='+' then
;     result=0
;  else
;    result=1
;  endif
   decimal_flag = 0

   call pinit_extract()
   loop
      code = pextract_string(line)
      if code = 1 then leave endif
      if code = 0 then  /* ignore blank lines */
         -- Find the number within the line.  Frees the user from having
         -- to have a perfectly-fitting block mark around the numbers.
         -- jbl 12/20/88 bug fix:  line might start with minus sign or decimal.
         -- LAM: The Parse was using only the first number on each line.
         startnum = verify(line,'0123456789-'DECIMAL,'M')
         if startnum then
;           parse value substr(line,startnum) with line .
            line = substr(line,startnum)
         endif
         if evalinput(tempresult, line, '',arg(1)) then
            call experror()
         else
            if arg(1)='+' then
               if pos('.',tempresult) then
                  decimal_flag = max(length(tempresult)-pos('.',tempresult), decimal_flag)
               endif
               result=result+tempresult
            else
               result=result*tempresult
            endif
         endif
      endif
   endloop
   if decimal_flag then  -- LAM:  Merge in CHC changes
      if pos('.',result) then   -- there's a decimal but the final zero is gone
         result = result || copies(0, decimal_flag - (length(result)-pos('.',result)))
      else
         result = result'.'copies(0, decimal_flag)
      endif
   endif
   -- Line up with decimal point of last line if there is one, else line up
   -- by the last digit of last line.  The old way lined up by the first digit
   -- which was seldom desirable:
   --insertline substr('',1,firstcol-1)result,lastline+1,fileid
   res_len = length(result)
   p = pos(DECIMAL,result)
   if p then
      q = pos(DECIMAL,line)
      if q then
         lpad = startnum+q-p-1
      else
         lpad = startnum+length(line)-p
      endif
   else
      lpad = startnum+length(line)-res_len-1
   endif

   -- jbl 12/11/88:  make it work with or without a marked area.
   lpad = max(lpad + firstcol -1, 0)

   -- If the next line has spaces in the proper posiition, fill them,
   -- don't insert a new line.
   if lastline<.last then
      getline line, lastline+1
   else
      line=''
   endif
   -- If the next line is all same character, like a dotted line, skip over.
   dash = substr(line, lpad+1, res_len)
   ch = substr(dash,1,1)
   if not verify(dash,ch) & ch<>' ' then
      lastline=lastline+1
      if lastline<.last then
         getline line, lastline+1
      endif
   endif
   if not verify(substr(line,lpad+1,res_len),' ') & lastline<.last then
      replaceline overlay(result,line,lpad+1), lastline+1
   else
      pad = substr(' ',1,lpad)
      insertline pad || result,lastline+1,fileid
   endif


/* returns 0 if expression evaluated successfully. */
/* result is set to evaluation of expression when successful */
/* returns 1 if error.  No message displayed */
defproc evalinput(var result,var sourceline,output)
   universal i,input
   universal exp_stack
   universal sym

   exp_stack=''
   i=pos('=',sourceline)
   if i then
      sourceline=substr(sourceline,1,i-1)
   endif
   input=sourceline
   i=1; call next_sym()
   call exp(arg(4))  -- Accept & pass to exp an optional 4th argument
   if sym<>'$' then
      return 1
   else
      result=strip(exp_stack)
      if output='x' then
         result=dec2hex(result)
      elseif output='o' then
         result=dec2hex(result,8)
      endif
      return 0
   endif


;  EXP takes an optional argument saying what the default operator
;  should be.  (I.e., what operator should be assumed if 2 numbers appear one
;  after the other).  If not given, error.  ('+' was assumed previously.)
defproc exp
   universal sym
   op_stack='$'
   loop
      call unary_exp(arg(1))   -- Pass to unary_exp, because it calls us.
      /* look for dual operator */
      if pos(sym,'+-*%/?') then
         oldsym=''
      else
         if not isnum(sym) & sym<>'(' then  -- '(' OK for column math.
            leave
         endif
         oldsym=sym
         if arg(1) then sym=arg(1); else call experror(); stop; endif
      endif
      while prec(substr(op_stack,length(op_stack)))>=prec(sym) do
         call reduce_dualop(substr(op_stack,length(op_stack)))
         op_stack=substr(op_stack,1,length(op_stack)-1)
      endwhile
      op_stack=op_stack||sym
      if oldsym='' then
         call next_sym()
      else
         sym=oldsym
      endif
   endloop
   for j=length(op_stack) to 2 by -1
      call reduce_dualop(substr(op_stack,j,1))
   endfor


defproc experror
   sayerror SYNTAX_ERROR__MSG


/* Dec2Hex       Usage:  HexStringOut=Dec2Hex(DecimalIn)          */
/*               Result will be a string beginning with 'x'.      */
/*  If decimal number is invalid, null string is returned.        */
defproc dec2hex
   if arg(2)<>'' then base=arg(2);output='o' else base=16;output='x' endif
   if base='' then base=16 endif
   dec=arg(1)
   if not isnum(dec) then
      return ''
   endif
   if dec<0 then
      dec=dec+ MAXINT+1
   endif
   vhex=''
   while dec>0 do
      i=dec%base
      vhex=substr('0123456789ABCDEF',dec-i*base+1,1)vhex
      dec=i
   endwhile
   if vhex='' then
      vhex='0'
   endif
   if arg(1)<0 then
      if base=8 then
         vhex='1'vhex
      else
         vhex='F'substr(vhex,2)
      endif
   endif
   return output||vhex


/* Hex2Dec       Usage:  DecimalOut=Hex2Dec(HexStringIn)                   */
/*                       where HexStringIn may optionally begin with 'X'.  */
/*  If hex number is invalid, null string is returned.                     */
defproc hex2dec
   if arg(2)<>'' then base=arg(2) else base=16 endif
   vhex=arg(1)
   if vhex='' then
      return ''
   endif
   dec=0
   loop
      i=upcase(substr(vhex,1,1))
      if i='' then leave endif
      if i<>'X' then                     /* Ignore initial X if any. */
         i=pos(i,'0123456789ABCDEF')
         if not i then
            return ''
         endif
         dec=dec*base -1 +i
      endif
      vhex=substr(vhex,2)
   endloop
   return dec

defproc lex_number
   universal input,i
   universal sym
   universal j

   if not j then j=length(input)+1 endif
   sym=substr(input,i+1,j-i-1)
   sym=hex2dec(sym,arg(1))
   if sym=='' then
      call experror();stop
   endif
   i=j

defproc next_sym
   universal sym
   universal input,i
   universal j

   call skip_spaces()
   if i>length(input) then sym='$';return '' endif
   sym=substr(input,i,1)
   if pos(sym,'Oo\xX0123456789+-/%*()'DECIMAL) then
      if isnum(sym) then
         j=verify(input,'0123456789'DECIMAL,'',i)
         if not j then j=length(input)+1 endif
         sym=substr(input,i,j-i)
 compile if 0 -- DECIMAL <> '.'  -- work in progress...
         i = pos(DECIMAL, sym)
         if i then
            sym = overlay('.', sym, i)
         endif
 compile endif  -- DECIMAL <> '.'
         i=j
      elseif upcase(sym)='X' then
         j=verify(input,'0123456789ABCDEFabcdef','',i+1)
         call lex_number(16)
      elseif upcase(sym)='O' or sym='\' then
         j=verify(input,'01234567','',i+1)
         call lex_number(8)
      else
         i=i+1
         if sym='/' & substr(input,i,1)='/' then
            sym = '?'  -- Use '?' to represent '//'
            i=i+1
         endif
      endif
   else
      call experror();stop
   endif

defproc prec
   /* Group operators in 4's so +- and *%/? each have same precedence. */
   return pos(arg(1),'$  +-  *%/?')%4+1

defproc reduce_dualop
   universal exp_stack
   parse value exp_stack with e2 e1 exp_stack
   if arg(1)='+' then
      exp_stack=e1+e2 exp_stack
   elseif arg(1)='-' then
      exp_stack=e1-e2 exp_stack
   elseif arg(1)='*' then
      exp_stack=e1*e2 exp_stack
   elseif arg(1)='/' then
      exp_stack=e1/e2 exp_stack
   elseif arg(1)='%' then
      exp_stack=e1%e2 exp_stack
   elseif arg(1)='?' then
      exp_stack=e1//e2 exp_stack
   endif

defproc skip_spaces
   universal input,i
   j=verify(input,' ','',i)
   if j then
      i=j
   else
      i=length(input)+1
   endif

defproc unary_exp
   universal exp_stack
   universal sym

   if sym='(' then
      call next_sym()
      call exp(arg(1))
      if sym<>')' then experror();stop endif
      call next_sym()
   elseif isnum(sym) then
      exp_stack=sym exp_stack
      call next_sym()
   elseif sym='-' then
      call next_sym()
      call unary_exp(arg(1))
      parse value exp_stack with e1 exp_stack
      exp_stack=-e1 exp_stack
   elseif sym='+' then
      call next_sym()
      call unary_exp()
   else
      call experror();stop
   endif

