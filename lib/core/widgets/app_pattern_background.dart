import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';

/// Tiled hand-drawn vegetable line-art texture.
///
/// Reproduces the CSS `background-image: veg-pattern; background-size:
/// 300px; opacity; mix-blend-mode` layer. Use [screenBlend] on brand-green
/// surfaces (splash, trip complete) and plain [opacity] on white (login).
class AppPatternBackground extends StatefulWidget {
  /// Creates the pattern layer.
  const AppPatternBackground({
    super.key,
    required this.opacity,
    this.screenBlend = false,
    this.tileSize = 300,
  });

  /// Layer opacity (0..1).
  final double opacity;

  /// Whether to blend with `screen` against what is painted below.
  final bool screenBlend;

  /// Tile edge in design px.
  final double tileSize;

  @override
  State<AppPatternBackground> createState() => _AppPatternBackgroundState();
}

class _AppPatternBackgroundState extends State<AppPatternBackground> {
  ui.Image? _image;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    _onImage,
    onError: _onError,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream?.removeListener(_listener);
    _stream = const AssetImage(
      AppAssets.vegPattern,
    ).resolve(createLocalImageConfiguration(context))..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    if (!mounted) {
      return;
    }
    setState(() => _image = info.image);
  }

  void _onError(Object error, StackTrace? stackTrace) {
    // The texture is decorative; a missing asset simply leaves it blank.
  }

  @override
  Widget build(BuildContext context) {
    final ui.Image? image = _image;
    if (image == null) {
      return const SizedBox.expand();
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _PatternPainter(
        image: image,
        opacity: widget.opacity,
        screenBlend: widget.screenBlend,
        tile: widget.tileSize.w,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.image,
    required this.opacity,
    required this.screenBlend,
    required this.tile,
  });

  final ui.Image image;
  final double opacity;
  final bool screenBlend;
  final double tile;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = tile / image.width;
    final Matrix4 matrix = Matrix4.diagonal3Values(scale, scale, 1);
    final Paint paint = Paint()
      ..shader = ImageShader(
        image,
        TileMode.repeated,
        TileMode.repeated,
        matrix.storage,
        filterQuality: FilterQuality.medium,
      )
      ..color = Color.fromRGBO(0, 0, 0, opacity)
      ..blendMode = screenBlend ? BlendMode.screen : BlendMode.srcOver;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.opacity != opacity ||
      oldDelegate.screenBlend != screenBlend ||
      oldDelegate.tile != tile;
}
