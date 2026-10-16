// Gallery page: steppers (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The steppers page.
final AmalfiGalleryPage steppersPage = AmalfiGalleryPage(
  family: 'steppers',
  title: 'Steppers',
  build: (context) => pendingFamily(context, 'steppers'),
);
