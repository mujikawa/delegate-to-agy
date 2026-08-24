# Unattended automation

Use automation only in a clean linked Git worktree or an isolated non-Git scratch directory named `agy-scratch-*`. Keep commit, push, merge, deployment, and destructive cleanup outside this wrapper.

Create `<workspace>/.agy/task.json` with this schema:

```json
{
  "schema_version": 1,
  "workspace_mode": "linked-worktree",
  "kind": "implement",
  "objective": "Implement the scoped change.",
  "acceptance_criteria": ["The focused tests pass."],
  "read_paths": ["AGENTS.md", "src", "test"],
  "write_paths": ["src/feature.js", "test/feature.test.js"],
  "out_of_scope": [".env", "secrets"],
  "timeout_seconds": 300,
  "conversation_id": null
}
```

All paths must be relative to the workspace. The wrapper rejects unknown fields, rooted paths, `..` escapes, `.agy` write targets, write/out-of-scope overlaps, missing read paths, missing write parents, main Git worktrees, dirty or populated ignored paths in linked worktrees (except the task file), allowlist paths that traverse reparse points, reparse points anywhere in scratch workspaces, and timeouts outside 30–900 seconds. It also fails if AGY modifies the task file or changes paths outside `write_paths`.

Use `kind: "implement"` with a null conversation ID for the first run. Use `kind: "remediate"` with the successful implementation conversation UUID only when sending Codex review findings back to AGY.

After a successful run, the wrapper writes `<task-name>.result.json` beside the task file. The receipt binds the task SHA-256, successful conversation ID, and hashes of all allowed outputs. Re-running an unchanged task with unchanged outputs returns a cached `SUCCESS` without contacting AGY. Changing the task or any allowed output invalidates the receipt and causes a real run.

After a failed run without prior successful remediation evidence, the same receipt
path contains `status: "NEEDS_FOLLOWUP"`, a failure `category`, `retryable`, the
task hash, terminal status, process exit code, and allowed-output state. It omits
the raw conversation ID and error text. A failed receipt is diagnostic evidence,
never a cache hit or authorization for a dirty baseline, and a later successful
fresh run may replace it.

Failure categories have fixed retry semantics:

- `transient_unavailable`: retryable once only when the workspace is unchanged;
- `permission_denied`, `canceled`, `timeout`, `invalid_terminal_output`,
  `process_error`, `terminal_error`, and `scope_drift`: do not retry the same
  task automatically.

The wrapper tells AGY not to invoke shell, Git, package-manager, test, or network
commands. Codex supplies explicit read paths, runs validation independently, and
must not convert a permission denial into unrestricted execution.

For `remediate`, the prior successful receipt may authorize existing changes only
inside `write_paths` when its conversation ID matches the remediation task and its
recorded output hashes still match the workspace. This is not a cache hit: the
wrapper contacts the same AGY conversation and replaces the receipt only after a
successful remediation. A stale receipt, conversation mismatch, output mismatch,
or dirty path outside `write_paths` still fails baseline validation.

Run the installed wrapper directly, resolving the Codex home directory on the current machine:

```powershell
$codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
& (Join-Path $codexRoot 'skills\delegate-to-agy\scripts\invoke-agy.ps1') -TaskFile C:\absolute\workspace\.agy\task.json
```

Use `-ValidateOnly` while preparing or testing a task. It validates the task and prints the resolved scope without contacting AGY.

## Worker authorization visibility

When a coordinator-owned Codex subagent invokes the wrapper, the host approval
reviewer may require the user's external-delegation authorization to be directly
visible in that worker's trusted input. A coordinator message can carry scope but
may not satisfy that trust check. Create the worker after authorization or use a
supported context-inheritance mechanism. If a pre-process approval rejects a
worker created before authorization, do not keep retrying the same relay or move
execution into the coordinator. Create a replacement only after the user
explicitly authorizes the replacement topology and its directly inherited AGY
scope. A rejection before process creation is not an AGY invocation.

Receipts bind the task and actual allowed outputs. They do not prove that an
output satisfies a semantic or cross-platform byte contract. For portable exact
text, define repository-owned EOL policy (for example `.gitattributes`) and verify
the immutable committed blob; use raw worktree bytes only when host-specific
materialization is intentionally part of acceptance.

The companion Codex rule allows only the installed wrapper executable path. Preview it with `scripts/install-rule.ps1`; install it only with `scripts/install-rule.ps1 -Apply`. Because subsequent arguments are allowed by a prefix rule, the wrapper must remain outside AGY's writable workspace and must continue rejecting unknown parameters and unsafe task content. After installing or changing a rule, restart Codex and verify it with `codex execpolicy check`.
