class VerifiedAiInsight {
  final int id;
  final String featureType;
  final String crowdLevel;
  final String crowdColor;
  final int waitTimeMin;
  final int waitTimeMax;
  final String estimatedWait;
  final int peakPercentage;
  final String confidenceScore;
  final String tips;
  final String verificationStatus;
  final String? verificationNotes;
  final DateTime? verifiedAt;

  const VerifiedAiInsight({
    required this.id,
    required this.featureType,
    required this.crowdLevel,
    required this.crowdColor,
    required this.waitTimeMin,
    required this.waitTimeMax,
    required this.estimatedWait,
    required this.peakPercentage,
    required this.confidenceScore,
    required this.tips,
    required this.verificationStatus,
    this.verificationNotes,
    this.verifiedAt,
  });

  factory VerifiedAiInsight.fromJson(Map<String, dynamic> json) {
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

    return VerifiedAiInsight(
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
      verificationStatus: json['verification_status']?.toString() ?? 'verified',
      verificationNotes: json['verification_notes']?.toString(),
      verifiedAt: parsedDate,
    );
  }
}
