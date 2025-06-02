highlight clear

if exists("syntax_on")
  syntax reset
endif

set background=dark
let g:colors_name = "gothic-cyberpunk"

" ___ Define color variables ___
" Black and Gray Tones
let s:blackest = "#000000"
let s:blacker = "#060606"
let s:black = "#0F0F0F"
let s:dark_gray = "#151515"
let s:light_gray = "#202020"
let s:lighter_gray = "#545454"
let s:lightest_gray = "#8F8F8F"
let s:white = "#C4C4C4"
let s:whiter = "#d9d9d9"
let s:whitest = "#FFFFFF"

let s:vibrant_teal = "#00FFC8"
let s:neon_magenta = "#FF0055"

" For terminal support
let s:cterm_vibrant_teal = "51"  " Approx teal in 256-color
let s:cterm_neon_magenta = "201" " Approx magenta in 256-color

"function! HighlightFor(group, fg, bg, style)
  "execute "hi ".a:group
        "\ ." guifg=".a:fg
        "\ ." guibg=".a:bg
        "\ ." gui=".a:style
        "\ ." ctermfg=".s:cterm_vibrant_teal
        "\ ." ctermbg=".s:cterm_neon_magenta
        "\ ." cterm=".a:style
"endfunction
function! HighlightFor(group, fg, bg, style)
  execute "hi " . a:group
        \ . " guifg=" . a:fg
        \ . " guibg=" . a:bg
        \ . " gui=" . a:style
        \ . " ctermfg=" . (a:fg == s:neon_magenta ? s:cterm_neon_magenta : (a:fg == s:vibrant_teal ? s:cterm_vibrant_teal : "NONE"))
        \ . " ctermbg=" . (a:bg == s:neon_magenta ? s:cterm_neon_magenta : (a:bg == s:vibrant_teal ? s:cterm_vibrant_teal : "NONE"))
        \ . " cterm=" . a:style
endfunction


" Diff
call HighlightFor("DiffAdd",    s:blackest,           s:vibrant_teal,   "NONE")
call HighlightFor("DiffDelete", s:blackest,           s:neon_magenta,   "NONE")
call HighlightFor("DiffText",   s:whitest,         s:dark_gray,    "NONE")
call HighlightFor("DiffChange", s:blackest,           s:whitest,    "NONE")

" Cursor
call HighlightFor("Cursor",       s:vibrant_teal,    "NONE",           "NONE")
call HighlightFor("CursorLineNr", s:blackest,       s:vibrant_teal,   "NONE")
call HighlightFor("CursorLine",   s:blackest,       s:neon_magenta,   "NONE")
call HighlightFor("CursorColumn", "NONE",            "NONE",           "NONE")

" Folds
call HighlightFor("Folded",      s:vibrant_teal,     s:blacker, "italic")
call HighlightFor("FoldColumn",  s:blackest,        s:whitest,   "NONE")

" Pmenu
call HighlightFor("Pmenu",       s:whitest,      s:dark_gray,   "NONE")
call HighlightFor("PmenuSel",    s:whitest,      s:neon_magenta,  "NONE")
call HighlightFor("PmenuSbar",   s:neon_magenta,     s:whitest,   "NONE")
call HighlightFor("PmenuThumb",  s:neon_magenta,     s:blackest,     "NONE")

" General
call HighlightFor("Normal",      s:whitest,      s:black,    "NONE")
call HighlightFor("Visual",      "NONE",             s:lightest_gray,  "NONE")
call HighlightFor("LineNr",      s:vibrant_teal,     s:blackest,     "NONE")
call HighlightFor("SignColumn",  s:vibrant_teal,     "NONE",          "NONE")
call HighlightFor("VertSplit",   s:blackest,        s:whitest,   "NONE")
call HighlightFor("IncSearch",   s:blackest,        s:vibrant_teal,  "NONE")
call HighlightFor("Search",      s:blackest,        s:vibrant_teal,  "NONE")
call HighlightFor("Substitute",  s:blackest,        s:vibrant_teal,  "NONE")
call HighlightFor("MatchParen",  s:blackest,        s:vibrant_teal,  "NONE")
call HighlightFor("NonText",     s:white,       "NONE",          "NONE")
call HighlightFor("Whitespace",  s:white,       "NONE",          "NONE")
call HighlightFor("Directory",   s:vibrant_teal,     s:blacker, "NONE")

" Code - data types
call HighlightFor("Comment",     s:lightest_gray,     "NONE",          "NONE")
call HighlightFor("String",      s:lightest_gray,      s:blacker,     "italic,bold")
call HighlightFor("Number",      s:vibrant_teal,     s:blackest,     "NONE")
call HighlightFor("Float",       s:whitest,      s:blackest,     "NONE")
call HighlightFor("Boolean",     s:whitest,      s:blackest,     "NONE")
call HighlightFor("Character",   s:whitest,      s:blackest,     "NONE")

