import '../../../../services/api_service.dart';
import '../../domain/models/verified_ai_insight.dart';

abstract class AiInsightRepository {
  Future<VerifiedAiInsight?> getLatestVerifiedInsight(
      {String featureType = 'queue_estimator'});
  Future<Map<String, dynamic>> calculateQueueWithGps({
    required String outlet,
    required String day,
    required String timeSlot,
    double? distanceKm,
    String? token,
  });
  Future<Map<String, dynamic>> getMenuRecommendation({
    String query = '',
    int? budget,
    String preference = '',
    String? token,
  });
}

class AiInsightRepositoryImpl implements AiInsightRepository {
  @override
  Future<VerifiedAiInsight?> getLatestVerifiedInsight(
      {String featureType = 'queue_estimator'}) async {
    try {
      final rawData =
          await ApiService.getLatestVerifiedAiInsight(featureType: featureType);
      if (rawData == null) return null;
      return VerifiedAiInsight.fromJson(rawData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> calculateQueueWithGps({
    required String outlet,
    required String day,
    required String timeSlot,
    double? distanceKm,
    String? token,
  }) async {
    return await ApiService.getAiQueueEstimate(
      outlet: outlet,
      day: day,
      timeSlot: timeSlot,
      distanceKm: distanceKm,
      token: token,
    );
  }

  @override
  Future<Map<String, dynamic>> getMenuRecommendation({
    String query = '',
    int? budget,
    String preference = '',
    String? token,
  }) async {
    return await ApiService.getAiRecommendation(
      query: query,
      budget: budget,
      preference: preference,
      token: token,
    );
  }
}
