return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            {
                "debugloop/telescope-undo.nvim",
                keys = { { "<leader>U", "<cmd>Telescope undo<cr>" } },
                config = function()
                    require("telescope").load_extension("undo")
                end,
            },
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            {
                "<leader>fp",
                function()
                    require("telescope.builtin").find_files({
                        cwd = require("lazy.core.config").options.root,
                    })
                end,
                desc = "Find Plugin File",
            },
            {
                "<leader>fl",
                function()
                    local files = {} ---@type table<string, string>
                    for _, plugin in pairs(require('lazy.core.config').plugins) do
                        repeat
                            if plugin._.module then
                                local info = vim.loader.find(plugin._.module)[1]
                                if info then
                                    files[info.modpath] = info.modpath
                                end
                            end
                            plugin = plugin._.super
                        until not plugin
                    end
                    require('telescope.builtin').live_grep({
                        default_text = "/",
                        search_dirs = vim.tbl_values(files),
                    })
                end,
                desc = "Find Lazy Plugin Spec",
            }
        },
        opts = {
            defaults = {
                file_ignore_patterns = "node_modules",
                path_display = { "truncate" },
                preview = {
                    treesitter = false, -- Disable treesitter in preview so large files to hang
                    filesize_limit = 0.1,
                    timeout = 250,
                },
                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        prompt_position = "top",
                        preview_width = 0.5,
                    },
                    width = 0.8,
                    height = 0.8,
                    preview_cutoff = 120,
                },
                sorting_strategy = "ascending",
                winblend = 0
            },
            pickers = {
                buffers = {
                    mappings = {
                        n = {
                            ["d"] = require("telescope.actions").delete_buffer,
                        }
                    }
                }
            }
        },
        config = function()
            vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
            vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
            vim.keymap.set('n', '<leader>/', function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                require("telescope.builtin").current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
            vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
            vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
            vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
            vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
            vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
            vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })
        end,
    }
}
