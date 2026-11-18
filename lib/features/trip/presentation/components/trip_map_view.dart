import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/local/location_local_ds.dart';

/// In-app trip map: numbered stop pins and the rider's live position.
///
/// Drawn with OpenStreetMap tiles (`flutter_map`) during development. Before
/// release only this file changes to `google_maps_flutter`; screens pass the
/// same plain data.
class TripMapView extends StatefulWidget {
  /// Creates the map.
  ///
  /// With [currentIndex] the camera frames that stop and the [rider];
  /// without it, every stop. [obscuredBottom] is the share of the map's
  /// height covered by a panel (0–1), kept clear when framing.
  const TripMapView({
    super.key,
    required this.stops,
    this.currentIndex,
    this.rider,
    this.obscuredBottom = 0,
    this.attributionAlignment = Alignment.bottomRight,
  });

  /// Stops in route order; pins are numbered 1, 2, 3…
  final List<DeliveryStop> stops;

  /// The stop being delivered, if any.
  final int? currentIndex;

  /// The rider's latest position, if known.
  final GeoPosition? rider;

  /// Share of the map's height covered by an overlay at the bottom.
  final double obscuredBottom;

  /// Where the OpenStreetMap credit sits; pick a corner no overlay covers.
  final Alignment attributionAlignment;

  @override
  State<TripMapView> createState() => _TripMapViewState();

  LatLng? get _riderPoint {
    final GeoPosition? position = rider;
    return position == null
        ? null
        : LatLng(position.latitude, position.longitude);
  }

