import 'db_helper.dart';
import 'public_api_service.dart';

class RecommendationsService {
  static Future<List<dynamic>> getRecommendations(String userId) async {
    final history = await DBHelper.getHistory(userId);
    String keyword = "action"; // Palabra clave por defecto si no hay historial

    if (history.isNotEmpty) {
      keyword = history.first['query']; // Extrae la búsqueda más reciente
    }

    final results = await PublicApiService.searchShows(keyword);

    if (results != null && results.length >= 3) {
      // Retorna 3 elementos recomendados basados en la regla lógica
      return results.take(3).toList();
    }

    return results ?? [];
  }
}