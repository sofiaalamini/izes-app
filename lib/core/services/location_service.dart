import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocation {
  const DeviceLocation(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Posição do aparelho, usada no clima quando o sensor não tem coordenadas.
abstract class LocationService {
  /// Devolve `null` se o GPS estiver desligado, a permissão for negada ou a
  /// leitura demorar demais. Nunca lança erro.
  Future<DeviceLocation?> currentPosition();
}

class DeviceLocationService implements LocationService {
  @override
  Future<DeviceLocation?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return DeviceLocation(position.latitude, position.longitude);
    } catch (error) {
      debugPrint('LocationService: sem posição do aparelho: $error');
      return null;
    }
  }
}
