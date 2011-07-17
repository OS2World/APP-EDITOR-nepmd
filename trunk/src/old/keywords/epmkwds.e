@ ***************************** Module Header ******************************\
@
@ Module Name: epmkwds.e
@
@ Copyright (c) Netlabs EPM Distribution Project 2002
@
@ $Id$
@
@ ===========================================================================
@
@ This file is part of the Netlabs EPM Distribution package and is free
@ software.  You can redistribute it and/or modify it under the terms of the
@ GNU General Public License as published by the Free Software
@ Foundation, in version 2 as it comes in the "COPYING" file of the
@ Netlabs EPM Distribution.  This library is distributed in the hope that it
@ will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
@ of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
@ General Public License for more details.
@
@ **************************************************************************/

@ ------------------------------------------------------------------
@ Format of the file - see NEPMD.INF
@ ------------------------------------------------------------------
@
@  This file is used by EPM to figure out which keywords to hilite
@  See EPMKWDS.C for additional documentation.
@
@ -----------------------------------------------------------------
@ Actual description of the keywords
@ -----------------------------------------------------------------
@
@DELIM
@
@ Start   Color Color  End     Escape
@ string  bg    fg     string  character  Col.
  /*      14     0      */
  --      14     0
  ;       14     0      @       @         1
  "       -1     2      "
  '       -1     2      '
