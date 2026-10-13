# AGENTS.md

Valgono le regole di `silica/AGENTS.md` (clean-room, asset, mai crashare, parità misurata).
In più, per questo pacchetto:

- L'API pubblica è stabile: ogni cambiamento di nomi, tipi o comportamento va in
  `CHANGELOG.md` e alza la versione come dice il README. I valori misurati possono cambiare.
- Prima di ogni commit: `flutter analyze --fatal-infos`, `flutter test`, `dart format`, e lo
  stesso in `example/`; ogni asset nuovo ha la sua riga in `ASSETS.md`.
- Un rilascio è un tag `vX.Y.Z` sul commit che aggiorna `version` in `pubspec.yaml` e il
  changelog; poi si aggiorna il `ref` nei repository che lo usano.
