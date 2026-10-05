#!/usr/bin/env bash
# usage: runtest.sh <build.lua> <report.lua or ""> [warmup_s] [measure_s] [extra libs...]
S="$(cd "$(dirname "$0")" && pwd)"; cd "$S/../../../../.."
PS="powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/factorio-blueprints/scripts/factorio.ps1"
LIBS="common.lua rails.lua layout.lua stations.lua blocks.lua blueprint.lua $(cygpath -w "$S/job.lua") ${5:-}"
$PS lua $LIBS "$(cygpath -w "$1")" || exit 1
sleep "${3:-10}"; $PS lua common.lua layout.lua "$(cygpath -w "$S/t0.lua")" >/dev/null
sleep "${4:-20}"; R="${2:-$S/finish.lua}"; $PS lua $LIBS "$(cygpath -w "$R")"
