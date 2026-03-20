import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

const String _defaultTileUrlTemplate =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
const List<String> _defaultTileSubdomains = ['a', 'b', 'c', 'd'];

/// Shared map widget used across the app.
class AppMap extends StatelessWidget {
  const AppMap({
    required this.center,
    required this.markers,
    this.mapController,
    this.initialZoom = 9,
    this.minZoom = 4,
    this.maxZoom = 18,
    this.onTap,
    this.clusterMarkers = true,
    this.maxClusterRadius = 70,
    this.clusterBreakoutZoom = 12,
    this.clusterSize = const Size(46, 46),
    this.clusterPadding = const EdgeInsets.all(60),
    this.clusterBuilder,
    this.tileUrlTemplate = _defaultTileUrlTemplate,
    this.tileSubdomains = _defaultTileSubdomains,
    super.key,
  });

  final MapController? mapController;
  final LatLng center;
  final List<Marker> markers;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final void Function(LatLng point)? onTap;
  final bool clusterMarkers;
  final int maxClusterRadius;
  final double clusterBreakoutZoom;
  final Size clusterSize;
  final EdgeInsets clusterPadding;
  final Widget Function(BuildContext context, List<Marker> markers)?
      clusterBuilder;
  final String tileUrlTemplate;
  final List<String> tileSubdomains;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: initialZoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        onTap: (_, point) => onTap?.call(point),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrlTemplate,
          subdomains: tileSubdomains,
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        if (clusterMarkers)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: maxClusterRadius,
              size: clusterSize,
              alignment: Alignment.center,
              maxZoom: clusterBreakoutZoom,
              padding: clusterPadding,
              markers: markers,
              builder: clusterBuilder ?? _defaultClusterBuilder,
            ),
          )
        else
          MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: const [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('© CARTO'),
          ],
        ),
      ],
    );
  }

  Widget _defaultClusterBuilder(BuildContext context, List<Marker> markers) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
      ),
      alignment: Alignment.center,
      child: Text(
        '${markers.length}',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
