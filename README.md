<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/silica-logo-dark.svg">
    <img alt="Silica" src=".github/silica-logo-light.svg" width="200">
  </picture>
</p>

<h1 align="center">silica_ui</h1>

<p align="center">
  <b>The design system of Silica for Flutter apps.</b><br>
  Inter, glass and Liquid Glass, toolbar, menus, alerts, icons and drag and drop between apps.
</p>

<p align="center">
  <img alt="Flutter: package" src="https://img.shields.io/badge/Flutter-package-02569B?style=flat-square&logo=flutter">
  <img alt="version: v0.19.2" src="https://img.shields.io/badge/version-v0.19.2-2f7bf5?style=flat-square">
  <img alt="license: MIT / Apache-2.0" src="https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-3a3a3a?style=flat-square">
</p>

Used by the Silica shell and by the apps (Mustache, Settings, …), each in its own repository.

```yaml
dependencies:
  silica_ui:
    git:
      url: https://github.com/silica-os/silica-ui.git
      ref: v0.19.2
```

## What's inside

| API | What it does |
| --- | --- |
| `uiFontFamily`, `uiText(size:, color:)` | Inter (OFL), the interface font, served by the package |
| `Glass`, `LiquidGlass`, `GlassMaterial` | glass areas composed by the Ossido compositor; Liquid Glass reacts to press and pointer |
| `WindowGlass` | glass drawn by Flutter inside a window (menus over the app's own content) |
| `SilicaWindow`, `WindowDragArea`, `ToolbarCapsule`, `ToolbarSegment`, `ToolbarScope`, `ToolbarGlassMetrics` | the unified toolbar and its glass controls: hover, press growth, glow |
| `SilicaAppearance`, `SilicaAppearanceScope`, `SilicaApp.appearance` | the appearance override (always dark / always light), for the app or the window; also sent to Ossido |
| `MenuHost`, `MenuPanel`, `MenuColors` | menus with submenus, sections, custom rows, light and dark |
| `SilicaMenuBar`, `SilicaMenus`, `SilicaMenuItem`, `SilicaMenuDelegate` | the app's menus in Silica's global menu bar, with their shortcuts ([docs/app-menus.md](docs/app-menus.md)) |
| `SilicaIcon`, `resolveFileIcon`, `resolveFolderIcon` | layered icons from silica-icons (the rendered PNG of each style when the pack has one), with badges and ground shadows |
| `SilicaDrag` | drag and drop of files between apps (`text/uri-list`) |

## How the glass works

The package does not draw the compositor glass: it declares the areas on the `silica/glass`
channel of the Silica embedder, and Ossido composes them with the `silica-glass-v1` protocol.
Outside Silica (tests, other embedders) the channel does not answer and there is no glass: the
app must stay readable that way.

## Stability

[Semver](https://semver.org/) versions with `vX.Y.Z` tags and a [`CHANGELOG.md`](CHANGELOG.md).
Names, types and behavior of the public API change only with a major version (in 0.x: minor).
Measured or provisional values (press scale, springs, colors) may change in a minor version
when new measurements arrive: they are parity with the reference, not a contract.

## Development

```sh
flutter analyze --fatal-infos && flutter test
cd example && flutter test      # the glass lab
```

## License

Code: MIT OR Apache-2.0 ([LICENSE-MIT](LICENSE-MIT), [LICENSE-APACHE](LICENSE-APACHE)).
Font: Inter, OFL 1.1 ([fonts/OFL.txt](fonts/OFL.txt)). Every asset has a row in
[ASSETS.md](ASSETS.md).
