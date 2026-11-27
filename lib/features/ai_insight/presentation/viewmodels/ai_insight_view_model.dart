import 'package:flutter/foundation.dart';
import '../../../../services/location_service.dart';
import '../../data/models/verified_ai_insight_model.dart';
import '../../domain/entities/verified_ai_insight.dart';
import '../../domain/usecases/calculate_queue_estimate.dart';
import '../../domain/usecases/get_latest_verified_insight.dart';
import '../../domain/usecases/get_menu_recommendation.dart';

/// ViewModel (MVVM + ChangeNotifier) untuk fitur AI Insight.
/// Hanya bergantung pada Use Cases di domain layer.
class AiInsightViewModel extends ChangeNotifier {
  final GetLatestVerifiedInsight _getLatestVerifiedInsight;
  final CalculateQueueEstimate _calculateQueueEstimate;
  final GetMenuRecommendation _getMenuRecommendation;

  AiInsightViewModel({
    required GetLatestVerifiedInsight getLatestVerifiedInsight,
    required CalculateQueueEstimate calculateQueueEstimate,
    required GetMenuRecommendation getMenuRecommendation,
  })  : _getLatestVerifiedInsight = getLatestVerifiedInsight,
        _calculateQueueEstimate = calculateQueueEstimate,
        _getMenuRecommendation = getMenuRecommendation;

  VerifiedAiInsight? _verifiedInsight;
  bool _isLoadingGps = false;
  bool _isLoadingVerified = false;
  bool _isLoadingMenu = false;
  bool _isPendingAudit = false;
  Map<String, dynamic>? _pendingEstimate;
  Map<String, dynamic>? _menuInsight;
  LocationResult? _locationResult;
  String? _gpsError;
  String? _errorMessage;

  VerifiedAiInsight? get verifiedInsight => _verifiedInsight;
  bool get isLoadingGps => _isLoadingGps;
  bool get isLoadingVerified => _isLoadingVerified;
  bool get isLoadingMenu => _isLoadingMenu;
  bool get isPendingAudit => _isPendingAudit;
  Map<String, dynamic>? get pendingEstimate => _pendingEstimate;
  Map<String, dynamic>? get menuInsight => _menuInsight;
  LocationResult? get locationResult => _locationResult;
  String? get gpsError => _gpsError;
  String? get errorMessage => _errorMessage;

  /// 1. Mengambil data AI terkini yang HANYA berstatus 'verified' (Disetujui Manajer)
  Future<void> loadVerifiedInsight() async {
    _isLoadingVerified = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _verifiedInsight = await _getLatestVerifiedInsight.execute(
        featureType: 'queue_estimator',
      );
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Input tidak valid.';
    } catch (_) {
      _errorMessage = 'Gagal memuat insight antrean tervalidasi.';
    } finally {
      _isLoadingVerified = false;
      notifyListeners();
    }
  }

  /// 2. Deteksi GPS Hardware & Kirim Prediksi Antrean ke Server via UseCase
  Future<void> analyzeQueueWithGps({
    required String timeSlot,
    String? token,
    String outlet = 'Gerai Pusat Celaket',
  }) async {
    _isLoadingGps = true;
    _gpsError = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _locationResult = await LocationService.getCurrentLocationToOutlet();
    } catch (e) {
      _gpsError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();

    try {
      final response = await _calculateQueueEstimate.execute(
        outlet: outlet,
        day: 'Hari Ini',
        timeSlot: timeSlot,
        distanceKm: _locationResult?.distanceKm,
        token: token,
      );

      final status = response['verification_status']?.toString() ?? 'pending';
      if (status == 'verified') {
        _verifiedInsight = VerifiedAiInsightModel.fromJson(response);
        _isPendingAudit = false;
        _pendingEstimate = null;
      } else {
        _isPendingAudit = true;
        _pendingEstimate = response;
      }
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Parameter antrean tidak valid.';
    } catch (_) {
      _errorMessage = 'Gagal memproses perhitungan antrean AI.';
    } finally {
      _isLoadingGps = false;
      notifyListeners();
    }
  }

  /// 3. Rekomendasi Menu AI via UseCase
  Future<void> loadMenuRecommendation({
    String query = '',
    int? budget,
    String preference = '',
    String? token,
  }) async {
    _isLoadingMenu = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _menuInsight = await _getMenuRecommendation.execute(
        query: query,
        budget: budget,
        preference: preference,
        token: token,
      );
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Permintaan rekomendasi tidak valid.';
    } catch (_) {
      _errorMessage = 'Gagal memuat rekomendasi menu AI.';
    } finally {
      _isLoadingMenu = false;
      notifyListeners();
    }
  }
}
