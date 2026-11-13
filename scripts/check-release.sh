#!/usr/bin/env bash
# Release checks.
#   scripts/check-release.sh versions   the .toc and the Lua VERSION agree
#   scripts/check-release.sh 1.2.0      also: the tag matches, it is higher than the last
#                                       release, and CHANGELOG.md has a filled-in section
set -euo pipefail
toc=$(sed -n 's/^## Version: *//p' SpicyKillStreaks/SpicyKillStreaks.toc | tr -d '\r')
lua=$(sed -n 's/^local VERSION = "\(.*\)"/\1/p' SpicyKillStreaks/SpicyKillStreaks.lua | tr -d '\r')
if [ "$toc" != "$lua" ]; then
  echo "::error::Version mismatch: .toc says '$toc', SpicyKillStreaks.lua says '$lua'"; exit 1
fi
[ "${1:-}" = versions ] && { echo "Versions agree: $toc"; exit 0; }

v="$1"
if [ "$v" != "$toc" ]; then
  echo "::error::Tag v$v does not match the addon version $toc"; exit 1
fi

# Higher than every earlier release (re-pushing the same tag is allowed, to rebuild it)
prev=$(git tag -l 'v[0-9]*' | sed 's/^v//' | grep -vx "$v" | sort -V | tail -1 || true)
if [ -n "$prev" ] && [ "$(printf '%s\n%s\n' "$prev" "$v" | sort -V | tail -1)" != "$v" ]; then
  echo "::error::Version $v is not higher than the last release ($prev)"; exit 1
fi

section=$(awk -v h="## v$v" '$0==h{f=1;next} /^## /{f=0} f' CHANGELOG.md)
if [ -z "$(echo "$section" | tr -d '[:space:]')" ]; then
  echo "::error::CHANGELOG.md has no '## v$v' section"; exit 1
fi
if echo "$section" | grep -q "TODO"; then
  echo "::error::CHANGELOG.md '## v$v' still has a TODO"; exit 1
fi
echo "Release $v OK (previous: ${prev:-none})"
