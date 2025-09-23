import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClusterIconService {
  static final Map<int, BitmapDescriptor> _clusterIconCache = {};

  /// Get a cached cluster icon or create a new one
  static Future<BitmapDescriptor> getCachedClusterIcon(int clusterSize) async {
    if (_clusterIconCache.containsKey(clusterSize)) {
      return _clusterIconCache[clusterSize]!;
    }

    final icon = await _createClusterIcon(clusterSize);
    _clusterIconCache[clusterSize] = icon;
    return icon;
  }

  /// Create a custom cluster icon with the cluster size
  static Future<BitmapDescriptor> _createClusterIcon(int clusterSize) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120.0;
    const double circleSize = 100.0;

    // Draw circle background
    final Paint circlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      circleSize / 2,
      circlePaint,
    );

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      circleSize / 2,
      borderPaint,
    );

    // Draw text
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: clusterSize > 99 ? 24.0 : 28.0,
        fontWeight: FontWeight.bold,
      ),
    );

    paragraphBuilder.pushStyle(
      ui.TextStyle(color: Colors.white),
    );
    paragraphBuilder.addText(clusterSize.toString());

    final ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: circleSize));

    final double textX = (size - paragraph.width) / 2;
    final double textY = (size - paragraph.height) / 2;

    canvas.drawParagraph(paragraph, Offset(textX, textY));

    // Convert to bitmap
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Clear the icon cache
  static void clearCache() {
    _clusterIconCache.clear();
  }
}