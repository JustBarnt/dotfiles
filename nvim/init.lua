require 'core.options'
if vim.g.neovide then
    local alpha = function()
        return string.format("%x", math.floor(255 * vim.g.transparency or 0.8))
    end

    -- Set font for neovide. Ligatures are enabled by default.
    vim.o.guifont = "CaskaydiaCove NF:h34"
    vim.g.neovide_scale_factor = 0.38

    --Configured neovide background opacity
    vim.g.transparency = 0.95
    vim.g.neovide_transparency = 0.95
    vim.g.neovide_background_color = "#190e2e" .. alpha();

    vim.g.neovide_theme = 'dark'
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_trail_length = 0
end

-- Leader Key -> Space
--
-- In general, it is good practice to set this early in your config because if any 
-- mappings get set before this they will be set to the OLD leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Turn off builtin plugins I do not use
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        "git",
        "clone",
        "--filter=blob:none",
        "--single-branch",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    }
end

vim.opt.runtimepath:preprend(lazypath)

require("lazy").setup("custom.plugins", {
    dev = {
        path = "~/plugins",
        fallback = false,
    },
    ui = {
        icons = {
            cmd = "",
            config = "",
            event = "",
            ft = "",
            init = "",
            keys = "",
            plugin = "",
            runtime = "",
            source = "",
            start = "",
            task = "",
        }
    }
})
