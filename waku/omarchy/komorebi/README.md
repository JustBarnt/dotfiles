# komorebi for the omarchy port

`komorebi.json` is the komorebi configuration this port is tuned for. Windows 11 rounds its windows, so
the border is rounded too (`border_style` "Rounded"): a square border around a rounded window looks wrong.

The focused window's border is drawn like the border of the shell's flyouts: the theme's `accent`
colour (the flyouts use the active-border colour, which is the accent) and the same thickness, 2 logical
px, which is 4 physical px on a 200% screen. Windows 11 draws its own 2 px outline inside every window
and that outline is see-through, so a 4 px border that stops at the window edge leaves a 2 px strip of
wallpaper between it and the window. So `border_width` is 6 and `border_offset` -2: 4 px show in the
accent and the last 2 px tuck under the outline. The other windows get the theme's `muted`, a floating
window `yellow` and a locked unfocused one `orange`.

Gaps are 9 px of workspace padding and 8 px of container padding, so windows sit about 17 px from the
screen edges (9 + 8) and 16 px from each other. That is about
Omarchy's 10 px between windows and 10 px at the edges (Hyprland `gaps_in` 5, `gaps_out` 10) on a
150% to 200% screen: komorebi counts physical pixels, so scale `default_workspace_padding` and
`default_container_padding` to your own screen if the gaps look off. Seven workspaces, all BSP
(Hyprland's dwindle), named 1 to 7 to match the bar.

The shipped colours are Catppuccin's. Apply it with `tools\apply-komorebi.ps1`: it backs up your current
`komorebi.json`, writes this one with the border colours of the theme the shell is on now (from
`state\home\.local\state\omarchy\current\theme`) and sends the border, gap and workspace-name settings to the running komorebi (`komorebic reload-configuration` does not read `komorebi.json`; komorebi reads it when it starts). Run it again after you
switch theme to move the borders along. `-WhatIf` shows what it would do; `-KeepColours` copies the file
as it is.

It keeps `app_specific_configuration_path` pointing at `applications.json` in
`$Env:KOMOREBI_CONFIG_HOME`, so your own application rules still apply.
