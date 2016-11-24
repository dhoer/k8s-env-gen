#!/usr/bin/env bats

@test "invoking keg without arguments prints usage" {
  run ../../keg
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: keg [-s] name file [file ...]" ]
}