  /// Builds the map; [onPadding] receives the framing padding so the state
  /// can re-frame later with the same insets.
  Widget _build(
    MapController controller,
    void Function(EdgeInsets padding) onPadding,
  ) {
    final List<_Pin> pins = <_Pin>[
      for (int i = 0; i < stops.length; i++)
        if (_hasCoordinates(stops[i]))
          _Pin(
            point: LatLng(stops[i].latitude, stops[i].longitude),
            number: i + 1,
            style: _styleFor(stops[i], current: i == currentIndex),
          ),
    ];
    final LatLng? riderPoint = _riderPoint;
    final List<LatLng> focus = _focusPoints(pins, riderPoint);

    return ColoredBox(
      color: AppColors.mapBackground,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Keep pins clear of the credit label and of any bottom panel.
          final bool creditOnTop = attributionAlignment.y < 0;
          final EdgeInsets padding = EdgeInsets.fromLTRB(
            MapConfig.fitPadding,
            MapConfig.fitPadding + (creditOnTop ? MapConfig.creditHeight : 0),
            MapConfig.fitPadding,
            MapConfig.fitPadding +
                constraints.maxHeight * obscuredBottom +
                (creditOnTop ? 0 : MapConfig.creditHeight),
          );
          onPadding(padding);
          return FlutterMap(
            mapController: controller,
            // Re-frame when the current stop, the set of stops or the first
            // GPS fix changes — not on every rider move (the rider may be
            // panning the map).
            key: ValueKey<String>(_frameKey()),
            options: _options(focus, padding),
            children: <Widget>[
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgentPackageName,
                maxNativeZoom: MapConfig.maxNativeZoom,
              ),
              // Straight lines (not roads): rider → current stop, then the
              // remaining stops in delivery order. Drawn under the pins.
              PolylineLayer<Object>(polylines: _routeLines(riderPoint)),
              MarkerLayer(
                markers: <Marker>[
                  for (final _Pin pin in pins)
                    Marker(
                      point: pin.point,
                      width: pin.style.size.r,
                      height: pin.style.size.r,
                      child: _StopPin(number: pin.number, style: pin.style),
                    ),
                  if (riderPoint != null)
                    Marker(
                      point: riderPoint,
                      width: _RiderDot.size.r,
                      height: _RiderDot.size.r,
                      child: const _RiderDot(),
                    ),
                ],
              ),
              SimpleAttributionWidget(
                source: const Text(MapConfig.attribution),
                alignment: attributionAlignment,
              ),
            ],
          );
        },
      ),
    );
  }

  MapOptions _options(List<LatLng> focus, EdgeInsets padding) {
    const InteractionOptions interaction = InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    );
    if (focus.isNotEmpty) {
      // A fit (even of one point) honours the padding, so the point lands
      // in the visible part of the map rather than under a panel.
      return MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: focus,
          padding: padding,
          maxZoom: focus.length == 1
              ? MapConfig.singlePointZoom
              : MapConfig.fitMaxZoom,
        ),
        interactionOptions: interaction,
      );
    }
    return const MapOptions(
      initialCenter: LatLng(
        MapConfig.fallbackLatitude,
        MapConfig.fallbackLongitude,
      ),
      initialZoom: MapConfig.fallbackZoom,
      interactionOptions: interaction,
    );
  }

  /// Solid line from the rider to the current stop; dashed line through the
  /// stops still to deliver. Without a current stop (Arrange Route), one
  /// dashed line joins every stop in the chosen order.
  List<Polyline<Object>> _routeLines(LatLng? riderPoint) {
    final int? index = currentIndex;
    final List<Polyline<Object>> lines = <Polyline<Object>>[];
    if (index == null) {
      final List<LatLng> all = <LatLng>[
        for (final DeliveryStop stop in stops)
          if (_hasCoordinates(stop)) _point(stop),
      ];
      if (all.length > 1) {
        lines.add(_upcomingLine(all));
      }
      return lines;
    }
    if (index >= stops.length || !_hasCoordinates(stops[index])) {
      return lines;
    }
    final LatLng current = _point(stops[index]);
    final List<LatLng> ahead = <LatLng>[
      current,
      for (int i = 0; i < stops.length; i++)
        if (i != index &&
            !stops[i].status.isTerminal &&
            _hasCoordinates(stops[i]))
          _point(stops[i]),
    ];
    if (ahead.length > 1) {
      lines.add(_upcomingLine(ahead));
    }
    if (riderPoint != null) {
      lines.add(
        Polyline<Object>(
          points: <LatLng>[riderPoint, current],
          color: AppColors.action,
          strokeWidth: MapConfig.activeLineWidth,
          strokeCap: StrokeCap.round,
        ),
      );
    }
    return lines;
  }

  static Polyline<Object> _upcomingLine(List<LatLng> points) =>
      Polyline<Object>(
        points: points,
        color: AppColors.brand,
        strokeWidth: MapConfig.upcomingLineWidth,
        // Not const: the pattern's asserts read the list at runtime.
        pattern: StrokePattern.dashed(
          segments: const <double>[MapConfig.dashLength, MapConfig.dashGap],
        ),
      );

  static LatLng _point(DeliveryStop stop) =>
      LatLng(stop.latitude, stop.longitude);

  /// Points to frame now (for re-framing when the rider leaves the view).
  List<LatLng> get _currentFocus {
    final List<_Pin> pins = <_Pin>[
      for (int i = 0; i < stops.length; i++)
        if (_hasCoordinates(stops[i]))
          _Pin(
            point: _point(stops[i]),
            number: i + 1,
            style: _PinStyle.upcoming,
          ),
    ];
    return _focusPoints(pins, _riderPoint);
  }

  /// The current stop plus the rider while delivering; otherwise every stop.
  List<LatLng> _focusPoints(List<_Pin> pins, LatLng? riderPoint) {
    final int? index = currentIndex;
    if (index != null) {
      final List<LatLng> points = <LatLng>[
        for (final _Pin pin in pins)
          if (pin.number == index + 1) pin.point,
      ];
      if (riderPoint != null) {
        points.add(riderPoint);
      }
      if (points.isNotEmpty) {
        return points;
      }
    }
    return <LatLng>[for (final _Pin pin in pins) pin.point];
  }

  String _frameKey() {
    final List<String> ids = stops.map((DeliveryStop s) => s.orderId).toList()
      ..sort();
    final DeliveryStop? current =
        currentIndex != null && currentIndex! < stops.length
        ? stops[currentIndex!]
        : null;
    // `rider != null` re-frames once when the first GPS fix arrives.
    return '${current?.orderId}|${ids.join(',')}|${rider != null}';
  }

  // Missing coordinates come through as 0,0 — leave those stops off the map.
  static bool _hasCoordinates(DeliveryStop stop) =>
      stop.latitude != 0 || stop.longitude != 0;

  static _PinStyle _styleFor(DeliveryStop stop, {required bool current}) {
    if (current) {
      return _PinStyle.current;
    }
    return stop.status.isTerminal ? _PinStyle.done : _PinStyle.upcoming;
  }
}

