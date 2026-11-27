import '../entities/verified_ai_insight.dart';

/// Kontrak Repository (Domain Layer) untuk fitur AI Insight.
abstract class AiInsightRepository {
  Future<VerifiedAiInsight?> getLatestVerifiedInsight({
    String featureType = 'queue_estimator',
  });

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

