# Discussion Exporter

A GitHub Action that fetches your repository's Discussions via the GraphQL API and exports each one as a Markdown file with YAML frontmatter.

## Usage

```yaml
- uses: RehabAbotalep/discussion-exporter@v1
  with:
    token: ${{ secrets.GH_PAT }}
```

## Inputs

| Input | Description | Required | Default |
|---|---|---|---|
| `token` | GitHub token with `read:discussion` permission. A fine-grained PAT is recommended. | Yes | — |
| `output-dir` | Directory to write Markdown files into. | No | `docs` |
| `limit` | Maximum number of discussions to fetch. Pagination is used automatically when the value exceeds 100. | No | `100` |
| `repository` | Target repository in `owner/name` format. | No | Current repository |

## Outputs

| Output | Description |
|---|---|
| `files-written` | Number of Markdown files written. |

## Example workflow

```yaml
name: Discussion Exporter

on:
  workflow_dispatch:

permissions:
  contents: write

jobs:
  export-discussions:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Export discussions
        uses: RehabAbotalep/discussion-exporter@v1
        with:
          token: ${{ secrets.GH_PAT }}
          output-dir: docs
          limit: 100

      - name: Commit and push exported files
        run: |
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git add docs/
          git diff --cached --quiet || git commit -m "Export discussions to Markdown"
          git push
```

## Output file format

Each discussion is saved as `{output-dir}/{number}-{slug}.md` with YAML frontmatter:

```markdown
---
number: 42
title: "My Discussion Title"
author: octocat
category: Q&A
url: https://github.com/owner/repo/discussions/42
created: 2025-01-15
updated: 2025-03-01
---

Discussion body content here...
```

## Prerequisites

- The `token` must have `read:discussion` permission on the target repository. The default `GITHUB_TOKEN` does not include this — a [fine-grained PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token) is recommended.
- The workflow must have `contents: write` permission to commit and push exported files.
- `gh` CLI and `jq` must be available on the runner. Both are pre-installed on `ubuntu-latest`.