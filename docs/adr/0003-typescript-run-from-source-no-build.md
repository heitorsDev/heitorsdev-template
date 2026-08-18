# 0003 — TypeScript with erasable syntax only, run from source, no build step

## Status

Accepted. New in this template; cc-discord and session-guard were plain JS with
no type layer at all, which is the gap this closes.

## Context

Both source repos are Node ESM with JSDoc-free plain JavaScript. Their bugs were
overwhelmingly shape bugs — a hook handed a config object missing a field, a
service passed a path where it expected a resolver. Types catch that class
directly.

The usual objection is the build step: a `tsc` output directory means the thing
you run is not the thing you edited, `bin/*` entry points need a compiled path,
installers have to ship `dist/`, and the CI test job needs a build before it can
test. For hook scripts and small CLIs — which is what these repos are — that
overhead buys nothing, because nothing is published to a registry as compiled
JavaScript.

Node's native type stripping (unflagged since 22.18) removes the tradeoff: Node
runs `.ts` files directly by erasing the type annotations, with no transform and
no dependency. The catch is that it only *erases* — it cannot execute syntax that
has runtime semantics (`enum`, `namespace`, parameter properties, non-`type`
re-exports). That's a constraint worth accepting rather than working around, and
TypeScript enforces it with `erasableSyntaxOnly`.

## Decision

- **Source is `.ts`, run directly by Node.** No `dist/`, no build script, no
  bundler. `bin/*.ts` files are the executables the workflows and installers
  call.
- **`erasableSyntaxOnly: true`.** No `enum`, no `namespace`, no parameter
  properties, no runtime-bearing TS syntax. Use `const` objects and union types.
- **Imports carry the `.ts` extension** (`allowImportingTsExtensions`), because
  that's the specifier Node actually resolves at runtime.
- **`tsc` never emits** — `npm run typecheck` is `tsc --noEmit`. TypeScript is a
  checker here, not a compiler.
- **Strictness is maximal from day one**: `strict`, plus
  `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`,
  `noFallthroughCasesInSwitch`, `noUnusedLocals`, `noUnusedParameters`,
  `verbatimModuleSyntax`, `isolatedModules`. Loosening any of them is a decision
  that belongs in an ADR, not in a commit.
- **Lint is type-aware**: `typescript-eslint`'s `recommendedTypeChecked` with
  `projectService`, so rules like `no-floating-promises` and
  `no-misused-promises` actually fire. `.js` config files are excluded from the
  type-aware program.
- **Tests are `.ts` next to their subject**, run by `node --test`
  (`src/**/*.test.ts`). No test framework, no transform, no separate test
  tsconfig.
- **Three commands, one gate**: `npm run typecheck`, `npm run lint`, `npm test` —
  each a separate CI step so a red run says which one failed. `npm run verify`
  runs all three locally in that order.
- **Node floor is `>=22.18`**, the release where type stripping stopped being
  experimental. CI runs Node `22` — the floor, not the newest — so a feature
  that only exists on 24+ fails CI rather than shipping.
- **Zero runtime dependencies stays the rule.** `typescript`, `@types/node`,
  `eslint`, `typescript-eslint` are dev dependencies; nothing enters
  `dependencies` without an ADR.

## Consequences

- What you edit is what runs. Stack traces point at real line numbers with no
  source map, and `node bin/next-version.ts` works from a fresh clone with no
  build.
- A published-to-npm-as-compiled-JS project cannot use this template unchanged —
  it would need a real `tsc` emit and a `dist/` layout. That's a deliberate
  scope limit: these are hooks, CLIs, and plugins run from a clone or a plugin
  install.
- Type errors are invisible to `node` at runtime, since stripping doesn't check.
  `npm run typecheck` is therefore load-bearing in CI, not a convenience — a repo
  that skips the step ships type errors happily.
- `erasableSyntaxOnly` will occasionally reject an idiom (usually `enum`). The
  replacement — a `const` object plus a union type — is what the codebase should
  have used anyway.
- Bumping the Node floor is an ADR-worthy change, because it's the thing that
  makes running `.ts` directly possible at all.
