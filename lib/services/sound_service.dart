import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static const String _successSound = 'sounds/cash_register.mp3';
  static const String _errorSound = 'sounds/error.mp3';
  static const String _clickSound = 'sounds/click.mp3';

  static Future<void> playSuccess() async {
    try {
      await _player.play(AssetSource(_successSound));
    } catch (_) {}
  }

  static Future<void> playError() async {
    try {
      await _player.play(AssetSource(_errorSound));
    } catch (_) {}
  }

  static Future<void> playClick() async {
    try {
      await _player.play(AssetSource(_clickSound));
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
