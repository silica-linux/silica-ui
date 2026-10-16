// Gallery page: lists (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The lists page.
final AmalfiGalleryPage listsPage = AmalfiGalleryPage(
  family: 'lists',
  title: 'Lists',
  build: (context) => pendingFamily(context, 'lists'),
);
