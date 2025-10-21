import 'dart:convert';
import 'package:frontend_qlte/config/config_url.dart';
import 'package:frontend_qlte/models/child_response_model.dart';
import 'package:http/http.dart' as http;

class ChildService {
  static final String _baseUrl = '${Config_URL.baseUrl}Child';

  static Future<ChildrenResponse> getChildrenByUserId(String userId,String token) async {
    try {

      var uri = Uri.parse('$_baseUrl/GetChildrenByUserId?userId=$userId');
      var response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // thêm token vào header
        },
      );

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
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }
}
