// L'icona di un'app o di un luogo come la disegna la shell. Le icone a livelli di
// silica-icons prendono forma, bordo e ombra da qui (icon-format.md: i livelli non li
// contengono); le icone freedesktop già composte vanno ridotte al keyline su un fondo neutro;
// senza icona, la tessera con l'iniziale.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, TileMode;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../silica_ui.dart' show uiFontFamily, uiText;
import 'file_icons.dart';
import 'silica_icons.dart';

/// Tela delle icone: 1024, corpo 824 a 100 dal bordo, keyline quadrato 600.
const double canvasSide = 1024;
const double bodyInset = 100;
const double bodySide = 824;
const double keylineSide = 600;

/// Maschera del corpo: superellisse per angolo con n ≈ 2,6 e raggio ≈ 0,32 × lato
/// (plan/reference/icons.md, misurata sul selettore delle app).
const double maskExponent = 2.6;
const double maskRadiusRatio = 0.32;

/// Ombra dell'icona sul fondo: ~3 % del lato sotto, sfocata altrettanto (dock.md).
const double dropOffsetRatio = 0.03;
const Color dropColor = Color(0x55000000);

/// Ombra del primo piano sul fondo (`"shadow": "neutral"`).
const double layerShadowRatio = 0.012;
const Color layerShadowColor = Color(0x38000000);

/// L'ombra a terra di un'icona (plan/reference/icons.md, IC-01: ombra gaussiana nera
/// adattata, uguale in tutti i temi). Misure per lato della tela: 32 → opacità 0,35, σ 1,2,
/// in basso 0,55; 64 → 0,20, 1,45, 0,8; 128 → 0,28, 2,7, 1,2; 512 → 0,25, 7,5, 3,1 (pt).
/// Fra le misure σ e spostamento seguono il lato in proporzione, l'opacità si interpola;
/// a 128 l'ombra sborda di ~5 pt per lato, come dice silica-icons.
@immutable
class IconShadow {
  const IconShadow(this.opacity, this.sigma, this.offset);

  final double opacity;
  final double sigma;
  final double offset;

  static const List<(double, double, double, double)> _measured = [
    (32, 0.35, 1.2, 0.55),
    (64, 0.20, 1.45, 0.8),
    (128, 0.28, 2.7, 1.2),
    (512, 0.25, 7.5, 3.1),
  ];

  static IconShadow forSide(double side) {
    final first = _measured.first, last = _measured.last;
    if (side <= first.$1) {
      final k = side / first.$1;
      return IconShadow(first.$2, first.$3 * k, first.$4 * k);
    }
    if (side >= last.$1) {
      final k = side / last.$1;
      return IconShadow(last.$2, last.$3 * k, last.$4 * k);
    }
    for (var i = 1; i < _measured.length; i++) {
      final (s0, a0, g0, d0) = _measured[i - 1];
      final (s1, a1, g1, d1) = _measured[i];
      if (side > s1) continue;
      // Sulla scala logaritmica del lato, come i rapporti misurati.
      final t = (math.log(side) - math.log(s0)) / (math.log(s1) - math.log(s0));
      double lerp(double a, double b) => a + (b - a) * t;
      return IconShadow(
        lerp(a0, a1),
        side * lerp(g0 / s0, g1 / s1),
        side * lerp(d0 / s0, d1 / s1),
      );
    }
    return IconShadow(last.$2, last.$3, last.$4);
  }
}

/// Fondo neutro delle icone senza livelli.
const List<Color> neutralLight = [Color(0xFFFFFFFF), Color(0xFFEDEDF0)];
const List<Color> neutralDark = [Color(0xFF3A3A3C), Color(0xFF161618)];

/// Mesi per l'icona del calendario (la shell è in italiano).
const List<String> monthNames = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

