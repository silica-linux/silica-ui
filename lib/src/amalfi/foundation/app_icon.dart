// The 16 pt icon of an app in a menu row (kit `Icons/App/16/<App>`), drawn from the app's own
// layers in silica-icons (`apps/<id>/icon.json`), not from a separate asset.

import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../icons/silica_icon.dart';
import '../../icons/silica_icons.dart';
import '../theme.dart';

/// The icon of the app [id], the `X-Silica-Icon` of its desktop entry: a silica-icons name
/// (folder `apps/<id>`, e.g. `photo-viewer`) or the absolute path of the `icon/` folder the app
/// carries, on a [size]
/// pt canvas (16 by default: `AmalfiMenuAction.icon` and `AmalfiMenuItem.icon`). It follows the theme's
/// brightness (the kit has a Light and a Dark master per app). Without such an icon it leaves
/// the box empty, so the labels still line up.
class AmalfiAppIcon extends StatelessWidget {
  const AmalfiAppIcon(this.id, {super.key, this.size = 16, this.env});

  /// The silica-icons id of the app.
  final String id;

  /// The side of the icon canvas (body and shadow margin), in pt.
  final double size;

  /// The environment for finding the icons (tests); null: the process one.
  final Map<String, String>? env;

  @override
  Widget build(BuildContext context) {
    final icon = id.startsWith('/')
        ? _fromFolder(id)
        : findSilicaIcon(id, env: env);
    final dark = AmalfiTheme.maybeOf(context)?.isDark ?? false;
    return SizedBox.square(
      dimension: size,
      child: icon == null
          ? null
          : Center(
              // The kit's 16 pt image is the whole 1024 canvas: the body is 824/1024 of it.
              child: SilicaIcon(
                LayeredSource(icon),
                side: size * bodySide / canvasSide,
                dark: dark,
                env: env,
              ),
            ),
    );
  }
}

final Map<String, LayeredIcon?> _folders = {};

LayeredIcon? _fromFolder(String dir) => _folders.putIfAbsent(dir, () {
  try {
    return parseManifest(dir, File('$dir/icon.json').readAsStringSync());
  } on FileSystemException {
    return null;
  }
});
