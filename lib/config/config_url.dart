import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config_URL {
  static String get baseUrl {
    String? url = dotenv.env['BASE_URL'];

    if (url == null || url.isEmpty) {
      print("⚠️ BASE_URL is not set in the .env file. Using default URL.");
      url = "https://losttealpencil82.conveyor.cloud/api/";
    }

    // 🔧 Đảm bảo có dấu '/' ở cuối để tránh lỗi nối chuỗi
    if (!url.endsWith("/")) {
      url = "$url/";
    }

    print("🔗 BASE_URL Loaded: $url"); // debug log

    return url;
  }

  static String get urlServer {
    String? url = dotenv.env['URL_SERVER'];

    if (url == null || url.isEmpty) {
      print("⚠️ BASE_URL is not set in the .env file. Using default URL.");
      url = "https://losttealpencil82.conveyor.cloud/api/";
    }

    // 🔧 Đảm bảo có dấu '/' ở cuối để tránh lỗi nối chuỗi
    if (!url.endsWith("/")) {
      url = "$url/";
    }

    print("🔗 BASE_URL Loaded: $url"); // debug log

    return url;
  }
}
