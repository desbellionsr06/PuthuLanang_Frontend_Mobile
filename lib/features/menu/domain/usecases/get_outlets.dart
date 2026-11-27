import '../entities/menu_entity.dart';
import '../repositories/menu_repository.dart';

/// Use Case: Mengambil data gerai / outlet resmi Puthu Lanang.
class GetOutlets {
  final MenuRepository _repository;

  const GetOutlets(this._repository);

  Future<List<OutletEntity>> execute() async {
    return _repository.getOutlets();
  }
}

