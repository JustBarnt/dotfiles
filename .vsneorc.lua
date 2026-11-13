-- VSNeo example Lua config — copy to ~/.vsneorc.lua
--
-- LazyVim-flavored: space leader, mappings with descriptions (the which-key
-- popup reads desc first; vimscript's :nnoremap cannot carry one, which is
-- why this file exists). The companion sources ~/.vsneorc (vimscript) first,
-- then this file, then pushes the mapping table for the popup.
--
-- Companion already provides: gd/gD/gi/gr, [d/]d, K, <leader>rn, <leader>ca,
-- <leader>f, gb (tab jumper), s (jump labels), <C-w>h/j/k/l (split nav).
-- This file adds the LazyVim-style leader groups on top.
--
-- Every option VSNeo reads, with defaults: docs/options.md.

vim.g.mapleader = ' '

vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Named-key ownership is configurable without changing the insert-typing model:
-- vim.cmd('Sethandler <C-p> n:ide i:ide')
-- vim.cmd('Sethandler <F2> a:ide c:vim')

-- nvim's syntax highlighting and Treesitter are off by default: Visual Studio
-- draws the text, so nvim's highlighting is never seen and only costs time.
-- Opt back in if an indent script or plugin needs syntax information:
-- vim.g.vsneo_syntax = 1
-- vim.cmd('syntax on')

