import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double distanceKm;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });
}

class LocationService {
  // Koordinat resmi Gerai Pusat Celaket Malang
  static const double _celaketLat = -7.9631;
  static const double _celaketLng = 112.6335;

  /// Mengambil lokasi GPS perangkat pengguna dan menghitung jarak (km) ke Gerai Celaket.
  static Future<LocationResult> getCurrentLocationToOutlet() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan GPS perangkat tidak aktif. Aktifkan lokasi terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Ubah melalui pengaturan perangkat.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _celaketLat,
      _celaketLng,
    );

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      distanceKm: double.parse((meters / 1000).toStringAsFixed(2)),
    );
  }
}

