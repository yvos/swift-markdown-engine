# SwiftMarkdownEngine NoFray fork

Read `FORK_CHANGES.md` before integration, an upstream update or a release.
`origin/main` is the single maintained fork branch. `upstream/main` tracks the
original project; `nofray/integration` is historical and no longer a release line.

Preserve existing work. Inspect status and worktrees before editing or publishing.
Use a separate `codex/...` worktree for overlapping work, coordinate with its
owner, and stage only reviewed paths/hunks, including intended new files.
Keep ordinary merge ancestry for upstream imports. Never rebase published main,
move a release tag, force-sync the fork, or discard local work to resolve a merge.

Keep engine extensions generic. Meeting/task/decision semantics belong to NoFray;
source ranges, native editor operations and opaque history context belong here.
Maintain the behavior/test ledger and exact upstream baseline in `FORK_CHANGES.md`.
If upstream implements an extension, reconcile it in a new commit and keep its
regression tests instead of rewriting published history.

Use `swift test` for package validation; report executed test counts and failures.
The products are `MarkdownEngine`, `MarkdownEngineCodeBlocks` and
`MarkdownEngineLatex`; the core engine remains free of external dependencies.
When a change affects a consumer contract, also verify the affected NoFray
adapter/history tests through the exact remote release pin, without an override.
NoFray work follows that repository's `AGENTS.md` and build wrapper.

Within existing user authorization, integrate verified work, publish a unique
immutable fork release and update the exact consumer pin/provenance together.
Verify local, tracking and live remote parity. Remove only worktrees owned by the
current task, after preserving their changes and checking for remaining work.
