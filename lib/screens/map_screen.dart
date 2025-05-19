import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../models/stasiun.dart';
import '../services/stasiun_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final StasiunService _service = StasiunService();

  List<Marker> _markers = [];
  List<Stasiun> _stasiunList = [];
  Stasiun? _selectedStasiun;

  @override
  void initState() {
    super.initState();
    _loadStasiun();
  }

  Future<void> _loadStasiun() async {
    final stasiuns = await _service.loadStasiun();
    setState(() {
      _stasiunList = stasiuns;
      _markers = stasiuns.map((s) => Marker(
        point: latlng.LatLng(s.latitude, s.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedStasiun = s);
          },
          child: const Icon(Icons.location_on, color: Colors.red),
        ),
      )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: latlng.LatLng(-2.5, 117.0),
            initialZoom: 5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: _markers),
          ],
        ),

        // === Info Panel ===
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedStasiun != null
              ? Align(
                  key: ValueKey(_selectedStasiun!.id),
                  alignment: Alignment.bottomCenter,
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.all(16),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStasiun!.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_city, size: 18, color: Colors.blueGrey),
                              const SizedBox(width: 6),
                              Text(
                                '${_selectedStasiun!.city}, ${_selectedStasiun!.province}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 18, color: Colors.blueGrey),
                              const SizedBox(width: 6),
                              Text(
                                'Populasi: ${_selectedStasiun!.jumlahPenduduk}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => _selectedStasiun = null),
                              child: const Text(
                                'Tutup',
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