" Code - general
call HighlightFor("Identifier",  s:whitest,      s:lighter_gray,  "italic")
call HighlightFor("Function",    s:blackest,        s:whiter,   "italic")
call HighlightFor("Statement",   s:whitest,      s:blacker, "NONE")
call HighlightFor("StorageClass",s:whiter,       "NONE",          "italic")
call HighlightFor("Structure",   s:whiter,       "NONE",          "italic")
call HighlightFor("Repeat",      s:whiter,       s:dark_gray,   "NONE")
call HighlightFor("Conditional", s:blackest, s:vibrant_teal,   "NONE")
call HighlightFor("Operator",    s:whitest,      s:blackest,     "NONE")
call HighlightFor("Type",        s:whitest,      s:light_gray,   "NONE")
call HighlightFor("Typedef",     s:whitest,      s:light_gray,   "NONE")
call HighlightFor("PreProc",     s:whitest,      s:lightest_gray,  "NONE")
call HighlightFor("Underlined",  s:whitest,      s:lightest_gray,  "NONE")
call HighlightFor("Special",     s:vibrant_teal,     s:blackest,     "NONE")
call HighlightFor("Keyword",  s:vibrant_teal,        s:blackest,  "NONE")

call HighlightFor("Label",       s:blacker,      s:neon_magenta,  "NONE")
call HighlightFor("Exception",       s:blacker,      s:neon_magenta,  "NONE")
call HighlightFor("Todo",        s:blackest,        s:vibrant_teal,  "italic")
call HighlightFor("Error",       s:blackest,        s:neon_magenta,  "undercurl")
call HighlightFor("WarningMsg",  s:blackest,        s:vibrant_teal,  "NONE")
call HighlightFor("Tag",         s:blackest,        s:vibrant_teal,  "undercurl")

" Status line
call HighlightFor("StatusLine",  s:vibrant_teal,      s:blackest,   "bold")
call HighlightFor("StatusLineNC",s:vibrant_teal,     s:blackest,     "NONE")

" Tab pages
call HighlightFor("TabLine",     s:whitest,      s:blackest,     "NONE")
call HighlightFor("TabLineSel",  s:blackest,        s:vibrant_teal,  "bold")
call HighlightFor("TabLineFill", s:whitest,      s:black,    "NONE")

" Placeholder
call HighlightFor("Title",       s:whitest,      s:dark_gray,   "NONE")
call HighlightFor("WildMenu",    s:whitest,      s:lightest_gray,  "NONE")

" Custom fugitive blame colors
call HighlightFor("fugitiveHash",     s:blackest,   s:vibrant_teal,  "NONE")
call HighlightFor("fugitiveAuthor",   s:blackest,   s:neon_magenta,  "NONE")
call HighlightFor("fugitiveTime",     s:blackest,   s:white,    "NONE")
call HighlightFor("fugitiveSummary",  s:blackest,   s:whiter,    "NONE")
call HighlightFor("fugitiveBoundary", s:blackest,   s:neon_magenta,  "NONE")
call HighlightFor("fugitiveUntracked",s:blackest,   s:lightest_gray,  "NONE")
call HighlightFor("fugitiveUnstaged", s:blackest,   s:lighter_gray,  "NONE")
call HighlightFor("fugitiveStaged",   s:blackest,   s:vibrant_teal,  "NONE")

" Additional General Interface Highlights
call HighlightFor("CursorIM",       s:vibrant_teal,     s:blackest,      "NONE")          " Cursor in insert mode (GUI/terminal)
call HighlightFor("VisualNOS",      s:whitest,      s:lightest_gray,   "NONE")          " Visual selection when not owning selection
call HighlightFor("QuickFixLine",   s:blackest,        s:vibrant_teal,   "bold")          " Selected line in quickfix window
call HighlightFor("ErrorMsg",       s:neon_magenta,     s:blackest,      "bold")          " Error messages on command line
call HighlightFor("ModeMsg",        s:whiter,       s:blacker,  "NONE")          " Mode messages (e.g., -- INSERT --)
call HighlightFor("MoreMsg",        s:whiter,       s:blacker,  "NONE")          " More prompts (e.g., -- More --)
call HighlightFor("Question",       s:vibrant_teal,     s:blacker,  "bold")          " Prompt questions (e.g., confirm prompts)
call HighlightFor("ColorColumn",    "NONE",             s:dark_gray,    "NONE")          " Column highlight (e.g., colorcolumn=80)
call HighlightFor("Conceal",        s:lightest_gray,     "NONE",           "NONE")          " Concealed text (e.g., markdown hidden chars)
call HighlightFor("EndOfBuffer",    s:white,       "NONE",           "NONE")          " Beyond buffer (e.g., ~ characters)
call HighlightFor("Menu",           s:whitest,      s:dark_gray,    "NONE")          " GUI Vim menu items
call HighlightFor("ScrollBar",      s:lightest_gray,     s:blacker,  "NONE")          " GUI Vim scrollbar
call HighlightFor("Tooltip",        s:whitest,      s:dark_gray,    "NONE")          " GUI Vim tooltips

