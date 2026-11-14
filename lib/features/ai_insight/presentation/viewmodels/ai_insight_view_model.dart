import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/location_service.dart';
import '../../data/repositories/ai_insight_repository.dart';
import '../../domain/models/verified_ai_insight.dart';

class AiInsightState {
  final VerifiedAiInsight? verifiedInsight;
  final bool isLoadingGps;
  final bool isLoadingVerified;
  final bool isLoadingMenu;
  final bool isPendingAudit;
  final Map<String, dynamic>? pendingEstimate;
  final Map<String, dynamic>? menuInsight;
  final LocationResult? locationResult;
  final String? gpsError;
  final String? errorMessage;

  const AiInsightState({
    this.verifiedInsight,
    this.isLoadingGps = false,
    this.isLoadingVerified = false,
    this.isLoadingMenu = false,
    this.isPendingAudit = false,
    this.pendingEstimate,
    this.menuInsight,
    this.locationResult,
    this.gpsError,
    this.errorMessage,
  });

  AiInsightState copyWith({
    VerifiedAiInsight? verifiedInsight,
    bool? isLoadingGps,
    bool? isLoadingVerified,
    bool? isLoadingMenu,
    bool? isPendingAudit,
    Map<String, dynamic>? pendingEstimate,
    Map<String, dynamic>? menuInsight,
    LocationResult? locationResult,
    String? gpsError,
    String? errorMessage,
  }) {
    return AiInsightState(
      verifiedInsight: verifiedInsight ?? this.verifiedInsight,
      isLoadingGps: isLoadingGps ?? this.isLoadingGps,
      isLoadingVerified: isLoadingVerified ?? this.isLoadingVerified,
      isLoadingMenu: isLoadingMenu ?? this.isLoadingMenu,
      isPendingAudit: isPendingAudit ?? this.isPendingAudit,
      pendingEstimate: pendingEstimate ?? this.pendingEstimate,
      menuInsight: menuInsight ?? this.menuInsight,
      locationResult: locationResult ?? this.locationResult,
      gpsError: gpsError ?? this.gpsError,
      errorMessage: errorMessage,
    );
  }
}

class AiInsightViewModel extends StateNotifier<AiInsightState> {
  final AiInsightRepository _repository;

  AiInsightViewModel(this._repository) : super(const AiInsightState());

  /// 1. Mengambil data AI terkini yang HANYA berstatus 'verified' (Disetujui Manajer)
  Future<void> loadVerifiedInsight() async {
    state = state.copyWith(isLoadingVerified: true, errorMessage: null);
    try {
      final verified = await _repository.getLatestVerifiedInsight(featureType: 'queue_estimator');
      state = state.copyWith(
        verifiedInsight: verified,
        isLoadingVerified: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingVerified: false,
        errorMessage: 'Gagal memuat insight antrean tervalidasi.',
      );
    }
  }

  /// 2. Deteksi GPS Hardware & Kirim Prediksi Antrean ke Server
  Future<void> analyzeQueueWithGps({
    required String timeSlot,
    String? token,
    String outlet = 'Gerai Pusat Celaket',
  }) async {
    state = state.copyWith(isLoadingGps: true, gpsError: null, errorMessage: null);

    LocationResult? locResult;
    String? gpsErr;
    try {
      locResult = await LocationService.getCurrentLocationToOutlet();
    } catch (e) {
      gpsErr = e.toString().replaceFirst('Exception: ', '');
    }

    state = state.copyWith(locationResult: locResult, gpsError: gpsErr);

    try {
      final response = await _repository.calculateQueueWithGps(
        outlet: outlet,
        day: 'Hari Ini',
        timeSlot: timeSlot,
        distanceKm: locResult?.distanceKm,
        token: token,
      );

      final status = response['verification_status']?.toString() ?? 'pending';

      if (status == 'verified') {
        // Jika data langsung disetujui (misal simulasi manajer)
        state = state.copyWith(
          verifiedInsight: VerifiedAiInsight.fromJson(response),
          isPendingAudit: false,
          pendingEstimate: null,
          isLoadingGps: false,
        );
      } else {
        // Data masih dalam antrean verifikasi Manajer di Web Admin
        // Single Source of Truth: JANGAN ubah verifiedInsight dengan data pending!
        state = state.copyWith(
          isPendingAudit: true,
          pendingEstimate: response,
          isLoadingGps: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingGps: false,
        errorMessage: 'Gagal memproses perhitungan antrean AI.',
      );
    }
  }

  /// 3. Rekomendasi Menu AI
  Future<void> loadMenuRecommendation({
    String preference = '',
    String? token,
  }) async {
    state = state.copyWith(isLoadingMenu: true);
    try {
      final res = await _repository.getMenuRecommendation(
        preference: preference,
        token: token,
      );
      state = state.copyWith(
        menuInsight: res,
        isLoadingMenu: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMenu: false);
    }
  }
}

/// Riverpod StateNotifierProvider untuk AiInsightViewModel (MVVM)
final aiInsightViewModelProvider =
    StateNotifierProvider.autoDispose<AiInsightViewModel, AiInsightState>((ref) {
  // Dependency Injection via get_it
  final repo = getIt<AiInsightRepository>();
  return AiInsightViewModel(repo);
});
