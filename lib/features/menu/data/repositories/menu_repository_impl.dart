import '../../../../models/menu_item.dart';
import '../../../../services/api_service.dart';
import '../../domain/entities/menu_entity.dart';
import '../../domain/repositories/menu_repository.dart';

/// Implementasi Repository (Data Layer) untuk fitur Menu & Gerai.
class MenuRepositoryImpl implements MenuRepository {
  static const List<MenuItem> _fallbackMenu = [
    MenuItem(
      id: 'puthu-01',
      name: 'Puthu',
      category: 'pusaka',
      description:
          'Puthu beras pandan suji dengan gula aren cair dan kelapa gurih.',
      image: 'assets/images/puthu_bambu.png',
      price: 18000,
      stock: 120,
      rating: 4.9,
    ),
    MenuItem(
      id: 'klepon-02',
      name: 'Klepon',
      category: 'paling_laris',
      description: 'Ketan hijau kenyal dengan isian gula aren cair.',
      image: 'assets/images/klepon_pandan.png',
      price: 18000,
      stock: 95,
      rating: 4.9,
    ),
    MenuItem(
      id: 'cenil-03',
      name: 'Cenil',
      category: 'pusaka',
      description: 'Cenil warna-warni dengan juruh gula aren dan kelapa.',
      image: 'assets/images/cenil_pelangi.png',
      price: 18000,
      stock: 80,
      rating: 4.8,
    ),
    MenuItem(
      id: 'lupis-04',
      name: 'Lupis',
      category: 'pusaka',
      description: 'Ketan legit dengan kelapa parut dan juruh aren.',
      image: 'assets/images/lupis_ketan.png',
      price: 18000,
      stock: 65,
      rating: 4.9,
    ),
    MenuItem(
      id: 'paket-campur-05',
      name: 'Paket Campur',
      category: 'paket_campur',
      description: 'Puthu, klepon, cenil dan lupis dalam satu paket.',
      image: 'assets/images/paket_tampah.png',
      price: 20000,
      stock: 150,
      rating: 5.0,
    ),
    MenuItem(
      id: 'besek-hampers-06',
      name: 'Box Besek Bambu Hampers',
      category: 'besek',
      description: 'Hampers tradisional dengan paket campur dan juruh aren.',
      image: 'assets/images/paket_tampah.png',
      price: 45000,
      stock: 40,
      rating: 5.0,
    ),
  ];

  static const List<OutletEntity> _outlets = [
    OutletEntity(
      name: 'Gerai Asli Celaket',
      address: 'Jl. Jaksa Agung Suprapto No. 73, Klojen, Malang',
      operatingHours: '17:30 - 21:30',
      latitude: -7.9631,
      longitude: 112.6335,
    ),
  ];

  @override
  Future<List<MenuItem>> getMenuCatalog() async {
    try {
      final remote = await ApiService.getMenu();
      return remote.isNotEmpty ? remote : _fallbackMenu;
    } catch (_) {
      return _fallbackMenu;
    }
  }

  @override
  Future<List<OutletEntity>> getOutlets() async {
    return _outlets;
  }
}

