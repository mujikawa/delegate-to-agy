# Delegate to AGY v0.1.4

This release improves authorization visibility and executor-handoff accounting
without weakening the wrapper's linked-worktree, allowlist, sandbox, receipt, or
single-writer boundaries.

## Highlights

- Private-source delegation records the trusted user authorization, repository,
  allowed read and write scope, exclusions, and inherited-context slice.
- The invoking worker verifies that its trusted context actually contains that
  authorization; a numeric turn count or coordinator relay alone is insufficient.
- A host rejection before process creation records zero AGY invocations and can
  route the already-authorized work to Codex without consuming an AGY loop.
- Capability handoffs identify runtime, runtime-only finding, unsupported
  operation, disclosure, or new-authority reasons.
- Final reporting keeps pre-process decisions, validation-only runs, cache hits,
  real invocations, remediation loops, and Codex handoffs distinct.

## Install

```text
Use $skill-installer to install mujikawa/delegate-to-agy at ref v0.1.4.
```

## Compatibility

No task schema or wrapper command changes are introduced. Existing v0.1.3 task
files and receipts remain valid. The update changes coordination and reporting
requirements only.
