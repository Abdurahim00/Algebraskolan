import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playSuccessSound() async {
    await _audioPlayer.play(AssetSource('audio/success.mp3'));
  }
}
