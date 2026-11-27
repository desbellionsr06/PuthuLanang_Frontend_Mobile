import '../../../../services/api_service.dart';
import '../../domain/entities/verified_ai_insight.dart';
import '../../domain/repositories/ai_insight_repository.dart';
import '../models/verified_ai_insight_model.dart';

/// Implementasi Repository (Data Layer) untuk fitur AI Insight.
/// Satu-satunya penghubung ke ApiService untuk endpoint AI.
class AiInsightRepositoryImpl implements AiInsightRepository {
  @override
  Future<VerifiedAiInsight?> getLatestVerifiedInsight({
    String featureType = 'queue_estimator',
  }) async {
    try {
      final rawData = await ApiService.getLatestVerifiedAiInsight(
        featureType: featureType,
      );
      if (rawData == null) return null;
      return VerifiedAiInsightModel.fromJson(rawData);
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
    return ApiService.getAiQueueEstimate(
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
    return ApiService.getAiRecommendation(
      query: query,
      budget: budget,
      preference: preference,
      token: token,
    );
  }
}

