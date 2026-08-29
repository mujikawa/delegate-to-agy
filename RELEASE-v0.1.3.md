# Delegate to AGY v0.1.3

This release adds task-contract preflight, objective-specific semantic probes,
and remediation-before-runtime sequencing for unattended AGY work.

## Highlights

- The wrapper is now used with `-ValidateOnly` before the first real invocation.
- Initial `write_paths` must contain every final destination required by the
  objective because a successful receipt cannot authorize later path expansion.
- Codex runs a cheap objective-specific probe immediately after `SUCCESS`, before
  expensive validation. When the baseline did not already satisfy the Definition
  of Done, an unexplained no-op, missing output tree, wrong structural metric, or
  failed value-equivalence check is a remediation finding.
- When dependencies permit, AGY implementation and likely remediation complete
  before large ignored dependency, build, or test trees are materialized.
- If early runtime materialization is unavoidable and later wrapper remediation
  becomes ineligible, Codex uses the declared bounded capability handoff rather
  than deleting or rebuilding the environment.
- Sandbox or host-approval rejection before process creation, validation-only
  rejection, and receipt cache hits remain outside the AGY loop and usage count.

## Installation

Ask Codex:

```text
Use $skill-installer to install mujikawa/delegate-to-agy at ref v0.1.3.
```

Restart or reload Codex after installation. AGY must already be installed and
authenticated. Keep the narrow installed-wrapper rule; do not approve arbitrary
`agy`, PowerShell, or shell prefixes.

## Safety boundary

This release does not weaken the linked-worktree, clean-baseline, path allowlist,
5,000 ignored-file, reparse-point, terminal-status, or scope-drift protections. It
does not authorize commits, pushes, merges, deployments, dependency installation,
destructive cleanup, secret access, or scope expansion. Codex remains responsible
for independent review, validation, and delivery acceptance.
