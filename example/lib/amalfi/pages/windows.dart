// Gallery page: windows (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The windows page.
final AmalfiGalleryPage windowsPage = AmalfiGalleryPage(
  family: 'windows',
  title: 'Windows',
  build: (context) => pendingFamily(context, 'windows'),
);
