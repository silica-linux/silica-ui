#!/bin/sh
# Every non-code file must have a row in ASSETS.md: either its own path in backticks or a
# glob in backticks that matches it (`test/amalfi/kit/**`; `*` also matches `/`).
status=0
set -f # the globs below are patterns for `case`, not paths to expand
globs=$(grep -o '`[^`]*\*[^`]*`' ASSETS.md | tr -d '`')
for file in $(git -c core.quotePath=false ls-files fonts shaders test/amalfi/kit | tr ' ' '\001'); do
  file=$(printf '%s' "$file" | tr '\001' ' ')
  grep -qF "\`$file\`" ASSETS.md && continue
  matched=0
  for glob in $globs; do
    # shellcheck disable=SC2254
    case "$file" in $glob) matched=1; break ;; esac
  done
  [ $matched = 1 ] || { echo "no row in ASSETS.md: $file"; status=1; }
done
exit $status
