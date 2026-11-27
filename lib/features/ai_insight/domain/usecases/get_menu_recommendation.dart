import '../repositories/ai_insight_repository.dart';

/// Use Case: Meminta kurasi rekomendasi menu dari layanan Gemini AI.
class GetMenuRecommendation {
  final AiInsightRepository _repository;

  const GetMenuRecommendation(this._repository);

  String _sanitize(String raw) =>
      raw.replaceAll(RegExp(r'[<>{}\[\];`]'), '').trim();

  Future<Map<String, dynamic>> execute({
    String query = '',
    int? budget,
    String preference = '',
    String? token,
  }) async {
    final cleanQuery = _sanitize(query);
    final cleanPreference = _sanitize(preference);

    if (cleanQuery.length > 150) {
      throw ArgumentError('Permintaan maksimal 150 karakter.');
    }
    if (budget != null && budget < 0) {
      throw ArgumentError('Budget tidak boleh bernilai negatif.');
    }

    return _repository.getMenuRecommendation(
      query: cleanQuery,
      budget: budget,
      preference: cleanPreference,
      token: token,
    );
  }
}

