import '../../../../models/menu_item.dart';
import '../entities/menu_entity.dart';

/// Kontrak Repository (Domain Layer) untuk fitur Menu & Gerai.
abstract class MenuRepository {
  Future<List<MenuItem>> getMenuCatalog();
  Future<List<OutletEntity>> getOutlets();
}

