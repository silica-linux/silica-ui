# AGENTS.md

The rules of `silica-desktop/AGENTS.md` apply (clean-room, assets, never crash, measured parity).
In addition, for this package:

- The public API is stable: every change of names, types or behavior goes into `CHANGELOG.md`
  and bumps the version as the README says. Measured values may change.
- Before every commit: `flutter analyze --fatal-infos`, `flutter test`, `dart format`, and the
  same in `example/`; every new asset has its row in `ASSETS.md`.
- A release is a `vX.Y.Z` tag on the commit that updates `version` in `pubspec.yaml` and the
  changelog; then the `ref` is updated in the repositories that use it.
- Everything in the repository is in English (comments, docs, tests, commits); user-visible
  UI strings are localized.
