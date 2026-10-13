// Menu a tendina e contestuali: un pannello di vetro spesso con voci da 24 pt, separatori da
// 11 pt, intestazioni di sezione, spunte, scorciatoie e sottomenu.
//
// Metriche (pt): margine interno 5 sopra e sotto; testo a 17 dal bordo (38 con le icone, 50
// con spunte e icone), corpo 13; scorciatoie e freccia del sottomenu che finiscono a 20 dal
// bordo destro; evidenziazione blu (#007aff) a 5 pt dai lati, raggio 8, testo bianco;
// separatore di 1 pt al centro dei suoi 11, a 16 pt dai lati; raggio del pannello 12.
// Un sottomenu si apre ~295 ms dopo l'arrivo del puntatore sulla sua voce, 5 pt sopra la
// voce e sovrapposto di 5 pt al menu madre; resta aperto mentre il puntatore va in diagonale
// verso di lui (tolleranza a triangolo). Scelta: la voce lampeggia (spenta subito, riaccesa a
// ~74 ms) e il menu sfuma in ~190 ms da ~114 ms; Esc sfuma allo stesso modo.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../silica_ui.dart' show uiFontFamily;
import 'glass.dart';
import 'liquid_glass.dart';

/// Una riga di un menu.
@immutable
sealed class MenuEntry {
  const MenuEntry();
}

/// Una voce: etichetta, scorciatoia, spunta, icona, sottomenu.
class MenuAction extends MenuEntry {
  const MenuAction(
    this.label, {
    this.shortcut,
    this.icon,
    this.checked = false,
    this.enabled = true,
    this.onSelected,
    this.submenu,
  });

  final String label;

  /// Testo della scorciatoia, già con i simboli dei modificatori (es. "⌘N").
  final String? shortcut;

  /// Un'icona di ~14 pt, disegnata nel colore che riceve.
  final Widget Function(Color color)? icon;
  final bool checked;
  final bool enabled;
  final VoidCallback? onSelected;
  final List<MenuEntry>? submenu;

  bool get selectable => enabled && (submenu == null || submenu!.isNotEmpty);
}

/// Linea di separazione.
class MenuDivider extends MenuEntry {
  const MenuDivider();
}

/// Intestazione grigia di un gruppo, non selezionabile.
class MenuSection extends MenuEntry {
  const MenuSection(this.label);
  final String label;
}

/// Le misure dei menu.
abstract final class MenuMetrics {
  static const double itemHeight = 24;
  static const double dividerHeight = 11;
  static const double sectionHeight = 24;
  static const double padding = 5;
  static const double radius = 12;
  static const double textLeft = 17;
  static const double textLeftIcons = 38;
  static const double textLeftChecks = 29;
  static const double textLeftBoth = 50;
  static const double checkLeft = 12;
  static const double iconLeftChecks = 29;
  static const double iconLeft = 16;
  static const double right = 20;
  static const double highlightInset = 5;
  static const double highlightRadius = 8;
  static const double dividerInset = 16;
  static const double fontSize = 13;
  static const double sectionFontSize = 11;
  static const double shortcutGap = 32;
  static const double chevronWidth = 6;
  static const double minWidth = 120;

  /// Sottomenu: sovrapposto di 5 pt e 5 pt sopra la voce.
  static const double submenuOverlap = 5;
  static const Duration submenuDelay = Duration(milliseconds: 295);
  static const Duration triangleGrace = Duration(milliseconds: 300);

  /// Lampeggio e dissolvenza della scelta.
  static const Duration blinkOff = Duration(milliseconds: 7);
  static const Duration blinkOn = Duration(milliseconds: 74);
  static const Duration fadeStart = Duration(milliseconds: 114);
  static const Duration fade = Duration(milliseconds: 190);
}

/// Colori dell'aspetto chiaro.
abstract final class MenuColors {
  static const Color text = Color(0xD9000000);
  static const Color disabled = Color(0x42000000);
  static const Color shortcut = Color(0x4D000000);
  static const Color section = Color(0x42000000);
  static const Color divider = Color(0x1A000000);
  static const Color highlight = Color(0xFF007AFF);
  static const Color highlightText = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x33000000);
}

