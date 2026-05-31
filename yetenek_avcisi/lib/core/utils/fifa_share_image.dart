import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// FIFA kart PNG — watermark + Story (9:16) formatı.
class FifaShareImage {
  static const Color _watermarkColor = Color(0xFF00FF87);

  static Future<Uint8List> addWatermark(Uint8List pngBytes) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final w = src.width;
    final h = src.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(src, Offset.zero, Paint());
    src.dispose();

    final paragraph = _watermarkParagraph('Scoutiq · yetenekavcisi.com');
    canvas.drawParagraph(
      paragraph,
      Offset(16, h - paragraph.height - 16),
    );

    final picture = recorder.endRecording();
    final out = await picture.toImage(w, h);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    if (data == null) throw Exception('Watermark PNG oluşturulamadı');
    return data.buffer.asUint8List();
  }

  static ui.Paragraph _watermarkParagraph(String text) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        textAlign: TextAlign.left,
      ),
    )
      ..pushStyle(ui.TextStyle(color: _watermarkColor))
      ..addText(text);
    final p = builder.build()..layout(const ui.ParagraphConstraints(width: 600));
    return p;
  }

  /// 1080×1920 Story — kart ortada, koyu zemin.
  static Future<Uint8List> toStoryFormat(Uint8List cardPng) async {
    const storyW = 1080;
    const storyH = 1920;

    final codec = await ui.instantiateImageCodec(cardPng);
    final frame = await codec.getNextFrame();
    final card = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bg = Paint()..color = const Color(0xFF0B0F19);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, storyW.toDouble(), storyH.toDouble()),
      bg,
    );

    final maxW = storyW * 0.88;
    final scale = maxW / card.width;
    final drawW = card.width * scale;
    final drawH = card.height * scale;
    final left = (storyW - drawW) / 2;
    final top = (storyH - drawH) / 2 - 40;

    canvas.save();
    canvas.translate(left, top);
    canvas.scale(scale);
    canvas.drawImage(card, Offset.zero, Paint());
    canvas.restore();
    card.dispose();

    final wm = _watermarkParagraph('Scoutiq');
    canvas.drawParagraph(wm, Offset(40, storyH - 80));

    final picture = recorder.endRecording();
    final img = await picture.toImage(storyW, storyH);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (data == null) throw Exception('Story PNG oluşturulamadı');
    return data.buffer.asUint8List();
  }
}
