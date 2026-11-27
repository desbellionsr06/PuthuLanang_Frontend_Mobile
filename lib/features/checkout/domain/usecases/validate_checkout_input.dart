import '../entities/checkout_entity.dart';

/// Use Case: Validasi aturan bisnis checkout (keranjang, slot pickup 17:30-21:30, kode promo).
class ValidateCheckoutInput {
  const ValidateCheckoutInput();

  void execute({
    required bool isLoggedIn,
    required bool isOperatingHours,
    required int itemCount,
    required int subtotal,
    required String pickupTimeSlot,
    required String pickupIsoDate,
    String? promoCode,
    int discount = 0,
  }) {
    if (!isLoggedIn) {
      throw StateError('Silakan masuk ke akun Anda terlebih dahulu.');
    }
    if (!isOperatingHours) {
      throw StateError(
        'Maaf, pemesanan hanya dibuka pada jam operasional Puthu Lanang pukul 17:30 – 21:30 WIB.',
      );
    }
    if (itemCount <= 0 || subtotal <= 0) {
      throw ArgumentError('Keranjang belanja Anda masih kosong.');
    }
    if (!CheckoutEntity.pickupTimeSlots.contains(pickupTimeSlot)) {
      throw ArgumentError(
        'Slot waktu pengambilan tidak valid. Pilih slot antara 17:30 – 21:30 WIB.',
      );
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(pickupIsoDate.trim())) {
      throw ArgumentError('Format tanggal pengambilan tidak valid.');
    }
    if (discount > 0 && subtotal < CheckoutEntity.promoMinTransaction) {
      throw ArgumentError(
        'Kupon promo hanya berlaku untuk transaksi minimal Rp 50.000.',
      );
    }
    if (promoCode != null &&
        promoCode.trim().isNotEmpty &&
        promoCode.trim().toUpperCase() != CheckoutEntity.promoCodeVip) {
      throw ArgumentError('Kode promo tidak dikenali.');
    }
  }
}

