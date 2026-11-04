#!/bin/bash
# Windows port: the plugin scan of PluginRegistry.rescan(), as a file. A multi-line script passed
# through argv gets mangled on Windows. $1 = first-party dir, $2 = third-party dir.
emit_manifest() {
local kind="$1"
local manifest="$2"
local sub
  if [[ ${manifest##*/} == "manifest.json" ]]
then sub="${manifest%/manifest.json}"
else sub="${manifest%/*}"
fi
  printf '===%s::%s===\n' "$kind" "$sub"
  printf '%s\n' "$(<"$manifest")"
  printf '\n=== EOM ===\n'
}
scan_firstparty() {
local dir="$1"
  [[ -d "$dir" ]] || return 0
  while IFS= read -r manifest
do emit_manifest firstparty "$manifest"
done < <(find "$dir" -mindepth 2 -maxdepth 3 -type f \( -name manifest.json -o -name '*.manifest.json' \) | sort)
}
scan_thirdparty() {
local dir="$1"
  [[ -d "$dir" ]] || return 0
  for sub in "$dir"/*/
do     [[ -f "$sub/manifest.json" ]] || continue
    emit_manifest thirdparty "$sub/manifest.json"
  done
}
scan_firstparty "$1"
scan_thirdparty "$2"
