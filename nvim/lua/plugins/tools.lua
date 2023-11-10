return {
    -- Preview github pull request
    { "pwntester/octo.nvim", opts = {}, cmd = "Octo" },

    -- markdown preview
    -- {
    --   "toppair/peek.nvim",
    --   build = "deno task --quiet build:fast",
    --   keys = {
    --     {
    --       "<leader>cp",
    --       ft = "markdown",
    --       function()
    --         local peek = require("peek")
    --         if peek.is_open() then
    --           peek.close()
    --         else
    --           peek.open()
    --         end
    --       end,
    --       desc = "Peek (Markdown Preview)",
    --     },
    --   },
    --   opts = { theme = "light" },
    -- },

    -- better diffing
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
        opts = {},
        keys = { { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView" } },
    },
}
