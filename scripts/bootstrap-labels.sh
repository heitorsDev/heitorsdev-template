#!/usr/bin/env bash
# Create this repo's agent-facing labels (idempotent).
#
# The 5 canonical triage roles read by /triage (docs/agents/triage-labels.md),
# plus the wayfinder types read by /wayfinder (docs/agents/issue-tracker.md).
# Colours match heitorsDev/cc-discord and heitorsDev/session-guard so labels
# look the same across repos.
#
# `wontfix` is intentionally absent: GitHub creates it by default, and its
# default description is the one both source repos kept.
set -euo pipefail

create() {
  gh label create "$1" --color "$2" --description "$3" --force
}

create "needs-triage"    "ededed" "Maintainer needs to evaluate this issue"
create "needs-info"      "d4c5f9" "Waiting on reporter for more information"
create "ready-for-agent" "0e8a16" "Fully specified, ready for an AFK agent"
create "ready-for-human" "fbca04" "Requires human implementation"

create "wayfinder:map"       "1d76db" "Wayfinder map issue"
create "wayfinder:research"  "1d76db" "Wayfinder child: research"
create "wayfinder:prototype" "1d76db" "Wayfinder child: prototype"
create "wayfinder:grilling"  "1d76db" "Wayfinder child: grilling"
create "wayfinder:task"      "1d76db" "Wayfinder child task"

echo "agent labels ready (wontfix comes from GitHub's defaults)"