-- Neovide-style cursor trail (Neovide's names, vsneo_ prefix). Defaults shown;
-- a length of 0 turns it off. Also off while Windows animations are disabled.
-- vim.g.vsneo_cursor_animation_length = 0.13
-- vim.g.vsneo_cursor_short_animation_length = 0.04  -- typing, h/l: <= 2 columns on one line

-- Smooth scrolling for <C-d>/<C-u>/<C-f>/<C-b>, zz/zt/zb, G, n... (Neovide's names).
-- vim.g.vsneo_scroll_animation_length = 0.3      -- 0 = instant
-- vim.g.vsneo_scroll_animation_far_lines = 1     -- past a screen, animate only the last N lines
-- Jump beacon: a fading bar at the cursor after a jump of >= min_jump lines, and on focus.
-- vim.g.vsneo_beacon = true
-- vim.g.vsneo_beacon_min_jump = 10
-- vim.g.vsneo_beacon_width = 40                  -- columns
-- vim.g.vsneo_beacon_duration = 0.4
-- Software rendering (Remote Desktop, GPU-less VM, VS hardware acceleration off) turns
-- particles, glow, smooth scrolling and fading blinks off. Override the detection:
-- vim.g.vsneo_reduce_effects = false   -- always keep effects; true = always reduce
-- vim.g.vsneo_cursor_trail_size = 0.8
-- vim.g.vsneo_cursor_animate_in_insert_mode = true
-- Cursor effects, off by default. One name or a list; mix freely.
--   Neovide's (on jumps): 'railgun', 'torpedo', 'pixiedust', 'sonicboom', 'ripple', 'wireframe'
--   Cyberpunk: 'glitch'   RGB-split tear on jumps, mode changes and focus
--              'matrix'   katakana rain from the jump path
--   glitch, matrix and circuit skip single steps (typing, h/j/k/l); the rest fire on every move.
--              'circuit'  a right-angle neon trace drawn from old to new position
--              'scanline' a scan line sweeping the editor on jumps across lines, and focus
--              'sparks'   sparks from every typed character
--              'flicker'  the cursor flickering like neon on mode changes and focus
-- vim.g.vsneo_cursor_vfx_mode = 'railgun'
-- vim.g.vsneo_cursor_vfx_mode = { 'circuit', 'glitch', 'sparks', 'flicker' }   -- a cyberpunk set
-- vim.g.vsneo_cursor_vfx_opacity = 200.0                 -- 0..255
-- vim.g.vsneo_cursor_vfx_particle_lifetime = 0.5
-- vim.g.vsneo_cursor_vfx_particle_highlight_lifetime = 0.2
-- vim.g.vsneo_cursor_vfx_particle_density = 0.7
-- vim.g.vsneo_cursor_vfx_particle_speed = 10.0
-- vim.g.vsneo_cursor_vfx_particle_phase = 1.5             -- railgun
-- vim.g.vsneo_cursor_vfx_particle_curl = 1.0              -- railgun, torpedo

-- VSNeo's own cursor instead of Visual Studio's caret (off until either is set).
-- Styles: 'block', 'block-outline', 'line', 'line-thin', 'underline', 'underline-thin'.
-- A string sets normal mode; a table sets any of normal/insert/replace/visual/operator/cmdline.
-- Blinking (VS Code's): 'blink', 'smooth', 'phase', 'expand' (shrinks to its centre), 'solid'.
-- vim.g.vsneo_cursor_style = { normal = 'block-outline', insert = 'line', replace = 'underline' }
-- vim.g.vsneo_cursor_blinking = 'expand'

-- Cursor color: '#rrggbb' or a highlight group name, one for every mode or a
-- table per mode. The trail and particles follow it. vsneo_cursor_glow adds
-- a neon halo (true = 12 px, or a radius in px). Cyberpunk presets
-- (preview: docs/cursor-vfx/cyberpunk-palettes.png) - pick one:
--
-- Night City (Cyberpunk 2077 yellow / cyan / red)
-- vim.g.vsneo_cursor_color = { normal = '#FCEE0A', insert = '#00F0FF', replace = '#FF003C', operator = '#FF003C' }
-- Neon Tokyo (hot pink / cyan)
-- vim.g.vsneo_cursor_color = { normal = '#FF2A6D', insert = '#05D9E8', replace = '#F9F002', operator = '#D1F7FF' }
-- Netrunner (acid green)
-- vim.g.vsneo_cursor_color = { normal = '#39FF14', insert = '#00FF9F', replace = '#FF073A', operator = '#F5F500' }
-- Blade Runner (orange / teal / magenta)
-- vim.g.vsneo_cursor_color = { normal = '#FF6C11', insert = '#2DE2E6', replace = '#F706CF', operator = '#FFD319' }
-- Vaporwave (purple / sky / pink)
-- vim.g.vsneo_cursor_color = { normal = '#B967FF', insert = '#01CDFE', replace = '#FF71CE', operator = '#FFFB96' }
--
-- vim.g.vsneo_cursor_glow = true

-- Presets. Blade Runner, The Matrix and Cyberpunk 2077 are built in, and
-- so are the editor themes Tokyo Night and Catppuccin:
--   vim.g.vsneo_preset = 'blade_runner'      -- or 'matrix', 'cyberpunk2077',
--   -- 'tokyo_night', 'tokyo_night_light', 'catppuccin_mocha',
--   -- 'catppuccin_macchiato', 'catppuccin_frappe', 'catppuccin_latte'
-- and :VSNeoPreset <name> switches live (:VSNeoPreset lists them). Anything
-- set above still wins over vsneo_preset; :VSNeoPreset wins over both for
-- the session, until :VSNeoPreset none. The blocks below are the same
-- values spelled out, to copy and adjust.
--
vim.g.vsneo_preset = 'tokyo_night'

-- Preset: Blade Runner. Sodium-orange city, teal spinner lights, magenta
-- neon, smoke. Uncomment the block as a whole; it sets everything above.
--   scanline - the Esper machine sweeping a photo (jumps across lines, focus)
--   torpedo  - spinner exhaust smoke drifting behind moves
--   flicker  - a failing neon sign on every mode change
--   sparks   - hot sparks off each typed character
--
-- vim.g.vsneo_cursor_style    = { normal = 'block-outline', insert = 'line', replace = 'underline' }
-- vim.g.vsneo_cursor_blinking = 'expand'
-- vim.g.vsneo_cursor_color    = { normal = '#FF6C11', insert = '#2DE2E6', replace = '#F706CF', operator = '#FFD319' }
-- vim.g.vsneo_cursor_glow     = true
-- vim.g.vsneo_cursor_animation_length = 0.16     -- a heavier trail, a spinner banking through smog
-- vim.g.vsneo_cursor_trail_size       = 0.85
-- vim.g.vsneo_cursor_vfx_mode = { 'scanline', 'torpedo', 'flicker', 'sparks' }
-- vim.g.vsneo_cursor_vfx_opacity = 170.0                     -- hazy
-- vim.g.vsneo_cursor_vfx_particle_lifetime = 0.6             -- smoke lingers
-- vim.g.vsneo_cursor_vfx_particle_highlight_lifetime = 0.25  -- a slower Esper sweep
-- vim.g.vsneo_cursor_vfx_particle_density = 0.6
-- vim.g.vsneo_cursor_vfx_particle_speed = 7.0                -- heavy air
-- vim.g.vsneo_cursor_vfx_particle_curl = 0.6                 -- lazy swirl in the smoke
-- vim.g.vsneo_mode_line = true
-- vim.g.vsneo_mode_line_opacity = 0.10
-- vim.g.vsneo_beacon_duration = 0.5
-- Swap 'torpedo' for 'pixiedust' for rain instead of smoke, or add 'matrix'
-- for orange glyph rain like the street signs.

-- Preset: The Matrix. Phosphor green on black, digital rain, the red pill
-- (replace) and the blue pill (visual). Uncomment the block as a whole.
--   matrix  - katakana and 0/1 rain from the jump path (real jumps only:
--             G, n, }, w, a click - not typing or single h/j/k/l)
--   sparks  - typing throws off sparks
--   flicker - the cursor stutters on mode changes: a glitch in the Matrix
--
-- vim.g.vsneo_cursor_style    = { normal = 'block-outline', insert = 'line', replace = 'underline' }
-- vim.g.vsneo_cursor_blinking = 'phase'           -- a soft fade, like an old green CRT
-- vim.g.vsneo_cursor_color    = {
--   normal   = '#00FF41',   -- phosphor green
--   insert   = '#D1FFD6',   -- pale "white rabbit" green
--   replace  = '#FF2A2A',   -- red pill
--   visual   = '#2A7FFF',   -- blue pill
--   operator = '#B6FF00',
-- }
-- vim.g.vsneo_cursor_glow = true
-- vim.g.vsneo_cursor_animation_length = 0.12
-- vim.g.vsneo_cursor_trail_size       = 0.9      -- long smear, bullet time
-- vim.g.vsneo_cursor_vfx_mode = { 'matrix', 'sparks', 'flicker' }
-- vim.g.vsneo_cursor_vfx_opacity = 220.0
-- vim.g.vsneo_cursor_vfx_particle_lifetime = 0.6             -- rain lives twice this: 1.2 s
-- vim.g.vsneo_cursor_vfx_particle_highlight_lifetime = 0.2
-- vim.g.vsneo_cursor_vfx_particle_density = 1.0              -- denser rain (capped at 60 glyphs a jump)
-- vim.g.vsneo_cursor_vfx_particle_speed = 8.0                -- a steady fall
-- vim.g.vsneo_mode_line = true
-- vim.g.vsneo_mode_line_opacity = 0.08
-- vim.g.vsneo_beacon = true
-- Add 'scanline' for a CRT sweep on far jumps, or 'railgun' for a green
-- helix along every jump.

-- Preset: Cyberpunk 2077. Night City yellow, netrunner cyan, Arasaka red;
-- glitch's fixed red/cyan split is the game's own look. Uncomment the block
-- as a whole.
--   glitch   - red/cyan split and tear bars on jumps, mode changes and focus
--   circuit  - a netrunner trace drawn from the old position to the new
--   scanline - a braindance scan across the line on far jumps and focus
--   sparks   - sparks off each typed character
--   (glitch, circuit and scanline skip typing and single h/j/k/l steps)
--
-- vim.g.vsneo_cursor_style    = { normal = 'block-outline', insert = 'line', replace = 'underline' }
-- vim.g.vsneo_cursor_blinking = 'blink'           -- hard on/off, like the game's HUD
-- vim.g.vsneo_cursor_color    = {
--   normal   = '#FCEE0A',   -- Night City yellow
--   insert   = '#00F0FF',   -- netrunner cyan
--   replace  = '#FF003C',   -- Arasaka red
--   visual   = '#FF2A6D',   -- neon pink
--   operator = '#FF003C',
-- }
-- vim.g.vsneo_cursor_glow = 10
-- vim.g.vsneo_cursor_animation_length = 0.10     -- snappy: chrome reflexes
-- vim.g.vsneo_cursor_trail_size       = 0.7
-- vim.g.vsneo_cursor_vfx_mode = { 'glitch', 'circuit', 'scanline', 'sparks' }
-- vim.g.vsneo_cursor_vfx_opacity = 230.0                     -- bright neon
-- vim.g.vsneo_cursor_vfx_particle_lifetime = 0.4             -- quick and sharp
-- vim.g.vsneo_cursor_vfx_particle_highlight_lifetime = 0.18
-- vim.g.vsneo_cursor_vfx_particle_density = 0.8
-- vim.g.vsneo_cursor_vfx_particle_speed = 12.0
-- vim.g.vsneo_mode_line = true
-- vim.g.vsneo_mode_line_opacity = 0.10
-- vim.g.vsneo_beacon = true
-- vim.g.vsneo_beacon_duration = 0.3
-- Add 'flicker' for a relic malfunction on mode changes, swap 'circuit' for
-- 'matrix' for yellow quickhack glyph rain, or use style 'block' for a solid
-- yellow cursor.

-- Do not disturb: every animation and effect off at once - trail, effects,
-- smooth scrolling, beacon, custom cursor, glow, mode line - just Visual
-- Studio's plain caret. The settings above are kept and come back when it
-- is turned off. Live: :VSNeoDnd (toggle), :VSNeoDnd on, :VSNeoDnd off.
-- vim.g.vsneo_dnd = true
-- vim.keymap.set('n', '<leader>z', '<Cmd>VSNeoDnd<CR>', { desc = 'Focus: animations off/on' })

-- Mode-colored cursor line (modes.nvim): uses the colors above per mode;
-- uncolored modes fall back to teal/red/purple/amber, normal stays plain.
vim.g.vsneo_mode_line = true
vim.g.vsneo_mode_line_opacity = 0.12
--
-- Relative line numbers (VSNeo's margin follows these nvim options; the
-- cursor line's number takes the mode color while vsneo_mode_line is on):
-- vim.o.relativenumber = true
-- vim.o.number = true        -- absolute number on the cursor line (without it: 0, as in Vim)

local function vsc(lhs, command, desc)
  vim.keymap.set('n', lhs, function() vsneo.cmd(command) end,
    { silent = true, desc = desc })
end

-- find: the embedded Seeky picker (Telescope-style, over the native fff
-- engine — built into VSNeo, nothing else to install). Its keys are Visual
-- Studio chords, so they work in every mode and take nothing from nvim:
--   Ctrl+Shift+Alt+O  files          Ctrl+Shift+Alt+,  workspace symbols
--   Ctrl+Shift+Alt+I  live grep      Ctrl+Shift+Alt+B  document outline
--   Ctrl+Shift+Alt+G  grep word/sel  Ctrl+Shift+Alt+M  git modified
--   Ctrl+Shift+Alt+L  current file   Ctrl+Shift+Alt+R  resume last picker
-- (rebind under Tools > Options > Keyboard, Tools.Seeky*). From nvim, the
-- same pickers are :Seeky <mode> [query] and vsneo.seeky(mode, query), e.g.
--   vim.keymap.set('n', '<leader>ff', function() vsneo.seeky('files') end)

-- vim.keymap.del('n', '<leader>f')
-- vim.keymap.del('n', '<leader>sf')
vim.keymap.set('n', '<leader>ff', function() vsneo.seeky('files') end)

vsc('<C-r>', 'Edit.Redo', 'Redo Change')

-- buffers / tabs
vsc('<S-L>', 'Window.NextTab', 'Next tab')
vsc('<S-H>', 'Window.PreviousTab', 'Previous tab')

vsc('<leader>bn', 'Window.NextTab', 'Next tab')
vsc('<leader>bp', 'Window.PreviousTab', 'Previous tab')

-- code
vsc('grn', 'Refactor.Rename', 'Rename symbol')
vsc('grf', 'Edit.FormatDocument', 'Format document')
vsc('gre', 'View.ErrorList', 'Error list')
vsc('grR', 'Edit.FindAllReferences', 'Find All References')
vsc('gro', 'EditorContextMenus.CodeWindow.ToggleHeaderCodeFile', 'Toggle Header/Source Code')
vsc('grO', 'EditorContextMenus.CodeWindow.PeekHeaderCodeFile', 'Peek Header/Source Code')
vsc('<leader>k', 'Edit.PeekDefinition', 'Peek Definition')

-- multi-edit: arm the matches of the last search (/ or *), change one with
-- cgn/ciw, and Esc replays the change at every other match
vim.keymap.set('n', '<leader>mm', function() vsneo.multi_edit() end,
  { silent = true, desc = 'Multi-edit all search matches' })

-- build
vsc('<leader>bb', 'Build.BuildSolution', 'Build solution')
vsc('<leader>bs', 'Build.BuildSelection', 'Build project')
vsc('<leader>bc', 'Build.CancelBuild', 'Cancel build')
vsc('<leader>be', 'View.ErrorList', 'Error list')

-- debug: nvim-dap's keys (as LazyVim binds them), driving Visual Studio's
-- debugger. Breakpoints and the current line are drawn by Visual Studio.
vsc('<leader>db', 'Debug.ToggleBreakpoint', 'Toggle breakpoint')
vsc('<leader>dB', 'Debug.EnableBreakpoint', 'Enable/disable breakpoint')
vsc('<leader>dc', 'Debug.Start', 'Continue / start debugging')
vsc('<leader>dC', 'Debug.RunToCursor', 'Run to cursor')
vsc('<leader>dn', 'Debug.StartWithoutDebugging', 'Run without debugging')
vsc('<leader>di', 'Debug.StepInto', 'Step into')
vsc('<leader>do', 'Debug.StepOut', 'Step out')
vsc('<leader>dO', 'Debug.StepOver', 'Step over')
vsc('<leader>dr', 'Debug.Restart', 'Restart debugging')
vsc('<leader>dt', 'Debug.StopDebugging', 'Terminate')
vsc('<leader>dp', 'Debug.BreakAll', 'Pause')
vsc('<leader>dq', 'Debug.QuickWatch', 'Quick watch')
vsc('<leader>dw', 'Debug.Watch1', 'Watch window')
vsc('<leader>dl', 'Debug.Locals', 'Locals window')
vsc('<leader>dk', 'Debug.CallStack', 'Call stack')
vsc('<leader>dD', 'Debug.Windows.Breakpoints', 'Breakpoints window')

-- test: neotest-style keys over the Test Explorer. "In context" is the test,
-- class or file under the cursor.
vsc('<leader>tt', 'TestExplorer.RunAllTestsInContext', 'Run tests here')
vsc('<leader>td', 'TestExplorer.DebugAllTestsInContext', 'Debug tests here')
vsc('<leader>tT', 'TestExplorer.RunAllTests', 'Run all tests')
vsc('<leader>tl', 'TestExplorer.RepeatLastRun', 'Repeat last run')
vsc('<leader>tf', 'TestExplorer.RunFailedTests', 'Run failed tests')
vsc('<leader>te', 'TestExplorer.ShowTestExplorer', 'Test Explorer')

-- git: the Git menu, gitsigns-style keys. Hunk navigation has no command
-- in Visual Studio's editor (only the diff viewer's Diff.NextDifference).
vsc('<leader>gg', 'Team.Git.GoToGitChanges', 'Git changes')
vsc('<leader>gc', 'Team.Git.CommitOrStash', 'Commit')
vsc('<leader>gp', 'Team.Git.Push', 'Push')
vsc('<leader>gP', 'Team.Git.Pull', 'Pull')
vsc('<leader>gf', 'Team.Git.Fetch', 'Fetch')
vsc('<leader>gs', 'Team.Git.Sync', 'Sync')
vsc('<leader>gh', 'Team.Git.ViewHistory', 'File history')
vsc('<leader>gB', 'Team.Git.ManageBranches', 'Branches')
vsc('<leader>gd', 'Team.Git.CompareWithUnmodified', 'Diff with unmodified')
vsc('<leader>gr', 'Team.Git.OpenRepository', 'Repository window')

-- windows
vsc('<leader>e', 'View.SolutionExplorer', 'Solution Explorer')

------------------------------------------------------------------
-- Plugins (standard packages layout rooted at ~/.vsneo; verified working
-- headless against VSNeo's exact startup flags):
--
--   git clone https://github.com/echasnovski/mini.ai       ~/.vsneo/pack/lazy/start/mini.ai
--   git clone https://github.com/echasnovski/mini.surround ~/.vsneo/pack/lazy/start/mini.surround
--   git clone https://github.com/chrisgrieser/nvim-spider  ~/.vsneo/pack/lazy/start/nvim-spider
--
-- mini.nvim defines nothing until setup() (lazy.nvim normally makes that
-- call; here we are our own distro). The pcall keeps this rc harmless when
-- a plugin is not installed.
------------------------------------------------------------------

pcall(function() require('mini.ai').setup() end)        -- argument textobject: cia, daa, ...
pcall(function() require('mini.surround').setup() end)  -- saiw) sd" sr"'

-- nvim-spider: camelCase/subword motions, the C# spelling of w/e/b.
-- Commented out by default because it remaps core motions; uncomment to try.
-- local ok, spider = pcall(require, 'spider')
-- if ok then
--   for _, key in ipairs({ 'w', 'e', 'b' }) do
--     vim.keymap.set({ 'n', 'o', 'x' }, key,
--       function() spider.motion(key) end,
--       { desc = 'spider ' .. key })
--   end
-- end
