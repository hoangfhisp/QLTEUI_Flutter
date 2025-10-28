import 'dart:convert';

import 'package:frontend_qlte/config/config_url.dart';
import 'package:frontend_qlte/models/message/chat_messages_response_model.dart';
import 'package:frontend_qlte/models/message/message_response_model.dart';
import 'package:frontend_qlte/models/message/messages_model.dart';
import 'package:http/http.dart' as http;

class MessageService {
  static final String _baseUrl = '${Config_URL.baseUrl}Message';

  static Future<MessageResponseModel> GetLastMessagePerUser(String userId, String token) async {
    try {
      var uri = Uri.parse('$_baseUrl/GetLastMessagePerUser?UserId=$userId');

      var response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final jsonData = jsonDecode(response.body);
      final value = MessageResponseModel.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return MessageResponseModel(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return MessageResponseModel(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  static Future<ChatMessagesResponseModel> getHistory(
      String userId1, String userId2, int page, int pageSize, String token) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/History?user1Id=$userId1&user2Id=$userId2&page=$page&pageSize=$pageSize');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final jsonData = jsonDecode(response.body);
      final value = ChatMessagesResponseModel.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return ChatMessagesResponseModel(
          total: 0,
          page: page,
          pageSize: pageSize,
          messages: MessagesModel(status: false, msg: 'Lỗi: ${value.messages.msg}', data: []),
        );
      }
    } catch (e) {
      return ChatMessagesResponseModel(
        total: 0,
        page: page,
        pageSize: pageSize,
        messages: MessagesModel(status: false, msg: 'Không thể kết nối server: $e', data: []),
      );
    }
  }
}