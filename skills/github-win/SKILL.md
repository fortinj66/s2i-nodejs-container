---
name: "github-win"
description: "GitHub CLI for Windows - issues, PRs, CI logs, comments, reviews, releases, repos, gh api"
metadata:
  {
    "openclaw":
      {
        "emoji": "🐙",
        "requires": { "bins": ["gh"] },
        "install":
          [
            {
              "id": "winget",
              "kind": "winget",
              "package": "GitHub.cli",
              "bins": ["gh"],
              "label": "Install GitHub CLI (winget)",
            },
            {
              "id": "choco",
              "kind": "exec",
              "command": "choco install gh --yes",
              "bins": ["gh"],
              "label": "Install GitHub CLI (Chocolatey)",
            },
          ],
        "env":
          {
            "PATH_APPEND": "C:\\Program Files\\GitHub CLI\\",
          },
      },
  }
---

# GitHub (Windows)

Use `gh` for GitHub operations on Windows. Use `git` for local commits/branches/push/pull. Use code-reading tools for deep reviews.

## Path

GitHub CLI is installed at: `C:\Program Files\GitHub CLI\gh.exe`

The gateway service includes this path in its environment.

## Auth

```bash
gh auth status
gh auth login
```

If `gh` auth exists in a different location, set `GH_CONFIG_DIR` in the gateway service env and restart.

## PRs

```bash
gh pr list --repo owner/repo --json number,title,state,author,url
gh pr view 55 --repo owner/repo --json title,body,author,files,commits,reviews,reviewDecision
gh pr checks 55 --repo owner/repo
gh pr diff 55 --repo owner/repo
gh pr create --repo owner/repo --title "feat: title" --body-file C:\temp\pr.md
gh pr merge 55 --repo owner/repo --squash
```

URLs work directly: `gh pr view https://github.com/owner/repo/pull/55`.

## Issues

```bash
gh issue list --repo owner/repo --state open --json number,title,labels,url
gh issue view 42 --repo owner/repo --json title,body,comments,labels,state
gh issue create --repo owner/repo --title "Bug: ..." --body-file C:\temp\issue.md
gh issue comment 42 --repo owner/repo --body-file C:\temp\comment.md
gh issue close 42 --repo owner/repo --comment "Fixed in ..."
```

## CI/runs

```bash
gh run list --repo owner/repo --limit 10
gh run view <run-id> --repo owner/repo --json status,conclusion,headSha,url
gh run view <run-id> --repo owner/repo --log-failed
gh run rerun <run-id> --repo owner/repo --failed
```

## API

```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
gh api repos/owner/repo/labels --jq '.[].name'
gh api --cache 1h repos/owner/repo --jq '{stars: .stargazers_count, forks: .forks_count}'
```

Use `--json` + `--jq` for structured output. Use `--body-file` for comments/bodies containing backticks, shell snippets, or user text.

## Windows Notes

- Use `C:\temp\` or `$env:TEMP\` for temporary files instead of `/tmp/`
- PowerShell: use `& gh` when calling from scripts
- PATH includes `C:\Program Files\GitHub CLI\` in gateway service
