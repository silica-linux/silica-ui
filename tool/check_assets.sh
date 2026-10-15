#!/bin/sh
# Every non-code file must have a row in ASSETS.md.
status=0
for file in $(git ls-files fonts shaders); do
  grep -q "\`$file\`" ASSETS.md || { echo "no row in ASSETS.md: $file"; status=1; }
done
exit $status
