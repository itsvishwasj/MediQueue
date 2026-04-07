class ApiConfig {
  // Change this to your machine's IP when testing on a physical device
  // Use 10.0.2.2 for Android emulator, localhost for web
  static const String baseUrl = 'http://192.168.0.116:5000';

  static const String register    = '$baseUrl/api/auth/register';
  static const String login       = '$baseUrl/api/auth/login';
  static const String hospitals   = '$baseUrl/api/hospitals';
  static const String doctors     = '$baseUrl/api/doctors';
  static const String appointments = '$baseUrl/api/appointments';
  static const String queue       = '$baseUrl/api/queue';
  static const String bookAppointment = "$baseUrl/api/appointments";
}