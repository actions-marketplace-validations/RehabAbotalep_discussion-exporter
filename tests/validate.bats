#!/usr/bin/env bats

load test_helper

@test "valid limit: 1" {
  run run_validate "1"
  [ "$status" -eq 0 ]
}

@test "valid limit: 100" {
  run run_validate "100"
  [ "$status" -eq 0 ]
}

@test "valid limit: 500 (pagination)" {
  run run_validate "500"
  [ "$status" -eq 0 ]
}

@test "reject limit: 0" {
  run run_validate "0"
  [ "$status" -ne 0 ]
  [[ "$output" == *"limit must be a positive integer"* ]]
}

@test "reject limit: -1" {
  run run_validate "-1"
  [ "$status" -ne 0 ]
  [[ "$output" == *"limit must be a positive integer"* ]]
}

@test "reject limit: abc" {
  run run_validate "abc"
  [ "$status" -ne 0 ]
  [[ "$output" == *"limit must be a positive integer"* ]]
}

@test "reject limit: empty string" {
  run run_validate ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"limit must be a positive integer"* ]]
}

@test "reject limit: 1.5" {
  run run_validate "1.5"
  [ "$status" -ne 0 ]
  [[ "$output" == *"limit must be a positive integer"* ]]
}

@test "valid repository: owner/repo" {
  run run_validate "10" "owner/repo"
  [ "$status" -eq 0 ]
}

@test "valid repository: falls back to GITHUB_REPOSITORY" {
  run run_validate "10" "" "fallback/repo"
  [ "$status" -eq 0 ]
}

@test "reject repository: no slash" {
  run run_validate "10" "justaname" "justaname"
  [ "$status" -ne 0 ]
  [[ "$output" == *"owner/name"* ]]
}
