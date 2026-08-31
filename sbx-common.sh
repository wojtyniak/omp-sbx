#!/usr/bin/env bash
# sbx-common.sh — shared helpers for the omp-sbx launchers.

# Short, stable hash of a string. Portable: sha256sum on Linux, shasum on macOS.
# Both produce identical digests (verified: same 8-char prefix for one input).
_path_hash() {
  { if command -v sha256sum >/dev/null 2>&1; then
      printf '%s' "$1" | sha256sum
    else
      printf '%s' "$1" | shasum -a 256
    fi
  } | cut -c1-8
}

# sandbox_name_for <absolute-path> [suffix]
#
# Sandboxes are keyed on the *full* path, not its basename: ~/work/api and
# ~/personal/api would otherwise collide on one name, and the launcher would
# silently attach the agent to whichever workspace got there first. The slug is
# cosmetic (readability in `sbx ls`); the hash carries the uniqueness.
#
# Callers MUST pass a PHYSICAL path (`pwd -P`, not `pwd`) — see note below.
sandbox_name_for() {
  local path="$1" suffix="${2:-}" slug key
  key="$path${suffix:+:$suffix}"
  slug="$(basename "$path" | tr '_' '-' | tr -cd '[:alnum:]-')"
  if [ -n "$suffix" ]; then
    slug="${slug}-$(printf '%s' "$suffix" | tr '_/' '--' | tr -cd '[:alnum:]-')"
  fi
  slug="${slug:0:32}"
  printf 'omp-%s-%s\n' "${slug:-ws}" "$(_path_hash "$key")"
}
