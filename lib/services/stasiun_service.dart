import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:stasiun_map_app/models/stasiun_statistik.dart';
import '../models/stasiun.dart';

class StasiunService {
  Future<List<Stasiun>> loadStasiun() async {
    final jsonStr = await rootBundle.loadString('assets/stasiun.json');
    final data = jsonDecode(jsonStr);
    return List<Stasiun>.from(data.map((e) => Stasiun.fromJson(e)));
  }

  Future<List<StasiunStatistik>> getStatistikByProvince() async {
    final stasiuns = await loadStasiun();

    // Kelompokkan stasiun berdasarkan provinsi
    final Map<String, List<Stasiun>> grouped = {};

    for (var s in stasiuns) {
      if (!grouped.containsKey(s.province)) {
        grouped[s.province] = [];
      }
      if (s.jumlahPenduduk > 0) {
        grouped[s.province]!.add(s);
      }
    }

    // Buat list statistik
    final List<StasiunStatistik> result = [];

    grouped.forEach((province, list) {
      final int jumlahStasiun = list.length;
      final int jumlahPenduduk = list
          .map((s) => s.jumlahPenduduk)
          .reduce((a, b) => a > b ? a : b);
      final int rasio = (jumlahPenduduk / jumlahStasiun).round();

      String kategori;
      if (rasio <= 200000) {
        kategori = 'Sangat Baik';
      } else if (rasio <= 400000) {
        kategori = 'Baik';
      } else if (rasio <= 700000) {
        kategori = 'Cukup';
      } else if (rasio <= 1000000) {
        kategori = 'Buruk';
      } else {
        kategori = 'Sangat Buruk';
      }

      result.add(
        StasiunStatistik(
          province: province,
          jumlahStasiun: jumlahStasiun,
          jumlahPenduduk: jumlahPenduduk,
          rasioOrangPerStasiun: rasio,
          kategoriAkses: kategori,
        ),
      );
    });

    // Urutkan DESC berdasarkan rasio
    result.sort(
      (a, b) => b.rasioOrangPerStasiun.compareTo(a.rasioOrangPerStasiun),
    );

    return result;
  }
}
