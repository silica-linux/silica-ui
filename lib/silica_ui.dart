/// Design system di Silica per Flutter.
library;

import 'package:flutter/widgets.dart';

export 'src/alert.dart';
export 'src/drag.dart';
export 'src/glass.dart';
export 'src/icons/silica_icon.dart'
    show
        SilicaIcon,
        IconSource,
        LayeredSource,
        FolderSource,
        FlatSource,
        FileSource,
        IconShadow,
        iconBodyPath;
export 'src/icons/file_icons.dart';
export 'src/icons/mime.dart';
export 'src/icons/silica_icons.dart';
export 'src/liquid_glass.dart';
export 'src/menu.dart';
export 'src/window.dart';
export 'src/window_glass.dart';

/// Il font dell'interfaccia: Inter (OFL), servito dal pacchetto.
const String uiFontFamily = 'Inter';

/// Uno stile di testo in Inter, servito da questo pacchetto.
TextStyle uiText({required double size, required Color color}) => TextStyle(
  fontFamily: uiFontFamily,
  package: 'silica_ui',
  fontSize: size,
  color: color,
);