/// Il contorno del corpo nel rettangolo `r`.
Path iconBodyPath(Rect r) {
  final radius = math.min(r.width, r.height) * maskRadiusRatio;
  const steps = 16;
  final path = Path();
  // Un angolo: centro (cx, cy), direzioni (sx, sy) verso l'esterno; da lato a lato.
  void corner(double cx, double cy, double sx, double sy, bool first) {
    for (var i = 0; i <= steps; i++) {
      final t = (sx * sy > 0 ? i : steps - i) / steps * math.pi / 2;
      final x = cx + sx * radius * math.pow(math.cos(t), 2 / maskExponent);
      final y = cy + sy * radius * math.pow(math.sin(t), 2 / maskExponent);
      if (first && i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
  }

  corner(r.right - radius, r.bottom - radius, 1, 1, true);
  corner(r.left + radius, r.bottom - radius, -1, 1, false);
  corner(r.left + radius, r.top + radius, -1, -1, false);
  corner(r.right - radius, r.top + radius, 1, -1, false);
  return path..close();
}

/// Da dove viene l'icona.
sealed class IconSource {
  const IconSource();
}

class LayeredSource extends IconSource {
  const LayeredSource(this.icon);
  final LayeredIcon icon;
}

/// Una cartella: la cartella generica con simbolo e tinta, o quella semplice
/// (`resolveFolderIcon`).
class FolderSource extends IconSource {
  const FolderSource(this.folder);
  final FolderIcon folder;
}

/// Un file (`resolveFileIcon`): l'icona del tipo, o il file generico con l'estensione.
class FileSource extends IconSource {
  const FileSource(this.file);
  final FileIcon file;
}

/// Un file SVG o PNG già composto (tema freedesktop).
class FlatSource extends IconSource {
  const FlatSource(this.path);
  final String path;
}

/// L'icona di `side` × `side`. Per un'app `side` è il corpo e la tela sborda di
/// `side × 100 / 824` per lato, come nel disegno; per file, cartelle, volumi e Cestino `side`
/// è la tela intera (silica-icons 0.2: icon-format.md, "Principio"), salvo [besideApps].
class SilicaIcon extends StatelessWidget {
  const SilicaIcon(
    this.source, {
    super.key,
    required this.side,
    this.dark,
    this.badges = const {},
    this.env,
    this.besideApps = false,
  });

  /// Un luogo (cartella, Cestino) accanto alle app, come nel Dock: anche lui ha `side` per
  /// corpo e la tela delle app attorno.
  final bool besideApps;

  /// La tela dell'icona coincide con `side` (file, cartelle, volumi fuori dal Dock).
  bool get fullCanvas =>
      !besideApps &&
      switch (source) {
        FileSource() || FolderSource() => true,
        LayeredSource(:final icon) => icon.kind != IconKind.app,
        FlatSource() => false,
      };

  /// Il lato della tela 1024, in pt: con questo si confrontano le fasce `min_size`.
  double get canvasExtent => fullCanvas ? side : side * canvasSide / bodySide;

  /// I badge da sovrapporre (alias, illeggibile, bloccato, nuvola): quanti e dove dipende dal
  /// lato (icon-format.md, "Badge").
  final Set<IconBadge> badges;

  /// L'ambiente per trovare i badge (test).
  final Map<String, String>? env;

  final IconSource source;
  final double side;

  /// La variante scura. È lo stile delle icone (icons.md IC-01: Impostazioni › Aspetto ›
  /// Stile icone, "Scuro"), non l'aspetto del sistema: in aspetto scuro con lo stile normale
  /// le icone restano le stesse (appswitcher.md; mu20-list-dark). Null: chiara.
  final bool? dark;

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? false;
    final canvas = canvasExtent;
    final inset = (canvas - side) / 2;
    final body = Rect.fromLTWH(inset, inset, side, side);
    final Widget content = switch (source) {
      LayeredSource(:final icon) when icon.kind == IconKind.app => _layeredApp(
        icon,
        canvas,
        body,
        isDark,
      ),
      LayeredSource(:final icon) => Stack(
        children: [
          for (final layer in icon.layers)
            _svg(layer.pathFor(dark: isDark), canvas),
        ],
      ),
      FolderSource(:final folder) => _folder(folder, canvas, isDark),
      FlatSource(:final path) => _flat(path, canvas, body, isDark),
      FileSource(:final file) => _file(file, canvas, isDark),
    };
    // File, cartelle, volumi e Cestino sono piatti: l'ombra del contesto la mette chi li
    // disegna (icon-format.md › "Cosa NON va nei livelli"), sotto la forma del disegno.
    final grounded = switch (source) {
      LayeredSource(:final icon) => icon.kind != IconKind.app,
      FileSource() || FolderSource() => true,
      FlatSource() => false,
    };
    final shown = badges.isEmpty
        ? const <IconBadge>[]
        : visibleBadges(
            badges,
            canvas,
            order: findBadgeRules(env: env)?.order ?? IconBadge.values,
          );
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -inset,
            top: -inset,
            width: canvas,
            height: canvas,
            child: IgnorePointer(
              child: grounded ? _grounded(content, canvas) : content,
            ),
          ),
          for (final badge in shown) _badge(badge, canvas, inset, isDark),
        ],
      ),
    );
  }

  /// L'icona con la sua ombra a terra: la stessa forma, nera, sfocata e spostata in basso.
  Widget _grounded(Widget content, double canvas) =>
      _GroundShadow(shadow: IconShadow.forSide(canvas), child: content);

  /// Un badge sopra l'icona composta, senza ombra: lato 315/1024 della tela da 32 pt, 509 se è
  /// l'unico (16–31 pt); appoggiato all'angolo in basso del corpo delle app (100…924 sulla
  /// tela), non al disegno.
  Widget _badge(IconBadge badge, double canvas, double inset, bool isDark) {
    final path = findBadgeRules(env: env)?.pathFor(badge, dark: isDark);
    if (path == null) return const SizedBox.shrink();
    final scale = canvas / canvasSide;
    final edge = (canvas >= 32 ? 315.0 : 509.0) * scale;
    final near = bodyInset * scale - inset;
    final far = (bodyInset + bodySide) * scale - inset;
    // alias in basso a sinistra, gli altri in basso a destra.
    final left = badge == IconBadge.alias ? near : far - edge;
    // La tela 1024 del badge, scalata di edge/824, con il suo corpo sul riquadro.
    final k = edge / bodySide;
    return Positioned(
      left: left - bodyInset * k,
      top: far - edge - bodyInset * k,
      width: canvasSide * k,
      height: canvasSide * k,
      child: IgnorePointer(child: _svg(path, canvasSide * k)),
    );
  }

  /// Un file: i livelli e l'etichetta (l'estensione) nel suo riquadro, centrata sulla riga
  /// naturale di Inter; più larga del riquadro, il corpo scende (`shrink`).
  Widget _file(FileIcon file, double canvas, bool isDark) {
    final box = file.labelBox;
    final label = file.label;
    final scale = canvas / canvasSide;
    return Stack(
      children: [
        for (final layer in file.icon.layers)
          _svg(layer.pathFor(dark: isDark), canvas),
        if (box != null && label != null && canvas >= file.labelMinSide)
          Positioned(
            left: box.left * scale,
            top: box.top * scale,
            width: box.width * scale,
            height: box.height * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: uiFontFamily,
                  package: 'silica_ui',
                  fontWeight: FontWeight
                      .values[(file.labelWeight ~/ 100 - 1).clamp(0, 8)],
                  fontSize: file.labelSize * scale,
                  color: isDark ? file.labelColor?.$2 : file.labelColor?.$1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _layeredApp(LayeredIcon icon, double canvas, Rect body, bool isDark) {
    final shadow = side * layerShadowRatio;
    return Stack(
      children: [
        CustomPaint(
          size: Size.square(canvas),
          painter: _DropPainter(body, side),
        ),
        ClipPath(
          clipper: _BodyClipper(body),
          child: Stack(
            children: [
              for (final layer in icon.layers) ...[
                if (layer.shadow)
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: shadow,
                      sigmaY: shadow,
                    ),
                    child: Transform.translate(
                      offset: Offset(0, shadow),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          layerShadowColor,
                          BlendMode.srcIn,
                        ),
                        child: _svg(layer.pathFor(dark: isDark), canvas),
                      ),
                    ),
                  ),
                _svg(layer.pathFor(dark: isDark), canvas),
              ],
              switch (icon.dynamic) {
                ClockHands hands => _Clock(
                  hands: hands,
                  canvas: canvas,
                  dark: isDark,
                  seconds: side >= 64,
                ),
                CalendarText text => _Calendar(
                  text: text,
                  canvas: canvas,
                  dark: isDark,
                ),
                FolderSymbol() ||
                FileLabelRules() ||
                TypeLabel() ||
                null => const SizedBox.shrink(),
              },
            ],
          ),
        ),
        CustomPaint(
          size: Size.square(canvas),
          painter: _RimPainter(body, side, isDark),
        ),
      ],
    );
  }

  /// La cartella: livelli, simbolo inciso (riflesso spostato in basso, poi il simbolo) e
  /// tinta sulla luminanza del tutto (icon-format.md, "Cartella generica").
  Widget _folder(FolderIcon folder, double canvas, bool isDark) {
    final icon = folder.icon;
    final dyn = icon.dynamic;
    final children = <Widget>[
      for (final layer in icon.layers)
        _svg(layer.pathFor(dark: isDark), canvas),
    ];
    if (dyn is FolderSymbol) {
      final name = folder.symbol;
      final band = dyn.bandFor(canvas);
      final file = name == null || band == null
          ? null
          : dyn.symbolFile(name, band.weight);
      if (band != null && file != null) {
        final k = canvas / canvasSide;
        final box = dyn.box;
        final w = box.width * band.scale * k;
        final h = box.height * band.scale * k;
        final left = box.center.dx * k - w / 2;
        final top = box.center.dy * k - h / 2;
        final fx = isDark ? dyn.dark : dyn.light;
        Widget glyph(Color color, double opacity, double dy) => Positioned(
          left: left,
          top: top + dy,
          width: w,
          height: h,
          child: Opacity(
            opacity: opacity,
            child: SvgPicture.string(
              svgText(file),
              width: w,
              height: h,
              theme: SvgTheme(currentColor: color),
            ),
          ),
        );
        if (band.highlight && fx.highlightOpacity > 0) {
          children.add(
            glyph(
              fx.highlight,
              fx.highlightOpacity,
              math.max(fx.offset * k, 0.5),
            ),
          );
        }
        children.add(glyph(fx.color, fx.opacity, 0));
      }
    }
    final Widget stack = SizedBox.square(
      dimension: canvas,
      child: Stack(children: children),
    );
    final tint = folder.tint;
    final ramp = dyn is FolderSymbol
        ? (isDark ? dyn.darkTint : dyn.lightTint)
        : null;
    if (tint == null || ramp == null) return stack;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(ramp.matrix(tint)),
      child: stack,
    );
  }

  Widget _flat(String path, double canvas, Rect body, bool isDark) {
    final glyph = side * keylineSide / bodySide;
    final file = File(path);
    return Stack(
      children: [
        CustomPaint(
          size: Size.square(canvas),
          painter: _DropPainter(body, side),
        ),
        ClipPath(
          clipper: _BodyClipper(body),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark ? neutralDark : neutralLight,
              ),
            ),
            child: Center(
              child: path.endsWith('.svg')
                  ? SvgPicture.string(
                      svgText(path),
                      width: glyph,
                      height: glyph,
                    )
                  : Image.file(
                      file,
                      width: glyph,
                      height: glyph,
                      filterQuality: FilterQuality.medium,
                    ),
            ),
          ),
        ),
        CustomPaint(
          size: Size.square(canvas),
          painter: _RimPainter(body, side, isDark),
        ),
      ],
    );
  }
}

