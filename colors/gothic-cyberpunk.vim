highlight clear

if exists("syntax_on")
  syntax reset
endif

set background=dark
let g:colors_name = "gothic-cyberpunk"

" ___ Define color variables ___
" Black and Gray Tones
let s:jet_black = "#000000"
let s:deep_charcoal = "#060606"
let s:dark_slate = "#0F0F0F"
let s:stormy_gray = "#151515"
let s:shadow_gray = "#202020"
let s:medium_steel = "#545454"
let s:muted_silver = "#8F8F8F"
let s:light_mist = "#C4C4C4"

" White Tones
let s:crisp_white = "#FFFFFF"
let s:soft_ivory = "#d9d9d9"

" Teal Tones
let s:vibrant_teal = "#00FFC8"

" Magenta Tones
let s:neon_magenta = "#FF0055"

function! HighlightFor(group, fg, bg, style)
  execute "hi ".a:group
        \ ." guifg=".a:fg
        \ ." guibg=".a:bg
        \ ." gui=".a:style
endfunction

" Diff
call HighlightFor("DiffAdd",    s:jet_black,           s:vibrant_teal,   "NONE")
call HighlightFor("DiffDelete", s:jet_black,           s:neon_magenta,   "NONE")
call HighlightFor("DiffText",   s:crisp_white,         s:stormy_gray,    "NONE")
call HighlightFor("DiffChange", s:jet_black,           s:crisp_white,    "NONE")

" Cursor
call HighlightFor("Cursor",       s:vibrant_teal,    "NONE",           "NONE")
call HighlightFor("CursorLineNr", s:jet_black,       s:vibrant_teal,   "NONE")
call HighlightFor("CursorLine",   s:jet_black,       s:neon_magenta,   "NONE")
call HighlightFor("CursorColumn", "NONE",            "NONE",           "NONE")

" Folds
call HighlightFor("Folded",      s:vibrant_teal,     s:deep_charcoal, "italic")
call HighlightFor("FoldColumn",  s:jet_black,        s:crisp_white,   "NONE")

" Pmenu
call HighlightFor("Pmenu",       s:crisp_white,      s:stormy_gray,   "NONE")
call HighlightFor("PmenuSel",    s:crisp_white,      s:neon_magenta,  "NONE")
call HighlightFor("PmenuSbar",   s:neon_magenta,     s:crisp_white,   "NONE")
call HighlightFor("PmenuThumb",  s:neon_magenta,     s:jet_black,     "NONE")

" General
call HighlightFor("Normal",      s:crisp_white,      s:dark_slate,    "NONE")
call HighlightFor("Visual",      "NONE",             s:muted_silver,  "NONE")
call HighlightFor("LineNr",      s:vibrant_teal,     s:jet_black,     "NONE")
call HighlightFor("SignColumn",  s:vibrant_teal,     "NONE",          "NONE")
call HighlightFor("VertSplit",   s:jet_black,        s:crisp_white,   "NONE")
call HighlightFor("IncSearch",   s:jet_black,        s:vibrant_teal,  "NONE")
call HighlightFor("Search",      s:jet_black,        s:vibrant_teal,  "NONE")
call HighlightFor("Substitute",  s:jet_black,        s:vibrant_teal,  "NONE")
call HighlightFor("MatchParen",  s:jet_black,        s:vibrant_teal,  "NONE")
call HighlightFor("NonText",     s:light_mist,       "NONE",          "NONE")
call HighlightFor("Whitespace",  s:light_mist,       "NONE",          "NONE")
call HighlightFor("Directory",   s:vibrant_teal,     s:deep_charcoal, "NONE")

" Code - data types
call HighlightFor("Comment",     s:muted_silver,     "NONE",          "NONE")
call HighlightFor("String",      s:crisp_white,      s:jet_black,     "NONE")
call HighlightFor("Number",      s:vibrant_teal,     s:jet_black,     "NONE")
call HighlightFor("Float",       s:crisp_white,      s:jet_black,     "NONE")
call HighlightFor("Boolean",     s:crisp_white,      s:jet_black,     "NONE")
call HighlightFor("Character",   s:crisp_white,      s:jet_black,     "NONE")

