// Gallery page: wells (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The wells page.
final AmalfiGalleryPage wellsPage = AmalfiGalleryPage(
  family: 'wells',
  title: 'Wells',
  build: (context) => pendingFamily(context, 'wells'),
);
