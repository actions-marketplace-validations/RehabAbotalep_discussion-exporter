#!/usr/bin/env bats

load test_helper

# --- Basic conversion ---

@test "converts 2 discussions to markdown files" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  [ "${FILES_WRITTEN}" -eq 2 ]
}

@test "sets files-written output" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q "files-written=2" "${GITHUB_OUTPUT}"
}

@test "generates correct filenames" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  [ -f "${OUTPUT_DIR}/1-hello-world.md" ]
  [ -f "${OUTPUT_DIR}/2-bug-something-broke.md" ]
}

# --- Frontmatter content ---

@test "frontmatter: number" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q "^number: 1$" "${OUTPUT_DIR}/1-hello-world.md"
}

@test "frontmatter: title is JSON-quoted" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q '^title: "Hello World!"$' "${OUTPUT_DIR}/1-hello-world.md"
}

@test "frontmatter: author is JSON-quoted" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q '^author: "octocat"$' "${OUTPUT_DIR}/1-hello-world.md"
}

@test "frontmatter: category is JSON-quoted" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q '^category: "General"$' "${OUTPUT_DIR}/1-hello-world.md"
}

@test "frontmatter: url is JSON-quoted" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q '^url: "https://github.com/owner/repo/discussions/1"$' "${OUTPUT_DIR}/1-hello-world.md"
}

@test "frontmatter: created date extracted" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q "^created: 2025-06-15$" "${OUTPUT_DIR}/1-hello-world.md"
}

@test "frontmatter: updated date extracted" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q "^updated: 2025-07-01$" "${OUTPUT_DIR}/1-hello-world.md"
}

@test "frontmatter delimiters present" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  local count
  count=$(grep -c "^---$" "${OUTPUT_DIR}/1-hello-world.md")
  [ "${count}" -eq 2 ]
}

# --- Body ---

@test "body content preserved" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q "This is the \*\*first\*\* discussion." "${OUTPUT_DIR}/1-hello-world.md"
}

@test "multiline body preserved" {
  run_convert "${FIXTURES_DIR}/discussions.json"
  grep -q "Steps to reproduce:" "${OUTPUT_DIR}/2-bug-something-broke.md"
}

# --- Empty input ---

@test "empty array writes 0 files" {
  run_convert "${FIXTURES_DIR}/empty.json"
  [ "${FILES_WRITTEN}" -eq 0 ]
}

@test "empty array sets files-written=0" {
  run_convert "${FIXTURES_DIR}/empty.json"
  grep -q "files-written=0" "${GITHUB_OUTPUT}"
}

@test "empty array produces no md files" {
  run_convert "${FIXTURES_DIR}/empty.json"
  local count
  count=$(find "${OUTPUT_DIR}" -name '*.md' | wc -l)
  [ "${count}" -eq 0 ]
}

# --- Edge cases ---

@test "non-ASCII title falls back to 'discussion' slug" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  [ -f "${OUTPUT_DIR}/10-discussion.md" ]
}

@test "null author falls back to 'unknown'" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  grep -q '^author: "unknown"$' "${OUTPUT_DIR}/10-discussion.md"
}

@test "null body writes empty body" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  # After the closing --- and blank line, body should be empty string
  ! grep -q "null" "${OUTPUT_DIR}/11-title-with-colons-and-quotes.md"
}

@test "title with colons and quotes is safely quoted" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  grep -q '^title: "Title with: colons and \\"quotes\\""$' "${OUTPUT_DIR}/11-title-with-colons-and-quotes.md"
}

@test "author with newline: injection blocked" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  # The injected field should not appear as a separate YAML key
  ! grep -q "^injected:" "${OUTPUT_DIR}/12-injection-attempt.md"
}

@test "category with newline: injection blocked" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  ! grep -q "^field:" "${OUTPUT_DIR}/12-injection-attempt.md"
}

@test "null category falls back to empty string" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  grep -q '^category: ""$' "${OUTPUT_DIR}/13-discussion.md"
}

@test "title of only dashes produces 'discussion' slug" {
  run_convert "${FIXTURES_DIR}/edge_cases.json"
  [ -f "${OUTPUT_DIR}/13-discussion.md" ]
}
