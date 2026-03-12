import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  
  // Sons disponíveis
  static const String _successSound = 'sounds/cash_register.mp3';
  static const String _errorSound = 'sounds/error.mp3';
  static const String _clickSound = 'sounds/click.mp3';
  
  /// Toca som de sucesso (venda concluída, cadastro salvo, etc)
  static Future<void> playSuccess() async {
    try {
      await _player.play(AssetSource(_successSound));
    } catch (e) {
      print('Erro ao tocar som de sucesso: $e');
    }
  }
  
  /// Toca som de erro (falha na operação, validação, etc)
  static Future<void> playError() async {
    try {
      await _player.play(AssetSource(_errorSound));
    } catch (e) {
      print('Erro ao tocar som de erro: $e');
    }
  }
  
  /// Toca som de click (botões, ações rápidas)
  static Future<void> playClick() async {
    try {
      await _player.play(AssetSource(_clickSound));
    } catch (e) {
      print('Erro ao tocar som de click: $e');
    }
  }
  
  /// Para o som atual
  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Erro ao parar som: $e');
    }
  }
  
  /// Libera recursos
  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      print('Erro ao liberar recursos de áudio: $e');
    }
  }
}
