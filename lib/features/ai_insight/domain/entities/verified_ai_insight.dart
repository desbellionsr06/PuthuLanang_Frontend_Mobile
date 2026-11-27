/// Entity murni untuk hasil insight AI yang telah diverifikasi Manajer.
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
}

