# Amalfi token sources

Copies of the Silica 1.0 "Amalfi" design hand-off, the input of `tool/gen_amalfi_tokens.dart`:

| File | Source |
| --- | --- |
| `tokens.json` | `silica-desktop/docs/design/amalfi/tokens.json` at commit `d11cfda` |
| `motion.md` | `silica-desktop/docs/design/amalfi/motion.md` at commit `d11cfda` (the spring, fade and delay tables) |

To update: copy the new files here, run `dart run tool/gen_amalfi_tokens.dart` from the package
root, and commit the sources together with `lib/src/amalfi/tokens.g.dart`. CI runs the generator
with `--check` and fails when the generated file is stale.
