// Gallery page: sheets (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The sheets page.
final AmalfiGalleryPage sheetsPage = AmalfiGalleryPage(
  family: 'sheets',
  title: 'Sheets',
  build: (context) => pendingFamily(context, 'sheets'),
);
