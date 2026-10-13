#!/bin/sh
# Ogni file non di codice deve avere una riga in ASSETS.md.
status=0
for file in $(git ls-files fonts); do
  grep -q "\`$file\`" ASSETS.md || { echo "senza riga in ASSETS.md: $file"; status=1; }
done
exit $status
