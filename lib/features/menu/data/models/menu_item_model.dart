import '../../../../models/menu_item.dart';
import '../../domain/entities/menu_entity.dart';

/// Model mapper (Data Layer) antara JSON backend, MenuEntity, dan MenuItem.
class MenuItemModel extends MenuEntity {
  const MenuItemModel({
    required super.id,
    required super.name,
    required super.category,
    required super.description,
    required super.image,
    required super.price,
    required super.stock,
    required super.rating,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: '${json['id']}',
      name: '${json['nama'] ?? json['name'] ?? 'Menu'}',
      category: '${json['kategori'] ?? json['category'] ?? 'Tradisional'}',
      description: '${json['deskripsi'] ?? json['description'] ?? ''}',
      image: '${json['gambar'] ?? json['image'] ?? '/images/puthu_bambu.png'}',
      price: int.tryParse('${json['harga'] ?? json['price'] ?? 0}') ?? 0,
      stock: int.tryParse('${json['stok'] ?? json['stockRemaining'] ?? 0}') ?? 0,
      rating: double.tryParse('${json['rating'] ?? 4.9}') ?? 4.9,
    );
  }

  MenuItem toMenuItem() {
    return MenuItem(
      id: id,
      name: name,
      category: category,
      description: description,
      image: image,
      price: price,
      stock: stock,
      rating: rating,
    );
  }
}

