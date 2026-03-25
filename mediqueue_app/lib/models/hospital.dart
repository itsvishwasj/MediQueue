class HospitalModel {
  final String id;
  final String name;
  final String address;
  final List<String> departments;

  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.departments,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['_id'],
      name: json['name'],
      address: json['address'],
      departments: List<String>.from(json['departments'] ?? []),
    );
  }
}