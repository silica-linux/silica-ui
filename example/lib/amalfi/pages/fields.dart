// Gallery page: fields (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The fields page.
final AmalfiGalleryPage fieldsPage = AmalfiGalleryPage(
  family: 'fields',
  title: 'Fields',
  build: (context) => pendingFamily(context, 'fields'),
);
