import '../../domain/entities/verified_ai_insight.dart';

/// Data Model mapper (JSON <-> Entity) untuk VerifiedAiInsight.
class VerifiedAiInsightModel extends VerifiedAiInsight {
  const VerifiedAiInsightModel({
    required super.id,
    required super.featureType,
    required super.crowdLevel,
    required super.crowdColor,
    required super.waitTimeMin,
    required super.waitTimeMax,
    required super.estimatedWait,
    required super.peakPercentage,
    required super.confidenceScore,
    required super.tips,
    required super.verificationStatus,
    super.verificationNotes,
    super.verifiedAt,
  });

  factory VerifiedAiInsightModel.fromJson(Map<String, dynamic> json) {
    final rawOutput = json['validated_output'];
    final Map<String, dynamic> output =
        (rawOutput is Map<String, dynamic>) ? rawOutput : json;

    final minWait = int.tryParse('${output['wait_time_min']}') ?? 8;
    final maxWait = int.tryParse('${output['wait_time_max']}') ?? 15;
    final estWait =
        output['estimated_wait']?.toString() ?? '~$minWait - $maxWait Mnt';

    DateTime? parsedDate;
    if (json['verified_at'] != null) {
      parsedDate = DateTime.tryParse('${json['verified_at']}');
    }

    return VerifiedAiInsightModel(
      id: int.tryParse('${json['id']}') ?? 0,
      featureType: json['feature_type']?.toString() ?? 'queue_estimator',
      crowdLevel: output['crowd_level']?.toString() ?? 'Ramai Lancar',
      crowdColor: output['crowd_color']?.toString() ?? 'gold',
      waitTimeMin: minWait,
      waitTimeMax: maxWait,
      estimatedWait: estWait,
      peakPercentage: int.tryParse('${output['peak_percentage']}') ?? 50,
      confidenceScore:
          output['confidence_score']?.toString() ?? 'Gemini AI (Tervalidasi)',
      tips: output['tips']?.toString() ??
          'Kondisi antrean gerai tervalidasi oleh Manajer.',
      verificationStatus:
          json['verification_status']?.toString() ?? 'verified',
      verificationNotes: json['verification_notes']?.toString(),
      verifiedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feature_type': featureType,
      'crowd_level': crowdLevel,
      'crowd_color': crowdColor,
      'wait_time_min': waitTimeMin,
      'wait_time_max': waitTimeMax,
      'estimated_wait': estimatedWait,
      'peak_percentage': peakPercentage,
      'confidence_score': confidenceScore,
      'tips': tips,
      'verification_status': verificationStatus,
      'verification_notes': verificationNotes,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}

