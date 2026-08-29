# Changelog

All notable changes to Delegate to AGY will be documented in this file.

## 0.1.4 - 2026-08-30

### Added

- A private-source disclosure authorization packet that records the trusted user
  turn, canonical repository, permitted path classes, write paths, exclusions,
  and inherited-context selection.
- Evidence-backed capability-handoff categories for runtime, unsupported-operation,
  disclosure, and new-authority boundaries.

### Changed

- A fixed inherited-turn count no longer serves as proof that an invoking worker
  can show trusted external-delegation authorization.
- Pre-process approval decisions, validation-only runs, cache hits, real AGY
  invocations, remediation loops, and Codex handoffs are reported separately.
- A disclosure rejection before process creation is recorded as zero AGY
  invocations rather than executor failure or a consumed loop.

## 0.1.3 - 2026-08-29

### Changed

- Unattended runs now validate the task before invocation and require initial
  write paths to cover the final output shape.
- Independent review now runs an objective-specific no-op, structural, or
  value-equivalence probe before expensive validation.
- Recommended sequencing completes likely AGY remediation before large ignored
  runtime trees, while preserving capability handoff when early materialization
  is unavoidable.

## 0.1.2 - 2026-08-29

### Changed

- Remediation guidance now separates the default two-pass budget from an explicitly
  selected economics-based hard cap, including higher caps such as 10.
- Every loop now requires new convergence evidence and stops early for repeated
  no-progress, deterministic failure, scope or authority drift, or an unsupported
  operation.
- AGY can hand off partial, reviewed work to Codex before the cap is exhausted;
  the handoff preserves baseline, diff, receipt, validation, and the remaining gap.
- Successful receipts remain available through immutable candidate acceptance,
  and unattended guidance now declares runtime-artifact ownership and cleanup.

### Added

- Safe receipt attempt history with AGY conversation-cumulative token usage,
  per-invocation token, turn, and duration deltas, terminal status, and failure
  category. Cache hits and pre-process rejections do not create usage attempts.

## 0.1.1 - 2026-08-24

### Added

- Structured failure receipts with deterministic categories and retryability.
- Fake-AGY wrapper regression tests for permission denial, transient service
  failure, cancellation, timeout, invalid output, success receipts, and pinned
  safe flags.

### Changed

- Fresh retry is now limited to an unchanged `transient_unavailable` outcome;
  permission denial, cancellation, timeout, invalid output, process failure, and
  scope drift stop without consuming a retry.
- Unattended AGY prompts prohibit shell, Git, package-manager, test, and network
  commands; Codex remains responsible for validation.

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
