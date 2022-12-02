local set = vim.o                    -- set global options
local buf = vim.bo                   -- set buffer-scoped options
local wnd = vim.wo                   -- set window-scoped options
local cmd = vim.cmd                  -- to call vim commands, like cmd('pwd')
local fn  = vim.fn                   -- to call vim functions

-- PLUGINS --------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- load the package manager
cmd 'packadd paq-nvim'
local paq = require('paq-nvim').paq
paq {'hoob3rt/lualine.nvim'}
paq {'hrsh7th/nvim-compe'}
paq {'hrsh7th/vim-vsnip'}
paq {'hrsh7th/vim-vsnip-integ'}
paq {'kyazdani42/nvim-web-devicons'}
paq {'mhinz/vim-signify'}
paq {'nvim-lua/popup.nvim'}
paq {'nvim-lua/plenary.nvim'}
paq {'nvim-telescope/telescope.nvim'}
paq {'nvim-treesitter/nvim-treesitter'}
paq {'neovim/nvim-lspconfig'}
paq {'projekt0n/github-nvim-theme'}
paq {'romgrk/barbar.nvim'}
paq {'sindrets/diffview.nvim'}
paq {'tpope/vim-fugitive'}
paq {'savq/paq-nvim', opt = true}

local diffcb = require('diffview.config').diffview_callback
require('diffview').setup {
  diff_binaries = false,    -- Show diffs for binaries
  file_panel = {
    with_config = {
      width = 35,
    },
  },
  use_icons = true,        -- Requires nvim-web-devicons
  key_bindings = {
    disable_defaults = false,                   -- Disable the default key bindings
    -- The `view` bindings are active in the diff buffers, only when the current
    -- tabpage is a Diffview.
    view = {
      ["<tab>"]     = diffcb("select_next_entry"),  -- Open the diff for the next file 
      ["<s-tab>"]   = diffcb("select_prev_entry"),  -- Open the diff for the previous file
      ["<leader>e"] = diffcb("focus_files"),        -- Bring focus to the files panel
      ["<leader>b"] = diffcb("toggle_files"),       -- Toggle the files panel.
    },
    file_panel = {
      ["j"]             = diffcb("next_entry"),         -- Bring the cursor to the next file entry
      ["<down>"]        = diffcb("next_entry"),
      ["k"]             = diffcb("prev_entry"),         -- Bring the cursor to the previous file entry.
      ["<up>"]          = diffcb("prev_entry"),
      ["<cr>"]          = diffcb("select_entry"),       -- Open the diff for the selected entry.
      ["o"]             = diffcb("select_entry"),
      ["<2-LeftMouse>"] = diffcb("select_entry"),
      ["-"]             = diffcb("toggle_stage_entry"), -- Stage / unstage the selected entry.
      ["S"]             = diffcb("stage_all"),          -- Stage all entries.
      ["U"]             = diffcb("unstage_all"),        -- Unstage all entries.
      ["X"]             = diffcb("restore_entry"),      -- Restore entry to the state on the left side.
      ["R"]             = diffcb("refresh_files"),      -- Update stats and entries in the file list.
      ["<tab>"]         = diffcb("select_next_entry"),
      ["<s-tab>"]       = diffcb("select_prev_entry"),
      ["<leader>e"]     = diffcb("focus_files"),
      ["<leader>b"]     = diffcb("toggle_files"),
    }
  }
}

require('telescope').setup {
}

require('nvim-treesitter.configs').setup {
    highlight = {enable = true}
}

-- set the colorsheme/background
require('catppuccin').setup({
    flavour = 'frappe',
    transparent_background = false,
    no_italic = true,
})

vim.cmd.colorscheme 'catppuccin'

require('lualine').setup {
    options = {
        theme = 'auto',
        section_separators = {'', ''},
        component_separators = {'', ''},
        disabled_filetypes = {},
        icons_enabled = true
    },
--  +-------------------------------------------------+
--  | A | B | C                             X | Y | Z |
--  +-------------------------------------------------+
    sections = {
        lualine_a = { {'mode', upper = true} },
        lualine_b = { {'branch', icon = ''} },
        lualine_c = { {'filename', file_status = true} },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location'  },
    },
    inactive_sections = {
        lualine_a = {  },
        lualine_b = {  },
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {  },
        lualine_z = {   }
    },
}

