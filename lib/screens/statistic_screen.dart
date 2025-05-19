import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/stasiun_statistik.dart';
import '../services/stasiun_service.dart';

class KategoriAksesCount {
  final String kategori;
  final int jumlah;

  KategoriAksesCount({required this.kategori, required this.jumlah});
}

class StatisticScreen extends StatefulWidget {
  @override
  _StatisticScreenState createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  final StasiunService _service = StasiunService();
  List<StasiunStatistik> _statistik = [];
  List<KategoriAksesCount> _kategoriSummary = [];
  String? _selectedKategoriFromChart;

  @override
  void initState() {
    super.initState();
    _loadStatistik();
  }

  Future<void> _loadStatistik() async {
    final data = await _service.getStatistikByProvince();
    setState(() {
      _statistik = data;
      _generateKategoriSummary();
    });
  }

  void _generateKategoriSummary() {
    final Map<String, int> countMap = {};
    for (var s in _statistik) {
      final kategori = s.kategoriAkses;
      countMap[kategori] = (countMap[kategori] ?? 0) + 1;
    }

    _kategoriSummary =
        countMap.entries
            .map((e) => KategoriAksesCount(kategori: e.key, jumlah: e.value))
            .toList();
  }

  List<String> _getProvinsiByKategori(String kategori) {
    return _statistik
        .where((s) => s.kategoriAkses == kategori)
        .map((s) => s.province)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Akses Stasiun'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body:
          _statistik.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart: Pie (interaktif)
                    SfCircularChart(
                      title: ChartTitle(
                        text: 'Distribusi Kategori Akses di Indonesia',
                      ),
                      legend: Legend(
                        isVisible: true,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      selectionGesture:
                          ActivationMode
                              .singleTap, // ini penting agar tap langsung aktif
                      onSelectionChanged: (SelectionArgs args) {
                        final index = args.pointIndex;
                        if (index != null) {
                          final kategori = _kategoriSummary[index].kategori;
                          setState(() {
                            _selectedKategoriFromChart =
                                _selectedKategoriFromChart == kategori
                                    ? null
                                    : kategori;
                          });
                        }
                      },
                      series: <CircularSeries>[
                        PieSeries<KategoriAksesCount, String>(
                          dataSource: _kategoriSummary,
                          xValueMapper: (data, _) => data.kategori,
                          yValueMapper: (data, _) => data.jumlah,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                          pointColorMapper:
                              (data, _) => _getKategoriColor(data.kategori),
                          selectionBehavior: SelectionBehavior(
                            enable: true,
                            toggleSelection: true,
                          ),
                        ),
                      ],
                    ),

                    // Provinsi hasil klik pie
                    if (_selectedKategoriFromChart != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Provinsi dengan Kategori: $_selectedKategoriFromChart',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              _getProvinsiByKategori(
                                    _selectedKategoriFromChart!,
                                  )
                                  .map(
                                    (provinsi) => Chip(
                                      label: Text(provinsi),
                                      backgroundColor: _getKategoriColor(
                                        _selectedKategoriFromChart!,
                                      ).withOpacity(0.15),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Detail Statistik per Provinsi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // List Detail
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _statistik.length,
                      itemBuilder: (context, index) {
                        final item = _statistik[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.province,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('Jumlah Stasiun: ${item.jumlahStasiun}'),
                                Text('Populasi: ${item.jumlahPenduduk}'),
                                Text(
                                  'Rasio Orang/Stasiun: ${item.rasioOrangPerStasiun}',
                                ),
                                Text(
                                  'Kategori: ${item.kategoriAkses}',
                                  style: TextStyle(
                                    color: _getKategoriColor(
                                      item.kategoriAkses,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori) {
      case 'Sangat Baik':
        return Colors.green;
      case 'Baik':
        return Colors.lightGreen;
      case 'Cukup':
        return Colors.orange;
      case 'Buruk':
        return Colors.deepOrange;
      case 'Sangat Buruk':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
