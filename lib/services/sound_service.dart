import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show AudioElement;

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  
  // Sons disponíveis
  static const String _successSound = 'sounds/cash_register.mp3';
  static const String _errorSound = 'sounds/error.mp3';
  static const String _clickSound = 'sounds/click.mp3';
  
  // Players HTML5 para web (melhor compatibilidade)
  static html.AudioElement? _webSuccessPlayer;
  static html.AudioElement? _webErrorPlayer;
  static html.AudioElement? _webClickPlayer;
  static bool _webPlayersInitialized = false;
  
  /// Inicializa players HTML5 para web
  static void _initWebPlayers() {
    if (kIsWeb && !_webPlayersInitialized) {
      try {
        _webSuccessPlayer = html.AudioElement('assets/$_successSound');
        _webSuccessPlayer!.load();
        
        _webErrorPlayer = html.AudioElement('assets/$_errorSound');
        _webErrorPlayer!.load();
        
        _webClickPlayer = html.AudioElement('assets/$_clickSound');
        _webClickPlayer!.load();
        
        _webPlayersInitialized = true;
        print('✅ Players HTML5 inicializados para web');
      } catch (e) {
        print('Erro ao inicializar players web: $e');
      }
    }
  }
  
  /// Toca som de sucesso (venda concluída, cadastro salvo, etc)
  static Future<void> playSuccess() async {
    try {
      if (kIsWeb) {
        _initWebPlayers();
        _webSuccessPlayer?.currentTime = 0;
        await _webSuccessPlayer?.play();
      } else {
        await _player.play(AssetSource(_successSound));
      }
    } catch (e) {
      print('Erro ao tocar som de sucesso: $e');
    }
  }
  
  /// Toca som de erro (falha na operação, validação, etc)
  static Future<void> playError() async {
    try {
      if (kIsWeb) {
        _initWebPlayers();
        _webErrorPlayer?.currentTime = 0;
        await _webErrorPlayer?.play();
      } else {
        await _player.play(AssetSource(_errorSound));
      }
    } catch (e) {
      print('Erro ao tocar som de erro: $e');
    }
  }
  
  /// Toca som de click (botões, ações rápidas)
  static Future<void> playClick() async {
    try {
      if (kIsWeb) {
        _initWebPlayers();
        _webClickPlayer?.currentTime = 0;
        await _webClickPlayer?.play();
      } else {
        await _player.play(AssetSource(_clickSound));
      }
    } catch (e) {
      print('Erro ao tocar som de click: $e');
    }
  }
  
  /// Para o som atual
  static Future<void> stop() async {
    try {
      if (kIsWeb) {
        _webSuccessPlayer?.pause();
        _webErrorPlayer?.pause();
        _webClickPlayer?.pause();
      } else {
        await _player.stop();
      }
    } catch (e) {
      print('Erro ao parar som: $e');
    }
  }
  
  /// Libera recursos
  static Future<void> dispose() async {
    try {
      if (kIsWeb) {
        _webSuccessPlayer?.pause();
        _webErrorPlayer?.pause();
        _webClickPlayer?.pause();
        _webSuccessPlayer = null;
        _webErrorPlayer = null;
        _webClickPlayer = null;
        _webPlayersInitialized = false;
      } else {
        await _player.dispose();
      }
    } catch (e) {
      print('Erro ao liberar recursos de áudio: $e');
    }
  }
}
