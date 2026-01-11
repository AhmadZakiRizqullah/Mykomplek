import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/mykomplek-web_api';
    } else {
      return 'http://10.194.91.214/mykomplek-web_api';
    }
  }

  // ================= AUTH =================
  static String get loginEndpoint => '$baseUrl/auth/login.php';
  static String get logoutEndpoint => '$baseUrl/auth/logout.php';

  // ================= ADMIN =================
  static String get getUsersEndpoint => '$baseUrl/admin/get_users.php';
  static String get createUserEndpoint => '$baseUrl/admin/create_user.php';
  static String get deleteUserEndpoint => '$baseUrl/admin/delete_user.php';
  static String get resetPasswordEndpoint => '$baseUrl/admin/reset_password.php';
  static String get updateUserEndpoint => '$baseUrl/admin/update_user.php';
  static String get visitorStatsWeeklyEndpoint =>
      '$baseUrl/admin/get_all_tamu.php';

  // ================= SECURE FILE =================
  // SEMUA FILE WAJIB LEWAT ENDPOINT INI
  static String get secureFileEndpoint =>
      '$baseUrl/utils/serve_file.php';

  // ================= SATPAM =================
  static String get addTamuEndpoint => '$baseUrl/satpam/add_tamu.php';
  static String get checkoutTamuEndpoint =>
      '$baseUrl/satpam/checkout_tamu.php';
  static String get getTamuTodayEndpoint =>
      '$baseUrl/satpam/get_tamu_today.php';

  // ================= WARGA =================
  static String get listTamuEndpoint =>
      '$baseUrl/warga/list_tamu.php';
}
