#!/usr/bin/env bash
# End-to-end check of the release path: replays release.yml's own shell logic
# against a throwaway git repo, once per kind of change, and asserts the tag
# that would be created.
#
#   scripts/verify-release.sh
#
# Covers what `npm test` can't: the tag-selection sed/sort, the "no tags yet"
# fallback, and the fail-soft branch of the workflow step.
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

FAILURES=0

# The exact body of release.yml's "Resolve current and next versions" step,
# with GITHUB_OUTPUT pointed at a temp file.
resolve() {
  local head_branch="$1" repo="$2" out="$3"
  (
    cd "${repo}"
    set -euo pipefail
    RAW_TAG="$(git tag --list 'v*' --sort=-v:refname | head -n 1 || true)"
    if [ -z "${RAW_TAG:-}" ]; then
      CURRENT_VERSION="0.0.0"
    else
      CURRENT_VERSION="${RAW_TAG#v}"
    fi
    if ! NEW_VERSION="$(node bin/next-version.js "${CURRENT_VERSION}" "${head_branch}" 2>/dev/null)"; then
      exit 0
    fi
    if [ -z "${NEW_VERSION}" ]; then
      exit 0
    fi
    echo "version=${NEW_VERSION}" >> "${out}"
  )
}

# check <description> <existing-tags-space-separated> <head-branch> <expected-tag-or-NONE>
check() {
  local desc="$1" tags="$2" branch="$3" expected="$4"
  local repo="${WORK}/repo" out="${WORK}/output"

  rm -rf "${repo}" "${out}"
  mkdir -p "${repo}"
  cp -r "${SOURCE}/bin" "${SOURCE}/src" "${repo}/"
  git -C "${repo}" init -q
  git -C "${repo}" config user.email ci@example.com
  git -C "${repo}" config user.name ci
  git -C "${repo}" add -A
  git -C "${repo}" commit -qm init
  for TAG in ${tags}; do
    git -C "${repo}" tag "${TAG}"
  done
  : > "${out}"

  resolve "${branch}" "${repo}" "${out}"

  local version actual
  version="$(sed -n 's/^version=//p' "${out}")"
  if [ -z "${version}" ]; then
    actual="NONE"
  else
    actual="v${version}"
  fi

  if [ "${actual}" = "${expected}" ]; then
    printf 'ok    %-46s %-16s -> %s\n' "${desc}" "${branch}" "${actual}"
  else
    printf 'FAIL  %-46s %-16s -> %s (expected %s)\n' "${desc}" "${branch}" "${actual}" "${expected}"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "release path: tag that each merge into main would create"
echo

check "fix on 1.4.2 bumps patch"          "v1.0.0 v1.4.2" "fix/typo"        "v1.4.3"
check "feat on 1.4.2 bumps minor"         "v1.0.0 v1.4.2" "feat/thing"      "v1.5.0"
check "release on 1.4.2 bumps major"      "v1.0.0 v1.4.2" "release/next"    "v2.0.0"
check "release branch with version name"  "v1.4.2"        "release/9.9.9"   "v2.0.0"
check "docs never releases"               "v1.4.2"        "docs/readme"     "NONE"
check "chore never releases"              "v1.4.2"        "chore/deps"      "NONE"
check "feature/ is not feat/"             "v1.4.2"        "feature/thing"   "NONE"
check "fixes/ is not fix/"                "v1.4.2"        "fixes/thing"     "NONE"
check "first fix with no tags"            ""              "fix/first"       "v0.0.1"
check "first feat with no tags"           ""              "feat/first"      "v0.1.0"
check "first release with no tags"        ""              "release/1"       "v1.0.0"
check "tag order is semver not lexical"   "v1.9.0 v1.10.0" "fix/x"          "v1.10.1"
check "double-digit minor rolls over"     "v0.9.9"        "feat/x"          "v0.10.0"
check "non-v tags are ignored"            "v1.2.3 nightly" "fix/x"          "v1.2.4"
check "nested slug in branch name"        "v1.2.3"        "fix/a/b/c"       "v1.2.4"

echo
if [ "${FAILURES}" -eq 0 ]; then
  echo "all release-path cases pass"
else
  echo "${FAILURES} case(s) failed"
  exit 1
fi
