# NoFray fork maintenance and changes

This is the maintained NoFray fork of
[`nodes-app/swift-markdown-engine`](https://github.com/nodes-app/swift-markdown-engine).
The integrated upstream baseline is `00b5e471277ac90c70cf82a31b425dd29ea96663`:
upstream `0.13.0` (`d1421012aeece640e2c2e47e0e573a93cbe2a420`) plus its subsequent
fixes through that baseline. NoFray releases do not depend on upstream accepting
our pull requests.

## Branch and release policy

- `origin/main` is the single integration and release branch for upstream code
  plus the tested NoFray extensions. It is **not** an upstream mirror.
- The `upstream` remote points to the original repository; `upstream/main` is the
  upstream reference. Do not add a second maintained mirror branch.
- Use short-lived `codex/...` branches and pull requests targeting this fork's
  `main`. Keep the source history of upstream imports with ordinary merges;
  do not squash those imports or rebase published `main`.
- `nofray/integration` is retired from integration and release work. Its existing
  reference is historical; no future release should start from it.
- Releases use unique immutable tags such as `0.13.0-nofray.2`. Never move an
  existing tag or force-push a published integration branch. Record the exact
  upstream SHA here even when it is newer than the named upstream release.
- NoFray uses an exact remote SwiftPM version. A release update includes its
  resolved revision and license/provenance metadata, followed by verification
  through the normal remote dependency route.
- Generic source editing, selection, annotation rendering and opaque undo
  context belong in this engine. Task, decision and meeting semantics belong
  in the host application.

## Updating upstream

Use a separate clean worktree so existing development is unaffected. Choose an
unused branch and worktree name for each update. From the repository:

```sh
git fetch origin
git fetch upstream --tags
git worktree add -b codex/upstream-update ../SwiftMarkdownEngine-upstream-update origin/main
cd ../SwiftMarkdownEngine-upstream-update
git merge --no-ff upstream/main
swift test
git push -u origin codex/upstream-update
gh pr create --repo yvos/swift-markdown-engine --base main --head codex/upstream-update
```

For a selected upstream release, merge its verified tag or commit instead of
`upstream/main`. Review conflicts and behavior before publication. Keep a regular
merge commit when merging an upstream-update PR; do not use squash/rebase merge.
Never use `gh repo sync --force`, `reset --hard` or an automatic conflict strategy
to make the fork match upstream.

Before merging, check this ledger, update the baseline SHA and run `swift test`.
When editor APIs or behavior change, also run the affected NoFray adapter and
editor-history tests. CI runs package build/tests on this fork's PRs and `main`.
A clean textual merge alone does not establish behavioral compatibility.

After merging, create a new unique release tag on the verified `main` commit,
update NoFray's exact pin and provenance together, and verify package resolution
and affected tests without a local package override. Check local, tracking and
live remote commit parity. Remove only the update worktree owned by that task,
after confirming its changes are retained and its working tree is clean.

## Maintained extensions

| Behavior | Regression coverage | Upstream status |
| --- | --- | --- |
| Optional two-way focus binding | `FocusBindingTests` | [PR #175](https://github.com/nodes-app/swift-markdown-engine/pull/175), open as of 2026-09-25 |
| Host fallback for declined Escape, Tab and Shift-Tab | `UnhandledCommandTests` | [PR #176](https://github.com/nodes-app/swift-markdown-engine/pull/176), open as of 2026-09-25 |
| Paragraph and task-list formatting | `BlockFormattingActionTests` | [PR #177](https://github.com/nodes-app/swift-markdown-engine/pull/177), open as of 2026-09-25 |
| Opt-in task-checkbox toggles in read-only editors | `ReadOnlyTaskCheckboxTests` | [PR #178](https://github.com/nodes-app/swift-markdown-engine/pull/178), open as of 2026-09-25 |
| Native pointer classification and exact source hit ranges | `PointerInteractionTests`, `MarkdownSourceRangeTests` | Maintained fork extension |
| Host-decided link activation (`MarkdownLinkActivation`, `onLinkActivation`) | `MarkdownASTStylerTests`, `LinkActivationTests` | Upstream candidate |
| Source transactions and opaque shared undo context | `MarkdownDocumentTransactionTests`, `PreparedTextMutationTests` | Maintained fork extension |
| Caret visibility during keyboard navigation in internally scrolling editors | `CaretVisibilityTests` | Maintained fork fix |

Keep upstream submissions narrowly scoped on separate topic branches based on
upstream. Existing PRs may stay open independently of fork releases. When
upstream supplies equivalent behavior, reconcile the implementation in a new
commit and retain the relevant regression tests; do not rewrite release history.

## Release provenance

- `0.13.0-nofray.3` ([PR #6](https://github.com/yvos/swift-markdown-engine/pull/6),
  [GitHub pre-release](https://github.com/yvos/swift-markdown-engine/releases/tag/0.13.0-nofray.3)):
  host-decided link activation and removal of unused hidden HTML-comment
  styling. Merge commit `c7a18eb4252ade3cbd1d33047eac872e0445c0f4`; annotated
  tag `0.13.0-nofray.3` (`da818d7`) dereferences to that commit. Upstream
  baseline: `00b5e471277ac90c70cf82a31b425dd29ea96663`.
- `0.13.0-nofray.2`: document-review engine APIs, source mapping, native undo and
  pre-edit hooks, plus caret visibility. Upstream baseline remains `00b5e471`.
  The engine accepts only document/source revisions, exact source replacements
  and opaque host state; NoFray owns application semantics.
- `0.13.0-nofray.1`: `b426d419c1a2c635f36d250091366517d9ca5321`, integrating
  upstream through `00b5e471277ac90c70cf82a31b425dd29ea96663` and the prior fork.
- `0.12.1-nofray.2`: `acaed5efd8dc124fd019f9270d2610af6d99e79d`, adding native
  pointer interaction callbacks.
- `0.12.1-nofray.1`: `605073321ca299cd5c2c941f8554aff06b667eda`, initial fork
  release. Its original baseline was `08ff3c07b198ed639f595d0279ebac62c0410bc7`,
  after upstream `0.12.0` (`e5f7607fc4021181056ef7a09dbb7573dc0237d9`).

The original topic-to-integration mapping remains available for upstream review:

| Change | Topic commit(s) | Original integration commit(s) |
| --- | --- | --- |
| Focus binding | `d5a0541` | `b19a6eb` |
| Unhandled commands | `bc5e27a`, `b0ddb9f` | `f564a90`, `a017c5a` |
| Block formatting | `8285c11` | `eae29d8` |
| Read-only checkbox | `098dc62`, `c66fb23` | `fc0a97c`, `f9f5bdc` |

## Preserved development snapshots

The original pre-0.13 review work is preserved at `f9e9c2c` on
`codex/meeting-review-annotations`. It is a recovery snapshot, not a release or
an additional integration line. The repaired review implementation is committed
at `ca8a412` on `codex/meeting-review-013-repair`; the independent caret fix is
`55b0965`. Both reviewed changes are merged into the maintained fork. On
2026-09-27, three historical worktree checkouts were removed before explicit
approval; the user later confirmed no changes were lost. After verifying each
tip as an ancestor of `main` at `c7a18eb`, the user authorized and the operator
removed their local and remote branches: `codex/host-interaction-callback`
(`d918309`, PR #2), `codex/meeting-review-013-repair` (`ca8a412`) and
`codex/upstream-0.13-integration` (`7b503d8`, PR #4). The clean PR #6 worktree
at `e49d947` was archived after its commits were verified in `main`; its local
and remote branch `codex/relative-markdown-links` was then removed. The separate
recovery snapshot `codex/meeting-review-annotations` (`f9e9c2c`) is not merged
and remains preserved. All `nofray/*` topic branches remain.

## Validation and attribution

On 2026-09-25, `swift test` passed 564 core tests in 79 suites and one LaTeX
integration test in the combined fork. Candidate `0.13.0-nofray.3` validation
on 2026-09-27 passed `swift test` with 569 core tests in 80 suites and one
LaTeX test. Compared with the baseline, the unused HTML-comment test is gone
and coverage for host activation, source ranges, and default fallbacks is added. The
NoFray `MarkdownSurfaceAdapterTests` compatibility check used a temporary
local package override on `origin/main` `aac47830`: 19 passed, zero failures
or skips. Exact remote-pin verification remains for the later NoFray pin task.
PR #6 [Build & Test (macOS)](https://github.com/yvos/swift-markdown-engine/actions/runs/36316891147)
passed on final PR head `e49d947`. The pre-release notes record this CI run,
the local package counts and the NoFray compatibility result. No manual UI
acceptance is claimed.
Release validation is also recorded
with each GitHub release. Distinguish package
checks from NoFray integration, manual UI acceptance and live-provider evidence.
This maintenance change does not claim new manual UI or provider acceptance.

The upstream Apache License 2.0 remains in `LICENSE`; the integrated upstream
baseline has no `NOTICE` file. No license, platform requirement or package
dependency is changed by these fork extensions. Generic additions and modified
files remain covered by that license. This record documents their provenance.
