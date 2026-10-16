import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

const String svg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
    '<rect x="100" y="100" width="824" height="824" fill="#ffffff"/></svg>';

String manifest(String id, {Object? dynamic}) => jsonEncode({
  'format': 1,
  'id': id,
  'name': id,
  'kind': 'file',
  'layers': [
    {'role': 'artwork', 'file': 'icon.svg'},
  ],
  'dynamic': dynamic,
});

const Map<String, Object> labelRules = {
  'type': 'file-label',
  'label': {
    'size': 160,
    'box': [245, 376, 534, 194],
    'max_chars': 4,
    'max_width': 534,
  },
  'colors': {
    'document': {'color': '#2f7cf6', 'dark_color': '#5aa0ff'},
    'data': {'color': '#1f9d55'},
    'code': {'color': '#ff6a00'},
    'other': {'color': '#636366'},
  },
  'overrides': {
    'json': 'data',
    'skt': {'color': '#f7b500'},
  },
  'icons': {
    'mime': {
      'application/pdf': 'file-pdf',
      'text/plain': 'file-text',
      'image/*': 'file-image',
      'application/x-shellscript': 'file-executable',
      'application/json': 'file-generic',
    },
    'extensions': {'pdf': 'file-pdf', 'xlsx': 'file-spreadsheet'},
  },
  'fallback': 'file-unknown',
};

/// A fake repo: the generic file with the rules, some type icons and the badges.
Directory iconTree() {
  final root = Directory.systemTemp.createTempSync('silica-file-icons-');
  for (final id in [
    'file-pdf',
    'file-text',
    'file-image',
    'file-executable',
    'file-spreadsheet',
    'file-unknown',
  ]) {
    Directory('${root.path}/files/$id').createSync(recursive: true);
    File('${root.path}/files/$id/icon.json').writeAsStringSync(manifest(id));
    File('${root.path}/files/$id/icon.svg').writeAsStringSync(svg);
  }
  Directory('${root.path}/files/file-generic').createSync(recursive: true);
  File(
    '${root.path}/files/file-generic/icon.json',
  ).writeAsStringSync(manifest('file-generic', dynamic: labelRules));
  File('${root.path}/files/file-generic/icon.svg').writeAsStringSync(svg);
  Directory('${root.path}/badges').createSync();
  for (final name in ['alias', 'unreadable', 'locked', 'cloud']) {
    File('${root.path}/badges/$name.svg').writeAsStringSync(svg);
  }
  File('${root.path}/badges/badges.json').writeAsStringSync(
    jsonEncode({
      'format': 1,
      'order': ['unreadable', 'alias', 'locked', 'cloud'],
      'badges': {
        for (final name in ['alias', 'unreadable', 'locked', 'cloud'])
          name: {'file': '$name.svg'},
      },
    }),
  );
  return root;
}

final MimeDatabase mime = MimeDatabase.fromText(
  globs2: '''
50:application/pdf:*.pdf
50:text/plain:*.txt
50:image/png:*.png
50:application/json:*.json
50:application/x-shellscript:*.sh
50:text/x-csrc:*.c
50:application/gzip:*.gz
50:application/x-compressed-tar:*.tar.gz
50:text/x-makefile:Makefile
10:text/x-readme:README*
50:application/vnd.ms-excel:*.xls
''',
  subclasses: '''
application/x-shellscript text/plain
text/x-csrc text/plain
application/json application/javascript
''',
  aliases: 'application/x-pdf application/pdf',
);

