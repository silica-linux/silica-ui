# Changelog

## 0.1.0 · 2026-10-13

Prima versione come pacchetto a sé (prima in `silica/packages/silica_ui`).

- `uiFontFamily` e `uiText`: Inter Regular e SemiBold.
- `Glass` e `GlassMaterial` (`clear`, `thick`, `regular`, `notification`) sul canale
  `silica/glass`.
- `LiquidGlass`: pressione, rilascio con rimbalzo, riflesso che segue il puntatore.
- `GlassRegistry` controlla le regioni a ogni frame: il vetro sotto un antenato che cambia
  trasformazione o opacità segue anche senza ridisegnarsi.
- `example/`: il laboratorio del vetro.
