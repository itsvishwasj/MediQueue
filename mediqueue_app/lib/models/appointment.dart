class AppointmentModel {
  final String id;
  final String doctorId; // add this
  final int tokenNumber;
  final String type;
  final String status;
  final String date;
  final int estimatedWaitTime;
  final String doctorName;
  final String doctorDepartment;
  final String hospitalName;
  final String? tokenQR;
  final String? checkinUrl;

  AppointmentModel({
    required this.id,
    required this.doctorId, // add this
    required this.tokenNumber,
    required this.type,
    required this.status,
    required this.date,
    required this.estimatedWaitTime,
    required this.doctorName,
    required this.doctorDepartment,
    required this.hospitalName,
    this.tokenQR,
    this.checkinUrl,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    final hospital = json['hospital'];
    return AppointmentModel(
      id: json['_id'],
      doctorId: doctor is Map ? doctor['_id'] : doctor, // add this
      tokenNumber: json['tokenNumber'],
      type: json['type'] ?? 'normal',
      status: json['status'] ?? 'waiting',
      date: json['date'],
      estimatedWaitTime: json['estimatedWaitTime'] ?? 0,
      doctorName: doctor is Map ? doctor['name'] : '',
      doctorDepartment: doctor is Map ? doctor['department'] : '',
      hospitalName: hospital is Map ? hospital['name'] : '',
      tokenQR: json['tokenQR'],
      checkinUrl: json['checkinUrl'],
    );
  }
}