class _TripMapViewState extends State<TripMapView> {
  MapController _controller = MapController();
  EdgeInsets _padding = EdgeInsets.zero;
  String? _frame;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rider != oldWidget.rider) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followRider());
    }
  }

  @override
  Widget build(BuildContext context) {
    // A new frame (current stop / stops / first fix) builds a new map, which
    // needs its own controller.
    final String frame = widget._frameKey();
    if (_frame != null && frame != _frame) {
      _controller.dispose();
      _controller = MapController();
    }
    _frame = frame;
    return widget._build(_controller, (EdgeInsets padding) {
      _padding = padding;
    });
  }

  // While delivering: when the rider's dot leaves the visible part of the
  // map (above the panel), frame the rider and the current stop again.
  // While it's in view the camera stays where the rider put it.
  void _followRider() {
    final LatLng? rider = widget._riderPoint;
    if (!mounted || rider == null || widget.currentIndex == null) {
      return;
    }
    final MapCamera camera;
    try {
      camera = _controller.camera;
    } catch (_) {
      return; // Map not laid out yet.
    }
    final Offset dot = camera.latLngToScreenOffset(rider);
    final double visibleBottom =
        camera.size.height * (1 - widget.obscuredBottom);
    final bool inView =
        dot.dx >= 0 &&
        dot.dx <= camera.size.width &&
        dot.dy >= 0 &&
        dot.dy <= visibleBottom;
    final List<LatLng> focus = widget._currentFocus;
    if (inView || focus.isEmpty) {
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: focus,
        padding: _padding,
        maxZoom: focus.length == 1
            ? MapConfig.singlePointZoom
            : MapConfig.fitMaxZoom,
      ),
    );
  }
}

class _Pin {
  const _Pin({required this.point, required this.number, required this.style});

  final LatLng point;
  final int number;
  final _PinStyle style;
}

/// Pin looks: the stop being delivered stands out, finished ones fade.
enum _PinStyle {
  current(size: 36, fill: AppColors.action, text: AppColors.white),
  upcoming(size: 30, fill: AppColors.white, text: AppColors.brand),
  done(size: 26, fill: AppColors.ink400, text: AppColors.white);

  const _PinStyle({required this.size, required this.fill, required this.text});

  final double size;
  final Color fill;
  final Color text;
}

class _StopPin extends StatelessWidget {
  const _StopPin({required this.number, required this.style});

  static const double _border = 2;
  static const double _shadowBlur = 6;
  static const Color _shadow = Color(0x33000000);

  final int number;
  final _PinStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: style == _PinStyle.upcoming
              ? AppColors.action
              : AppColors.white,
          width: _border,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: _shadow, blurRadius: _shadowBlur),
        ],
      ),
      child: style == _PinStyle.done
          ? AppIcon(AppIconGlyph.check, size: 13, color: style.text)
          : Text(
              '$number',
              style: AppTypography.display(
                style == _PinStyle.current ? 15 : 13,
                color: style.text,
              ),
            ),
    );
  }
}

class _RiderDot extends StatelessWidget {
  const _RiderDot();

  static const double size = 34;
  static const double _dot = 16;
  static const double _border = 3;
  static const Color _halo = Color(0x33008CFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: _halo, shape: BoxShape.circle),
      child: Container(
        width: _dot.r,
        height: _dot.r,
        decoration: BoxDecoration(
          color: AppColors.link,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: _border),
        ),
      ),
    );
  }
}
