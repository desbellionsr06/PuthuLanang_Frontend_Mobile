import 'package:flutter/foundation.dart';
import '../../../../models/menu_item.dart';
import '../../../ai_insight/domain/usecases/get_menu_recommendation.dart';
import '../../domain/entities/menu_entity.dart';
import '../../domain/usecases/get_menu_catalog.dart';
import '../../domain/usecases/get_outlets.dart';

/// ViewModel (MVVM + ChangeNotifier) untuk fitur Menu & Beranda.
/// Memanggil Use Cases (GetMenuCatalog, GetOutlets, GetMenuRecommendation).
class MenuViewModel extends ChangeNotifier {
  final GetMenuCatalog _getMenuCatalog;
  final GetOutlets _getOutlets;
  final GetMenuRecommendation _getMenuRecommendation;

  MenuViewModel({
    required GetMenuCatalog getMenuCatalog,
    required GetOutlets getOutlets,
    required GetMenuRecommendation getMenuRecommendation,
  })  : _getMenuCatalog = getMenuCatalog,
        _getOutlets = getOutlets,
        _getMenuRecommendation = getMenuRecommendation;

  List<MenuItem> _items = const [];
  List<OutletEntity> _outlets = const [];
  bool _isLoading = false;
  bool _isAiExpanded = false;
  bool _loadingAi = false;
  Map<String, dynamic>? _aiRecommendation;
  String? _errorMessage;

  List<MenuItem> get items => _items;
  List<OutletEntity> get outlets => _outlets;
  bool get isLoading => _isLoading;
  bool get isAiExpanded => _isAiExpanded;
  bool get loadingAi => _loadingAi;
  Map<String, dynamic>? get aiRecommendation => _aiRecommendation;
  String? get errorMessage => _errorMessage;

  void toggleAiExpanded() {
    _isAiExpanded = !_isAiExpanded;
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _getMenuCatalog.execute();
      _outlets = await _getOutlets.execute();
    } catch (_) {
      _errorMessage = 'Gagal memuat daftar menu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestRecommendation({
    String query = '',
    String preference = '',
    int? budget,
    String? token,
  }) async {
    _loadingAi = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _aiRecommendation = await _getMenuRecommendation.execute(
        query: query,
        preference: preference,
        budget: budget,
        token: token,
      );
      _isAiExpanded = true;
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Permintaan tidak valid.';
    } catch (_) {
      _errorMessage = 'Gagal memuat rekomendasi AI.';
    } finally {
      _loadingAi = false;
      notifyListeners();
    }
  }
}

