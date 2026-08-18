# Skill map

Which of the engineering skills ([mattpocock/skills](https://github.com/mattpocock/skills))
read this repo's configuration, and what they read.

This repo is already configured — the three adapter files in this directory are
the output of `/setup-matt-pocock-skills`. **Don't re-run that skill** unless
switching issue trackers or restarting the config from scratch; edit these files
directly instead.

## The adapter files

| File | Answers | Read by |
| ---- | ------- | ------- |
| `issue-tracker.md` | Where issues live, and the exact `gh` commands for each operation | `/to-spec`, `/to-tickets`, `/triage`, `/wayfinder` |
| `triage-labels.md` | The label string for each of the 5 canonical triage roles | `/triage` |
| `domain.md` | Where `CONTEXT.md` and ADRs live, and how to consume them | `/domain-modeling`, `/grill-with-docs`, `/improve-codebase-architecture`, and any skill exploring the codebase |

Config as configured here:

- **Issue tracker**: GitHub Issues via the `gh` CLI. Repo inferred from
  `git remote -v`.
- **PRs as a request surface**: **no**. External PRs don't enter the triage
  queue. Flip the flag in `issue-tracker.md` to change it.
- **Triage labels**: the 5 defaults, each label string equal to its role name.
  Create them with `scripts/bootstrap-labels.sh`.
- **Domain docs**: single-context — `CONTEXT.md` + `docs/adr/` at the repo root.

## The flow these repos actually used

1. **`/grill-with-docs`** on the initial idea — produces the ADRs in `docs/adr/`
   and the glossary in `CONTEXT.md` as decisions get resolved, rather than
   upfront.
2. **`/to-spec`** — publishes the agreed spec as issue #1. Every ADR's `## Status`
   cites it (`Source: the v1 spec, issue #1`), which is what makes a decision
   traceable to the conversation that settled it.
3. **`/to-tickets`** — breaks the spec into tracer-bullet tickets as child issues
   with blocking edges.
4. **`/triage`** on anything arriving later — moves it through the 5 labels and
   writes an agent-ready brief onto `ready-for-agent` issues.
5. **`/implement`** or **`/tdd`** per ticket, on a `fix/*` or `feat/*` branch
   (see `AGENTS.md` → **Branching**).
6. **`/code-review`** since the merge-base before opening the PR — it reviews
   against both this repo's documented standards (`AGENTS.md`, the ADRs) and the
   originating issue.
7. Merge to `main` → the release workflow tags and releases. No version is typed
   by hand.

`/wayfinder` is for work too big for one session — a map issue plus investigation
tickets resolved one at a time. Reach for it instead of `/to-tickets` when the
destination is known but the route isn't.

## Wayfinder on GitHub: what works here

Verified against `heitorsDev/session-guard`, which ran a full wayfinder map:

- **Map**: one issue labelled `wayfinder:map` holding Notes / Decisions-so-far /
  Fog.
- **Children**: labelled `wayfinder:<type>` (`research`, `prototype`, `grilling`,
  `task`). GitHub **sub-issues were not used** — children were listed in a task
  list in the map body with `Part of #<map>` at the top of each child. That's the
  documented fallback in `issue-tracker.md` and it's the path that's been
  exercised.
- **Blocking**: GitHub's **native issue dependencies** were used and do work —
  `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by
  -F issue_id=<blocker-db-id>`, where the id is the numeric **database id**
  (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`), not the `#number`.
  `issue_dependencies_summary.blocked_by` counts open blockers only — that's the
  live gate for the frontier query.
- Run `scripts/bootstrap-labels.sh` before the first wayfinder session; it
  creates the `wayfinder:*` labels alongside the triage ones.

## `CONTEXT.md` is created lazily

There is no `CONTEXT.md` in this template on purpose. `domain.md` tells skills to
**proceed silently** when it's absent; `/domain-modeling` creates it when a term
or decision actually gets resolved. Don't scaffold an empty one.