TextStyle _style(double size, Color color, {FontWeight? weight}) => TextStyle(
  fontFamily: uiFontFamily,
  package: 'silica_ui',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1,
);

double _textWidth(String text, TextStyle style) => (TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout()).width;

double _entryHeight(MenuEntry entry) => switch (entry) {
  MenuAction() => MenuMetrics.itemHeight,
  MenuDivider() => MenuMetrics.dividerHeight,
  MenuSection() => MenuMetrics.sectionHeight,
};

/// La colonna del testo: dipende da spunte e icone presenti nel menu.
double menuTextLeft(List<MenuEntry> entries) {
  final actions = entries.whereType<MenuAction>();
  final checks = actions.any((a) => a.checked);
  final icons = actions.any((a) => a.icon != null);
  return switch ((checks, icons)) {
    (true, true) => MenuMetrics.textLeftBoth,
    (false, true) => MenuMetrics.textLeftIcons,
    (true, false) => MenuMetrics.textLeftChecks,
    (false, false) => MenuMetrics.textLeft,
  };
}

/// La dimensione del pannello di un menu.
Size menuSize(List<MenuEntry> entries) {
  final left = menuTextLeft(entries);
  var width = MenuMetrics.minWidth;
  for (final entry in entries) {
    final w = switch (entry) {
      MenuAction(:final label, :final shortcut, :final submenu) =>
        left +
            _textWidth(label, _style(MenuMetrics.fontSize, MenuColors.text)) +
            (shortcut != null
                ? MenuMetrics.shortcutGap +
                      _textWidth(
                        shortcut,
                        _style(MenuMetrics.fontSize, MenuColors.shortcut),
                      )
                : submenu != null
                ? MenuMetrics.shortcutGap + MenuMetrics.chevronWidth
                : 0) +
            MenuMetrics.right,
      MenuSection(:final label) =>
        MenuMetrics.textLeft +
            _textWidth(
              label,
              _style(MenuMetrics.sectionFontSize, MenuColors.section),
            ) +
            MenuMetrics.right,
      MenuDivider() => 0.0,
    };
    if (w > width) width = w;
  }
  final height =
      2 * MenuMetrics.padding +
      entries.fold<double>(0, (h, e) => h + _entryHeight(e));
  return Size(width.ceilToDouble(), height);
}

/// La cima di ogni riga, dal bordo superiore del pannello.
List<double> menuRowTops(List<MenuEntry> entries) {
  final tops = <double>[];
  var y = MenuMetrics.padding;
  for (final entry in entries) {
    tops.add(y);
    y += _entryHeight(entry);
  }
  return tops;
}

/// Un menu aperto: le voci, il rettangolo e la voce evidenziata.
class _Level {
  _Level(this.entries, this.rect);
  final List<MenuEntry> entries;
  final Rect rect;
  int? highlighted;
  late final List<double> tops = menuRowTops(entries);

  int? rowAt(Offset p) {
    if (!rect.contains(p)) return null;
    final y = p.dy - rect.top;
    for (var i = 0; i < entries.length; i++) {
      if (y >= tops[i] && y < tops[i] + _entryHeight(entries[i])) return i;
    }
    return null;
  }
}

/// Un menu con i suoi sottomenu, disegnato in un'area che lo contiene (un layer a schermo
/// intero, la superficie della barra allungata). Il menu principale sta con l'angolo in alto a
/// sinistra in `anchor`, o con il bordo inferiore lì se `upwards`.
class MenuHost extends StatefulWidget {
  const MenuHost({
    super.key,
    required this.entries,
    required this.anchor,
    this.upwards = false,
    this.onDismissed,
    this.onNext,
    this.onPrevious,
    this.autofocus = true,
  });

  final List<MenuEntry> entries;
  final Offset anchor;
  final bool upwards;

  /// Il menu è sparito (scelta, Esc o clic fuori), a dissolvenza finita.
  final VoidCallback? onDismissed;

  /// → e ← senza sottomenu: il menu accanto (nella barra).
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool autofocus;

  @override
  State<MenuHost> createState() => MenuHostState();
}

