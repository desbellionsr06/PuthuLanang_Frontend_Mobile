import '../entities/verified_ai_insight.dart';
import '../repositories/ai_insight_repository.dart';

/// Use Case: Mengambil insight AI terbaru yang telah diverifikasi Manajer.
class GetLatestVerifiedInsight {
  final AiInsightRepository _repository;

  const GetLatestVerifiedInsight(this._repository);

  Future<VerifiedAiInsight?> execute({
    String featureType = 'queue_estimator',
  }) async {
    final cleanType = featureType.trim();
    if (cleanType.isEmpty) {
      throw ArgumentError('Jenis fitur AI tidak boleh kosong.');
    }
    return _repository.getLatestVerifiedInsight(featureType: cleanType);
  }
}

