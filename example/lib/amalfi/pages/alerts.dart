// Gallery page: alerts (every variant × size × state, in the gallery's appearance).

import '../specimen.dart';

/// The alerts page.
final AmalfiGalleryPage alertsPage = AmalfiGalleryPage(
  family: 'alerts',
  title: 'Alerts',
  build: (context) => pendingFamily(context, 'alerts'),
);