Widget _svg(String path, double canvas) =>
    SvgPicture.string(svgText(path), width: canvas, height: canvas);

/// Gli SVG esportati da Sketch usano i filtri, che flutter_svg non applica:
/// - i passaggi d'ombra (una copia del tracciato con un `filter`, nera per difetto) si
///   tolgono, altrimenti verrebbero disegnati neri pieni;
/// - ellissi e cerchi sfocati (ombre a terra, bagliori) diventano un gradiente radiale
///   che sfuma per ~2σ oltre il bordo;
/// - ogni altro attributo `filter` si ignora;
/// - il testo in Inter usa l'Inter del pacchetto silica_ui (Sketch scrive
///   `font-family="Inter-Regular_Medium, Inter"`).
final RegExp _filteredUse = RegExp(
  r'<use\b[^>]*\bfilter="[^"]*"[^>]*?(/>|>\s*</use>)',
);
final RegExp _blurredShape = RegExp(
  r'<(ellipse|circle)\b([^>]*?)\sfilter="url\(#([^)"]+)\)"([^>]*?)(/>|>\s*</\1>)',
);
final RegExp _filterAttribute = RegExp(r'\sfilter="[^"]*"');
final RegExp _interFamily = RegExp(r'font-family="[^"]*\bInter\b[^"]*"');

