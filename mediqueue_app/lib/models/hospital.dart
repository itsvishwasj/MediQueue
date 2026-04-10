class HospitalModel {
  final String id;
  final String name;
  final String address;
  final List<String> departments;
  final double hospitalLat;
  final double hospitalLon;
  final String fullAddress;

  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.departments,
    this.hospitalLat = 0.0,
    this.hospitalLon = 0.0,
    this.fullAddress = '',
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double lon = 0.0;
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
      name: json['name'],
      address: json['address'],
      departments: List<String>.from(json['departments'] ?? []),
      hospitalLat: lat,
      hospitalLon: lon,
      fullAddress: json['fullAddress'] ?? '',
    );
  }
}