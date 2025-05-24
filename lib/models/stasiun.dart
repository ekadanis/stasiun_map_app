class Stasiun {
  final String id;
  final String name;
  final String city;
  final String province;
  final double latitude;
  final double longitude;

  Stasiun({
    required this.id,
    required this.name,
    required this.city,
    required this.province,
    required this.latitude,
    required this.longitude,
  });

  factory Stasiun.fromJson(Map<String, dynamic> json) {
    return Stasiun(
      id: json['stasiun_id'],
      name: json['stasiun_name'],
      city: json['city'],
      province: json['province'],
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
    );
  }
}
