import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; //for playing sounds

void main() => runApp(const XylophoneApp());

class XylophoneApp extends StatelessWidget {
  const XylophoneApp({super.key});

  Future<void> _playSound(int noteNumber) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('note$noteNumber.wav'));
      print('Sound played successfully.');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Widget _buildSoundButton(int soundId, Color color){
    return Expanded(
      child: TextButton(
        onPressed: () => _playSound(soundId),
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          backgroundColor: color,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  //to remove debug banner
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSoundButton(1, Colors.red),
              _buildSoundButton(2, Colors.orange),
              _buildSoundButton(3, Colors.yellow),
              _buildSoundButton(4, Colors.green),
              _buildSoundButton(5, Colors.teal),
              _buildSoundButton(6, Colors.blue),
              _buildSoundButton(7, Colors.purple),
            ],
          ),
        ),
      ),
    );
  }
}
