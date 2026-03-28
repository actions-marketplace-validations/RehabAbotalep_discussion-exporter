#!/usr/bin/env bash

# Shared setup/teardown for all Bats test files.

FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"

setup() {
  export RUNNER_TEMP=$(mktemp -d)
  export GITHUB_OUTPUT="${RUNNER_TEMP}/github_output"
  export OUTPUT_DIR="${RUNNER_TEMP}/docs"
  : > "${GITHUB_OUTPUT}"
}

teardown() {
  rm -rf "${RUNNER_TEMP}"
}

# Run the convert step from action.yml against a fixture JSON file.
# Usage: run_convert <fixture.json>
run_convert() {
  local fixture="$1"
  cp "${fixture}" "${RUNNER_TEMP}/discussions.json"

  mkdir -p "${OUTPUT_DIR}"
  local count=0

  jq -j '.[] |
    ((.title | ascii_downcase | gsub("[^a-z0-9]"; "-") | gsub("-+"; "-") | gsub("^-+|-+$"; "")) | if . == "" then "discussion" else . end) as $slug |
    "\(.number)\u0000" +
    "\($slug)\u0000" +
    "\(.title | @json)\u0000" +
    "\(.author.login // "unknown" | @json)\u0000" +
    "\(.category.name // "" | @json)\u0000" +
    "\(.url | @json)\u0000" +
    "\(.createdAt | split("T")[0])\u0000" +
    "\(.updatedAt | split("T")[0])\u0000" +
    "\(.body // "")\u0000"
  ' "${RUNNER_TEMP}/discussions.json" > "${RUNNER_TEMP}/discussions.nul"

  while IFS= read -r -d '' number && \
        IFS= read -r -d '' slug && \
        IFS= read -r -d '' yaml_title && \
        IFS= read -r -d '' yaml_author && \
        IFS= read -r -d '' yaml_category && \
        IFS= read -r -d '' url && \
        IFS= read -r -d '' created && \
        IFS= read -r -d '' updated && \
        IFS= read -r -d '' body; do

    filename="${OUTPUT_DIR}/${number}-${slug}.md"

    {
      printf '%s\n' '---'
      printf 'number: %s\n' "${number}"
      printf 'title: %s\n' "${yaml_title}"
      printf 'author: %s\n' "${yaml_author}"
      printf 'category: %s\n' "${yaml_category}"
      printf 'url: %s\n' "${url}"
      printf 'created: %s\n' "${created}"
      printf 'updated: %s\n' "${updated}"
      printf '%s\n' '---'
      printf '\n'
      printf '%s\n' "${body}"
    } > "${filename}"

    count=$((count + 1))
  done < "${RUNNER_TEMP}/discussions.nul"

  echo "files-written=${count}" >> "${GITHUB_OUTPUT}"
  if (( count == 0 )); then
    echo "::notice::No discussions found. 0 files written."
  else
    echo "Wrote ${count} Markdown files to ${OUTPUT_DIR}."
  fi

  # Export for assertions
  export FILES_WRITTEN="${count}"
}

# Run the validation logic from the fetch step.
# Usage: run_validate <limit> <repository>
run_validate() {
  local INPUT_LIMIT="$1"
  local INPUT_REPOSITORY="${2:-}"
  local GITHUB_REPOSITORY="${3:-owner/repo}"

  if ! [[ "${INPUT_LIMIT}" =~ ^[0-9]+$ ]] || (( INPUT_LIMIT < 1 )); then
    echo "::error::limit must be a positive integer (got '${INPUT_LIMIT}')"
    return 1
  fi

  local REPOSITORY="${INPUT_REPOSITORY:-${GITHUB_REPOSITORY}}"
  if [[ "${REPOSITORY}" != */* ]]; then
    echo "::error::repository must be in 'owner/name' format (got '${REPOSITORY}')"
    return 1
  fi

  return 0
}
