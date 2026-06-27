#!/usr/bin/env bash
#
# Regression guard for checked-accessor inlining / loop auto-vectorization.
#
# The small checked index accessors in `builtin` (ArrayView/MutArrayView/
# BytesView/StringView `at`/`set`, Array::swap, Deque::at/set) keep their cold
# out-of-bounds path in shared `#inline(never)` helpers (see builtin/bounds.mbt)
# so the accessor bodies stay small enough for the native (C/LLVM) backend to
# inline. When they are inlined, the per-element bounds guard is hoisted out of
# the loop and the loop auto-vectorizes; when they are NOT (e.g. if the cold
# `abort` formatting is ever inlined back into the body), the body grows past
# clang's inline-cost threshold, the accessor is emitted as an out-of-line call,
# and hot view/array loops silently fall back to scalar code.
#
# This script detects exactly that regression: it compiles the generated native
# C with clang's inline-cost remarks and fails if any checked accessor is
# reported "not inlined ... because too costly to inline".
#
# Notes:
#   * Requires clang (for -Rpass-missed=inline); gcc does not emit these remarks.
#   * Runs on a single platform by design ("at least on some platform"); the
#     inline-cost threshold is architecture-independent, so one runner suffices.
#   * A healthy accessor inlines at cost ~40-70 (threshold 225), so it can never
#     produce a "too costly" remark -> no false positives. A regressed accessor
#     jumps to cost ~800+ -> caught.
#
set -euo pipefail

MOON_HOME="${MOON_HOME:-$HOME/.moon}"
INCLUDE="$MOON_HOME/include"
CC="${CLANG:-clang}"

# Infra problems (no clang, build/codegen layout drift) fail OPEN: emit a
# warning and pass, so toolchain changes never block unrelated PRs. Only a real
# "too costly" regression fails the job.
if ! command -v "$CC" >/dev/null 2>&1; then
  echo "::warning::'$CC' not found; skipping accessor-inlining guard (needs clang for -Rpass)"
  exit 0
fi

echo "==> building optimized native C for builtin"
build_log="$(mktemp)"
if ! moon bench --target native -p builtin --build-only >"$build_log" 2>&1; then
  cat "$build_log" >&2
  echo "::warning::native build failed; skipping accessor-inlining guard (other jobs cover build failures)"
  exit 0
fi

echo "==> locating generated C"
C="$(grep -rl 'ArrayView2at' _build/native/release --include='*.c' 2>/dev/null | head -1 || true)"
if [ -z "${C:-}" ]; then
  echo "::warning::could not find generated native C under _build/native/release; skipping guard"
  exit 0
fi
echo "    $C"

echo "==> compiling with clang inline-cost remarks"
# Compile-only (-c -o /dev/null): unresolved externs are fine, we only want the
# optimizer's inlining decisions. Flags mirror moon's native release build.
remarks="$("$CC" -O2 -fwrapv -fno-strict-aliasing -DMOONBIT_USE_SIMDUTF \
  -I "$INCLUDE" -c "$C" -o /dev/null -Rpass-missed=inline 2>&1 || true)"

# The checked accessor method symbols (mangled): <Type><len><method>.
accessors='ArrayView2at|MutArrayView2at|MutArrayView3set|BytesView2at|StringView2at|Deque2at|Deque3set|Array4swap'

bad="$(printf '%s\n' "$remarks" \
  | grep 'too costly to inline' \
  | grep -oE "'_M0[^']*(${accessors})[^']*' not inlined into '[^']*'[^[]*" \
  | sort -u || true)"

if [ -n "$bad" ]; then
  {
    echo "::error::checked accessor(s) regressed: no longer inlineable (loop auto-vectorization lost)"
    printf '%s\n' "$bad" | sed 's/^/  /'
    echo
    echo "A checked accessor's body grew past clang's inline threshold. Keep its"
    echo "out-of-bounds abort in an #inline(never) helper (see builtin/bounds.mbt:"
    echo "index_out_of_bounds / index_out_of_bounds2) instead of inlining it."
  } >&2
  exit 1
fi

echo "OK: all checked accessors remain inlineable."
