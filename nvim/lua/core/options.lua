vim.g.loaded.matchparen = 1

local opt = vim.opt

-- Spell Checking
opt.spell = true
opt.spelllang = "en_us"

-- Cool floating window popup menu for completion on command line
opt.pumblend = 17
opt.wildmode = "longest:full"
opt.wildoptions = 'pum'

opt.showmode = false
opt.showcmd = true
opt.cmdheight = 1 -- Height of the command bar
opt.incsearch = true -- Makes search act like search in modern browsers
opt.showmatch = true -- Show matching brackets when text indicator is over them
opt.relativenumber = true -- Show line numbers, makes vertical movement/searching easier
opt.number = true -- Show the actual number for the line we are on
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- Unless are query has a capital letter
opt.hidden = true -- Buffers stay open unless you close them via ":bd"
opt.equalalways = false -- Doesn't force all windows to be the same size
opt.splitright = true -- Prefer windows splitting to the right
opt.splitbelow = true -- Prefer windows splitting to the bottom
opt.updatetime = 1000 -- Make updates happen faster
opt.hlsearch = true -- TeejDV - Dont use without his DoNoHL function
opt.scrolloff = 10  -- Make it so there are always 10 lines below cursors current pos

opt.smoothscroll = true

-- Cursorline highlighting control
-- Only haveit on in the active buffers
opt.cursorline = true -- Highlight the current line
local group = vim.api.nvim_create_augroup("CursorLineControl", { clear = true })
local set_cursorline = function(event, value, pattern)
    vim.api.nvim_create_autocmd(event, {
        group = group,
        pattern = pattern,
        callback = function()
            vim.opt_local.cursorline = value
        end,
    })
end

set_cursorline("WinLeave", false)
set_cursorline("WinEnter", true)
set_cursorline("FileType", false, "TelescopePrompt")

-- Tabs
opt.autoindent = true
opt.cindent = true
opt.wrap = true

opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = 4

opt.breakline = 4
opt.showbreak = string.rep(" ", 3) -- Make it so that long lines wrap smartly
opt.linebreak = true

opt.foldmethod = "marker"
opt.foldlevel = 0
opt.modelines = 1

opt.belloff = "all" -- turn off all annoying "ding" sounds that neovim could potentially trigger

opt.clipboard = "unnamedplus" -- Use system clipboard

opt.inccommand = "split"
opt.swapfile = false -- disable creating backups of the buffer, almost always in a git repo

-- {"!" -- Load shada securely, "'1000" --Max items in history, "<50" --Max Lines stored, "s10" --File size to 10kb, "h" --include cli history }
opt.shada = { "!", "'1000", "<50", "s10", "h" } -- Configures shared data file

opt.mouse = "a" -- Enables mouse for all modes

-- Helpful related items:
--   1. :center, :left, :right
--   2. gw{motion} - Put cursor back after formatting motion.
--
-- TODO: w, {v, b, l}
opt.formatoptions = opt.formatoptions
    - "a" -- Auto formatting is BAD.
    - "t" -- Don't auto format my code. I got linters for that.
    + "c" -- In general, I like it when comments respect textwidth
    + "q" -- Allow formatting comments w/ gq
    - "o" -- O and o, don't continue comments
    + "r" -- But do continue when pressing enter.
    + "n" -- Indent past the formatlistpat, not underneath it.
    + "j" -- Auto-remove comments if possible.
    - "2" -- I'm not in gradeschool anymore

opt.joinspaces = false
opt.fillchars = { eob = "~" }

vim.opt.diffopt = { "internal", "filler", "closeoff", "hiddenoff", "algorithm:minimal" }

vim.opt.undofile = true
vim.opt.signcolumn = "yes"