void main() {
  test('MIME: longest glob, case, literals, parents, aliases', () {
    expect(mime.typeForName('a.pdf'), 'application/pdf');
    expect(mime.typeForName('A.PDF'), 'application/pdf');
    expect(mime.typeForName('x.tar.gz'), 'application/x-compressed-tar');
    expect(mime.typeForName('Makefile'), 'text/x-makefile');
    expect(mime.typeForName('README.it'), 'text/x-readme');
    expect(mime.typeForName('senza'), isNull);
    expect(mime.parentsOf('text/x-csrc'), ['text/plain']);
    expect(mime.parentsOf('text/x-readme'), ['text/plain']);
    expect(mime.canonical('application/x-pdf'), 'application/pdf');
    final ambiguous = MimeDatabase.fromText(
      globs2:
          '50:text/vnd.trolltech.linguist:*.ts\n50:video/mp2t:*.ts\n'
          '50:application/pdf:*.pdf\n',
    );
    expect(ambiguous.isAmbiguousName('main.ts'), isTrue);
    expect(ambiguous.isAmbiguousName('a.pdf'), isFalse);
  });

  test('MIME from the content: ELF, script, text, binary, empty', () {
    final dir = Directory.systemTemp.createTempSync('mime-');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(
      '${dir.path}/prog',
    ).writeAsBytesSync([0x7f, 0x45, 0x4c, 0x46, ...List.filled(12, 0), 2, 0]);
    File(
      '${dir.path}/lib',
    ).writeAsBytesSync([0x7f, 0x45, 0x4c, 0x46, ...List.filled(12, 0), 3, 0]);
    File('${dir.path}/avvia').writeAsStringSync('#!/bin/bash\necho ciao\n');
    File('${dir.path}/note').writeAsStringSync('solo testo\n');
    File('${dir.path}/dati').writeAsBytesSync([1, 2, 0, 3]);
    File('${dir.path}/vuoto').writeAsBytesSync([]);
    expect(mime.typeOf('${dir.path}/prog'), 'application/x-executable');
    expect(mime.typeOf('${dir.path}/lib'), 'application/x-sharedlib');
    expect(mime.typeOf('${dir.path}/avvia'), 'application/x-shellscript');
    expect(mime.typeOf('${dir.path}/note'), 'text/plain');
    expect(mime.typeOf('${dir.path}/dati'), octetStream);
    expect(mime.typeOf('${dir.path}/vuoto'), 'application/x-zerosize');
    expect(mime.typeOf('${dir.path}/sparito'), octetStream);
  });

  group('file icon', () {
    late Directory root;
    late Map<String, String> env;

    setUp(() {
      root = iconTree();
      env = {'SILICA_ICONS_DIR': root.path};
    });
    tearDown(() => root.deleteSync(recursive: true));

    FileIcon? resolve(String name, {bool? executable}) => resolveFileIcon(
      '/no/folder/$name',
      mime: mime,
      env: env,
      executable: executable,
      type: mime.typeForName(name) ?? octetStream,
    );

    test('new type layout: borrowed sheet, mark and rendered PNG', () {
      final dir = '${root.path}/files/file-pdf';
      File('$dir/mark.svg').writeAsStringSync(svg);
      File('$dir/icon.png').writeAsBytesSync([0]);
      File('$dir/icon.json').writeAsStringSync(
        jsonEncode({
          'format': 1,
          'id': 'file-pdf',
          'kind': 'file',
          'layers': [
            {'role': 'page', 'icon': 'file-generic'},
            {'role': 'mark', 'file': 'mark.svg'},
          ],
          'variants': null,
          'rendered': {'default': 'icon.png'},
        }),
      );
      final icon = resolve('a.pdf')?.icon;
      expect(icon?.id, 'file-pdf');
      expect(icon?.layers.length, 2);
      expect(icon?.layers.last.path, endsWith('file-pdf/mark.svg'));
      expect(icon?.renderedFor(IconAppearance.light), '$dir/icon.png');
    });

    test('order: type, type with *, parents, extension, label', () {
      expect(resolve('a.pdf')?.icon.id, 'file-pdf');
      expect(resolve('photo.png')?.icon.id, 'file-image');
      // text/x-csrc is not in the map, its parent text/plain is.
      expect(resolve('main.c')?.icon.id, 'file-text');
      expect(resolve('conti.xls')?.icon.id, 'file-generic');
      expect(resolve('conti.xlsx')?.icon.id, 'file-spreadsheet');
      final json = resolve('dati.json');
      expect(json?.icon.id, 'file-generic');
      expect(json?.label, 'JSON');
      expect(json?.labelColor?.$1, const Color(0xFF1F9D55));
      // The explicit entry wins over the parent (application/javascript), with the label.
      expect(json?.labelBox, isNotNull);
      expect(resolve('progetto.skt')?.labelColor?.$1, const Color(0xFFF7B500));
      expect(resolve('LEGGIMI')?.icon.id, 'file-unknown');
      expect(resolve('troppo.lunghissima')?.icon.id, 'file-unknown');
    });

    test(
      'executable without extension: file-executable only with the x bit',
      () {
        final dir = Directory.systemTemp.createTempSync('exec-');
        addTearDown(() => dir.deleteSync(recursive: true));
        final script = File('${dir.path}/avvia')
          ..writeAsStringSync('#!/bin/sh\n');
        expect(
          resolveFileIcon(
            script.path,
            mime: mime,
            env: env,
            executable: true,
          )?.icon.id,
          'file-executable',
        );
        // Without x it keeps its type (a script is text through its parents).
        expect(
          resolveFileIcon(
            script.path,
            mime: mime,
            env: env,
            executable: false,
          )?.icon.id,
          'file-executable',
        );
      },
    );

    testWidgets('the label sits in its box, in the color of the category', (
      tester,
    ) async {
      final icon = resolve('dati.json')!;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SilicaIcon(FileSource(icon), side: 1024, dark: false),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('JSON'));
      expect(text.style?.color, const Color(0xFF1F9D55));
      // A single text: the shadow repaints the same child, it does not duplicate it.
      expect(find.text('JSON'), findsOneWidget);
      final box = tester.getRect(
        find.ancestor(of: find.text('JSON'), matching: find.byType(FittedBox)),
      );
      final body = tester.getTopLeft(find.byType(SilicaIcon));
      // A file has the whole canvas as its side: the box (245, 376, 534, 194) at 1024 pt.
      expect(box.left - body.dx, closeTo(245, 0.5));
      expect(box.top - body.dy, closeTo(376, 0.5));
      expect(box.width, closeTo(534, 0.5));
    });

    testWidgets(
      'badges: alias on the left, the first on the right; below 32 just one',
      (tester) async {
        expect(
          visibleBadges({
            IconBadge.alias,
            IconBadge.cloud,
            IconBadge.locked,
          }, 64),
          [IconBadge.alias, IconBadge.locked],
        );
        expect(visibleBadges({IconBadge.alias, IconBadge.unreadable}, 20), [
          IconBadge.unreadable,
        ]);
        expect(visibleBadges({IconBadge.alias}, 12), isEmpty);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SilicaIcon(
                FileSource(resolve('a.pdf')!),
                side: 64,
                dark: false,
                badges: const {IconBadge.alias, IconBadge.locked},
                env: env,
              ),
            ),
          ),
        );
        final body = tester.getRect(find.byType(SilicaIcon));
        final positioned = tester
            .widgetList<Positioned>(find.byType(Positioned))
            .where((p) => p.width != null && p.width! < 64)
            .toList();
        expect(positioned, hasLength(2));
        // The file has the canvas as its side: badge 315/1024 of 64, in the box between the edge of the
        // app body (100…924 of the canvas) and the golden line; its canvas spills by 100 k.
        const t = 64 / 1024;
        const edge = 315 * t;
        const k = edge / 824;
        final lefts = positioned.map((p) => p.left!).toList()..sort();
        final tops = positioned.map((p) => p.top!).toSet();
        expect(lefts.first, closeTo(100 * t - 100 * k, 0.01));
        expect(lefts.last, closeTo(924 * t - edge - 100 * k, 0.01));
        expect(tops.single, closeTo(924 * t - edge - 100 * k, 0.01));
        expect(body.width, 64);
      },
    );

    test('badges from disk: symlink, broken, unreadable', () {
      final dir = Directory.systemTemp.createTempSync('badge-');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/vero').writeAsStringSync('x');
      Link('${dir.path}/link').createSync('vero');
      Link('${dir.path}/broken').createSync('missing');
      expect(badgesOf('${dir.path}/vero'), isEmpty);
      expect(badgesOf('${dir.path}/link'), {IconBadge.alias});
      expect(badgesOf('${dir.path}/broken'), {
        IconBadge.alias,
        IconBadge.unreadable,
      });
      expect(badgesOf('${dir.path}/vero', cloud: true), {IconBadge.cloud});
    });
  });

  test('volumes: network, image, optical, external, internal', () {
    expect(volumeIconId(const VolumeInfo(fsType: 'cifs')), 'volume-network');
    expect(volumeIconId(const VolumeInfo(scheme: 'sftp')), 'volume-network');
    expect(
      volumeIconId(
        const VolumeInfo(device: '/dev/loop3', backingFile: '/a.iso'),
      ),
      'volume-disk-image',
    );
    expect(
      volumeIconId(const VolumeInfo(device: '/dev/sr0')),
      'volume-optical',
    );
    expect(
      volumeIconId(const VolumeInfo(device: '/dev/sdb1', connectionBus: 'usb')),
      'volume-external',
    );
    expect(
      volumeIconId(const VolumeInfo(device: '/dev/nvme0n1p2')),
      'volume-internal',
    );
    final mounts = parseMountinfo(
      '29 1 259:2 / / rw,relatime shared:1 - ext4 /dev/nvme0n1p2 rw\n'
      '80 29 8:17 / /media/io/Chiave\\040USB rw - vfat /dev/sdb1 rw\n',
    );
    expect(mounts.map((m) => m.path), ['/', '/media/io/Chiave USB']);
    expect(mounts.last.fsType, 'vfat');
    expect(mounts.last.device, '/dev/sdb1');
  });

  testWidgets('the label of a type is not written below min_size', (
    tester,
  ) async {
    final root = iconTree();
    addTearDown(() => root.deleteSync(recursive: true));
    final env = {'SILICA_ICONS_DIR': root.path};
    final dir = Directory('${root.path}/files/file-image')
      ..createSync(recursive: true);
    File('${dir.path}/icon.json').writeAsStringSync(
      manifest(
        'file-image',
        dynamic: {
          'type': 'file-type-label',
          'label': {
            'size': 101.79,
            'box': [292, 741.43, 440, 124],
            'max_chars': 5,
            'max_width': 440,
            'color': '#30b0c7',
            'no_extension': null,
            'min_size': 32,
          },
        },
      ),
    );
    final icon = resolveFileIcon(
      '/x/photo.png',
      mime: mime,
      env: env,
      type: 'image/png',
    )!;
    expect(icon.label, 'PNG');
    for (final (side, shown) in [(64.0, true), (16.0, false)]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SilicaIcon(FileSource(icon), side: side, dark: false),
          ),
        ),
      );
      expect(find.text('PNG'), shown ? findsOneWidget : findsNothing);
    }
  });

  test('the real repo and the system database, if present', () {
    final repo =
        Platform.environment['SILICA_ICONS_DIR'] ??
        '${Platform.environment['HOME']}/silica/silica-icons';
    if (!File('$repo/files/file-generic/icon.json').existsSync() ||
        !File('/usr/share/mime/globs2').existsSync()) {
      markTestSkipped('silica-icons o shared-mime-info assenti');
      return;
    }
    final env = {'SILICA_ICONS_DIR': repo};
    final db = MimeDatabase.load();
    String? id(String name) => resolveFileIcon(
      '/tmp/$name',
      mime: db,
      env: env,
      type: db.typeForName(name),
      executable: false,
    )?.icon.id;
    expect(id('relazione.pdf'), 'file-pdf');
    expect(id('conti.xlsx'), 'file-spreadsheet');
    expect(id('lettera.docx'), 'file-document');
    expect(id('pagina.html'), 'file-web');
    expect(id('font.ttf'), 'file-font');
    expect(id('disco.iso'), 'file-disk-image');
    expect(id('photo.jpg'), 'file-image');
    expect(id('main.rs'), 'file-code');
    FileIcon? icon(String name) => resolveFileIcon(
      '/tmp/$name',
      mime: db,
      env: env,
      type: db.typeForName(name),
      executable: false,
    );
    // The real extension on the type icons, in the color of the type.
    expect(icon('photo.jpg')?.label, 'JPG');
    expect(icon('photo.jpg')?.labelColor?.$1, const Color(0xFF2F7CF6));
    expect(icon('font.ttf')?.label, 'TTF');
    // JSON: explicit entry to the generic file, given category (not the code of the parent).
    expect(icon('dati.json')?.icon.id, 'file-generic');
    expect(icon('dati.json')?.labelColor?.$1, const Color(0xFF1F9D55));
    // Step 0b: .ts is ambiguous in the system database, the extension decides.
    expect(
      resolveFileIcon(
        '/tmp/main.ts',
        mime: db,
        env: env,
        executable: false,
      )?.icon.id,
      'file-code',
    );

    expect(
      findBadgeRules(env: env)?.pathFor(IconBadge.alias, dark: true),
      endsWith('alias-dark.svg'),
    );
  });

  test('ground shadow: the IC-01 measurements and in between', () {
    for (final (side, opacity, sigma, offset) in [
      (32.0, 0.35, 1.2, 0.55),
      (64.0, 0.20, 1.45, 0.8),
      (128.0, 0.28, 2.7, 1.2),
      (512.0, 0.25, 7.5, 3.1),
    ]) {
      final s = IconShadow.forSide(side);
      expect(s.opacity, closeTo(opacity, 1e-9));
      expect(s.sigma, closeTo(sigma, 1e-9));
      expect(s.offset, closeTo(offset, 1e-9));
    }
    final mid = IconShadow.forSide(90);
    expect(mid.sigma, inExclusiveRange(1.45, 2.7));
    expect(IconShadow.forSide(16).sigma, closeTo(0.6, 1e-9));
  });
}
