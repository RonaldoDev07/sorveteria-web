import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  // Criar ícone simples com fundo rosa e emoji de sorvete
  final sizes = [48, 72, 96, 144, 192]; // mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
  final folders = ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi'];
  
  for (var i = 0; i < sizes.length; i++) {
    await createIcon(sizes[i], folders[i]);
  }
  
  print('✅ Ícones gerados com sucesso!');
}

Future<void> createIcon(int size, String folder) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Fundo rosa
  final paint = Paint()..color = Color(0xFFFF69B4);
  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
  
  // Texto "🍦"
  final textPainter = TextPainter(
    text: TextSpan(
      text: '🍦',
      style: TextStyle(fontSize: size * 0.6),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File('android/app/src/main/res/$folder/ic_launcher.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  
  print('✅ Criado: $folder/ic_launcher.png');
}
