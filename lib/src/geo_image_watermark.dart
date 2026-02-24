import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class GeoImageWatermark {
  static Future<File> stamp({required File imageFile}) async {
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(image, Offset.zero, Paint());

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String address = '';
    try {
      final place = (await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ))
          .first;

      address =
      '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
    } catch (_) {}

    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text:
            '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n',
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF)),
          ),
          TextSpan(
            text:
            '🕒 ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}\n',
            style:
            const TextStyle(fontSize: 24, color: Color(0xFFFFFFFF)),
          ),
          TextSpan(
            text: '🏠 $address',
            style:
            const TextStyle(fontSize: 24, color: Color(0xFFFFFFFF)),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: image.width.toDouble() * 0.95);

    const margin = 20.0;
    const padding = 14.0;

    final offset = Offset(
      margin,
      image.height.toDouble() - textPainter.height - margin,
    );

    final bgPaint = Paint()..color = const Color(0x99000000);

    final rect = Rect.fromLTWH(
      offset.dx - padding,
      offset.dy - padding,
      textPainter.width + padding * 2,
      textPainter.height + padding * 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      bgPaint,
    );

    textPainter.paint(canvas, offset);

    final img =
    await recorder.endRecording().toImage(image.width, image.height);

    final byteData =
    await img.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/geo_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await out.writeAsBytes(byteData!.buffer.asUint8List());
    return out;
  }
}