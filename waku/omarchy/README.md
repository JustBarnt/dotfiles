# omarchy for waku

A port of the [Omarchy 4](https://github.com/omacom/omarchy) ("Quattro") desktop shell to waku: the
top bar, the menu / app launcher, the theme and background switchers and the control panels. MIT,
derived from the upstream `shell/` directory (see `LICENSE`). The default theme is Catppuccin.

## Run it

    .\tools\start.ps1       # live: your deployed engine, tray, app bar, Windows taskbar hidden
    .\tools\start.ps1 -Dev  # the bundled engine, hidden, no tray, no app bar, taskbar left alone
    .\tools\stop.ps1        # (-Dev for the bundled engine); the engine restores the taskbar

| Hotkey | What |
|---|---|
| Alt+Shift+Space | The Omarchy menu (also the Omarchy icon in the bar) |
| Alt+Space | The app launcher (Apps list) |
| Ctrl+Alt+T | Theme switcher |
| Ctrl+Alt+B | Background switcher |
| Ctrl+Alt+E | Windows emoji picker (Win+.) |
| Ctrl+Alt+V | Windows clipboard history (Win+V) |

Needs Git for Windows (`C:\Program Files\Git`; the shell runs bash scripts), komorebi (workspaces) and a
Nerd Font (`Cascadia Mono NF` is the default, see `Style.qml`). No Python. The shell uses its own home,
`state\home`, not your user profile.

## What it does

| Part | How it works on Windows |
|---|---|
| Bar | menu, workspaces (komorebi), running apps (one icon per program), clock, weather, tray, bluetooth, network, audio, power |
| Menu | Apps, Appearance (Theme, Background), Trigger (Emoji, Clipboard), Setup (Audio, Bluetooth, Network, Power, Windows Settings), About, System (Lock, Sleep, Sign out, Restart, Shut down) |
| Apps | the Start menu through the engine's `AppsService`: Win32, UWP and shortcuts, with icons |
| Theme switcher | 21 Omarchy themes (`themes\`); `tools\theme-apply.ps1 <name>` rewrites the files the shell watches, so colours change live |
| Background switcher | the images of the current wallpaper's folder (or `OMARCHY_WALLPAPER_DIR`); a choice calls the engine's `Wallpapers.setWallpaper`, the service Caelestia's port uses. It also sets the lock screen picture unless the service is told not to |
| Emoji, clipboard | Windows' own panels, opened by `tools\winkeys.ps1` (clipboard history must be on in Windows settings) |
| Wi-Fi | the engine's `Network` service behind `qs.compat.Networking`: networks, signal, saved-network connect, radio switch. A new network or password opens Windows' Wi-Fi settings; disconnect and forget use `netsh` |
| Audio, Bluetooth, battery | the engine's Pipewire, Bluetooth and UPower modules |

Dropped (they run `omarchy-*`, `hyprctl`, `timedatectl` or other Linux commands): the indicators, world
clock, system-update, keyboard-layout, agents, monitor, Tailscale, Dropbox, Wi-Fi QR, speed-test, the
Linux emoji/clipboard/reminders overlays, night light, remote session, idle, lock screen, polkit prompt
and the Unix-socket IPC. Switched off by default: the background layer (Windows or another shell draws the
wallpaper) and the dock.

## Developing

| Tool | What it does |
|---|---|
| `tools\loadcheck.ps1` | Compiles every QML file; 0 errors expected |
| `tools\run.ps1 -Seconds 12` | Boots the shell, reports status and log problems, then quits. `-Call 'shell call omarchy.menu open {"menu":"apps"}'` runs `wakuc call` lines |
| `tools\menu-state.ps1 -Menu apps -Rows 8` | Opens a menu and prints its state and rows, no screenshot |
| `tools\winshot.ps1` | Saves each shell window as a PNG (transparency is lost; desktop captures can contain private content) |
| `tools\theme-apply.ps1 <name>` | Applies a theme (`-Prepare` only refreshes the picker's previews) |
| `tools\apply-komorebi.ps1` | Applies `komorebi\komorebi.json` (rounded border in the flyout border's colour and thickness, Omarchy's gaps, the current theme's colours) to komorebi, with a backup; run it again after a theme change (see `komorebi\README.md`) |
| `tools\build-menu.py` | Regenerates the Windows menu from the upstream one |
| `tools\apply-batchN.py` | The port's mechanical changes, in order; each is idempotent (batch 10 then 16 for Wi-Fi) |

`Menu.qml` and `ImagePicker.qml` have `debugState` helpers (marked `PORTDBG`) that the tools above call.

## Port notes (the non-obvious ones)

- `"bash"` in a Process command resolves to the WSL launcher in System32 (Windows searches it before
  PATH). Every call uses `C:/Program Files/Git/usr/bin/bash.exe`; so does `find`.
- A multi-line script passed through argv gets mangled; the plugin scan is `services/scan-plugins.sh`.
- Paths handed to Qt need `file:///D:/...` (`Util.fileUrl`).
- The engine's `PopupAnchor` has `item`, `rect`, `edges`, `gravity` only; popups follow `anchor.item`.
- `OverlayWindow` waited for a Hyprland monitor; it now builds one from the screen.
- `IpcHandler` is the engine's own (`import waku as W`); `wakuc call <target> <function>` reaches it.
- `Quickshell.Networking` has only `wifiEnabled`; `qs.compat` supplies the rest.
- `theme.name` holds the theme's folder name (`tokyo-night`); the picker matches rows against it.

## Known gaps

- Not verified on screen: the look of the bar, menu and both switchers; applying a background (only a
  call with the current wallpaper was tried); Win+. / Win+V from the hotkeys; Wi-Fi with a real adapter.
- Wi-Fi: no password entry and no profile creation; the engine joins saved networks only.
- The audio input meter is empty (`PwNodePeakMonitor` is a stub). The weather widget needs `curl` and
  network access (wttr.in).
- The tooltip logs "Binding loop detected for property contentWidth" (engine `PopupWindow`).
- `PopupCard` and the tooltip no longer clamp to the screen edge.
- The theme list has no per-theme wallpapers (those are large and live in Omarchy's repo).
