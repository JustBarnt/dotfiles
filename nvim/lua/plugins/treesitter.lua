return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, {
                "c",
                "cmake",
                "cpp",
                "css",
                "gitcommit",
                "gitignore",
                "http",
                "php",
                "lua",
                "json",
                "sql",
                "svelte",
                "html",
                "c_sharp",
                "javascript",
                "typescript",
                "regex",
                "markdown",
                "markdown_inline",
            })
        end,
    }
}