" Code - general
call HighlightFor("Keyword",     s:crisp_white,      s:medium_steel,  "italic")
call HighlightFor("Function",    s:jet_black,        s:crisp_white,   "italic")
call HighlightFor("Identifier",  s:jet_black,        s:medium_steel,  "NONE")
call HighlightFor("Statement",   s:crisp_white,      s:deep_charcoal, "NONE")
call HighlightFor("StorageClass",s:soft_ivory,       "NONE",          "italic")
call HighlightFor("Structure",   s:soft_ivory,       "NONE",          "italic")
call HighlightFor("Repeat",      s:soft_ivory,       s:stormy_gray,   "NONE")
call HighlightFor("Conditional", s:soft_ivory,       s:stormy_gray,   "NONE")
call HighlightFor("Operator",    s:crisp_white,      s:jet_black,     "NONE")
call HighlightFor("Type",        s:crisp_white,      s:shadow_gray,   "NONE")
call HighlightFor("Typedef",     s:crisp_white,      s:shadow_gray,   "NONE")
call HighlightFor("PreProc",     s:crisp_white,      s:muted_silver,  "NONE")
call HighlightFor("Underlined",  s:crisp_white,      s:muted_silver,  "NONE")
call HighlightFor("Special",     s:vibrant_teal,     s:jet_black,     "NONE")

call HighlightFor("Label",       s:crisp_white,      s:neon_magenta,  "NONE")
call HighlightFor("Exception",   s:jet_black,        s:neon_magenta,  "NONE")
call HighlightFor("Todo",        s:jet_black,        s:vibrant_teal,  "italic")
call HighlightFor("Error",       s:jet_black,        s:neon_magenta,  "undercurl")
call HighlightFor("WarningMsg",  s:jet_black,        s:vibrant_teal,  "NONE")
call HighlightFor("Tag",         s:jet_black,        s:vibrant_teal,  "undercurl")

" Status line
call HighlightFor("StatusLine",  s:stormy_gray,      s:crisp_white,   "bold")
call HighlightFor("StatusLineNC",s:vibrant_teal,     s:jet_black,     "NONE")

" Tab pages
call HighlightFor("TabLine",     s:crisp_white,      s:jet_black,     "NONE")
call HighlightFor("TabLineSel",  s:jet_black,        s:vibrant_teal,  "bold")
call HighlightFor("TabLineFill", s:crisp_white,      s:dark_slate,    "NONE")

" Placeholder
call HighlightFor("Title",       s:crisp_white,      s:stormy_gray,   "NONE")
call HighlightFor("WildMenu",    s:crisp_white,      s:muted_silver,  "NONE")

" Custom fugitive blame colors
call HighlightFor("fugitiveHash",     s:jet_black,   s:vibrant_teal,  "NONE")
call HighlightFor("fugitiveAuthor",   s:jet_black,   s:neon_magenta,  "NONE")
call HighlightFor("fugitiveTime",     s:jet_black,   s:light_mist,    "NONE")
call HighlightFor("fugitiveSummary",  s:jet_black,   s:soft_ivory,    "NONE")
call HighlightFor("fugitiveBoundary", s:jet_black,   s:neon_magenta,  "NONE")
call HighlightFor("fugitiveUntracked",s:jet_black,   s:muted_silver,  "NONE")
call HighlightFor("fugitiveUnstaged", s:jet_black,   s:medium_steel,  "NONE")
call HighlightFor("fugitiveStaged",   s:jet_black,   s:vibrant_teal,  "NONE")

" Additional General Interface Highlights
call HighlightFor("CursorIM",       s:vibrant_teal,     s:jet_black,      "NONE")          " Cursor in insert mode (GUI/terminal)
call HighlightFor("VisualNOS",      s:crisp_white,      s:muted_silver,   "NONE")          " Visual selection when not owning selection
call HighlightFor("QuickFixLine",   s:jet_black,        s:vibrant_teal,   "bold")          " Selected line in quickfix window
call HighlightFor("ErrorMsg",       s:neon_magenta,     s:jet_black,      "bold")          " Error messages on command line
call HighlightFor("ModeMsg",        s:soft_ivory,       s:deep_charcoal,  "NONE")          " Mode messages (e.g., -- INSERT --)
call HighlightFor("MoreMsg",        s:soft_ivory,       s:deep_charcoal,  "NONE")          " More prompts (e.g., -- More --)
call HighlightFor("Question",       s:vibrant_teal,     s:deep_charcoal,  "bold")          " Prompt questions (e.g., confirm prompts)
call HighlightFor("ColorColumn",    "NONE",             s:stormy_gray,    "NONE")          " Column highlight (e.g., colorcolumn=80)
call HighlightFor("Conceal",        s:muted_silver,     "NONE",           "NONE")          " Concealed text (e.g., markdown hidden chars)
call HighlightFor("EndOfBuffer",    s:light_mist,       "NONE",           "NONE")          " Beyond buffer (e.g., ~ characters)
call HighlightFor("Menu",           s:crisp_white,      s:stormy_gray,    "NONE")          " GUI Vim menu items
call HighlightFor("ScrollBar",      s:muted_silver,     s:deep_charcoal,  "NONE")          " GUI Vim scrollbar
call HighlightFor("Tooltip",        s:crisp_white,      s:stormy_gray,    "NONE")          " GUI Vim tooltips