String withoutFilters(String svg) {
  var soft = 0;
  final shapes = svg.replaceAllMapped(_blurredShape, (m) {
    final attributes = '${m[2]}${m[4]}';
    String? attr(String name) =>
        RegExp('\\s$name="([^"]*)"').firstMatch(attributes)?.group(1);
    double number(String name, double fallback) =>
        double.tryParse(attr(name) ?? '') ?? fallback;
    final sigma =
        double.tryParse(
          RegExp(
                '<filter[^>]*id="${RegExp.escape(m[3]!)}"[^>]*>\\s*'
                '<feGaussianBlur[^>]*stdDeviation="([0-9.]+)"',
              ).firstMatch(svg)?.group(1) ??
              '',
        ) ??
        0;
    final cx = number('cx', 0);
    final cy = number('cy', 0);
    final rx = m[1] == 'circle' ? number('r', 0) : number('rx', 0);
    final ry = m[1] == 'circle' ? number('r', 0) : number('ry', 0);
    final fill = attr('fill') ?? '#000000';
    final alpha = number('fill-opacity', 1) * number('opacity', 1);
    if (rx <= 0 || ry <= 0 || !fill.startsWith('#')) return '';
    final grow = 2 * sigma;
    final inner =
        (math.min(rx, ry) - sigma).clamp(0, double.infinity) /
        (math.min(rx, ry) + grow);
    final id = 'silica-soft-${soft++}';
    return '<defs><radialGradient id="$id">'
        '<stop offset="0" stop-color="$fill" stop-opacity="$alpha"/>'
        '<stop offset="$inner" stop-color="$fill" stop-opacity="$alpha"/>'
        '<stop offset="1" stop-color="$fill" stop-opacity="0"/>'
        '</radialGradient></defs>'
        '<ellipse cx="$cx" cy="$cy" rx="${rx + grow}" ry="${ry + grow}" '
        'fill="url(#$id)"/>';
  });
  return shapes
      .replaceAll(_filteredUse, '')
      .replaceAll(_filterAttribute, '')
      .replaceAll(
        _interFamily,
        'font-family="packages/silica_ui/$uiFontFamily"',
      );
}

