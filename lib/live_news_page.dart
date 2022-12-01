import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flu_rive/audio_model.dart';
import 'package:flu_rive/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class LiveNewsPage extends StatefulWidget {
  const LiveNewsPage({super.key});

  @override
  State<LiveNewsPage> createState() => _LiveNewsPageState();
}

class _LiveNewsPageState extends State<LiveNewsPage> {
  late AudioPlayer player;
  StreamSubscription? positionSubscription;
  late AudioModel audioModel;
  AudioModel? audioModelOpt;

  /// 1眨眼睛  3说话  5浮动
  SMIInput<double>? levelInput;
  SMITrigger? rightTrigger;
  SMIInput<bool>? byeInput;
  Artboard? artboard;
  late StateMachineController stateController;
  String subtitle = "";
  PlayerState playerState = PlayerState.stopped;
  PositionInfo robotPosition = PositionInfo(
    x: 0,
    y: 0,
    width: 0,
    height: 0,
    scale: 1,
  );
  double dy = 56 + 120;
  PositionInfo imagePosition =
      PositionInfo(x: 0, y: 0, width: 465, height: 270, scale: 1);
  String inputImagePath = "assets/green_tree.jpg";
  List<String> images = [
    "assets/green_tree.jpg",
    "assets/大山.jpeg",
    "assets/sheep.jpeg",
    "assets/deer.jpeg",
    "assets/再见.jpeg"
  ];

  @override
  void initState() {
    super.initState();
    imagePosition.x = 386;
    imagePosition.y = 234 - dy;
    setupAnimatedRobot();
    setupAudio();
    loadAudioJson();
  }

