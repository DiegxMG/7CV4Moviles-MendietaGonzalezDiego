import 'dart:convert';
import 'package:http/http.dart' as http;

class PublicApiService {
  static const String _baseUrl = 'https://api.tvmaze.com';

  static Future<List<dynamic>?> searchShows(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search/shows?q=$query'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      // Devuelve null en caso de falla de conectividad
      return null;
    }
  }
}