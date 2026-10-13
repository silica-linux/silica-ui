# silica_ui

Il design system di [Silica](https://github.com/silica-linux/silica) per le app Flutter: il
font dell'interfaccia e il vetro. Lo usano la shell di Silica e le app (Mustache,
Impostazioni, …), ognuna nel suo repository.

```yaml
dependencies:
  silica_ui:
    git:
      url: https://github.com/silica-linux/silica-ui.git
      ref: v0.2.0
```

## Cosa c'è

| API | Cosa fa |
| --- | --- |
| `uiFontFamily`, `uiText(size:, color:)` | Inter (OFL), il font dell'interfaccia, servito dal pacchetto |
| `Glass(radius:, material:, child:)` | un'area di vetro grande quanto il figlio: lo sfondo sfocato lo compone Ossido, il figlio disegna sopra |
| `GlassMaterial` | `clear` (Dock), `thick` (menu, ricerca), `regular` (Liquid Glass dei controlli), `notification` (banner) |
| `LiquidGlass(radius:, material:, interactive:, child:)` | vetro che reagisce: si gonfia alla pressione, il riflesso segue il puntatore |
| `GlassRegistry` | raccoglie le aree di vetro dopo ogni frame e le manda al compositor quando cambiano |

## Come funziona il vetro

Il pacchetto non disegna il vetro: dichiara le aree al compositor sul canale `silica/glass`
dell'embedder di Silica (`setRegions` con `x`, `y`, `width`, `height`, `radius`, `material`,
`opacity` in pixel logici della superficie), e Ossido le compone con il protocollo `silica-glass-v1`.
Fuori da Silica (test, altri embedder) il canale non risponde e il vetro non c'è: l'app deve
restare leggibile anche così.

## Stabilità

Versioni [semver](https://semver.org/lang/it/) con tag `vX.Y.Z` e [`CHANGELOG.md`](CHANGELOG.md).
Nomi, tipi e comportamento dell'API pubblica cambiano solo con una versione maggiore (in 0.x:
minore). I valori misurati o provvisori (scala della pressione, molle, colori) possono
cambiare in una versione minore quando arrivano misure nuove: sono la parità con il
riferimento, non un contratto.

## Sviluppo

```
flutter analyze --fatal-infos && flutter test
cd example && flutter test      # il laboratorio del vetro
```

Il laboratorio (`example/`) si prova dentro Silica con l'embedder del repo principale.

## Licenza

Codice: MIT OR Apache-2.0 ([LICENSE-MIT](LICENSE-MIT), [LICENSE-APACHE](LICENSE-APACHE)).
Font: Inter, OFL 1.1 ([fonts/OFL.txt](fonts/OFL.txt)). Ogni asset ha una riga in
[ASSETS.md](ASSETS.md).
