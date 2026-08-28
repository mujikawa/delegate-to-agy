# Delegate to AGY v0.1.2

This release adds cost-aware remediation budgets, early capability handoff to
Codex, and durable per-invocation AGY usage accounting.

## Highlights

- The default remains two remediation passes when no budget is declared, while an
  explicit economics-based hard cap such as 10 is honored as a ceiling rather than
  a target.
- Every loop requires a new concrete finding, diff improvement, or changed
  verification evidence. Repeated no-progress, deterministic failure, scope or
  authority drift, and unsupported operations stop early.
- AGY can hand off partial work to Codex before the cap. The handoff preserves the
  baseline, actual diff, completed criteria, remaining gap, unavailable operation,
  validation, receipt, and next action without widening authorization.
- Safe receipts retain an `attempts` history containing conversation-cumulative
  usage and per-invocation token, turn, and duration deltas.
- Failed remediation telemetry is appended without replacing a prior successful
  task/output binding. Cache hits and rejections before AGY starts create no usage
  attempt.
- Runtime artifacts and successful receipt retention now have explicit lifecycle
  ownership through immutable candidate acceptance.

## Installation

Ask Codex:

```text
Use $skill-installer to install mujikawa/delegate-to-agy at ref v0.1.2.
```

Restart or reload Codex after installation. AGY must already be installed and
authenticated. For unattended execution, keep the narrow installed-wrapper rule;
do not approve arbitrary `agy`, PowerShell, or shell prefixes.

## Safety boundary

This release keeps AGY sandboxed and does not authorize commits, pushes, merges,
deployments, dependency installation, destructive cleanup, arbitrary shell
execution, secret access, or scope expansion. Usage recording does not convert a
failed AGY invocation into success. Codex remains responsible for independent diff
review, validation, and delivery acceptance.
