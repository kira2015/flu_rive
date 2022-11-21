import 'dart:async';
import 'dart:convert';

import 'package:flu_rive/audio_model.dart';
import 'package:flu_rive/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  late AudioPlayer player;
  StreamSubscription? positionSubscription;
  late AudioModel audioModel;
  AudioModel? audioModelOpt;
  // 字幕
  String subTitle = "";

  @override
  void initState() {
    player = AudioPlayer();
    player.setSource(AssetSource('audio-22.wav'));
    loadAudioJson();

    positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() {
        //字幕
        List<AudioData>? audios = audioModelOpt?.data;

        if (audios?.isNotEmpty == true) {
          AudioData? firstObj = audios?.first;

          if ((firstObj?.bg ?? 0) <= p.inMilliseconds &&
              (firstObj?.ed ?? 0) >= p.inMilliseconds) {
            subTitle = firstObj?.onebest ?? "";
          } else if (audios!.length > 1 &&
              (audios[1].bg ?? 0) <= p.inMilliseconds) {
            audioModelOpt?.data?.removeAt(0);
          } else {
            subTitle = "";
          }
        }
      }),
    );

    super.initState();
  }
  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  void loadAudioJson() async {
    final String jsonString =
        await rootBundle.loadString('assets/audio_info.json');
    audioModel = AudioModel.fromJson(jsonDecode(jsonString));
    
  }

  void handleAudioInfo() {
    int index = 0;
    int middle = 500;
    List<AudioData> audioDataList = audioModel.data ?? [];
    List<AudioData> audioDataListOpt = [];
    for (var i = 0; i < audioDataList.length; i++) {
      if (i < index || index >= audioDataList.length) {
        continue;
      }

      AudioData firstObj = audioDataList[index];
      if (i == audioDataList.length - 1) {
        audioDataListOpt.add(firstObj);
        continue;
      }

      AudioData secondObj = audioDataList[index + 1];
      if ((secondObj.bg ?? 0) - (firstObj.ed ?? 0) > middle) {
        audioDataListOpt.add(firstObj);
        index = i + 1;
      } else {
        audioDataListOpt.add(firstObj
          ..ed = secondObj.ed
          ..onebest = "${firstObj.onebest}${secondObj.onebest}");
        index = i + 2;
      }
    }
    audioModelOpt = AudioModel(data: audioDataListOpt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio'),
      ),
      body: Column(
        children: [
          PlayerWidget(player: player),
          const Divider(color: Colors.black),
          //控制面板
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.star_outline),
                onPressed: () {
                  handleAudioInfo();
                },
              ),
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () {},
              ),
            ],
          ),

          //字幕
          Center(
            child: Text(
              subTitle,
              style: const TextStyle(color: Colors.blue, fontSize: 24),
            ),
          )
        ],
      ),
    );
  }
}
