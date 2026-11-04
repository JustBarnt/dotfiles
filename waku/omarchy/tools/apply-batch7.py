"""Batch 7: tools\\run.ps1 gets -Call: one or more `wakuc call <target> <function> [args]` strings, run in
order (2 s apart) after the shell has started, before the screenshot. Idempotent.
"""
p = "tools/run.ps1"
with open(p, encoding="utf8", newline="") as h:
    t = h.read()
if "[string[]]$Call" not in t:
    t = t.replace("  [string[]]$Shortcut,", "  [string[]]$Call, # `wakuc call` lines, e.g. 'shell summon omarchy.menu {}'\n  [string[]]$Shortcut,", 1)
    marker = "  foreach ($sc in ($Shortcut -split \",\")) {"
    block = (
        "  foreach ($c in $Call) {\n"
        "    Write-Host \"== call $c\"\n"
        "    & $wakuc --config-home $ConfigHome call @($c -split ' ')\n"
        "    Start-Sleep -Seconds 2\n"
        "  }\n"
    )
    assert marker in t
    t = t.replace(marker, block + marker, 1)
    with open(p, "w", encoding="utf8", newline="") as h:
        h.write(t)
print("batch7 ok")
