#!/usr/bin/env nu

use std assert

const temp_file = 'test/temp.nu'
let files = glob test/input_*.nu

$env.TOPIARY_CONFIG_FILE = (pwd | path join languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = (pwd | path join languages)

for f in $files {
  print $"(ansi green)Testing: (ansi yellow)($f)(ansi reset)"
  cp $f $temp_file
  topiary format $temp_file
  let expected_file = $f | str replace --regex '/input_' '/expected_'
  try {
    assert ((open $temp_file) == (open $expected_file))
  } catch {
    delta $temp_file $expected_file
  }
  rm $temp_file
}
