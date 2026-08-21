# Changelog

All notable changes to Delegate to AGY will be documented in this file.

## Unreleased

## 0.1.0 - 2026-08-21

### Added

- Scoped fresh AGY implementation and same-conversation remediation workflows.
- A validated PowerShell wrapper for linked Git worktrees and isolated scratch
  directories, with path allowlists, scope-drift detection, and pinned safe AGY
  flags.
- Successful-run receipts binding task hashes, private conversation routing, and
  allowed output hashes, including receipt-bound remediation baselines.
- Command-scoped Git ownership handling for cross-identity Windows worktrees.
- Direct trusted-user authorization guidance for coordinator-owned workers.
- Independent Codex review, portable EOL, immutable-blob acceptance, bounded
  retry, and terminal-status requirements.

### Security

- The wrapper rejects main worktrees, reparse-point traversal, rooted or escaping
  paths, dirty baselines outside the receipt contract, task-control changes,
  undeclared writes, unsafe timeouts, and unknown task fields.
- AGY remains sandboxed; arbitrary `agy`, PowerShell, and shell execution are not
  granted by the companion Codex rule.