@
@SPECIAL
@
; -1 12
, -1 12
@
@CHARSET
@
abcdefghijklmnopqrstuvwxyz_#ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.
@
@INSENSITIVE
@
@ -------------------- compile-time keywords ---------------------------
#define            -1 9
a_0                -1 9
a_1                -1 9
a_2                -1 9
a_3                -1 9
a_4                -1 9
a_5                -1 9
a_6                -1 9
a_7                -1 9
a_8                -1 9
a_9                -1 9
a_a                -1 9
a_b                -1 9
a_backslash        -1 9
a_backspace        -1 9
a_c                -1 9
a_comma            -1 9
a_d                -1 9
a_e                -1 9
a_enter            -1 9
a_equal            -1 9
a_equal            -1 9
a_f                -1 9
a_f1               -1 9
a_f10              -1 9
a_f11              -1 9
a_f12              -1 9
a_f2               -1 9
a_f3               -1 9
a_f4               -1 9
a_f5               -1 9
a_f6               -1 9
a_f7               -1 9
a_f8               -1 9
a_f9               -1 9
a_g                -1 9
a_h                -1 9
a_i                -1 9
a_j                -1 9
a_k                -1 9
a_l                -1 9
a_left_bracket     -1 9
a_leftbracket      -1 9
a_m                -1 9
a_minus            -1 9
a_minus            -1 9
a_n                -1 9
a_o                -1 9
a_p                -1 9
a_pad_enter        -1 9
a_padenter         -1 9
a_period           -1 9
a_q                -1 9
a_quote            -1 9
a_r                -1 9
a_right_bracket    -1 9
a_rightbracket     -1 9
a_s                -1 9
a_semicolon        -1 9
a_slash            -1 9
a_space            -1 9
a_t                -1 9
a_u                -1 9
a_v                -1 9
a_w                -1 9
a_x                -1 9
a_y                -1 9
a_z                -1 9
abbrev             -1 9
activateacceltable -1 9
activatefile       -1 9
address            -1 9
adjust_block       -1 9
adjust_mark        -1 9
adjustblock        -1 9
adjustmark         -1 9
and                -1 9
arg                -1 9
asc                -1 9
atoi               -1 9
atol               -1 9
attribute_action   -1 9
backspace          -1 9
backtab            -1 9
backtab_word       -1 9
backtabword        -1 9
backward           -1 9
begin_line         -1 9
beginline          -1 9
bot                -1 9
bottom             -1 9
browse             -1 9
buffer             -1 9
buildacceltable    -1 9
buildmenuitem      -1 9
buildsubmenu       -1 9
by                 -1 9
c2x                -1 9
c_0                -1 9
c_1                -1 9
c_2                -1 9
c_3                -1 9
c_4                -1 9
c_5                -1 9
c_6                -1 9
c_7                -1 9
c_8                -1 9
c_9                -1 9
c_a                -1 9
c_b                -1 9
c_backslash        -1 9
c_backspace        -1 9
c_c                -1 9
c_comma            -1 9
c_d                -1 9
c_del              -1 9
c_down             -1 9
c_e                -1 9
c_end              -1 9
c_enter            -1 9
c_equal            -1 9
c_f                -1 9
c_f1               -1 9
c_f10              -1 9
c_f11              -1 9
c_f12              -1 9
c_f2               -1 9
c_f3               -1 9
c_f4               -1 9
c_f5               -1 9
c_f6               -1 9
c_f7               -1 9
c_f8               -1 9
c_f9               -1 9
c_g                -1 9
c_h                -1 9
c_home             -1 9
c_i                -1 9
c_ins              -1 9
c_j                -1 9
c_k                -1 9
c_l                -1 9
c_left             -1 9
c_left_bracket     -1 9
c_leftbracket      -1 9
c_m                -1 9
c_minus            -1 9
c_minus            -1 9
c_n                -1 9
c_o                -1 9
c_p                -1 9
c_pad_enter        -1 9
c_padenter         -1 9
c_pagedown         -1 9
c_pageup           -1 9
c_period           -1 9
c_pgdn             -1 9
c_pgup             -1 9
c_prtsc            -1 9
c_q                -1 9
c_quote            -1 9
c_r                -1 9
c_right            -1 9
c_right_bracket    -1 9
c_rightbracket     -1 9
c_s                -1 9
c_semicolon        -1 9
c_slash            -1 9
c_space            -1 9
c_t                -1 9
c_tab              -1 9
c_tab              -1 9
c_u                -1 9
c_up               -1 9
c_v                -1 9
c_w                -1 9
c_x                -1 9
c_y                -1 9
c_z                -1 9
call               -1 9
center             -1 9
center_search      -1 9
centersearch       -1 9
centre             -1 9
chr                -1 9
circleit           -1 9
compare            -1 9
compile            -1 9
compiler_msg       -1 9
const              -1 9
copies             -1 9
copy_mark          -1 9
copymark           -1 9
count              -1 9
cursor_dimensions  -1 9
def                -1 9
defc               -1 9
defexit            -1 9
define             -1 9
defined            -1 9
definit            -1 9
defkeys            -1 9
defload            -1 9
defmain            -1 9
defmodify          -1 9
defproc            -1 9
defselect          -1 9
del                -1 9
delete             -1 9
delete_char        -1 9
delete_mark        -1 9
deleteaccel        -1 9
deletechar         -1 9
deleteline         -1 9
deletemark         -1 9
deletemenu         -1 9
delstr             -1 9
delword            -1 9
directory          -1 9
display            -1 9
do                 -1 9
do_array           -1 9
do_overlaywindows  -1 9
do_tblocking       -1 9
down               -1 9
dynafree           -1 9
dynalink           -1 9
dynalink32         -1 9
dynalinkc          -1 9
echo               -1 9
else               -1 9
elseif             -1 9
end                -1 9
end_line           -1 9
enddo              -1 9
endfor             -1 9
endif              -1 9
endline            -1 9
endloop            -1 9
endwhile           -1 9
enter              -1 9
erase_end_line     -1 9
eraseendline       -1 9
esc                -1 9
executekey         -1 9
exit               -1 9
f1                 -1 9
f10                -1 9
f11                -1 9
f12                -1 9
f2                 -1 9
f3                 -1 9
f4                 -1 9
f5                 -1 9
f6                 -1 9
f7                 -1 9
f8                 -1 9
f9                 -1 9
filesinring        -1 9
filesize           -1 9
fill_mark          -1 9
fillmark           -1 9
findfile           -1 9
for                -1 9
forever            -1 9
get_key_state      -1 9
get_search         -1 9
getfileid          -1 9
getkeystate        -1 9
getline            -1 9
getmark            -1 9
getmarkg           -1 9
getpminfo          -1 9
getsearch          -1 9
hex                -1 9
home               -1 9
if                 -1 9
include            -1 9
ins                -1 9
insert             -1 9
insert_attribute   -1 9
insert_state       -1 9
insert_toggle      -1 9
insertline         -1 9
insertstate        -1 9
insertstr          -1 9
inserttoggle       -1 9
isadefc            -1 9
isadefproc         -1 9
isadirtyline       -1 9
iterate            -1 9
itoa               -1 9
join               -1 9
join_after_wrap    -1 9
joinafterwrap      -1 9
keyin              -1 9
keys               -1 9
last_error         -1 9
lasterror          -1 9
lastkey            -1 9
lastpos            -1 9
lastword           -1 9
leave              -1 9
left               -1 9
leftstr            -1 9
length             -1 9
lexam              -1 9
link               -1 9
linked             -1 9
longestline        -1 9
loop               -1 9
lowcase            -1 9
ltoa               -1 9
machine            -1 9
map_point          -1 9
mark_block         -1 9
mark_char          -1 9
mark_line          -1 9
markblock          -1 9
markblockg         -1 9
markchar           -1 9
markcharg          -1 9
markline           -1 9
marklineg          -1 9
marktype           -1 9
memcpyx            -1 9
mouse_setpointer   -1 9
move_mark          -1 9
movemark           -1 9
next_file          -1 9
nextfile           -1 9
not                -1 9
offset             -1 9
ofs                -1 9
or                 -1 9
other              -1 9
other_keys         -1 9
otherkeys          -1 9
overlay            -1 9
overlay_block      -1 9
overlayblock       -1 9
pad_enter          -1 9
padenter           -1 9
page_down          -1 9
page_up            -1 9
pagedown           -1 9
pageup             -1 9
parse              -1 9
peek               -1 9
peek32             -1 9
peekz              -1 9
pgdn               -1 9
pgup               -1 9
poke               -1 9
poke32             -1 9
pos                -1 9
prevfile           -1 9
qprint             -1 9
query_attribute    -1 9
queryaccelstring   -1 9
queryfont          -1 9
querymenustring    -1 9
queryprofile       -1 9
quiet_shell        -1 9
quietshell         -1 9
reflow             -1 9
refresh            -1 9
registerfont       -1 9
repeat_find        -1 9
repeatfind         -1 9
replaceline        -1 9
return             -1 9
reverse            -1 9
right              -1 9
rightstr           -1 9
rubout             -1 9
s_backspace        -1 9
s_del              -1 9
s_down             -1 9
s_end              -1 9
s_enter            -1 9
s_esc              -1 9
s_f1               -1 9
s_f10              -1 9
s_f11              -1 9
s_f12              -1 9
s_f2               -1 9
s_f3               -1 9
s_f4               -1 9
s_f5               -1 9
s_f6               -1 9
s_f7               -1 9
s_f8               -1 9
s_f9               -1 9
s_home             -1 9
s_ins              -1 9
s_left             -1 9
s_padenter         -1 9
s_pagedown         -1 9
s_pageup           -1 9
s_pgdn             -1 9
s_pgup             -1 9
s_right            -1 9
s_space            -1 9
s_tab              -1 9
s_up               -1 9
say_error          -1 9
sayat              -1 9
sayerror           -1 9
sayerrortext       -1 9
screenheight       -1 9
screenwidth        -1 9
seg                -1 9
selector           -1 9
set                -1 9
set_search         -1 9
setmark            -1 9
setprofile         -1 9
setsearch          -1 9
shift_left         -1 9
shift_right        -1 9
shiftleft          -1 9
shiftright         -1 9
showmenu           -1 9
space              -1 9
split              -1 9
stop               -1 9
stop_on_rc         -1 9
stoponrc           -1 9
strip              -1 9
substr             -1 9
subword            -1 9
tab                -1 9
tab_word           -1 9
tabglyph           -1 9
tabword            -1 9
textline           -1 9
then               -1 9
to                 -1 9
top                -1 9
translate          -1 9
tryinclude         -1 9
two_spaces         -1 9
twospaces          -1 9
undo               -1 9
undoaction         -1 9
universal          -1 9
unlink             -1 9
unmark             -1 9
up                 -1 9
upcase             -1 9
value              -1 9
var                -1 9
ver                -1 9
verify             -1 9
while              -1 9
windowmessage      -1 9
with               -1 9
word               -1 9
wordindex          -1 9
wordlength         -1 9
wordpos            -1 9
words              -1 9
@ -------------------- Standard macro routines ---------------------------
AMU_addenda_addition_processing  -1 3
AMU_addenda_processing           -1 3
AMU_script_verification          -1 3
Append_Path                      -1 3
EHLLAPI_SEND_RECEIVE             -1 3
Exist                            -1 3
FastMoveATTRtoBeg                -1 3
GetBuffCommon                    -1 3
HLLAPI_call                      -1 3
Insert_Attribute_Pair            -1 3
LoadVersionString                -1 3
MH_set_mouse                     -1 3
MakeBakName                      -1 3
MakeTempName                     -1 3
MouseLineColOff                  -1 3
PostCmdToEditWindow              -1 3
QueryCurrentHLPFiles             -1 3
SUE_free                         -1 3
SUE_new                          -1 3
SUE_readln                       -1 3
SUE_write                        -1 3
SetCurrentHLPFiles               -1 3
SetMenuAttribute                 -1 3
SetMouseSet                      -1 3
Thunk                            -1 3
add_command_menu                 -1 3
add_edit_menu                    -1 3
add_file_menu                    -1 3
add_help_menu                    -1 3
add_help_menu                    -1 3
add_options_menu                 -1 3
add_options_menu                 -1 3
add_ring_menu                    -1 3
add_search_menu                  -1 3
add_tags                         -1 3
address                          -1 3
already_in_ring                  -1 3
askyesno                         -1 3
asm_proc_search                  -1 3
atol_swap                        -1 3
attribute_on                     -1 3
beep                             -1 3
begin_shift                      -1 3
breakout_mvs                     -1 3
breakout_vm                      -1 3
c_first_expansion                -1 3
c_proc_search                    -1 3
c_second_expansion               -1 3
check_for_host_file              -1 3
check_for_printer                -1 3
check_mark_on_screen             -1 3
check_path_piece                 -1 3
check_savepath                   -1 3
checkini                         -1 3
checkmark                        -1 3
clipcheck                        -1 3
column_math                      -1 3
cursoroff                        -1 3
dec2hex                          -1 3
dec_to_string                    -1 3
default_printer                  -1 3
delete_ea                        -1 3
dos_command                      -1 3
dos_version                      -1 3
dosmove                          -1 3
draw_down                        -1 3
draw_left                        -1 3
draw_right                       -1 3
draw_up                          -1 3
drop_dictionary                  -1 3
e_first_expansion                -1 3
e_proc_search                    -1 3
e_second_expansion               -1 3
ec_position_on_error             -1 3
einsert_line                     -1 3
end_shift                        -1 3
enter_common                     -1 3
enter_main_heading               -1 3
entrybox                         -1 3
erasetemp                        -1 3
evalinput                        -1 3
exp                              -1 3
experror                         -1 3
extend_mark                      -1 3
filetype                         -1 3
find_ea                          -1 3
find_matching_paren              -1 3
find_routine                     -1 3
find_token                       -1 3
fixup_cursor                     -1 3
get_EAT_ASCII_value              -1 3
get_array_value                  -1 3
get_char                         -1 3
get_env                          -1 3
get_file_date                    -1 3
getdate                          -1 3
getdatetime                      -1 3
getheading_name                  -1 3
gethwnd                          -1 3
gethwndc                         -1 3
gettime                          -1 3
hex2dec                          -1 3
hidden_info                      -1 3
init_operation_on_comma          -1 3
isa_mvs_filename                 -1 3
isa_pc_filename                  -1 3
isa_vm_filename                  -1 3
isdbcs                           -1 3
ishost                           -1 3
isnum                            -1 3
isoption                         -1 3
joinlines                        -1 3
leave_last_command               -1 3
left_right                       -1 3
leftstr                          -1 3
lex_number                       -1 3
link_exec                        -1 3
list_toolbars                    -1 3
listbox                          -1 3
listmark                         -1 3
load_host_file                   -1 3
load_lexam                       -1 3
load_wps_config                  -1 3
loadfile                         -1 3
lock                             -1 3
mathcommon                       -1 3
max                              -1 3
maybe_autosave                   -1 3
maybe_save_addenda               -1 3
maybe_show_menu                  -1 3
message                          -1 3
messageNwait                     -1 3
mgetkey                          -1 3
min                              -1 3
mouse_in_mark                    -1 3
move_results_to_command          -1 3
mpfrom2short                     -1 3
my_c_enter                       -1 3
my_enter                         -1 3
namefile                         -1 3
next_sym                         -1 3
no_char_mark                     -1 3
pBuild_Helpfile                  -1 3
pGet_Identifier                  -1 3
pHelp_C_identifier               -1 3
parse_file                       -1 3
parse_file_n_opts                -1 3
parse_filename                   -1 3
parse_leading_options            -1 3
parse_tagline                    -1 3
pas_first_expansion              -1 3
pas_proc_search                  -1 3
pas_second_expansion             -1 3
passist                          -1 3
pbegin_mark                      -1 3
pbegin_word                      -1 3
pblock_reflow                    -1 3
pc_chars                         -1 3
pcenter_mark                     -1 3
pcommand_state                   -1 3
pcommon_adjust_overlay           -1 3
pcommon_tab_margin               -1 3
pcopy_mark                       -1 3
pdelete_mark                     -1 3
pdisplay_margins                 -1 3
pdisplay_tabs                    -1 3
pend_mark                        -1 3
pend_word                        -1 3
pextract_string                  -1 3
pfile_exists                     -1 3
pfill_mark                       -1 3
pfind_blank_line                 -1 3
pfirst_nonblank                  -1 3
pinit_extract                    -1 3
plowercase                       -1 3
pmargins                         -1 3
pmark                            -1 3
pmark_word                       -1 3
pmove_mark                       -1 3
ppeek32                          -1 3
prec                             -1 3
prestore_mark                    -1 3
prestore_pos                     -1 3
prestore_pos2                    -1 3
printer_ready                    -1 3
proc_search                      -1 3
process_key                      -1 3
process_mark_like_cua            -1 3
proof1                           -1 3
proof2                           -1 3
psave_mark                       -1 3
psave_pos                        -1 3
psave_pos2                       -1 3
pset_mark                        -1 3
ptabs                            -1 3
puppercase                       -1 3
put_file_as_MVST                 -1 3
put_in_buffer                    -1 3
qfilemode                        -1 3
querycontrol                     -1 3
queryframecontrol                -1 3
quitfile                         -1 3
readd_help_menu                  -1 3
reduce_dualop                    -1 3
register_mousehandler            -1 3
repaint_window                   -1 3
resolve_key                      -1 3
restore_command_state            -1 3
rex_first_expansion              -1 3
rex_second_expansion             -1 3
rexxfunctionregister             -1 3
rexxsubcomdrop                   -1 3
rexxsubcomregister               -1 3
save_command_state               -1 3
save_host_file                   -1 3
saveas_dlg                       -1 3
savefile                         -1 3
savefilewithtabs                 -1 3
sayat_color                      -1 3
sayatbox                         -1 3
screenxysize                     -1 3
scroll_lock                      -1 3
search_path                      -1 3
search_path_ptr                  -1 3
select_edit_keys                 -1 3
setLT                            -1 3
set_FTO                          -1 3
setfont                          -1 3
setini                           -1 3
settitletext                     -1 3
shifted                          -1 3
show_modify                      -1 3
showwindow                       -1 3
simple_HLLAPI_call               -1 3
skip_spaces                      -1 3
sort                             -1 3
spellword                        -1 3
spellword2                       -1 3
spellwordd                       -1 3
splitlines                       -1 3
strippunct                       -1 3
subdir                           -1 3
swapwords                        -1 3
synonym                          -1 3
tag_case                         -1 3
tags_filename                    -1 3
tags_supported                   -1 3
text_reflow                      -1 3
textline                         -1 3
timestamp                        -1 3
trunc                            -1 3
unary_exp                        -1 3
unlock                           -1 3
up_down                          -1 3
update_edit_menu_text            -1 3
updateringmenu                   -1 3
updownkey                        -1 3
user_FTO                         -1 3
verify_buffer_size               -1 3
vmfile                           -1 3
whatisit                         -1 3
windowsize1                      -1 3
winmessagebox                    -1 3
@ --------------------  Fields  ---------------------------
.autosave                -1 9
.autoshell               -1 9
.bofmarker               -1 9
.codepage                -1 9
.col                     -1 9
.currentview_of_file     -1 9
.cursorcolumn            -1 9
.cursoroffset            -1 9
.cursorx                 -1 9
.cursory                 -1 9
.cursoryg                -1 9
.dragcolor               -1 9
.dragstyle               -1 9
.eaarea                  -1 9
.eof                     -1 9
.fileinfo                -1 9
.filename                -1 9
.font                    -1 9
.fontheight              -1 9
.fontwidth               -1 9
.jumpscrollhorz          -1 9
.jumpscrollvert          -1 9
.keyset                  -1 9
.kludge1                 -1 9
.last                    -1 9
.levelofattributesupport -1 9
.line                    -1 9
.lineg                   -1 9
.lockhandle              -1 9
.margins                 -1 9
.markcolor               -1 9
.modify                  -1 9
.mousex                  -1 9
.mousey                  -1 9
.nextview                -1 9
.nextview_of_file        -1 9
.prevview                -1 9
.readonly                -1 9
.repkey_cutoff           -1 9
.scrollx                 -1 9
.scrolly                 -1 9
.tabs                    -1 9
.textcolor               -1 9
.titletext               -1 9
.tofmarker               -1 9
.typingclass1            -1 9
.typingclass2            -1 9
.typingclassval1         -1 9
.typingclassval2         -1 9
.userstring              -1 9
.visible                 -1 9
.windowheight            -1 9
.windowheightg           -1 9
.windowwidth             -1 9
.windowwidthg            -1 9
.windowx                 -1 9
.windowy                 -1 9
