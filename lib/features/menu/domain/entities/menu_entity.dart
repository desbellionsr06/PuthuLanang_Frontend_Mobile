/// Entity murni untuk item menu jajanan tradisional Puthu Lanang.
class MenuEntity {
  final String id;
  final String name;
  final String category;
  final String description;
  final String image;
  final int price;
  final int stock;
  final double rating;

  const MenuEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.image,
    required this.price,
    required this.stock,
    required this.rating,
  });
}

/// Entity murni untuk data gerai / outlet Puthu Lanang.
class OutletEntity {
  final String name;
  final String address;
  final String operatingHours;
  final double latitude;
  final double longitude;

  const OutletEntity({
    required this.name,
    required this.address,
    required this.operatingHours,
    required this.latitude,
    required this.longitude,
  });
}

