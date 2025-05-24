import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../models/stasiun.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}


List<Map<String, dynamic>> parseGeoJson(String geoJsonString) {
  final List<dynamic> decoded = jsonDecode(geoJsonString);
  return decoded.cast<Map<String, dynamic>>();
}

Future<List<Polygon>> parsePolygonsInBackground(String geoJsonString) async {
  final data = json.decode(geoJsonString);
  List<Polygon> newPolygons = [];

  List features = data['features'];
  for (var feature in features) {
    final geometry = feature['geometry'];
    final type = geometry['type'];
    final coordinates = geometry['coordinates'];
    final String label = feature['properties']['Propinsi'];
    final properties = feature['properties'];

    if (type == 'MultiPolygon') {
      for (var polygonGroup in coordinates) {
        for (var polygon in polygonGroup) {
          List<LatLng> latlngPoints = polygon
              .map<LatLng>((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          final int jumlahPenduduk = properties['jumlah_penduduk'] ?? 0;
          final int jumlahStasiun = properties['jumlah_stasiun'] ?? 0;
          final double ratio = jumlahPenduduk == 0 ? 0.0 : jumlahPenduduk / jumlahStasiun;

          newPolygons.add(
            Polygon(
              label: label,
              labelStyle: TextStyle(
                fontSize: 12,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1
                  ..color = Colors.black,
              ),
              points: latlngPoints,
              color: getColorByThreshold(ratio),
              borderColor: Colors.white,
              borderStrokeWidth: 1,
              isFilled: true,
            ),
          );
        }
      }
    } else if (type == 'Polygon') {
      for (var polygon in coordinates) {
        List<LatLng> latlngPoints = polygon
            .map<LatLng>((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        final int jumlahPenduduk = properties['jumlah_penduduk'] ?? 0;
        final int jumlahStasiun = properties['jumlah_stasiun'] ?? 0;
        final double ratio = jumlahPenduduk == 0 ? 0.0 : jumlahPenduduk / jumlahStasiun;

        newPolygons.add(
          Polygon(
            label: label,
            labelStyle: TextStyle(
              fontSize: 12,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = Colors.black,
            ),
            points: latlngPoints,
            color: getColorByThreshold(ratio),
            borderColor: Colors.white,
            borderStrokeWidth: 1,
            isFilled: true,
          ),
        );
      }
    }
  }

  return newPolygons;
}


class _MapScreenState extends State<MapScreen> {
  List<Polygon> polygons = [];
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  Future<void> loadData() async {
    await Future.wait([
      loadPolygonGeoJson(),
      loadMarkerGeoJson(),
    ]);

  }

  final PopupController popupController = PopupController();

  Future<void> loadMarkerGeoJson() async {
    List<Marker> newMarkers = [];

    String geoJsonString = await rootBundle.loadString('assets/stasiun.json');

    List<Map<String, dynamic>> rawStations = await compute(parseGeoJson, geoJsonString);
    List<Stasiun> stations = rawStations.map((e) => Stasiun.fromJson(e)).toList();

    markers.clear();

    for (var station in stations) {
      newMarkers.add(
        Marker(
          point: LatLng(station.latitude, station.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          key: ValueKey<Stasiun>(station),
        ),
      );
    }

    setState(() {
      markers = newMarkers;
    });
  }


  Future<void> loadPolygonGeoJson() async {
    String geoJsonString = await rootBundle.loadString('assets/indonesia-province-simple.json');
    List<Polygon> newPolygons = await compute(parsePolygonsInBackground, geoJsonString);

    setState(() {
      polygons = newPolygons;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Map Cluster')),
      body:
      Stack(
        children: [
          PopupScope(
            popupController: popupController,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-2.5, 118.0),
                initialZoom: 3.5,
                // interactionOptions: InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
                // crs: const Epsg4326(), // Tambahkan ini
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                PolygonLayer(polygons: polygons),
                // MarkerLayer(markers: markers),   // ①
                MarkerClusterLayerWidget(
                  options:
                  MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    disableClusteringAtZoom: 12, // Start showing individual markers earlier
                    markers: markers,
                    polygonOptions: const PolygonOptions(
                      borderColor: Colors.blueAccent,
                      color: Colors.black12,
                      borderStrokeWidth: 3,
                    ),
                    popupOptions: PopupOptions(
                      popupController: popupController,
                      popupBuilder: (context, marker) {
                        final stasiun = (marker.key as ValueKey<Stasiun>).value;

                        return Card(
                          child: IntrinsicWidth(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.train, size: 16),
                                      const SizedBox(width: 4),
                                      Text(stasiun.name),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_city, size: 16),
                                      const SizedBox(width: 4),
                                      Text(stasiun.city),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.account_balance, size: 16),
                                      const SizedBox(width: 4),
                                      Text(stasiun.province),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${stasiun.latitude}, ${stasiun.longitude}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    builder: (context, clusterMarkers) {
                      if (clusterMarkers.length == 1) {
                        return const Icon(Icons.location_on, color: Colors.red, size: 40);
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            clusterMarkers.length.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 164,
            height: 216,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            // color: Colors.red,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              spacing: 8,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Color(0xFFFDDED8),
                    ),
                    Text(
                      'Sangat Baik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Color(0xFFFBB1A7),
                    ),
                    Text(
                      'Baik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Color(0xFFF98476),
                    ),
                    Text(
                      'Cukup',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Color(0xFFFA5844),
                    ),
                    Text(
                      'Buruk',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Color(0xFFD7250E),
                    ),
                    Text(
                      'Sangat Buruk',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Color(0xFFCCCCCC),
                    ),
                    Text(
                      'NA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Color getColorByThreshold(double value) {
  if (value > 1000000) {
    return Color(0xFFD7250E);
  } else if (value > 700000) {
    return Color(0xFFFA5844);
  } else if (value > 400000) {
    return Color(0xFFF98476);
  } else if (value > 200000) {
    return Color(0xFFFBB1A7);
  } else if (value > 0) {
    return Color(0xFFFDDED8);
  } else {
    return Color(0xFFCCCCCC);
  }
}