import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Polygon> polygons = [];
  List<Marker> markers = [];

  // Future<void> loadTest() async {
  //   List.generate(30, (i) {
  //     final lat = -7.25 + (i * 0.01); // Lokasi disebar sekitar Yogyakarta
  //     final lng = 112.75 + (i * 0.01);
  //     markers.add(
  //       Marker(
  //         point: LatLng(lat, lng),
  //         width: 40,
  //         height: 40,
  //         child: const Icon(Icons.location_on, color: Colors.red, size: 40),
  //       )
  //     );
  //   });
  // }

  @override
  void initState() {
    super.initState();
    // Buat method async terpisah untuk load data dan setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  Future<void> loadData() async {
    await Future.wait([
      loadPolygonGeoJson(),
      loadMarkerGeoJson(),
      // loadTest(),
    ]);

  }

  final PopupController popupController = PopupController();

  List<Map<String, dynamic>> parseGeoJson(String geoJsonString) {
    return jsonDecode(geoJsonString) as List<Map<String, dynamic>>;
  }

  Future<void> loadMarkerGeoJson() async {
    List<Marker> newMarkers = [];

    String geoJsonString = await rootBundle.loadString('assets/stasiun.json');

    final List<Map<String, dynamic>> stations =
      await compute(parseGeoJson, geoJsonString);
    // final List<Map<String, dynamic>> stations = List<Map<String, dynamic>>.from(jsonData);

    markers.clear();

    for (var station in stations) {
      dynamic lonData = station['longitude'];
      dynamic latData = station['latitude'];

      double lon = lonData is String ? double.parse(lonData) : (lonData as num).toDouble();
      double lat = latData is String ? double.parse(latData) : (latData as num).toDouble();

      if (lon < 95 || lon > 141 || lat < -11 || lat > 6) {
        continue;
      }

      String name = station['stasiun_name'];
      String city = station['city'];
      String keyValue = '$name|$city';

      newMarkers.add(
        Marker(
          point: LatLng(lat, lon),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          key: ValueKey<String>(keyValue),
        ),
      );
    }

    setState(() {
      markers = newMarkers;
    });
  }


  Future<void> loadPolygonGeoJson() async {
    String geoJsonString = await rootBundle.loadString('assets/indonesia-province-simple.json');
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
            List<LatLng> latlngPoints = [];
            for (var coord in polygon) {
              double lon = (coord[0] as num).toDouble();
              double lat = (coord[1] as num).toDouble();
              latlngPoints.add(LatLng(lat, lon));
            }
            final int jumlahPenduduk = properties['jumlah_penduduk'] ?? 0;
            final int jumlahStasiun = properties['jumlah_stasiun'] ?? 0; // tambahkan default value jika perlu
            final double ratio = jumlahPenduduk == 0 ? 0.0 : jumlahPenduduk / jumlahStasiun;

            newPolygons.add(
              Polygon(
                label: label,
                labelStyle: TextStyle(
                  // fontWeight: FontWeight.bold,
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
          List<LatLng> latlngPoints = [];
          for (var coord in polygon) {
            double lon = (coord[0] as num).toDouble();
            double lat = (coord[1] as num).toDouble();
            latlngPoints.add(LatLng(lat, lon));
          }

          final int jumlahPenduduk = properties['jumlah_penduduk'] ?? 0;
          final int jumlahStasiun = properties['jumlah_stasiun'] ?? 0; // tambahkan default value jika perlu
          final double ratio = jumlahPenduduk == 0 ? 0.0 : jumlahStasiun / jumlahPenduduk;

          newPolygons.add(
            Polygon(
              label: label,
              labelStyle: TextStyle(
                // fontWeight: FontWeight.bold,
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
                        final keyString = (marker.key as ValueKey<String>).value;
                        final parts = keyString.split('|');
                        final name = parts[0];
                        final city = parts[1];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('$name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('$city'),
                              ],
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


// Fungsi untuk mengecek apakah titik ada di dalam poligon
// bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
//   double x = point.latitude;
//   double y = point.longitude;
//   bool inside = false;
//
//   for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
//     double xi = polygon[i].latitude, yi = polygon[i].longitude;
//     double xj = polygon[j].latitude, yj = polygon[j].longitude;
//
//     bool intersect = ((yi > y) != (yj > y)) &&
//         (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
//     if (intersect) inside = !inside;
//   }
//   return inside;
// }

// int countStationsInProvince(List<Marker> station, Province province) {
//   int count = 0;
//   for (var station in stations) {
//     if (isPointInPolygon(LatLng(station.lat, station.lng), province.polygon)) {
//       count++;
//     }
//   }
//   return count;
// }
}
