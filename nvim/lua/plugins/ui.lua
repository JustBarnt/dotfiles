return {
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_,opts)
            table.insert(opts.sections.lua_x, {
                function()
                    return require("util.dashboard").status()
                end,
            })
        end,
    },
    "folke/twilight.nvim",
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        opts = {
            plugins = {
                gitsigns = true,
            },
        },
        keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
    },
}
