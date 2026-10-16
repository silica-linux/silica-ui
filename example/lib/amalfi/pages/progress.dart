// Gallery page: progress (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The progress page.
final AmalfiGalleryPage progressPage = AmalfiGalleryPage(
  family: 'progress',
  title: 'Progress',
  build: (context) => pendingFamily(context, 'progress'),
);
