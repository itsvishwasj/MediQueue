class HospitalModel {
  final String id;
  final String name;
  final String address;
  final List<String> departments;
  final double? latitude;
  final double? longitude;
  double? distanceInKm;

  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.departments,
    this.latitude,
    this.longitude,
    this.distanceInKm,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lon;
    if (json['location'] != null) {
      if (json['location']['latitude'] != null) {
        lat = (json['location']['latitude'] as num).toDouble();
      }
      if (json['location']['longitude'] != null) {
        lon = (json['location']['longitude'] as num).toDouble();
      }
    }

    return HospitalModel(
      id: json['_id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      departments: List<String>.from(json['departments'] ?? []),
      latitude: lat,
      longitude: lon,
    );
  }
}