# Changelog

## 0.3.0 · 2026-10-13

- Menu: `MenuHost` (un menu con i suoi sottomenu in un'area che lo contiene), `MenuPanel`,
  le voci `MenuAction` (scorciatoia, spunta, icona, sottomenu, disattivata), `MenuDivider` e
  `MenuSection`; `menuSize` e `menuRowTops` per posizionarli. Voci da 24 pt, separatori da 11,
  evidenziazione blu, vetro spesso con l'ombra fuori dal pannello; sottomenu dopo ~295 ms
  con la tolleranza a triangolo; ↑ ↓ → ← Invio Esc e le lettere; la scelta lampeggia e il
  menu sfuma in ~190 ms.

## 0.2.0 · 2026-10-13

- Il vetro porta l'opacità degli antenati (`Opacity`, `FadeTransition`, `AnimatedOpacity`):
  la regione mandata al compositor ha il campo `opacity` (0–1) e Ossido compone il vetro in
  dissolvenza insieme al pannello (`silica-glass-v1` versione 3). Con un compositor più
  vecchio il vetro resta pieno.

## 0.1.0 · 2026-10-13

Prima versione come pacchetto a sé (prima in `silica/packages/silica_ui`).

- `uiFontFamily` e `uiText`: Inter Regular e SemiBold.
- `Glass` e `GlassMaterial` (`clear`, `thick`, `regular`, `notification`) sul canale
  `silica/glass`.
- `LiquidGlass`: pressione, rilascio con rimbalzo, riflesso che segue il puntatore.
- `GlassRegistry` controlla le regioni a ogni frame: il vetro sotto un antenato che cambia
  trasformazione o opacità segue anche senza ridisegnarsi.
- `example/`: il laboratorio del vetro.