" Additional Syntax Highlights
call HighlightFor("Constant",       s:whitest,      s:blackest,      "NONE")          " General constants (parent group)
call HighlightFor("SpecialKey",     s:vibrant_teal,     "NONE",           "NONE")          " Special chars when :set list (e.g., tabs)
call HighlightFor("SpecialChar",    s:vibrant_teal,     s:blackest,      "NONE")          " Special chars in strings (e.g., \n)
call HighlightFor("Debug",          s:whiter,       s:dark_gray,    "italic")        " Debugging-related elements
call HighlightFor("Define",         s:whitest,      s:lightest_gray,   "NONE")          " Preprocessor definitions (e.g., #define)
call HighlightFor("Macro",          s:whitest,      s:lightest_gray,   "NONE")          " Macro definitions/invocations
call HighlightFor("PreCondit",      s:whitest,      s:lightest_gray,   "NONE")          " Preprocessor conditionals (e.g., #ifdef)
call HighlightFor("Include",        s:whitest,      s:lightest_gray,   "NONE")          " Include/import statements
call HighlightFor("Delimiter",      s:white,       s:blackest,      "NONE")          " Delimiters (e.g., commas, parentheses)
call HighlightFor("SpecialComment", s:blackest,     s:vibrant_teal,  "italic")        " Special comments (e.g., TODO, FIXME)

" Spell Checking Highlights
call HighlightFor("SpellBad",       s:neon_magenta,     s:blackest,      "undercurl")     " Misspelled words
call HighlightFor("SpellCap",       s:neon_magenta,     s:blackest,      "undercurl")     " Capitalization errors
call HighlightFor("SpellRare",      s:whiter,       s:blackest,      "undercurl")     " Rare/unusual words
call HighlightFor("SpellLocal",     s:vibrant_teal,     s:blackest,      "undercurl")     " Locally correct words

" Neovim-Specific Highlights (LSP and Tree-Sitter)
call HighlightFor("LspDiagnosticsDefaultError",       s:neon_magenta,     s:blackest,      "undercurl")     " LSP error diagnostics
call HighlightFor("LspDiagnosticsDefaultWarning",     s:vibrant_teal,     s:blackest,      "undercurl")     " LSP warning diagnostics
call HighlightFor("LspDiagnosticsDefaultInformation", s:whiter,       s:blackest,      "NONE")          " LSP info diagnostics
call HighlightFor("LspDiagnosticsDefaultHint",        s:vibrant_teal,     s:blackest,      "NONE")          " LSP hint diagnostics
call HighlightFor("LspReferenceText",                 s:whitest,      s:dark_gray,    "NONE")          " LSP reference text
call HighlightFor("LspReferenceRead",                 s:whitest,      s:dark_gray,    "NONE")          " LSP read references
call HighlightFor("LspReferenceWrite",                s:whitest,      s:dark_gray,    "NONE")          " LSP write references
call HighlightFor("TSVariable",                       s:whiter,       s:blackest,      "NONE")          " Tree-sitter variables
call HighlightFor("TSFunction",                       s:blackest,        s:whitest,    "italic")        " Tree-sitter functions
call HighlightFor("TSString",                         s:whitest,      s:blackest,      "NONE")          " Tree-sitter strings
call HighlightFor("TSKeyword",                        s:whitest,      s:lighter_gray,   "italic")        " Tree-sitter keywords
call HighlightFor("TSTag",                            s:blackest,        s:vibrant_teal,   "undercurl")     " Tree-sitter tags (e.g., HTML tags)


" Perl -specific
" syntax match perlInterpolatedVar "\$\h\w*" containedin=perlString
" highlight link perlInterpolatedVar perlVarSimpleMember
" call HighlightFor("perlInterpolatedVar", s:neon_magenta, s:vibrant_teal,   "NONE")

" Ensure your colorscheme is applied
" highlight perlVarSimpleMember ctermfg=Red guifg=#ff5555

" Apply highlights for standalone Perl variables
"call HighlightFor("perlVarPlain", s:neon_magenta, "NONE", "NONE")
"call HighlightFor("perlVarSimpleMember", s:neon_magenta, "NONE", "NONE")
"call HighlightFor("perlVarPlain2", s:neon_magenta, "NONE", "NONE")

" Ensure highlights apply to Perl files
"augroup perl_colors
  "autocmd!
  "autocmd FileType perl call HighlightFor("perlVarPlain", s:neon_magenta, "NONE", "NONE")
  "autocmd FileType perl call HighlightFor("perlVarSimpleMember", s:neon_magenta, "NONE", "NONE")
  "autocmd FileType perl call HighlightFor("perlVarPlain2", s:neon_magenta, "NONE", "NONE")
"augroup END
