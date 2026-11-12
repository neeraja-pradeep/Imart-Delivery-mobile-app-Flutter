import 'package:flutter/material.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/map_embed_frame_stub.dart'
    if (dart.library.js_interop) 'package:imart_delivery_app/features/trip/presentation/components/map_embed_frame_web.dart'
    if (dart.library.io) 'package:imart_delivery_app/features/trip/presentation/components/map_embed_frame_io.dart';

/// Embedded Google Map for [url] (iframe on web, WebView on Android/iOS,
/// neutral placeholder elsewhere).
class MapEmbedView extends StatelessWidget {
  /// Creates the map.
  const MapEmbedView({super.key, required this.url});

  /// Embed URL from `MapLinks`.
  final String url;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mapBackground,
      child: buildMapFrame(url),
    );
  }
}
