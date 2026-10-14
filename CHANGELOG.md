# Changelog

## 0.17.0 · 2026-10-14

- **Cambia il disegno** delle icone di file, cartelle, volumi e Cestino (silica-icons 0.2,
  icon-format.md › "Principio"): `side` è la tela intera, non più il corpo delle app.
  Le fasce `min_size` di etichette, simboli della cartella e badge si confrontano con il lato
  della tela; i badge restano nel riquadro fra il corpo delle app (100…924) e la linea aurea.
- `SilicaIcon.besideApps`: un luogo accanto alle app (Dock) tiene `side` per corpo e la tela
  delle app attorno. `canvasExtent` dà il lato della tela.

## 0.16.0 · 2026-10-14

- `SilicaDrag` (canale `silica/drag` dell'embedder): il trascinamento fra app di Ossido.
  `start(paths, icon:)` porta fuori dalla finestra un elenco di file (`text/uri-list`) con
  l'immagine sul puntatore; `events` dà ingresso, movimento, uscita e rilascio
  (`SilicaDrop` con gli URI e i percorsi) dei file trascinati da altre app, e la fine
  (`SilicaDragFinished`: `copy`, `move`, `none`) di quelli usciti da qui.

## 0.15.1 · 2026-10-14

- `SilicaIcon`: senza `dark` l'icona è sempre quella chiara. La variante scura appartiene
  allo stile delle icone (un'impostazione a parte), non all'aspetto del sistema: in aspetto
  scuro le icone delle app e dei file restano le stesse (icons.md IC-01, mu20-list-dark).

## 0.15.0 · 2026-10-14

- Aspetto scuro dal sistema (`MediaQuery.platformBrightness`, che l'embedder riceve dal
  portale delle impostazioni).
- **Cambia l'API**: `ToolbarColors` e `MenuColors` non sono più costanti statiche ma
  istanze `light` / `dark`, con `of(context)` secondo l'aspetto del sistema
  (`ToolbarColors.title` → `ToolbarColors.of(context).title`). `MenuColors.highlight` e
  `highlightText` restano statiche: sono uguali nei due aspetti.
- Barra degli strumenti scura: fondo `#4c4c4c` → `#535454`, pillola `#595959`, icone e
  titolo `#e9e9e9` (mustache-spec 1.2).
- Menu scuri: testo bianco all'85 %, disattivato al 26 %, scorciatoie al 30 %, separatore
  al 14 %; il fondo pieno `#353536` (menubar.md).

## 0.14.0 · 2026-10-14

- `GlassTip.up`: la punta del vetro rivolta in alto, sul bordo superiore (silica-glass-v1
  versione 5, `add_upward_tip`).
- `MenuHost.tipUp` / `MenuPanel.tipUp`: un menu sotto la punta, che indica il pulsante da
  cui si apre (il popover di disposizione delle finestre).

## 0.13.1 · 2026-10-14

- Menu: un'intestazione (`MenuSection`) conta nella larghezza come una voce a 13 pt e sta
  allineata al testo delle voci (a 29 con le spunte), come nel menu delle pile del Dock
  (d06-pila-menu: 220 pt).

## 0.13.0 · 2026-10-14

- `SilicaWindow` (canale `silica/window`): `setFullSizeContent(toolbar)` chiede a Ossido il
  contenuto a tutta finestra (i pulsanti della finestra sopra la barra dell'app),
  `startMove()` sposta la finestra.
- `WindowDragArea`: il vuoto della barra degli strumenti sposta la finestra.
- `ToolbarCapsule`, `ToolbarSegment`, `ToolbarColors`: le capsule della barra unificata
  (alte 38, raggio 19, segmento scelto a pillola 34 × 28).

## 0.12.0 · 2026-10-13

- `MenuCustom`: una riga del menu disegnata da chi lo apre (alta `height`, larga almeno
  `width`), con la funzione per chiudere il menu: la fila dei cerchi delle etichette.

## 0.11.1 · 2026-10-13

- Passo 0b di silica-icons: se il tipo viene solo dal nome e `globs2` dà più tipi con lo
  stesso peso (`.ts`), decide prima la mappa delle estensioni. `MimeDatabase.isAmbiguousName`.

## 0.11.0 · 2026-10-13

- Le icone dei tipi scrivono l'estensione vera (`file-type-label` di silica-icons): riquadro,
  corpo, colore chiaro e scuro, `no_extension`, niente etichetta sotto `min_size`.
- `icons.mime` accetta `{icon, category}`: il file generico con quella categoria (l'override
  dell'estensione resta prima). Passo 0: il tipo diventa canonico con gli alias.
- `FileIcon`: `labelBox`, `labelSize`, `labelWeight`, `labelMinSide` al posto di `rules`.
  L'etichetta usa la riga naturale di Inter, centrata nel riquadro.

## 0.10.0 · 2026-10-13

- `MenuHost.opaque` e `MenuPanel.opaque`: menu a fondo pieno (`#fcfcfd` con un filo) invece
  del vetro, per i menu contestuali disegnati dentro la finestra di un'app (finché l'embedder
  non ha i popup).

## 0.9.1 · 2026-10-13

- `resolveFileIcon`: una voce di `icons.mime` che porta al file generico (`application/json`)
  lo disegna con l'etichetta e il colore di categoria, come al passo 5.

## 0.9.0 · 2026-10-13

- `MimeDatabase`: il tipo MIME di un file da shared-mime-info (glob di `globs2` con pesi e
  maiuscole, `subclasses`, `aliases`) e, se il nome non basta, dal contenuto (ELF, script con
  `#!`, testo o binario).
- `resolveFileIcon` e `FileSource`: l'icona di un file con l'ordine di silica-icons (tipo,
  tipo con `*`, genitori, estensione, file generico con l'estensione scritta nel colore della
  categoria, foglio con il punto di domanda); un eseguibile senza estensione prende
  `file-executable`. La mappa è quella del manifest del file generico (`FileLabelRules`).
- Badge (`IconBadge`, `SilicaIcon.badges`, `badgesOf`, `visibleBadges`): alias in basso a
  sinistra, a destra il primo fra illeggibile, bloccato, nuvola; da 16 a 31 pt uno solo,
  sotto 16 nessuno; varianti scure.
- Volumi: `volumeIconId` (rete, immagine disco, ottico, esterno, interno), `parseMountinfo`,
  `blockRemovable`.

## 0.8.1 · 2026-10-13

- `SilicaAlert.opaque`: fondo pieno (bianco o `#272727`, filo esterno, ombra) invece del
  vetro, per un avviso disegnato dentro una finestra: lì il vetro del compositor starebbe
  sotto il contenuto e non si vedrebbe. Il pulsante normale diventa `#e8e8e8`.

## 0.8.0 · 2026-10-13

- `SilicaAlert`: l'avviso di sistema (292 pt, vetro spesso, icona 66, titolo in grassetto,
  pulsanti alti 30 impilati a tutta larghezza o affiancati), con i ruoli `AlertRole`
  (predefinito blu, annulla, distruttivo rosato); Invio sceglie il predefinito, Esc
  l'annulla (o l'unico pulsante).

## 0.7.1 · 2026-10-13

- `fileIconId(nome)` e `fileIconFor(nome)`: l'icona di silica-icons di un file
  dall'estensione (prima nella Dock della shell). Un file nascosto senza estensione
  (`.bashrc`) è `file-unknown`.

## 0.7.0 · 2026-10-13

- Le icone di silica-icons passano qui dalla shell, per le app (Mustache) e per la shell:
  `SilicaIcon` (prima `ShellIcon` della shell) con `LayeredSource`, `FolderSource`,
  `FlatSource`; il manifest (`parseManifest`, `findSilicaIcon`, `silicaIconDirs`), la
  cartella generica con simbolo e tinta (`resolveFolderIcon`, `FolderIcon`) e le cartelle
  speciali (`xdgUserDirs`, `specialFolderKey`, `xdgDataDirs`). `iconBodyPath`: la
  superellisse del corpo.
- Nuova dipendenza: `flutter_svg`.

## 0.6.0 · 2026-10-13

- `Glass.group` e `LiquidGlass.group`: il vetro si fonde solo con quello dello stesso
  gruppo, e un gruppo più alto sta sopra. Ogni livello di un menu ha il suo: il sottomenu
  è un pannello distinto sopra il menu madre, non una forma unica con lui.
- `Glass.tip` (`GlassTip`): una punta che fa parte della forma di vetro, con il vertice
  arrotondato e i lati raccordati al corpo. La punta dei menu del Dock non è più un
  triangolo dipinto sopra il vetro; l'ombra del menu non cade sulla punta.
- Tolti `MenuColors.tipFill` e `MenuColors.tipLine` (non servono più).
- Richiede silica-glass-v1 versione 4 (Ossido); con un compositor più vecchio i gruppi si
  ignorano e la punta non c'è.

## 0.5.1 · 2026-10-13

- `MenuHost`: quando cambiano `tip` o `anchor` (la superficie che ospita il menu si allunga)
  i menu aperti si spostano con loro; prima restavano dov'erano.

## 0.5.0 · 2026-10-13

- `MenuHost.onRectsChanged`: i rettangoli dei menu aperti, dopo il frame in cui cambiano
  (un sottomenu che si apre o si chiude), per allargare la regione d'input di chi ospita il
  menu. Senza, su una superficie con regione d'input il sottomenu non riceveva il puntatore.

## 0.4.0 · 2026-10-13

- `MenuHost.tip` e `MenuPanel.tipX`: un menu che indica un oggetto sotto di sé (le icone del
  Dock) ha una punta alta 8 pt e larga 22 alla base, con il corpo 27 pt a sinistra del
  vertice.

## 0.3.2 · 2026-10-13

- `MenuHost.handlesPointer`: falso per passare il puntatore dall'esterno (`pointerMoved`,
  `pointerDown`, `pointerUp`, `contains`), come una barra in cui si preme su una voce e si
  rilascia su una voce del menu.

## 0.3.1 · 2026-10-13

- Uguale a 0.3.0 (tag pubblicato per errore senza la modifica prevista).

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
