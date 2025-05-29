highlight clear

if exists("syntax_on")
  syntax reset
endif

set background=dark
let g:colors_name = "gothic-cyberpunk"

" ___ Define color variables ___
let s:magenta_bright = "#FF0055"
let s:teal_bright = "#00FFC8"

" Blacks and Grays
let s:pure_black = "#000000"
let s:almost_black = "#060606"
let s:light_gray = "#C4C4C4"
let s:med_gray = "#8F8F8F"
let s:med_gray2 = "#545454"
let s:semidark_gray = "#202020"
let s:dark_gray = "#151515"
let s:darker_gray = "#0F0F0F"
let s:almost_white = "#d9d9d9"
let s:pure_white = "#FFFFFF"



function! HighlightFor(group, fg, bg, style)
  execute "hi ".a:group
        \ ." guifg=".a:fg
        \ ." guibg=".a:bg
        \ ." gui=".a:style
endfunction

" Diff
call HighlightFor("DiffAdd",    s:pure_black,           s:teal_bright,   "NONE")
call HighlightFor("DiffDelete", s:pure_black,           s:magenta_bright,     "NONE")
call HighlightFor("DiffText",   s:pure_white,           s:dark_gray,   "NONE")
call HighlightFor("DiffChange", s:pure_black,           s:pure_white,         "NONE")

" Cursor
call HighlightFor("Cursor",       s:teal_bright,    "NONE",           "NONE")
call HighlightFor("CursorLineNr", s:pure_black, s:teal_bright, "NONE")
call HighlightFor("CursorLine", s:pure_black, s:magenta_bright, "NONE")
call HighlightFor("CursorColumn", "NONE", "NONE", "NONE")

" Folds
call HighlightFor("Folded",      s:teal_bright,     s:almost_black, "italic")
call HighlightFor("FoldColumn",  s:pure_black,     s:pure_white, "NONE")

" Pmenu
call HighlightFor("Pmenu",    s:pure_white,     s:dark_gray, "NONE")
call HighlightFor("PmenuSel",       s:pure_white,     s:magenta_bright, "NONE")
call HighlightFor("PmenuSbar",   s:magenta_bright,     s:pure_white, "NONE")
call HighlightFor("PmenuThumb",  s:magenta_bright,     s:pure_black, "NONE")

" General
call HighlightFor("Normal",      s:pure_white, s:darker_gray, "NONE")
call HighlightFor("Visual",      "NONE",           s:med_gray, "NONE")
call HighlightFor("LineNr",      s:teal_bright, s:pure_black,          "NONE")
call HighlightFor("SignColumn",  s:teal_bright,    "NONE",          "NONE")
call HighlightFor("VertSplit",  s:pure_black, s:pure_white, "NONE")
call HighlightFor("IncSearch",  s:pure_black,           s:teal_bright,      "NONE")
call HighlightFor("Search",     s:pure_black,           s:teal_bright,      "NONE")
call HighlightFor("Substitute", s:pure_black,           s:teal_bright,      "NONE")
call HighlightFor("MatchParen", s:pure_black, s:teal_bright,    "NONE")
call HighlightFor("NonText",    s:light_gray, "NONE",           "NONE")
call HighlightFor("Whitespace", s:light_gray, "NONE",           "NONE")
call HighlightFor("Directory",  s:teal_bright,    s:almost_black,           "NONE")

" Code - data types
call HighlightFor("Comment",     s:med_gray,   "NONE", "NONE")
call HighlightFor("String",      s:pure_white,   s:pure_black, "NONE")
call HighlightFor("Number",      s:teal_bright,   s:pure_black, "NONE")
call HighlightFor("Float",       s:pure_white,   s:pure_black, "NONE")
call HighlightFor("Boolean",     s:pure_white,   s:pure_black, "NONE")
call HighlightFor("Character",   s:pure_white,   s:pure_black, "NONE")

" Code - general"
call HighlightFor("Statement",   s:pure_white,     s:almost_black, "NONE")
call HighlightFor("StorageClass",s:almost_white,"NONE", "italic")
call HighlightFor("Structure",   s:almost_white,"NONE", "italic")
call HighlightFor("Repeat",      s:almost_white, s:dark_gray, "NONE")
call HighlightFor("Conditional", s:almost_white, s:dark_gray, "NONE")
call HighlightFor("Keyword",    s:pure_black,     s:light_gray, "italic")
call HighlightFor("Function",     s:pure_black,     s:pure_white, "italic")
call HighlightFor("Operator",    s:pure_white,    s:pure_black, "NONE")
call HighlightFor("Identifier",  s:pure_white, s:med_gray2, "NONE")
call HighlightFor("Type",  s:pure_white, s:semidark_gray, "NONE")
call HighlightFor("Typedef",  s:pure_white, s:semidark_gray, "NONE")
call HighlightFor("PreProc",     s:pure_white,     s:med_gray, "NONE")
call HighlightFor("Underlined",     s:pure_white,     s:med_gray, "NONE")
call HighlightFor("Special",      s:teal_bright,   s:pure_black, "NONE")

call HighlightFor("Label",       s:pure_white,     s:magenta_bright, "NONE")
call HighlightFor("Exception",   s:pure_black,     s:magenta_bright, "NONE")
call HighlightFor("Todo",        s:pure_black,     s:teal_bright, "italic")
call HighlightFor("Error",       s:pure_black,     s:magenta_bright, "undercurl")
call HighlightFor("WarningMsg",  s:pure_black,     s:teal_bright, "NONE")
call HighlightFor("Tag",         s:pure_black,     s:teal_bright, "undercurl")

" Status line
call HighlightFor("StatusLine",  s:dark_gray, s:pure_white, "bold")
call HighlightFor("StatusLineNC", s:teal_bright,    s:pure_black, "NONE")

" Tab pages
call HighlightFor("TabLine",     s:pure_white,     s:pure_black, "NONE")
call HighlightFor("TabLineSel",  s:pure_black,     s:teal_bright, "bold")
call HighlightFor("TabLineFill", s:pure_white,     s:darker_gray, "NONE")

" Placeholder
call HighlightFor("Title",      s:pure_white,   s:dark_gray,           "NONE")
call HighlightFor("WildMenu",   s:pure_white,    s:med_gray,           "NONE")

" call HighlightFor("String",      s:med_gray, s:dark_gray, "NONE") DARK
" call HighlightFor("Function",    s:teal_bright,     "#36004a", "NONE")


" Custom fugitive blame colors
call HighlightFor("fugitiveHash", s:pure_black, s:teal_bright, "NONE")
call HighlightFor("fugitiveAuthor", s:pure_black, s:magenta_bright, "NONE")
call HighlightFor("fugitiveTime", s:pure_black, s:light_gray, "NONE")
call HighlightFor("fugitiveSummary", s:pure_black, s:almost_white, "NONE")
call HighlightFor("fugitiveBoundary", s:pure_black, s:magenta_bright, "NONE")
call HighlightFor("fugitiveUntracked", s:pure_black, s:med_gray, "NONE")
call HighlightFor("fugitiveUnstaged", s:pure_black, s:med_gray2, "NONE")
call HighlightFor("fugitiveStaged", s:pure_black, s:teal_bright, "NONE")

