import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> ensureAll() async {
    // 📍 Location
    LocationPermission loc = await Geolocator.checkPermission();

    if (loc == LocationPermission.denied) {
      loc = await Geolocator.requestPermission();
    }

    if (loc == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }

    // 📷 Camera
    final cam = await Permission.camera.request();

    if (cam.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return cam.isGranted &&
        (loc == LocationPermission.always ||
            loc == LocationPermission.whileInUse);
  }
}
