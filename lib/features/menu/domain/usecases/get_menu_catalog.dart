import '../../../../models/menu_item.dart';
import '../repositories/menu_repository.dart';

/// Use Case: Mengambil daftar katalog menu jajanan dari backend / fallback.
class GetMenuCatalog {
  final MenuRepository _repository;

  const GetMenuCatalog(this._repository);

  Future<List<MenuItem>> execute() async {
    return _repository.getMenuCatalog();
  }
}

