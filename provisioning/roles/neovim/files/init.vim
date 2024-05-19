set mouse=a
"
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab

set expandtab
set smartindent

set wildmode=longest,full

set autochdir

set showcmd

colorscheme torte

" permits to exit insert mode by typing with jj
imap jj <Esc>
imap jk <Esc>
imap kk <Esc>
imap hh <Esc>

nmap dk :wq<CR>
nmap fk :w<CR>
"the status bar is always displayed
set laststatus=2
if has("statusline")
    set statusline=%<%f%h%m%r%=%l,%c\ %P
elseif has("cmdline_info")
    set ruler " display cursor position
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

Plug 'nvim-neotest/nvim-nio'

Plug 'folke/tokyonight.nvim', { 'branch': 'main' }

Plug 'ntpeters/vim-better-whitespace'

Plug 'dcampos/nvim-snippy'
Plug 'dcampos/cmp-snippy'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
Plug 'rmagatti/goto-preview'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

Plug 'phpactor/phpactor', {'for': 'php', 'branch': 'master', 'do': 'composer install --no-dev -o'}

Plug 'evidens/vim-twig'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'mfussenegger/nvim-dap'
Plug 'rcarriga/nvim-dap-ui'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'theHamsta/nvim-dap-virtual-text'
Plug 'codota/tabnine-nvim', { 'do': './dl_binaries.sh' }
Plug 'andymass/vim-matchup'


" Initialize plugin system
call plug#end()

colorscheme tokyonight

" to easily switch from a split containing a terminal to an other split
" see https://medium.com/@garoth/neovim-terminal-usecases-tricks-8961e5ac19b9
func! s:mapMoveToWindowInDirection(direction)
    func! s:maybeInsertMode(direction)
        stopinsert
        execute "wincmd" a:direction

        if &buftype == 'terminal'
            startinsert!
        endif
    endfunc

    execute "tnoremap" "<silent>" "<C-" . a:direction . ">"
                \ "<C-\\><C-n>"
                \ ":call <SID>maybeInsertMode(\"" . a:direction . "\")<CR>"
    execute "nnoremap" "<silent>" "<C-" . a:direction . ">"
                \ ":call <SID>maybeInsertMode(\"" . a:direction . "\")<CR>"
endfunc
for dir in ["h", "j", "l", "k"]
    call s:mapMoveToWindowInDirection(dir)
endfor



let $FZF_DEFAULT_COMMAND='rg --files --hidden --follow --ignore-vcs'

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>).' /vagrant', 1,
  \   fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)

command! -bang -nargs=* Rgall
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-ignore-vcs  --glob "!{node_modules/*,.git/*}"  --no-heading --color=always --smart-case -- '.shellescape(<q-args>).' /vagrant', 1,
  \   fzf#vim#with_preview(), <bang>0)

command! -bang PF call fzf#vim#files('/vagrant', <bang>0)
nnoremap <c-p> :PF<CR>
nnoremap <c-g> :Rg<CR>
nnoremap <c-f> :Rgall<CR>

" GoTo code navigation.
lua << EOF

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- https://vonheikemen.github.io/devlog/tools/setup-nvim-lspconfig-plus-nvim-cmp/
local lsp_defaults = {
  flags = {
    debounce_text_changes = 150,
  },
  capabilities = require('cmp_nvim_lsp').default_capabilities(
    vim.lsp.protocol.make_client_capabilities()
  ),
  on_attach = function(client, bufnr)
    vim.api.nvim_exec_autocmds('User', {pattern = 'LspAttached'})
  end
}
local lspconfig = require('lspconfig')

lspconfig.util.default_config = vim.tbl_deep_extend(
  'force',
  lspconfig.util.default_config,
  lsp_defaults
)

vim.api.nvim_create_autocmd('User', {
  pattern = 'LspAttached',
  desc = 'LSP actions',
  callback = function()
    local bufmap = function(mode, lhs, rhs)
      local opts = {buffer = true}
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    -- Displays hover information about the symbol under the cursor
    bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')

    -- Jump to the definition
    bufmap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>')

    -- Jump to declaration
    bufmap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>')

    -- Lists all the implementations for the symbol under the cursor
    bufmap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>')

    -- Jumps to the definition of the type symbol
    bufmap('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>')

    -- Displays a function's signature information
    bufmap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')

    -- Renames all references to the symbol under the cursor
    bufmap('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>')

    -- Selects a code action available at the current cursor position
    bufmap('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>')
    bufmap('x', '<F4>', '<cmd>lua vim.lsp.buf.range_code_action()<cr>')

    -- Show diagnostics in a floating window
    bufmap('n', 'gl', '<cmd>lua vim.diagnostic.open_float({scope="buffer"})<cr>')

    -- Move to the previous diagnostic
    bufmap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

    -- Move to the next diagnostic
    bufmap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
  end
})

lspconfig.phpactor.setup{
    cmd = {'/home/vagrant/.local/share/nvim/plugged/phpactor/bin/phpactor', 'language-server'},
    on_attach = function(client, bufnr)
      lspconfig.util.default_config.on_attach(client, bufnr)
    end,
    init_options = {
        ["language_server_phpstan.enabled"] = true,
        ["language_server_psalm.enabled"] = false,
    }
}

vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

local cmp = require('cmp')
local select_opts = {behavior = cmp.SelectBehavior.Select}

cmp.setup({
    snippet = {
      expand = function(args)
        require('snippy').expand_snippet(args.body) -- For `snippy` users.
      end,
    },
    sources = {
      {name = 'path'},
      {name = 'nvim_lsp', keyword_length = 2},
      {name = 'buffer', keyword_length = 3},
      {name = 'snippy' },
    },
    window = {
      documentation = cmp.config.window.bordered()
    },
    mapping = {
      ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
      ['<Down>'] = cmp.mapping.select_next_item(select_opts),

      ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
      ['<C-n>'] = cmp.mapping.select_next_item(select_opt),

      ['<C-u>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),

      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({select = true}),
      ['<C-k>'] = cmp.mapping(function(fallback)
        local col = vim.fn.col('.') - 1

        if cmp.visible() then
          cmp.select_next_item(select_opts)
        elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
          fallback()
        else
          cmp.complete()
        end
      end, {'i', 's'}),

      ['<C-j>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item(select_opts)
        else
          fallback()
        end
      end, {'i', 's'}),
   }

})

local sign = function(opts)
  vim.fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = ''
  })
end

sign({name = 'DiagnosticSignError', text = '✘'})
sign({name = 'DiagnosticSignWarn', text = '▲'})
sign({name = 'DiagnosticSignHint', text = '⚑'})
sign({name = 'DiagnosticSignInfo', text = ''})

vim.diagnostic.config({
  virtual_text = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'always',
    header = '',
    prefix = '',
  },
})

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  {border = 'rounded'}
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  {border = 'rounded'}
)

require('goto-preview').setup {}

EOF
nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>
nnoremap gpt <cmd>lua require('goto-preview').goto_preview_type_definition()<CR>
nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>
nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>
" Only set if you have telescope installed
nnoremap gr <cmd>lua require('goto-preview').goto_preview_references()<CR>

autocmd FileType php set iskeyword+=$
autocmd FileType css set iskeyword+=-
autocmd FileType html set iskeyword+=-
autocmd FileType js set iskeyword+=-
autocmd FileType htmldjango.twig set iskeyword+=-


" nvim dap
lua <<EOF

    local watch_type = require("vim._watch").FileChangeType

    local function handler(res, callback)
      if not res.files or res.is_fresh_instance then
        return
      end

      for _, file in ipairs(res.files) do
        local path = res.root .. "/" .. file.name
        local change = watch_type.Changed
        if file.new then
          change = watch_type.Created
        end
        if not file.exists then
          change = watch_type.Deleted
        end
        callback(path, change)
      end
    end

    function watchman(path, opts, callback)
      vim.system({ "watchman", "watch", path }):wait()

      local buf = {}
      local sub = vim.system({
        "watchman",
        "-j",
        "--server-encoding=json",
        "-p",
      }, {
        stdin = vim.json.encode({
          "subscribe",
          path,
          "nvim:" .. path,
          {
            expression = { "anyof", { "type", "f" }, { "type", "d" } },
            fields = { "name", "exists", "new" },
          },
        }),
        stdout = function(_, data)
          if not data then
            return
          end
          for line in vim.gsplit(data, "\n", { plain = true, trimempty = true }) do
            table.insert(buf, line)
            if line == "}" then
              local res = vim.json.decode(table.concat(buf))
              handler(res, callback)
              buf = {}
            end
          end
        end,
        text = true,
      })

      return function()
        sub:kill("sigint")
      end
    end

    if vim.fn.executable("watchman") == 1 then
      require("vim.lsp._watchfiles")._watchfunc = watchman
    end



    local dap = require('dap')
    dap.adapters.php = {
      type = 'executable',
      command = 'node',
      args = { '/opt/vscode-php-debug-main/out/phpDebug.js' }
    }

    dap.configurations.php = {
      {
        type = 'php',
        request = 'launch',
        name = 'Listen for Xdebug',
        port = 9003,
        host = '0.0.0.0',
--        pathMappings = { ['/vagrant'] = '/vagrant/'}
        pathMappings = { ['/var/task'] = '/vagrant/'}


      }
    }
    require("nvim-dap-virtual-text").setup()

    local dapui = require("dapui")
    dapui.setup()
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    require'nvim-treesitter.configs'.setup {
      -- A list of parser names, or "all"
      ensure_installed = { "php" },
      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,
      -- Automatically install missing parsers when entering buffer
      auto_install = true,

      matchup = {
        enable = true,              -- mandatory, false will disable the whole extension
      },
    }

    require('tabnine').setup({
      disable_auto_comment=true,
      accept_keymap="<Tab>",
      dismiss_keymap = "<C-]>",
      debounce_ms = 800,
      suggestion_color = {gui = "#808080", cterm = 244},
      exclude_filetypes = {"TelescopePrompt", "NvimTree"},
      log_file_path = nil, -- absolute path to Tabnine log file
    })
EOF

nnoremap <silent> <F5> :lua require('dap').toggle_breakpoint()<CR>
nnoremap <silent> <F9> :lua require('dap').continue()<CR>
