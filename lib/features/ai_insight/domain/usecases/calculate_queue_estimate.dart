import '../repositories/ai_insight_repository.dart';

/// Use Case: Menghitung estimasi antrean AI berbasis slot waktu & jarak GPS.
class CalculateQueueEstimate {
  final AiInsightRepository _repository;

  const CalculateQueueEstimate(this._repository);

  String _sanitize(String raw) =>
      raw.replaceAll(RegExp(r'[<>{}\[\];`]'), '').trim();

  Future<Map<String, dynamic>> execute({
    required String outlet,
    required String day,
    required String timeSlot,
    double? distanceKm,
    String? token,
  }) async {
    final cleanOutlet = _sanitize(outlet);
    final cleanDay = _sanitize(day);
    final cleanSlot = _sanitize(timeSlot);

    if (cleanOutlet.isEmpty) {
      throw ArgumentError('Nama gerai tidak boleh kosong.');
    }
    if (cleanSlot.isEmpty) {
      throw ArgumentError('Slot waktu pengambilan wajib dipilih.');
    }
    if (distanceKm != null && (distanceKm.isNaN || distanceKm < 0)) {
      throw ArgumentError('Jarak GPS tidak valid.');
    }

    return _repository.calculateQueueWithGps(
      outlet: cleanOutlet,
      day: cleanDay.isEmpty ? 'Hari Ini' : cleanDay,
      timeSlot: cleanSlot,
      distanceKm: distanceKm,
      token: token,
    );
  }
}

