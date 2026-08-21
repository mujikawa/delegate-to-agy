# Delegate to AGY v0.1.0

The first tagged release provides a bounded bridge from Codex to Google
Antigravity CLI (`agy`) while keeping Codex responsible for scope, independent
review, verification, and delivery acceptance.

## Highlights

- Fresh implementation and same-conversation remediation through a validated
  PowerShell wrapper.
- Clean linked-worktree or isolated scratch-workspace enforcement.
- Read/write/out-of-scope allowlists and post-run scope-drift detection.
- Successful-run receipts binding the task, conversation routing, and actual
  allowed outputs.
- Receipt-bound dirty-baseline admission for valid remediation only.
- Command-scoped Windows Git ownership handling without global configuration.
- Explicit trusted-user authorization requirements for the worker that launches
  an external executor.
- Independent terminal-status, diff, test, EOL, and immutable-blob verification.

## Installation

Ask Codex:

```text
Use $skill-installer to install mujikawa/delegate-to-agy at ref v0.1.0.
```

Restart or reload Codex after installation. AGY must already be installed and
authenticated interactively. For unattended execution, preview the narrow rule
with `scripts/install-rule.ps1` before applying it, then restart Codex again.

## Safety boundary

This release does not authorize commits, pushes, merges, deployments, dependency
installation, destructive cleanup, arbitrary shell execution, or secret access.
AGY terminal `SUCCESS` and a valid receipt are execution evidence; Codex must
still inspect actual changes and run the required acceptance checks.