" Additional Syntax Highlights
call HighlightFor("Constant",       s:crisp_white,      s:jet_black,      "NONE")          " General constants (parent group)
call HighlightFor("SpecialKey",     s:vibrant_teal,     "NONE",           "NONE")          " Special chars when :set list (e.g., tabs)
call HighlightFor("SpecialChar",    s:vibrant_teal,     s:jet_black,      "NONE")          " Special chars in strings (e.g., \n)
call HighlightFor("Debug",          s:soft_ivory,       s:stormy_gray,    "italic")        " Debugging-related elements
call HighlightFor("Define",         s:crisp_white,      s:muted_silver,   "NONE")          " Preprocessor definitions (e.g., #define)
call HighlightFor("Macro",          s:crisp_white,      s:muted_silver,   "NONE")          " Macro definitions/invocations
call HighlightFor("PreCondit",      s:crisp_white,      s:muted_silver,   "NONE")          " Preprocessor conditionals (e.g., #ifdef)
call HighlightFor("Include",        s:crisp_white,      s:muted_silver,   "NONE")          " Include/import statements
call HighlightFor("Delimiter",      s:light_mist,       s:jet_black,      "NONE")          " Delimiters (e.g., commas, parentheses)
call HighlightFor("SpecialComment", s:muted_silver,     s:deep_charcoal,  "italic")        " Special comments (e.g., TODO, FIXME)

" Spell Checking Highlights
call HighlightFor("SpellBad",       s:neon_magenta,     s:jet_black,      "undercurl")     " Misspelled words
call HighlightFor("SpellCap",       s:neon_magenta,     s:jet_black,      "undercurl")     " Capitalization errors
call HighlightFor("SpellRare",      s:soft_ivory,       s:jet_black,      "undercurl")     " Rare/unusual words
call HighlightFor("SpellLocal",     s:vibrant_teal,     s:jet_black,      "undercurl")     " Locally correct words

" Neovim-Specific Highlights (LSP and Tree-Sitter)
call HighlightFor("LspDiagnosticsDefaultError",       s:neon_magenta,     s:jet_black,      "undercurl")     " LSP error diagnostics
call HighlightFor("LspDiagnosticsDefaultWarning",     s:vibrant_teal,     s:jet_black,      "undercurl")     " LSP warning diagnostics
call HighlightFor("LspDiagnosticsDefaultInformation", s:soft_ivory,       s:jet_black,      "NONE")          " LSP info diagnostics
call HighlightFor("LspDiagnosticsDefaultHint",        s:vibrant_teal,     s:jet_black,      "NONE")          " LSP hint diagnostics
call HighlightFor("LspReferenceText",                 s:crisp_white,      s:stormy_gray,    "NONE")          " LSP reference text
call HighlightFor("LspReferenceRead",                 s:crisp_white,      s:stormy_gray,    "NONE")          " LSP read references
call HighlightFor("LspReferenceWrite",                s:crisp_white,      s:stormy_gray,    "NONE")          " LSP write references
call HighlightFor("TSVariable",                       s:soft_ivory,       s:jet_black,      "NONE")          " Tree-sitter variables
call HighlightFor("TSFunction",                       s:jet_black,        s:crisp_white,    "italic")        " Tree-sitter functions
call HighlightFor("TSString",                         s:crisp_white,      s:jet_black,      "NONE")          " Tree-sitter strings
call HighlightFor("TSKeyword",                        s:crisp_white,      s:medium_steel,   "italic")        " Tree-sitter keywords
call HighlightFor("TSTag",                            s:jet_black,        s:vibrant_teal,   "undercurl")     " Tree-sitter tags (e.g., HTML tags)
