// Gallery page: group boxes (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The group boxes page.
final AmalfiGalleryPage groupBoxesPage = AmalfiGalleryPage(
  family: 'group_boxes',
  title: 'Group boxes',
  build: (context) => pendingFamily(context, 'group_boxes'),
);
