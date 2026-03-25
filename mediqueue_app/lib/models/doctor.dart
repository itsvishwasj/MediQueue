class DoctorModel {
  final String id;
  final String name;
  final String department;
  final int avgConsultationTime;
  final String hospitalId;
  final String hospitalName;

  DoctorModel({
    required this.id,
    required this.name,
    required this.department,
    required this.avgConsultationTime,
    required this.hospitalId,
    required this.hospitalName,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final hospital = json['hospital'];
    return DoctorModel(
      id: json['_id'],
      name: json['name'],
      department: json['department'],
      avgConsultationTime: json['avgConsultationTime'] ?? 10,
      hospitalId: hospital is Map ? hospital['_id'] : hospital,
      hospitalName: hospital is Map ? hospital['name'] : '',
    );
  }
}