-- CONFIGURE LSP --------------------------------------------------------------
-- ----------------------------------------------------------------------------
local nvimlsp = require('lspconfig')

require('compe').setup {
    enabled = true,
    autocomplete = true,
    debug = false,
    min_length = 1,
    preselect = 'enable',
    throttle_time = 80,
    source_timeout = 200,
    resolve_timeout = 800,
    incomplete_delay = 400,
    max_abbr_width = 100,
    max_kind_width = 100,
    max_menu_width = 100,

    documentation = {
        border = { '', '' ,'', ' ', '', '', '', ' ' },
        winhighlight = "NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder",
        max_width = 120,
        min_width = 60,
        max_height = math.floor(vim.o.lines * 0.3),
        min_height = 1,
    },

    source = {
        path = true,
        buffer = true,
        calc = true,
        nvim_lsp = true,
        nvim_lua = true,
        vsnip = true,
    },
}

local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    local opts = {noremap=true, silent=true}
    local opts_map = {silent=true}
    buf_set_keymap('n', '[n,', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']n;', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>a', '<cmd>Telescope lsp_code_actions<CR>', opts)
    -- display hover information about the symbol under the cursor
    buf_set_keymap('n', '<F2>', '<cmd>lua vim.lsp.buf.hover()<CR>', opts_map)
    -- jumps to the definition of the symbol under the cursor
    buf_set_keymap('n', '<F3>', '<cmd>Telescope lsp_definitions<CR>', opts_map)
    -- jumps to the definition of the type of the symbol under the cursor 
    buf_set_keymap('n', '<F4>', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts_map)
    -- jumps to the declaration of the symbol under the cursor
    buf_set_keymap('n', '<F5>', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts_map)
    -- lists all implementations for the symbol under the cursor
    buf_set_keymap('n', '<F6>', '<cmd>Telescope lsp_implementations<CR>', opts_map)
    -- lists all references to the symbol under the cursor
    buf_set_keymap('n', '<F7>', "<cmd>Telescope lsp_references<CR>", opts_map)
    -- renames all references to the symbol under the cursor
    buf_set_keymap('n', '<F8>', '<cmd>lua vim.lsp.buf.rename()<CR>', opts_map)
    -- displays the signature information about the function under the cursor
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>s', '<cmd>Telescope lsp_document_symbols<CR>', opts)

    -- formats the current buffer
    if client.resolved_capabilities.document_formatting then
        buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
    elseif client.resolved_capabilities.document_range_formatting then
        buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', opts)
    end

    -- sent request to server to resolve document highlights for the current position
    if client.resolved_capabilities.document_highlight then
        vim.api.nvim_exec([[
            hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
            hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
            hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
            augroup lsp_document_highlight
                autocmd! * <buffer>
                autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
                autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
            augroup END
        ]], false)
    end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
        'documentation',
        'detail',
        'additionalTextEdits',
    }
}

local servers = {'clangd', 'pyright', 'bashls', 'gopls', 'tsserver', 'rust_analyzer'}
for _, lsp in ipairs(servers) do
    nvimlsp[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities
    }
end

cmd 'au TextYankPost * lua vim.highlight.on_yank{}'

set.cscopequickfix = "s-,c-,d-,i-,t-,e-"

-- FUNCTIONS ------------------------------------------------------------------
-- ----------------------------------------------------------------------------
local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend('force', options, opts) end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

local scopes = {o = vim.o, b = vim.bo, w = vim.wo}
local function opt(scope, key, value)
    scopes[scope][key] = value
    if scope ~= 'o' then scopes['o'][key] = value end
end

local termcds = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- MIXED SCOPE SETTINGS -------------------------------------------------------
-- ----------------------------------------------------------------------------
-- convert TABs to SPACEs
opt('b', 'expandtab', true)

-- size of an indent
opt('b', 'shiftwidth', 4)

-- number os spaces that a tab counts for
opt('b', 'tabstop', 4)

-- number of spaces that a tab counts for in editing mode
opt('b', 'softtabstop', 4)

