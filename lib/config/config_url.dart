import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config_URL {
  static final String urlServer = (() {
    String? url = dotenv.env['URL_SERVER'];

    if (url == null || url.isEmpty) {
      print("⚠️ URL_SERVER is not set in the .env file. Using default URL.");
      url = "https://firstsagecat76.conveyor.cloud/api/";
    }

    // 🔧 Đảm bảo có dấu '/' ở cuối để tránh lỗi nối chuỗi
    if (!url.endsWith("/")) {
      url = "$url/";
    }

    print("✅ URL_SERVER Loaded once: $url");
    return url;
  })();

  static final String baseUrl = (() {
    String? url = dotenv.env['BASE_URL'];

    if (url == null || url.isEmpty) {
      print("⚠️ BASE_URL is not set in the .env file. Using default URL.");
      url = "https://firstsagecat76.conveyor.cloud/api/";
    }

    if (!url.endsWith("/")) {
      url = "$url/";
    }

    print("✅ BASE_URL Loaded once: $url");
    return url;
  })();
}
