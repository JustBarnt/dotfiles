return {
    -- neodev
    -- Provides LSP for vim functions
    {
        "folke/neodev.nvim",
        opts = {
            debug = true,
            experimental = {
                pathStrict = true,
            },
            library = {
                runtime = "C:\\Program Files\\Neovim\\share\\nvim\\runtime"
            }
        }
    },

    -- tools
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, {
                "stylua",
                "selene",
                "luacheck",
                "powershell",
                "eslint_d"
            })
        end,
    },

    -- lsp servers
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = { enabled = true },
            capabilities = {
                workspace = {
                    didChangeWatchedFiles = {
                        dynamicRegistration = false,
                    },
                },
            },
            ---@type lspconfig.options
            servers = {
                emmet_language_server = {
                    filetypes = { "html", "svelte", "astro", "javascriptreact", "typescriptreact", "xml" },
                },
                intelephense = {
                    settings = {
                        intelephense = { 
                            files = {
                                maxSize = 100000;
                            },
                        },
                        environment = {
                            includePaths = {
                                "C:\\PHP\\include"
                            }
                        }
                    }
                },
                powershell_es = {
                    cmd = { "pwsh", "-NoLogo", "-NoProfile", "-Command", vim.fn.stdpath('data') .. "/mason/packages/powershell-editor-services" }                },
                svelte = {
                    root_dir = function(...)
                        return require('lspconfig.util').root_pattern(".git")(...)
                    end,
                },
                tailwindcss = {
                    root_dir = function(...)
                        return require('lspconfig.util').root_pattern(".git")(...)
                    end,
                },
                vimls = {},
                tsserver = {
                    single_file_support = false,
                    settings = {
                        typescript = {
                            inlayHints = {
                                includeInlayParameterNameHints = "literal",
                                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHints = false,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
                            },
                        },
                        javascript = {
                            inlayHints = {
                                includeInlayParameterNameHints = "all",
                                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHints = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
                            },
                        },
                    },
                },
                sqlls = { filetypes = { "sql", "mysql" } },
                html = { filetypes = { "html", "twig", "hbs" } },
                lua_ls = {
                    single_file_support = true,
                    settings = {
                        Lua = {
                            workspace = {
                                checkThirdParty = false,
                            },
                            completion = {
                                workspaceWord = true,
                                callSnippet = "Both",
                            },
                            misc = {
                                parameters = {

                                }
                            },
                        },
                        hover = { expandAlias = false },
                        hint = {
                            enable = true,
                            setType = false,
                            paramType = true,
                            paramName = "Disable",
                            semicolon = "Disable",
                            arrayIndex = "Disable",
                        },
                        doc = {
                            privateName = { "^_" },
                        },
                        type = {
                            castNumberToInteger = true,
                        },
                        diagnostics = {
                            disable = { "incomplete-signature-doc", "trailing-space" },
                            groupSeverity = {
                                strong = "Warning",
                                strict = "Warning",
                            },
                            groupFileStatus = {
                                ["ambiguity"] = "Opened",
                                ["await"] = "Opened",
                                ["codestyle"] = "None",
                                ["duplicate"] = "Opened",
                                ["global"] = "Opened",
                                ["luadoc"] = "Opened",
                                ["redefined"] = "Opened",
                                ["strict"] = "Opened",
                                ["strong"] = "Opened",
                                ["type-check"] = "Opened",
                                ["unbalanced"] = "Opened",
                                ["unused"] = "Opened",
                            },
                            unusedLocalExclude = { "_*" },
                        },
                    },
                    format = {
                        enable = true,
                        defaultConfig = {
                            indent_style = "space",
                            indent_size = "2",
                            continuation_indent_size = "2",
                        },
                    },
                },
            },
            setup = {},
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            diagnostics = { virtual_text = { prefix = 'icons' } },
        }
    },

    {
        'stevearch/conform.nvim',
        optional = true,
        opts = {
            formatters_by_ft = {
                ["markdown"] = { { "prettierd", "prettier" } },
                ["markdown.mdx"] = { { "prettierd", "prettier" } },
                ["javascript"] = { "dprint" },
                ["javascriptreact"] = { "dprint" },
                ["typescript"] = { "dprint" },
                ["typescriptreact"] = { "dprint" },
            },
            formatters = {
                shfmt = {
                    prepend_args = { "-i", "2", "-ci" },
                },
                dprint = {
                    condition = function(ctx)
                        return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
                    end,
                },
            },
        }
    },
    {
        "mfussenegger/nvim-lint",
        opts = {
            linters_by_ft = {
                lua = { "selene", "luacheck" },
                markdown = { "markdownlint" },
            },
            linters = {
                selene = {
                    condition = function(ctx)
                        return vim.fs.find({"selene.toml" }, { path = ctx.filename, upward = true})[1]
                    end,
                },
                luacheck = {
                    condition = function(ctx)
                        return vim.fs.find({".luacheckrc" }, { path = ctx.filename, upward = true })[1]
                    end,
                },
            },
        },
    },
}