-- apply the indentation of current line to the next (<enter>
opt('b', 'autoindent', true)

-- follow the syntax of the code being edited
opt('b', 'smartindent', true)

-- show file numbers
opt('w', 'number', true)

-- signs and numbers in the same column
opt('w', 'signcolumn', 'number')

-- EDITOR CHANGES -------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- inserts blank spaces when TAB in front of a line
set.smarttab = true

-- highlight searches
set.hlsearch = true

-- ignore "insensitive" case if start searching with capital letter
set.smartcase = true

-- start matching patterns while searching is being typed
set.incsearch = true

-- show the effects of a command incrementally
set.inccommand = 'split'

-- don't unload abandoned buffers
set.hidden = true

-- show longest list of command completition
 set.wildmode = 'list:longest'

-- ignore case when completing filenames and directories
set.wildignorecase = true

-- file that matches the pattern are ignored when expanding wildcards
set.wildignore = ".git,*.pyc,*.o,**/tmp/**"

-- quick jump to the matching bracked when editing
set.showmatch = true

-- command lines remebered
set.history = 5000

-- round indent to multiple of shiftwidth
set.shiftround = true

-- behavior of backspace
set.backspace = "indent,eol,start"

-- do not adjust the case of the match base on the text
set.infercase = false

set.updatetime=200

-- matches for insert mode completition
--set.complete = '.,w,b,k'
set.completeopt = "menuone,noselect"
--set.completeopt = 'menu,noinsert,noselect,preview'
--                   ^     ^         ^        ^-- extra info about selected cmd
--                   |     |         +-- dont select a match, user must choose
--                   |     +-- dont insert any text for a match
--                   +-- popup menu to show the possibilities

-- try make messages shorter
set.shortmess = vim.o.shortmess .. 'c'

-- number of screen lines to use for cmd line
set.cmdheight = 2

-- virtualedit lets visual selection choose empty spaces as well
set.virtualedit = "block"

-- GUI ------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

-- use 24-bit color palette
set.termguicolors = true

-- highligh the current line
set.cursorline = true

-- do not wrap long lines
set.wrap = false

-- always show a status line
set.laststatus = 2

-- enhanced mode command line completition
set.wildmenu = true

-- show partial command in the status line
set.showcmd = true

set.lazyredraw = true
set.shell = '/bin/zsh'

-- GENERAL --------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- add fuzzy to runtime path
set.rtp = set.rtp .. os.getenv("HOME") .. "/.fzf/bin/fzf"

-- do not allow :autocmd shell commands
-- set.secure = true

-- set the filename as titlestring (konsole might display it)
set.title = true

-- when splitting, new windows will be place at right
set.splitright = true

-- don't save backup files
set.backup = false
set.writebackup = false
set.swapfile = false

-- uses a file to remember the undos of a buffer
set.undofile = true
set.undolevels = 1000
set.undodir = os.getenv("HOME") .. "/.cache/nvim/undofile"

-- enables mouse support in all (normal, visual, insert, command) modes
set.mouse='a'

-- gives EOL formats to be tried when starting to edit a new buffer
set.fileformats="unix,dos,mac"

-- list of directories that will be search when using gf, :find, etc...
set.path = set.path .. '**'

-- set file encodings
set.encoding = 'utf-8'
set.fileencoding = set.encoding
set.fileencodings = set.encoding

-- let cursor positioned where there is no actual character
set.virtualedit = 'block'

-- strings to use in 'list' mode or :list
-- set.listchars = 'tab:░░,trail:·,space:·,extends:»,precedes:«,nbsp:⣿'
set.listchars = 'tab:╰─,trail:·,extends:»,precedes:«,nbsp:␣'
set.list = true

-- characters to fill the statuslines and vertical separators
set.fillchars = "stlnc:»,vert:║,fold:·"

-- enable file vim configuration
set.modeline = true

-- parses up to 2 lines of configuration
set.modelines = 2

-- remember information of closed files
set.shada = "!,'50,<50,@50,s10,h"
--           ^  ^   ^   ^   ^  ^-- disable effect of hlsearch when loading shada
--           |  |   |   |   +-- max size of item contents in KiB
--           |  |   |   +-- max number of items in input-line hist. saved
--           |  |   +-- max number of lines saved
--           |  +-- max number of prev. edited files remembered
--           +-- save/restore global vars that start with uppercase letter

-- VIM COMMANDS ---------------------------------------------------------------

-- enable filetype detection
cmd 'filetype plugin indent on'

-- GLOBALS --------------------------------------------------------------------

-- set map leader key
vim.g.mapleader = ","
vim.b.mapleader = vim.g.mapleader

-- MAPS -----------------------------------------------------------------------

local normal_echo = { silent = false, noremap = true }
local silent_echo = { silent = true, noremap = true }
local expr = { silent = true, noremap = false, expr=true }

map('n', '<leader>e', ':e <C-R>=expand("%:p:h") . "/" <CR>', normal_echo)
map('n', '<leader>h', ':<C-u>split<CR>', normal_echo)
map('n', '<leader>v', ':<C-u>vsplit<CR>', normal_echo)
map('n', '<leader>z', ':bp<CR>', normal_echo)
map('n', '<leader>x', ':bn<CR>', normal_echo)
map('n', '<leader>c', ':bw<CR>', normal_echo)
map('n', '<leader><space>', ':noh<CR>', silent_echo)

map('v', 'Y', '"+y', normal_echo)
map('n', '<leader>p', '"+p', normal_echo)
map('i', '<C-p>', '<Esc>"+gpa', normal_echo)

map('n', '<leader>ff', '<cmd>Telescope find_files<cr>', silent_echo)
map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', silent_echo)
map('n', '<leader>fb', '<cmd>Telescope buffers<cr>', silent_echo)
map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', silent_echo)
map('n', '<leader>gc', '<cmd>Telescope git_commits<cr>', silent_echo)
map('n', '<leader>gn', '<cmd>Telescope git_bcommits<cr>', silent_echo)
map('n', '<leader>gb', '<cmd>Telescope git_branches<cr>', silent_echo)
map('n', '<leader>gs', '<cmd>Telescope git_status<cr>', silent_echo)
map('n', '<leader>gt', '<cmd>Telescope git_stash<cr>', silent_echo)
map('n', '<leader>gs', '<cmd>Telescope spell_suggest<cr>', silent_echo)

map('i', '<C-Space>', 'compe#complete()', expr)
map('i', '<CR>', 'compe#confirm("<CR>")', expr)
map('i', '<C-e>', 'compe#close("<C-e>")', expr)
map('i', '<C-f>', 'compe#scroll({ "delta": +4 })', expr)
map('i', '<C-d>', 'compe#scroll({ "delta": -4 })', expr)

map('i', '<Tab>', 'v:lua.tab_complete()', expr)
map('s', '<Tab>', 'v:lua.tab_complete()', expr)
map('i', '<S-Tab>', 'v:lua.s_tab_complete()', expr)
map('s', '<S-Tab>', 'v:lua.s_tab_complete()', expr)

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

_G.tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return termcds "<C-n>"
    elseif vim.fn['vsnip#available'](1) == 1 then
        return termcds "<Plug>(vsnip-expand-or-jump)"
    elseif check_back_space() then
        return termcds "<Tab>"
    else
        return vim.fn['compe#complete']()
    end
end

_G.s_tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return termcds "<C-p>"
    --elseif vim.fn['vsnip#jumpable'](-1) == 1 then
    --    return termcds "<Plug>(vsnip-jump-prev)"
    else
        return termcds "<S-Tab>"
    end
end

-- VIM CONFIG ----------------------------------------------------------------
-- ---------------------------------------------------------------------------
vim.api.nvim_command('let bufferline = get(g:, "bufferline", {})')
vim.api.nvim_command('let bufferline.animation = v:false')
vim.api.nvim_command('let bufferline.closable = v:false')
vim.api.nvim_command('let bufferline.icons = v:false')
vim.api.nvim_command('let bufferline.maximum_padding = 1')

vim.api.nvim_exec([[
  autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit' | exe "normal! g`\"" | endif
  autocmd BufNewFile,BufRead *.fs,*.fsx,*.fsi set filetype=fsharp
]], false)

