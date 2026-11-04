"""Batch 5: the shell runs bash scripts (plugin scan uses bash and find). Put Git for Windows' usr\\bin
first on PATH in the test scripts so `bash` is Git's, not the WSL launcher in System32. Idempotent.
"""
OLD = "$env:PATH += ';C:\\Program Files\\komorebi\\bin'"
NEW = ("$env:PATH = 'C:\\Program Files\\Git\\usr\\bin;' + $env:PATH + ';C:\\Program Files\\komorebi\\bin'"
       " # Git's bash and find first: the shell runs bash scripts")

for p in ("tools/run.ps1", "tools/winshot.ps1", "tools/loadcheck.ps1"):
    with open(p, encoding="utf8", newline="") as h:
        t = h.read()
    if OLD in t:
        with open(p, "w", encoding="utf8", newline="") as h:
            h.write(t.replace(OLD, NEW))
        print("patched", p)
    else:
        print("no match", p)