class MenuHostState extends State<MenuHost>
    with SingleTickerProviderStateMixin {
  final List<_Level> _levels = [];
  final FocusNode _focus = FocusNode();
  Timer? _submenuTimer;
  Timer? _graceTimer;
  Offset? _lastPointer;
  bool _blinkHidden = false;
  bool _closing = false;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: MenuMetrics.fade,
    value: 1,
  )..addListener(() => setState(() {}));

  /// I rettangoli dei menu aperti (per la regione d'input).
  List<Rect> get rects => [for (final l in _levels) l.rect];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(MenuHost old) {
    super.didUpdateWidget(old);
    if (old.entries != widget.entries || old.anchor != widget.anchor) _reset();
  }

  void _reset() {
    _levels.clear();
    final size = menuSize(widget.entries);
    final origin = widget.upwards
        ? widget.anchor - Offset(0, size.height)
        : widget.anchor;
    _levels.add(_Level(widget.entries, origin & size));
    _closing = false;
    _blinkHidden = false;
    _fade.value = 1;
  }

  @override
  void dispose() {
    _submenuTimer?.cancel();
    _graceTimer?.cancel();
    _fade.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openSubmenu(int level, int row) {
    final parent = _levels[level];
    final entry = parent.entries[row];
    if (entry is! MenuAction || entry.submenu == null || !entry.enabled) return;
    final size = menuSize(entry.submenu!);
    final origin = Offset(
      parent.rect.right - MenuMetrics.submenuOverlap,
      parent.rect.top + parent.tops[row] - MenuMetrics.padding,
    );
    setState(() {
      _levels.removeRange(level + 1, _levels.length);
      _levels.add(_Level(entry.submenu!, origin & size));
    });
  }

  /// Il puntatore va verso il sottomenu aperto: dentro il triangolo fra la posizione di
  /// prima e il lato sinistro del sottomenu.
  bool _towardSubmenu(int level, Offset p) {
    final from = _lastPointer;
    if (from == null || level + 1 >= _levels.length) return false;
    final sub = _levels[level + 1].rect;
    if (p.dx <= from.dx) return false;
    double cross(Offset a, Offset b, Offset c) =>
        (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
    final a = from, b = sub.topLeft, c = sub.bottomLeft;
    final d1 = cross(a, b, p), d2 = cross(b, c, p), d3 = cross(c, a, p);
    final negative = d1 < 0 || d2 < 0 || d3 < 0;
    final positive = d1 > 0 || d2 > 0 || d3 > 0;
    return !(negative && positive);
  }

  void _hover(Offset p) {
    if (_closing) return;
    for (var level = _levels.length - 1; level >= 0; level--) {
      final row = _levels[level].rowAt(p);
      if (row == null && !_levels[level].rect.contains(p)) continue;
      // Verso il sottomenu: la voce madre resta evidenziata ancora per un po'.
      if (level + 1 < _levels.length && _towardSubmenu(level, p)) {
        _graceTimer ??= Timer(MenuMetrics.triangleGrace, () {
          _graceTimer = null;
          if (_lastPointer case final last?) _hover(last);
        });
        _lastPointer = p;
        return;
      }
      _graceTimer?.cancel();
      _graceTimer = null;
      final current = _levels[level];
      final entry = row == null ? null : current.entries[row];
      final selectable = entry is MenuAction && entry.selectable;
      setState(() {
        current.highlighted = selectable ? row : null;
        // Su un'altra voce il sottomenu di prima si chiude.
        if (level + 1 < _levels.length) {
          _levels.removeRange(level + 1, _levels.length);
        }
      });
      _submenuTimer?.cancel();
      if (selectable && entry.submenu != null && row != null) {
        _submenuTimer = Timer(
          MenuMetrics.submenuDelay,
          () => _openSubmenu(level, row),
        );
      }
      _lastPointer = p;
      return;
    }
    _lastPointer = p;
  }

  void _press(Offset p) {
    for (var level = _levels.length - 1; level >= 0; level--) {
      final row = _levels[level].rowAt(p);
      if (row == null) {
        if (_levels[level].rect.contains(p)) return;
        continue;
      }
      final entry = _levels[level].entries[row];
      if (entry is! MenuAction || !entry.selectable) return;
      if (entry.submenu != null) {
        _submenuTimer?.cancel();
        _openSubmenu(level, row);
        return;
      }
      _choose(level, row);
      return;
    }
    // Fuori da tutti i menu: si chiude senza scegliere.
    close();
  }

  /// Sceglie una voce: lampeggio, poi l'azione e la dissolvenza.
  Future<void> _choose(int level, int row) async {
    if (_closing) return;
    final entry = _levels[level].entries[row];
    if (entry is! MenuAction) return;
    _closing = true;
    setState(() => _levels[level].highlighted = row);
    await Future<void>.delayed(MenuMetrics.blinkOff);
    if (!mounted) return;
    setState(() => _blinkHidden = true);
    await Future<void>.delayed(MenuMetrics.blinkOn - MenuMetrics.blinkOff);
    if (!mounted) return;
    setState(() => _blinkHidden = false);
    await Future<void>.delayed(MenuMetrics.fadeStart - MenuMetrics.blinkOn);
    if (!mounted) return;
    entry.onSelected?.call();
    await _fade.animateTo(0);
    widget.onDismissed?.call();
  }

  /// Chiude con la dissolvenza (Esc, clic fuori).
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    _submenuTimer?.cancel();
    await _fade.animateTo(0);
    widget.onDismissed?.call();
  }

  int? _step(_Level level, int from, int delta) {
    final n = level.entries.length;
    for (var k = 1; k <= n; k++) {
      final i = (from + delta * k) % n;
      final e = level.entries[i];
      if (e is MenuAction && e.selectable) return i;
    }
    return null;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_closing || _levels.isEmpty) return KeyEventResult.handled;
    final depth = _levels.length - 1;
    final level = _levels[depth];
    final current = level.highlighted;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        close();
      case LogicalKeyboardKey.arrowDown:
        setState(() => level.highlighted = _step(level, current ?? -1, 1));
      case LogicalKeyboardKey.arrowUp:
        setState(
          () => level.highlighted = _step(
            level,
            current ?? level.entries.length,
            -1,
          ),
        );
      case LogicalKeyboardKey.arrowRight:
        final entry = current == null ? null : level.entries[current];
        if (entry is MenuAction && entry.submenu != null && current != null) {
          _openSubmenu(depth, current);
          final sub = _levels.last;
          setState(() => sub.highlighted = _step(sub, -1, 1));
        } else {
          widget.onNext?.call();
        }
      case LogicalKeyboardKey.arrowLeft:
        if (depth > 0) {
          setState(() => _levels.removeLast());
        } else {
          widget.onPrevious?.call();
        }
      case LogicalKeyboardKey.enter ||
          LogicalKeyboardKey.numpadEnter ||
          LogicalKeyboardKey.space:
        if (current != null) {
          final entry = level.entries[current];
          if (entry is MenuAction && entry.submenu != null) {
            _openSubmenu(depth, current);
          } else {
            _choose(depth, current);
          }
        }
      default:
        // Una lettera: la prima voce che comincia così.
        final char = event.character?.toLowerCase();
        if (char == null || char.trim().isEmpty) return KeyEventResult.ignored;
        final index = level.entries.indexWhere(
          (e) =>
              e is MenuAction &&
              e.selectable &&
              e.label.toLowerCase().startsWith(char),
        );
        if (index < 0) return KeyEventResult.ignored;
        setState(() => level.highlighted = index);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onKeyEvent: _key,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: (e) => _hover(e.localPosition),
        onPointerMove: (e) => _hover(e.localPosition),
        onPointerUp: (e) {
          // Pressione su una voce della barra, trascinamento e rilascio su una voce: sceglie.
          for (var level = _levels.length - 1; level >= 0; level--) {
            final row = _levels[level].rowAt(e.localPosition);
            if (row != null && _levels[level].highlighted == row) {
              final entry = _levels[level].entries[row];
              if (entry is MenuAction &&
                  entry.selectable &&
                  entry.submenu == null) {
                _choose(level, row);
              }
              return;
            }
          }
        },
        onPointerDown: (e) => _press(e.localPosition),
        child: Opacity(
          opacity: _fade.value,
          child: Stack(
            children: [
              for (final level in _levels)
                Positioned.fromRect(
                  rect: level.rect,
                  child: MenuPanel(
                    entries: level.entries,
                    highlighted: _blinkHidden ? null : level.highlighted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il pannello di un menu: vetro, ombra, righe. La dimensione la decide chi lo posiziona
/// (`menuSize`).
class MenuPanel extends StatelessWidget {
  const MenuPanel({super.key, required this.entries, this.highlighted});

  final List<MenuEntry> entries;
  final int? highlighted;

  @override
  Widget build(BuildContext context) {
    final left = menuTextLeft(entries);
    final checks = entries.whereType<MenuAction>().any((a) => a.checked);
    final tops = menuRowTops(entries);
    return CustomPaint(
      painter: const _MenuShadow(),
      child: LiquidGlass(
        radius: MenuMetrics.radius,
        material: GlassMaterial.thick,
        interactive: false,
        child: Stack(
          children: [
            for (var i = 0; i < entries.length; i++)
              Positioned(
                left: 0,
                right: 0,
                top: tops[i],
                height: _entryHeight(entries[i]),
                child: _row(entries[i], i == highlighted, left, checks),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(MenuEntry entry, bool lit, double textLeft, bool checks) {
    switch (entry) {
      case MenuDivider():
        return Center(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(
              horizontal: MenuMetrics.dividerInset,
            ),
            color: MenuColors.divider,
          ),
        );
      case MenuSection(:final label):
        return Padding(
          padding: const EdgeInsets.only(left: MenuMetrics.textLeft),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: _style(
                MenuMetrics.sectionFontSize,
                MenuColors.section,
                weight: FontWeight.w600,
              ),
            ),
          ),
        );
      case MenuAction(
        :final label,
        :final shortcut,
        :final icon,
        :final checked,
        :final submenu,
      ):
        final color = lit
            ? MenuColors.highlightText
            : entry.enabled
            ? MenuColors.text
            : MenuColors.disabled;
        final minor = lit ? MenuColors.highlightText : MenuColors.shortcut;
        return Stack(
          children: [
            if (lit)
              Positioned.fill(
                left: MenuMetrics.highlightInset,
                right: MenuMetrics.highlightInset,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: MenuColors.highlight,
                    borderRadius: BorderRadius.all(
                      Radius.circular(MenuMetrics.highlightRadius),
                    ),
                  ),
                ),
              ),
            if (checked)
              Positioned(
                left: MenuMetrics.checkLeft,
                top: 7,
                width: 9,
                height: 10,
                child: CustomPaint(painter: _CheckPainter(color)),
              ),
            if (icon != null)
              Positioned(
                left: checks
                    ? MenuMetrics.iconLeftChecks
                    : MenuMetrics.iconLeft,
                top: 5,
                width: 14,
                height: 14,
                child: icon(color),
              ),
            Positioned(
              left: textLeft,
              right: MenuMetrics.right,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(MenuMetrics.fontSize, color),
                ),
              ),
            ),
            if (shortcut != null)
              Positioned(
                right: MenuMetrics.right,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    shortcut,
                    style: _style(
                      MenuMetrics.fontSize,
                      entry.enabled ? minor : MenuColors.disabled,
                    ),
                  ),
                ),
              ),
            if (submenu != null)
              Positioned(
                right: MenuMetrics.right,
                top: 7.5,
                width: MenuMetrics.chevronWidth,
                height: 9,
                child: CustomPaint(painter: _ChevronPainter(color)),
              ),
          ],
        );
    }
  }
}

/// Ombra fuori dal pannello: più lunga in basso (~20 pt) che ai lati (~16 pt).
class _MenuShadow extends CustomPainter {
  const _MenuShadow();

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(MenuMetrics.radius),
    );
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect((Offset.zero & size).inflate(60))
          ..addRRect(body),
      )
      ..drawRRect(
        body.shift(const Offset(0, 4)),
        Paint()
          ..color = MenuColors.shadow
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            Shadow.convertRadiusToSigma(16),
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_MenuShadow old) => false;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0.8, size.height * 0.55)
        ..lineTo(size.width * 0.38, size.height - 1)
        ..lineTo(size.width - 0.5, 1),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0.8, 0.8)
        ..lineTo(size.width - 0.8, size.height / 2)
        ..lineTo(0.8, size.height - 0.8),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