  @override
  void dispose() {
    stateController.dispose();
    positionSubscription?.cancel();
    player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live News'),
      ),
      body: Column(
        children: [
          //播放器
          SizedBox(
            height: 120,
            width: double.infinity,
            child: PlayerWidget(
              player: player,
              onPlay: () {
                audioModelOpt = handleAudioInfo(audioModel);
                print("onPlay");
              },
              onPause: () {
                print("onPause");
              },
              onStop: () {
                print("onStop");
              },
            ),
          ),
          Expanded(
            child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/rive_bg.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Stack(
                  children: [
                    // 主播
                    Positioned(
                      left: robotPosition.x,
                      top: robotPosition.y,
                      child: artboard == null
                          ? const CircularProgressIndicator()
                          : Draggable(
                              onDragEnd: (detail) {
                                setState(() {
                                  robotPosition.x = detail.offset.dx;
                                  robotPosition.y = detail.offset.dy - dy;
                                });
                                print("onDraEnd:${detail.offset}");
                              },
                              ignoringFeedbackPointer: false,
                              childWhenDragging: const SizedBox.shrink(),
                              feedback: SizedBox(
                                width: 300 * robotPosition.scale,
                                height: 400 * robotPosition.scale,
                                child: Rive(artboard: artboard!),
                              ),
                              child: SizedBox(
                                width: 300 * robotPosition.scale,
                                height: 400 * robotPosition.scale,
                                child: Rive(artboard: artboard!),
                              ),
                            ),
                    ),
                    // 输入图片
                    inputImagePath.isNotEmpty
                        ? Positioned(
                            left: imagePosition.x,
                            top: imagePosition.y,
                            child: Draggable(
                              feedback: SizedBox(
                                width: imagePosition.width,
                                height: imagePosition.height,
                                child: imagePosition.width > 0 &&
                                        imagePosition.height > 0
                                    ? Image.asset(
                                        inputImagePath,
                                        fit: BoxFit.fill,
                                        // colorBlendMode: BlendMode.screen,
                                      )
                                    : Container(),
                              ),
                              onDragStarted: () {},
                              onDragEnd: (detail) {
                                setState(() {
                                  imagePosition.x = detail.offset.dx;
                                  imagePosition.y = detail.offset.dy - dy;
                                });
                                print("onDraEnd:${detail.offset}");
                              },
                              childWhenDragging: Container(),
                              ignoringFeedbackSemantics: false,
                              child: SizedBox(
                                width: imagePosition.width,
                                height: imagePosition.height,
                                child: imagePosition.width > 0 &&
                                        imagePosition.height > 0
                                    ? Image.asset(
                                        inputImagePath,
                                        fit: BoxFit.fill,
                                      )
                                    : Container(),
                              ),
                            ),
                          )
                        : Container(),

                    //新闻内容
                    Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: null,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24),
                        )),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  void setupAnimatedRobot() {
    rootBundle.load('assets/itv-robot-new.riv').then((data) async {
      final file = RiveFile.import(data);
      final mainArtboard = file.mainArtboard;
      final controller =
          StateMachineController.fromArtboard(mainArtboard, "ActiveState");
      if (controller != null) {
        mainArtboard.addController(controller);
        levelInput = controller.findInput("level");
        rightTrigger = controller.findInput<bool>("right") as SMITrigger;
        byeInput = controller.findInput("bye");
        SMIInput<bool>? standInput = controller.findInput("stand");

        standInput?.value = false;

        levelInput?.value = 1;

        stateController = controller;
      }
      setState(() => artboard = mainArtboard);
    });
  }

  void loadAudioJson() async {
    final String jsonString =
        await rootBundle.loadString('assets/audio_info.json');
    audioModel = AudioModel.fromJson(jsonDecode(jsonString));
  }

  void setupAudio() {
    player = AudioPlayer();
    player.setSource(AssetSource('audio-313.wav'));
    positionSubscription = player.onPositionChanged.listen(
      startPlay,
    );
    player.onSeekComplete.listen((_) {
      print("onSeekComplete");
      audioModelOpt = handleAudioInfo(audioModel);
    });
    player.onPlayerStateChanged.listen((event) {
      print("onPlayerStateChanged:$event");
      playerState = event;
    });
  }

  void startPlay(Duration p) {
    //字幕
    List<AudioData>? audios = audioModelOpt?.data;

    if (audios?.isNotEmpty == true && playerState == PlayerState.playing) {
      AudioData? firstObj = audios?.first;

      if ((firstObj?.bg ?? 0) <= p.inMilliseconds &&
          (firstObj?.ed ?? 0) >= p.inMilliseconds) {
        String onebest = firstObj?.onebest ?? "";
        subtitle = contentEx(onebest);
        levelInput?.value = 4;
      } else if (audios!.length > 1 &&
          (audios[1].bg ?? 0) <= p.inMilliseconds) {
        audioModelOpt?.data?.removeAt(0);
      } else {
        //没有字幕
        subtitle = "";
        levelInput?.value = 5;
      }
    } else {
      levelInput?.value = 5;
    }
    setState(() {});
  }

  AudioModel handleAudioInfo(AudioModel m) {
    int index = 0;
    int middle = 500;
    List<AudioData> audioDataList = m.data ?? [];
    List<AudioData> audioDataListOpt = [];
    if (audioDataList.isEmpty) {
      return m;
    }

    for (var i = 0; i < audioDataList.length; i++) {
      if (i < index || index >= audioDataList.length) {
        continue;
      }

      AudioData firstObj = AudioData.copy(audioDataList[index]);
      if (i == audioDataList.length - 1) {
        audioDataListOpt.add(firstObj);
        continue;
      }

      AudioData secondObj = AudioData.copy(audioDataList[index + 1]);
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
    return AudioModel(data: audioDataListOpt);
  }

  String contentEx(String content) {
    String contentOpt = content;
    if (content.contains('<#') && content.contains('#>')) {
      //截取<#>中间的内容
      int start = content.indexOf("<#") + 2;
      int end = content.indexOf("#>");
      String tagStr = content.substring(start, end);
      final imageIndex = int.tryParse(tagStr);

      if (imageIndex != null) {
        inputImagePath = images[imageIndex - 1];
      }

      //去除标识
      contentOpt = content.replaceAll("<#$tagStr#>", "");
    }

    return contentOpt;
  }
}

class PositionInfo {
  double x;
  double y;
  double width;
  double height;
  double scale;
  PositionInfo({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.scale,
  });
}
