import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Single HTTP client. All network calls go through here.
/// Handles status-code → exception mapping in one place.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path').replace(
      queryParameters: params,
    );
    try {
      final response = await _client.get(uri, headers: _headers);
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      case 404:
        throw const NotFoundException();
      case >= 500:
        throw const ServerException();
      default:
        throw ServerException('Unexpected status: ${response.statusCode}');
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
