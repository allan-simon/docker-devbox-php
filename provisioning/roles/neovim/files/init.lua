-- Basic settings
vim.opt.mouse = 'a'
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wildmode = 'longest,full'
vim.opt.autochdir = true
vim.opt.showcmd = true
vim.cmd('colorscheme torte')

-- Key mappings for exiting insert mode
vim.keymap.set('i', 'jj', '<Esc>')
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('i', 'kk', '<Esc>')
vim.keymap.set('i', 'hh', '<Esc>')

-- Save and quit mappings
vim.keymap.set('n', 'dk', ':wq<CR>')
vim.keymap.set('n', 'fk', ':w<CR>')

-- Status line configuration
vim.opt.laststatus = 3
if vim.fn.has("statusline") == 1 then
    vim.opt.statusline = '%<%f%h%m%r%=%l,%c\\ %P'
elseif vim.fn.has("cmdline_info") == 1 then
    vim.opt.ruler = true -- display cursor position
end

-- Plugin management with vim-plug
local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.local/share/nvim/plugged')

-- Plugins
Plug('folke/tokyonight.nvim', { branch = 'main' })
Plug('ntpeters/vim-better-whitespace')
Plug('dcampos/nvim-snippy')
Plug('dcampos/cmp-snippy')
Plug('nvim-lua/plenary.nvim')
Plug('nvim-telescope/telescope.nvim', { tag = '0.1.0' })
Plug('rmagatti/goto-preview')
Plug('neovim/nvim-lspconfig')
Plug('hrsh7th/cmp-nvim-lsp')
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-cmdline')
Plug('hrsh7th/nvim-cmp')
Plug('phpactor/phpactor', {['for'] = 'php', branch = 'master', ['do'] = 'composer install --no-dev -o'})
Plug('evidens/vim-twig')
Plug('junegunn/fzf', { ['do'] = function() vim.fn['fzf#install']() end })
Plug('junegunn/fzf.vim')
Plug('nvim-neotest/nvim-nio')
Plug('mfussenegger/nvim-dap')
Plug('rcarriga/nvim-dap-ui')
Plug('nvim-treesitter/nvim-treesitter', {['do'] = ':TSUpdate'})
Plug('theHamsta/nvim-dap-virtual-text')
Plug('codota/tabnine-nvim', { ['do'] = './dl_binaries.sh' })
Plug('andymass/vim-matchup')
Plug('f-person/git-blame.nvim')

-- avante.nvim and dependencies
Plug('nvim-treesitter/nvim-treesitter')
Plug('stevearc/dressing.nvim')
Plug('nvim-lua/plenary.nvim')
Plug('MunifTanjim/nui.nvim')
Plug('MeanderingProgrammer/render-markdown.nvim')
Plug('hrsh7th/nvim-cmp')
Plug('nvim-tree/nvim-web-devicons')
Plug('HakonHarnes/img-clip.nvim')
Plug('zbirenbaum/copilot.lua')
Plug('yetone/avante.nvim', { branch = 'main', ['do'] = 'make' })

vim.call('plug#end')

-- Set colorscheme after plugin initialization
vim.cmd('colorscheme tokyonight')

-- Terminal window navigation
local function maybe_insert_mode(direction)
    vim.cmd('stopinsert')
    vim.cmd('wincmd ' .. direction)

    if vim.bo.buftype == 'terminal' then
        vim.cmd('startinsert!')
    end
end

-- Set up keymaps for window navigation
for _, dir in ipairs({"h", "j", "l", "k"}) do
    vim.keymap.set('t', '<C-' .. dir .. '>',
        '<C-\\><C-n>:lua maybe_insert_mode("' .. dir .. '")<CR>',
        {noremap = true, silent = true})
    vim.keymap.set('n', '<C-' .. dir .. '>',
        ':lua maybe_insert_mode("' .. dir .. '")<CR>',
        {noremap = true, silent = true})
end


-- FZF configuration
vim.env.FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --ignore-vcs'

vim.cmd([[
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>).' /vagrant', 1,
  \   fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)

command! -bang -nargs=* Rgall
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-ignore-vcs  --glob "!{node_modules/*,.git/*}"  --no-heading --color=always --smart-case -- '.shellescape(<q-args>).' /vagrant', 1,
  \   fzf#vim#with_preview(), <bang>0)

command! -bang PF call fzf#vim#files('/vagrant', <bang>0)
]])

