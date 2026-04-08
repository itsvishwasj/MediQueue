class ApiConfig {
  static const String baseUrl = 'https://mediqueue-backend-el5a.onrender.com';
  static const String socketUrl = 'wss://mediqueue-backend-el5a.onrender.com';

  static const String register    = '$baseUrl/api/auth/register';
  static const String login       = '$baseUrl/api/auth/login';
  static const String hospitals   = '$baseUrl/api/hospitals';
  static const String doctors     = '$baseUrl/api/doctors';
  static const String appointments = '$baseUrl/api/appointments';
  static const String queue       = '$baseUrl/api/queue';
  static const String bookAppointment = "$baseUrl/api/appointments";
}
