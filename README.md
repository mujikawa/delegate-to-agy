# delegate-to-agy

A Codex skill that delegates scoped implementation work to Google Antigravity CLI (`agy`), then requires Codex to independently review the changes and run verification.

## What it provides

- Fresh AGY implementation conversations with JSON terminal-status checks.
- Exact read/write path boundaries and workspace scope-drift detection.
- Safe unattended execution through a single validated PowerShell wrapper.
- Linked Git worktree enforcement for repository tasks.
- Successful-task receipts that prevent duplicate AGY runs.
- Codex review and bounded remediation guidance.

## Requirements

- Windows with PowerShell 7.
- Codex CLI and Git available on `PATH`.
- Google Antigravity CLI (`agy`) installed and authenticated interactively once.

## Install

Copy this repository to `<CODEX_HOME>/skills/delegate-to-agy` (normally `~/.codex/skills/delegate-to-agy`). Restart Codex so it discovers the skill.

For unattended AGY execution, preview and then explicitly install the narrow Codex rule:

```powershell
./scripts/install-rule.ps1
./scripts/install-rule.ps1 -Apply
```

Restart Codex after installing the rule. The rule allows only the installed `invoke-agy.ps1` path; it does not allow general `agy`, `pwsh`, or shell execution.

Read [references/automation.md](references/automation.md) for the task schema and linked-worktree requirements.

## Security model

The Codex sandbox is bypassed only for the installed wrapper. AGY's own `--sandbox` remains enabled. The wrapper rejects main worktrees, path escapes, reparse-point traversal, dirty baselines, unknown task fields, scope overlaps, task-control changes, and changes outside the declared write paths.

Commit, push, merge, deployment, dependency installation, and destructive cleanup remain outside the wrapper and require separate authorization.

## License

No open-source license has been selected yet. Choose one before public release if reuse is intended.