const String _emptySvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"/>';
final Map<String, String> _svgCache = {};

/// Il testo dell'SVG pronto per flutter_svg; vuoto se il file non si legge.
String svgText(String path) => _svgCache.putIfAbsent(path, () {
  try {
    return withoutFilters(File(path).readAsStringSync());
  } on FileSystemException {
    return _emptySvg;
  }
});

class _BodyClipper extends CustomClipper<Path> {
  const _BodyClipper(this.body);
  final Rect body;

  @override
  Path getClip(Size size) => iconBodyPath(body);

  @override
  bool shouldReclip(_BodyClipper old) => old.body != body;
}

class _DropPainter extends CustomPainter {
  const _DropPainter(this.body, this.side);
  final Rect body;
  final double side;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      iconBodyPath(body.shift(Offset(0, side * dropOffsetRatio))),
      Paint()
        ..color = dropColor
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          side * dropOffsetRatio,
        ),
    );
  }

  @override
  bool shouldRepaint(_DropPainter old) => old.body != body;
}

/// Il bordo luminoso del corpo: più chiaro in alto, sfuma in basso.
class _RimPainter extends CustomPainter {
  const _RimPainter(this.body, this.side, this.dark);
  final Rect body;
  final double side;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final width = math.max(1.0, side / 64);
    canvas.drawPath(
      iconBodyPath(body.deflate(width / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0x40FFFFFF), Color(0x0FFFFFFF)]
              : const [Color(0x80FFFFFF), Color(0x1AFFFFFF)],
        ).createShader(body),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.body != body || old.dark != dark;
}

