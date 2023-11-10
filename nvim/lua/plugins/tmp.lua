return {
    {
        "echasnovski/mini.align",
        opts = {},
        keys = {
            { "ga", mode = { "n", "v" } },
            { "gA", mode = { "n", "v" } },
        }
    },
    {
        "2kabhishek/nerdy.nvim",
        cmd = "Nerdy",
        keys = {
            { "<leader>ci", "<cmd>Nerdy<cr>", desc = "Pick Icon" },
        },
    },
    {
        "echasnovski/mini.pick",
        cmd = "Pick",
        opts = {},
    },
    {
        "Ackld/muren.nvim",
        event = {
            { "BufNewFile", "BufAdd" },
        },
        opts = {
            patterns_width = 60,
            patterns_height = 20,
            options_width = 40,
            preview_height = 24,
        },
        cmd = "MurenToggle",
    },
    {
        "folke/flash.nvim",
        enabled = true,
        init = function()
        end,
        ---@opts Flash.Config
        opts = {
            modes = {
                treesitter_search = {
                    label = {
                        rainbow = { enabled = true },
                    },
                },
            },
        },
    }
}
