class ApiConfig {
  // Base URL for the backend API
  static const String baseUrl = 'https://grx6djfl-5003.inc1.devtunnels.ms/';
  //backend url http://165.22.208.62:5003  server of collage//

  // Auth endpoints
  static String get loginEndpoint => '$baseUrl/login';

  // Helper method to build full URLs
  static String getUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
