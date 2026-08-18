# 0001 — CI matrix is Linux + Windows, and CI is the only merge gate

## Status

Accepted. Extracted from `heitorsDev/cc-discord` ADR 0005 and
`heitorsDev/session-guard` ADR 0005, which reached the same shape independently.

## Context

Both source repos ship Node CLIs/hooks whose *runtime* support is narrower than
their *code*. cc-discord is Linux-only (Discord's IPC transport differs per
platform); session-guard branches on `process.platform` and supports Windows.

The CI matrix was first narrowed to `ubuntu-latest` alone on the grounds that
Linux was all one project supported. That reasoning was wrong, and this template
encodes the correction: most of a codebase like this is platform-independent by
nature — argument parsing, config loading, transcript/file reading, version
computation — and a stray POSIX-path or separator assumption in any of it is a
real bug regardless of which OS ships. A Windows leg costs nothing and catches
exactly that class of slip.

A Windows leg can stay green without any Windows code path existing, but only
under a discipline: OS-specific resolvers must not be evaluated at import time
and must not be reached by tests. `XDG_RUNTIME_DIR` is undefined on Windows and
`path.join(undefined, …)` throws, so an eagerly-evaluated resolver fails the
whole leg. Injectable resolvers plus tests that always inject are what keep it
passing.

## Decision

- **CI**: GitHub Actions, `.github/workflows/ci.yml`.
  - Triggers: `pull_request` (any base, so it covers `feat/*` → `release/*` and
    `release/*` → `main`) and `push` to `release/**`.
  - Matrix: `ubuntu-latest` + `windows-latest`, `fail-fast: false`.
  - Steps: `actions/checkout@v4`, `actions/setup-node@v4` with Node `20` and
    `cache: "npm"`, then `npm ci`, `npm run lint`, `npm test`.
- **Runtime support is declared separately from the matrix.** An adopting repo
  states its supported platforms in its own ADR. The Windows leg is a
  portability check, not a support claim — no installer, daemon, or transport is
  claimed to work there by virtue of it passing.
- **No live anything in CI**: no network, no real external process or socket, no
  credentials, no live agent session. Fixtures and injected boundaries only.
- **No test may call a filesystem resolver's default** — every test injects its
  own directory.
- **CI is the merge gate.** The release workflow (see
  [0002](./0002-branching-and-semver-by-branch-prefix.md)) is not a gate and
  must never be relied on as one.
- **Lint and test are one command each** (`npm run lint`, `npm test`) so the
  local pre-PR check and CI are identical. `npm test` is `node --test` — no test
  framework dependency.

## Consequences

- Tested behaviour is the behaviour that carries logic: services, protocol
  encode/decode against byte fixtures, config and installer merges, version
  computation. Thin controllers and adapters stay uncovered on purpose, and are
  kept thin precisely so the untested part contains no decisions.
- A genuinely single-platform regression can't be caught by the other leg, and
  isn't meant to be. The matrix catches accidental platform coupling in code
  that shouldn't have any.
- Adding a second runtime platform is a deliberate ADR in the adopting repo,
  paired with a real transport/implementation — never a side effect of CI being
  green there.
- Because dev dependencies are limited to `eslint`, `npm ci` on both legs stays
  fast enough that the matrix is effectively free.
