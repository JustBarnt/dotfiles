if vim.env.VSCODE then
    vim.g.vscode = true
    vim.print("WE ARE IN VSCODE ☠")
end

-- Check to ensure vim is set to load     

if vim.loader then
    vim.loader.enable()
end


pcall(require, 'config.env')

require('config.lazy')({
    debug = false,
    profiling = {
        loader = false,
        require = false
    },
})

_G.lv = require("lazyvim.util")

vim.api.nvim_create_autocmd("User", {
    pattern = 'VeryLazy',
    callback = function()
        require('util').version()
    end,
})
