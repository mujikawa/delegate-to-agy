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

Run the installed wrapper directly, resolving the Codex home directory on the current machine:

```powershell
$codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
& (Join-Path $codexRoot 'skills\delegate-to-agy\scripts\invoke-agy.ps1') -TaskFile C:\absolute\workspace\.agy\task.json
```

Use `-ValidateOnly` while preparing or testing a task. It validates the task and prints the resolved scope without contacting AGY.

The companion Codex rule allows only the installed wrapper executable path. Preview it with `scripts/install-rule.ps1`; install it only with `scripts/install-rule.ps1 -Apply`. Because subsequent arguments are allowed by a prefix rule, the wrapper must remain outside AGY's writable workspace and must continue rejecting unknown parameters and unsafe task content. After installing or changing a rule, restart Codex and verify it with `codex execpolicy check`.
