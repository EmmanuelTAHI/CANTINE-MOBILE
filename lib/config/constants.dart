/// Constantes de l'application
class AppConstants {
  // API Configuration
  // TODO: Remplacer par l'URL réelle de votre backend
  static const String baseUrl = 'http://localhost:8000/api';
  // Pour Android Emulator: 'http://10.0.2.2:8000/api'
  // Pour iOS Simulator: 'http://localhost:8000/api'
  // Pour appareil physique: 'http://VOTRE_IP_LOCALE:8000/api'

  // API Endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String studentsEndpoint = '/students/';
  static const String attendanceEndpoint = '/attendance/';
  static const String attendanceTodayEndpoint = '/attendance/today/';
  static const String attendanceStudentEndpoint = '/attendance/student/';
  static const String menusJournalierEndpoint = '/menus/journaliers/';
  static const String menusMensuelEndpoint = '/menus/mensuels/';
  static const String depensesEndpoint = '/depenses/';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // App Info
  static const String appName = 'Cantine HEG';
  static const String appVersion = '1.0.0';
}
