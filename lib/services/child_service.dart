import 'dart:convert';
import 'package:frontend_qlte/config/config_url.dart';
import 'package:frontend_qlte/models/child_response_model.dart';
import 'package:frontend_qlte/utils/api_helper.dart';

class ChildService {
  static final String _baseUrl = '${Config_URL.baseUrl}Child';

  static Future<ChildrenResponse> getChildrenByUserId(String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/GetChildrenByUserId?userId=$userId');

      // 👉 Gọi ApiHelper để tự động xử lý token & refresh nếu cần
      final response = await ApiHelper.sendRequest("GET", uri);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ChildrenResponse.fromJson(jsonData);
      } else {
        return ChildrenResponse(
          status: false,
          msg: 'Lỗi: ${response.statusCode}',
          data: [],
        );
      }
    } catch (e) {
      return ChildrenResponse(
        status: false,
        msg: 'Không thể kết nối server: $e',
        data: [],
      );
    }
  }
}