/// Le lancette all'ora corrente: ore (h mod 12 + m/60 + s/3600) × 30°, minuti
/// (m + s/60) × 6°, secondi s × 6°; il perno sopra. I secondi solo da 64 pt.
class _Clock extends StatefulWidget {
  const _Clock({
    required this.hands,
    required this.canvas,
    required this.dark,
    required this.seconds,
  });

  final ClockHands hands;
  final double canvas;
  final bool dark;
  final bool seconds;

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_Clock old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(
      widget.seconds ? const Duration(seconds: 1) : const Duration(seconds: 20),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _now.second.toDouble();
    final m = _now.minute + s / 60;
    final h = _now.hour % 12 + m / 60;
    Widget hand(IconLayer layer, double degrees) => Transform.rotate(
      angle: degrees * math.pi / 180,
      child: _svg(layer.pathFor(dark: widget.dark), widget.canvas),
    );
    return Stack(
      children: [
        hand(widget.hands.hour, h * 30),
        hand(widget.hands.minute, m * 6),
        if (widget.seconds)
          if (widget.hands.second case final second?) hand(second, s * 6),
        _svg(widget.hands.cap.pathFor(dark: widget.dark), widget.canvas),
      ],
    );
  }
}

/// Mese e giorno di oggi, aggiornati a mezzanotte.
class _Calendar extends StatefulWidget {
  const _Calendar({
    required this.text,
    required this.canvas,
    required this.dark,
  });

  final CalendarText text;
  final double canvas;
  final bool dark;

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  Timer? _timer;
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now) + const Duration(seconds: 1), () {
      setState(() => _today = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.canvas / canvasSide;
    Widget line(IconText t, String value) {
      final style =
          uiText(
            size: t.size * k,
            color: widget.dark ? t.darkColor : t.color,
          ).copyWith(
            fontWeight: FontWeight.values[(t.weight ~/ 100 - 1).clamp(0, 8)],
            letterSpacing: t.tracking * k,
            height: 1,
          );
      final width = (t.maxWidth ?? t.box.width) * k;
      return Positioned(
        left: t.box.left * k,
        top: t.box.top * k,
        width: t.box.width * k,
        height: t.box.height * k,
        child: Center(
          child: SizedBox(
            width: width,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                t.upper ? value.toUpperCase() : value,
                style: style,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        line(widget.text.month, monthNames[_today.month - 1]),
        line(widget.text.day, '${_today.day}'),
      ],
    );
  }
}

/// Dipinge il figlio due volte: prima nero, sfocato e spostato (l'ombra), poi com'è. Un solo
/// figlio nell'albero (niente testi doppi per chi cerca nei widget).
class _GroundShadow extends SingleChildRenderObjectWidget {
  const _GroundShadow({required this.shadow, super.child});
  final IconShadow shadow;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGroundShadow(shadow);

  @override
  void updateRenderObject(BuildContext context, _RenderGroundShadow render) =>
      render.shadow = shadow;
}

class _RenderGroundShadow extends RenderProxyBox {
  _RenderGroundShadow(this._shadow);

  IconShadow _shadow;
  set shadow(IconShadow value) {
    if (value.opacity == _shadow.opacity &&
        value.sigma == _shadow.sigma &&
        value.offset == _shadow.offset) {
      return;
    }
    _shadow = value;
    markNeedsPaint();
  }

  final LayerHandle<ImageFilterLayer> _layer = LayerHandle<ImageFilterLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final filter = ImageFilter.compose(
      outer: ImageFilter.blur(
        sigmaX: _shadow.sigma,
        sigmaY: _shadow.sigma,
        tileMode: TileMode.decal,
      ),
      inner: ColorFilter.mode(
        Color.fromRGBO(0, 0, 0, _shadow.opacity),
        BlendMode.srcIn,
      ),
    );
    final layer = (_layer.layer ??= ImageFilterLayer())..imageFilter = filter;
    context.pushLayer(
      layer,
      (context, offset) => context.paintChild(child, offset),
      offset + Offset(0, _shadow.offset),
    );
    context.paintChild(child, offset);
  }

  @override
  void dispose() {
    _layer.layer = null;
    super.dispose();
  }
}
