import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class TextBubble extends StatelessWidget {
  const TextBubble({
    Key? key,
    required this.text,
    required this.isCurrentUser,
    this.color = Colors.white,
  }) : super(key: key);
  final String text;
  final bool isCurrentUser;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // asymmetric padding
      padding: EdgeInsets.fromLTRB(
        isCurrentUser ? 64.0 : 16.0,
        4,
        isCurrentUser ? 16.0 : 64.0,
        4,
      ),
      child: Align(
        // align the child within the container
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            color: isCurrentUser ? color : Colors.white38,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: isCurrentUser ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

class VoiceBubble extends StatelessWidget {
  const VoiceBubble({
    Key? key,
    required this.isCurrentUser,
    this.color = Colors.white,
    required this.time,
    required this.filePath,
    required this.player
  }) : super(key: key);
  final bool isCurrentUser;
  final int time;
  final Color? color;
  final String filePath;
  final FlutterSoundPlayer player;

  void play() async {
    var exists = File(filePath).existsSync();
    if (exists){
      if (player.isPlaying) {
        player.stopPlayer();
      }
      await player.startPlayer(
        fromURI: filePath,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        whenFinished: (){
          _stopPlayer();
        },
      );
      }
    }
  void _stopPlayer() async {
    await player.stopPlayer().then((value) => {});
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      // asymmetric padding
      padding: EdgeInsets.fromLTRB(
        isCurrentUser ? 64.0 : 16.0,
        4,
        isCurrentUser ? 16.0 : 64.0,
        4,
      ),
      child: Align(
        // align the child within the container
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          height: 42,
          width: time == 0 ? 50 : (50 + 10 * time).toDouble(),
          child: DecoratedBox(
            // chat bubble decoration
            decoration: BoxDecoration(
              color: isCurrentUser ? color : Colors.white38,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: play,
                child: Container(
                  alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                  color: isCurrentUser ? color : Colors.white38,
                  child: Text(
                      "$time\"",
                  style: TextStyle(
                      color: isCurrentUser ? Colors.white: Colors.black87,
                      fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        )
      ),
    )
    );
  }
}