vim.keymap.set('n', '<c-p>', ':PF<CR>')
vim.keymap.set('n', '<c-g>', ':Rg<CR>')
vim.keymap.set('n', '<c-f>', ':Rgall<CR>')

-- LSP configuration
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

-- Phpactor setup
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

-- Completion configuration
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
      {name = 'snippy'},
    },
    window = {
      documentation = cmp.config.window.bordered()
    },
    mapping = {
      ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
      ['<Down>'] = cmp.mapping.select_next_item(select_opts),

      ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
      ['<C-n>'] = cmp.mapping.select_next_item(select_opts),

      ['<C-u>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),

      ['<C-e>'] = cmp.mapping.abort(),
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

-- Diagnostic signs
local function sign(opts)
  vim.fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = ''
  })
end

sign({name = 'DiagnosticSignError', text = '✘'})
sign({name = 'DiagnosticSignWarn', text = '▲'})
sign({name = 'DiagnosticSignHint', text = '⚑'})
sign({name = 'DiagnosticSignInfo', text = ''})

-- Diagnostic configuration
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

-- LSP handlers configuration
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  {border = 'rounded'}
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  {border = 'rounded'}
)

-- Setup goto-preview
require('goto-preview').setup {}

-- Goto preview keymaps
vim.keymap.set('n', 'gpd', "<cmd>lua require('goto-preview').goto_preview_definition()<CR>")
vim.keymap.set('n', 'gpt', "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>")
vim.keymap.set('n', 'gpi', "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
vim.keymap.set('n', 'gP', "<cmd>lua require('goto-preview').close_all_win()<CR>")
vim.keymap.set('n', 'gr', "<cmd>lua require('goto-preview').goto_preview_references()<CR>")

-- Set iskeyword for different filetypes
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'php',
  callback = function() vim.opt_local.iskeyword:append('$') end
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = {'css', 'html', 'js', 'htmldjango.twig'},
  callback = function() vim.opt_local.iskeyword:append('-') end
})

-- Watchman setup for file watching
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

-- DAP (Debug Adapter Protocol) configuration
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
    pathMappings = { ['/var/task'] = '/vagrant/'}
  }
}

-- DAP virtual text setup
require("nvim-dap-virtual-text").setup()

-- DAP UI setup
local dapui = require("dapui")
dapui.setup()

-- DAP UI listeners
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Treesitter configuration
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all"
  ensure_installed = { "php" },
  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,
  -- Automatically install missing parsers when entering buffer
  auto_install = true,

  fold = {
    enable = true,
    exclude = { '#\\[.*\\]' }  -- Exclude attributes
  },
  matchup = {
    enable = true,              -- mandatory, false will disable the whole extension
  },
}

-- Enable treesitter folding
vim.opt.foldmethod = 'expr'

-- Custom fold function
vim.cmd([[
  function! CustomFold()
    let line = getline(v:lnum)
    if line =~ '^use\s' && getline(v:lnum - 1) !~ '^use\s'
      return '>2'
    elseif line =~ '^use\s'
      return '2'
    elseif getline(v:lnum - 1) =~ '^use\s' && line !~ '^use\s'
      return '<2'
    elseif line =~ '^\s*#\[.*$'
      return '>1'  -- Fold for attributes
    endif
    return nvim_treesitter#foldexpr()
  endfunction
]])

vim.opt.foldexpr = 'CustomFold()'
vim.opt.foldlevel = 1  -- Level 1 keeps classes open but methods folded

-- Tabnine setup
require('tabnine').setup({
  disable_auto_comment = true,
  accept_keymap = "<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  exclude_filetypes = {"TelescopePrompt", "NvimTree"},
  log_file_path = nil, -- absolute path to Tabnine log file
})

-- Matchup configuration
vim.g.matchup_matchparen_offscreen = {method = 'popup'}

-- Debug keymaps
vim.keymap.set('n', '<F5>', "<cmd>lua require('dap').toggle_breakpoint()<CR>", {silent = true})
vim.keymap.set('n', '<F9>', "<cmd>lua require('dap').continue()<CR>", {silent = true})

-- Initialize avante.nvim
vim.cmd([[
autocmd! User avante.nvim lua require('avante').setup()
]])

