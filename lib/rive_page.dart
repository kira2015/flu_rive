import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flu_rive/audio_model.dart';
import 'package:flu_rive/player_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rive/rive.dart';

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

class PlayInfo {
  String subTitle;
  bool changePicture;
  bool slow;
  bool bye;
  PlayInfo(
      {required this.subTitle,
      this.changePicture = false,
      this.slow = false,
      this.bye = false});
}

class RivePage extends StatefulWidget {
  const RivePage({super.key});

  @override
  State<RivePage> createState() => _RivePageState();
}

class _RivePageState extends State<RivePage> {
  /// 1眨眼睛  3说话  5浮动
  SMIInput<double>? levelInput;
  SMITrigger? rightTrigger;
  SMIInput<bool>? standInput; //动静
  SMIInput<bool>? byeInput;
  Artboard? artboard;
  late StateMachineController stateController;
  final ImagePicker picker = ImagePicker();
  String backgroundImagePath = "";
  String inputImagePath = "";
  List images = [
    "assets/green_tree.jpg",
    "assets/大山.jpeg",
    "assets/sheep.jpeg",
    "assets/deer.jpeg",
    "assets/再见.jpeg"
  ];
  int imageSelect = 0;
  double riveDy = 0;
  final GlobalKey _riveKey = GlobalKey();
  PositionInfo robotPosition = PositionInfo(
    x: 0,
    y: 0,
    width: 0,
    height: 0,
    scale: 1,
  );
  PositionInfo imagePosition =
      PositionInfo(x: 0, y: 0, width: 420, height: 270, scale: 1);

  ///新闻内容
  String newsContent =
      "今天是个好日子,疫情三年终于要结束了,沿着绿树成荫的康庄大道,开始了我的这一次说走就走旅行.#来到了莫里亚蒂的乌拉尔境内的天空之城，除了和蔼和亲的莫里亚蒂人之外，#我遇到了神蒂亚戈山羊，你看它的身躯异常高大、健壮，像钢铁般的树桩一样。哇 这是这是这是，#还有那迷失森林里的神鹿,它每一步都印着浓浓的梅花香.这一次的天空城之游毕生难忘,时间差不多了,再见.";
  String subtitle = "";
  Timer? timer;
  late AudioPlayer player;
  StreamSubscription? positionSubscription;
  late AudioModel audioModel;
  AudioModel? audioModelOpt;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      RenderBox renderBox =
          _riveKey.currentContext?.findRenderObject() as RenderBox;
      riveDy = renderBox.localToGlobal(Offset.zero).dy;
    });

    rootBundle.load('assets/itv-robot-new.riv').then((data) async {
      final file = RiveFile.import(data);
      final mainArtboard = file.mainArtboard;
      final controller =
          StateMachineController.fromArtboard(mainArtboard, "ActiveState");
      if (controller != null) {
        mainArtboard.addController(controller);
        levelInput = controller.findInput("level");
        rightTrigger = controller.findInput<bool>("right") as SMITrigger;
        standInput = controller.findInput("stand");
        byeInput = controller.findInput("bye");

        standInput?.value = false;

        levelInput?.value = 1;

        stateController = controller;
      }
      setState(() => artboard = mainArtboard);
    });

    setupAudio();

    super.initState();
  }

  void loadAudioJson() async {
    final String jsonString =
        await rootBundle.loadString('assets/audio_info_test.json');
    audioModel = AudioModel.fromJson(jsonDecode(jsonString));
  }

  void setupAudio() {
    player = AudioPlayer();
    player.setSource(AssetSource('audio-128.wav'));
    loadAudioJson();

    positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() {
        //字幕
        List<AudioData>? audios = audioModelOpt?.data;

        if (audios?.isNotEmpty == true) {
          AudioData? firstObj = audios?.first;

          if ((firstObj?.bg ?? 0) <= p.inMilliseconds &&
              (firstObj?.ed ?? 0) >= p.inMilliseconds) {
            subtitle = firstObj?.onebest ?? "";
            levelInput?.value = 4;
          } else if (audios!.length > 1 &&
              (audios[1].bg ?? 0) <= p.inMilliseconds) {
            audioModelOpt?.data?.removeAt(0);
          } else {
            //没有字幕
            subtitle = "";
            levelInput?.value = 5;
          }
        }
      }),
    );
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
  void dispose() {
    stateController.dispose();
    positionSubscription?.cancel();
    player.dispose();
    timer?.cancel();
    super.dispose();
  }

  //更换图片
  void changePicture() {
    imageSelect++;
    inputImagePath = images[imageSelect % images.length];
  }

  List<PlayInfo> handleText() {
    List<PlayInfo> li = [];
    if (newsContent.isEmpty) {
      return li;
    }
    newsContent = newsContent.replaceAll(r'。', '.');
    newsContent = newsContent.replaceAll(r'，', ',');
    newsContent = newsContent.replaceAll(r'？', '?');
    newsContent = newsContent.replaceAll(r'！', '!');

    for (var element in newsContent.split('.')) {
      final items = element.split(',');
      for (var i = 0; i < items.length; i++) {
        if (items[i].isNotEmpty) {
          bool changePicture = items[i].contains("#") ? true : false;
          String subTitle = items[i].replaceAll("#", "");
          bool bye = items[i].contains("再见") ? true : false;
          li.add(PlayInfo(
              subTitle: subTitle, changePicture: changePicture, bye: bye));
        }

        if (i == items.length - 1) {
          //最后一个需要加. 停顿
          li.add(PlayInfo(subTitle: "", slow: true));
        }
      }
    }

    return li;
  }

  @override
  Widget build(BuildContext context) {
    var imagesBtn = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Text('图片:'),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: TextField(
                style: const TextStyle(fontSize: 10),
                onSubmitted: (value) {
                  setState(() {
                    imagePosition.x = double.tryParse(value) ?? imagePosition.x;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'X',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: TextField(
                style: const TextStyle(fontSize: 10),
                onSubmitted: (value) {
                  setState(() {
                    imagePosition.y = double.tryParse(value) ?? imagePosition.y;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Y',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: TextField(
                style: const TextStyle(fontSize: 10),
                onSubmitted: (value) {
                  setState(() {
                    imagePosition.width =
                        double.tryParse(value) ?? imagePosition.width;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'width',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: TextField(
                style: const TextStyle(fontSize: 10),
                onSubmitted: (value) {
                  setState(() {
                    imagePosition.height =
                        double.tryParse(value) ?? imagePosition.height;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'height',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    var robotBtn = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Text('主播位置'),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: TextField(
                style: const TextStyle(fontSize: 10),
                onSubmitted: (value) {
                  setState(() {
                    robotPosition.x = double.tryParse(value) ?? robotPosition.x;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'X',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: TextField(
                style: const TextStyle(fontSize: 10),
                onSubmitted: (value) {
                  setState(() {
                    robotPosition.y = double.tryParse(value) ?? robotPosition.y;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Y',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('scale:'),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: TextField(
                style: const TextStyle(fontSize: 10),
                onSubmitted: (value) {
                  setState(() {
                    robotPosition.scale =
                        double.tryParse(value) ?? robotPosition.scale;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '1.0',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    var robotAction = Wrap(
      spacing: 10,
      children: [
        ElevatedButton(
            onPressed: () {
              // standInput?.value = !(standInput?.value ?? false);
              handleAudioInfo();
            },
            child: const Text('恢复字幕数据')),
        ElevatedButton(
            onPressed: () {
              levelInput?.value = 2;
            },
            child: const Text('说话+眨眼睛')),
        ElevatedButton(
            onPressed: () {
              levelInput?.value = 5;
            },
            child: const Text('浮动')),
        ElevatedButton(
            onPressed: () {
              levelInput?.value = 4;
            },
            child: const Text('说话+浮动+眨眼睛')),
        ElevatedButton(
            onPressed: () {
              rightTrigger?.fire();
            },
            child: const Text('向右看')),
        ElevatedButton(
            onPressed: () {
              byeInput?.value = true;
            },
            child: const Text('再见')),
        ElevatedButton(
            onPressed: () async {
              // final image = await picker.pickImage(
              //     source: ImageSource.gallery);
              // if (image != null) {
              //   setState(() {
              //     backgroundImagePath = image.path;
              //   });
              // }
              setState(() {
                backgroundImagePath = "assets/rive_bg.png";
              });
            },
            child: const Text('更换背景')),
        ElevatedButton(
            onPressed: () async {
              // final image = await picker.pickImage(
              //     source: ImageSource.gallery);
              // if (image != null) {
              //   setState(() {
              //     inputImagePath = image.path;
              //   });
              // }
              setState(() {
                inputImagePath = "assets/green_tree.jpg";
              });
            },
            child: const Text('插入图片')),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive'),
      ),
      body: Column(
        children: [
          //按钮区
          Container(
            color: Colors.grey,
            child: Column(
              children: [
                robotAction,

                // 获取图片
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    robotBtn,
                    //图片编辑
                    imagesBtn,

                    ElevatedButton(
                        onPressed: () {
                          standInput?.value = false;
                          imageSelect = 0;
                          List<PlayInfo> playData = handleText();
                          timer = Timer.periodic(const Duration(seconds: 1),
                              (timer) {
                            print("tick: ${timer.tick}");
                            if (timer.tick > playData.length) {
                              timer.cancel();
                              standInput?.value = true;
                              return;
                            }
                            PlayInfo playInfo = playData[timer.tick - 1];

                            if (playInfo.changePicture) {
                              changePicture();
                              rightTrigger?.fire();
                            }
                            if (playInfo.slow) {
                              levelInput?.value = 5;
                            } else {
                              //说话
                              levelInput?.value = 4;
                            }
                            setState(() {
                              subtitle = playInfo.subTitle;
                            });
                            if (playInfo.bye) {
                              byeInput?.value = true;
                              changePicture();
                              return;
                            }
                          });
                        },
                        child: const Text("开始"))
                  ],
                ),

                PlayerWidget(player: player),
              ],
            ),
          ),

          Expanded(
            child: Container(
              key: _riveKey,
              decoration: BoxDecoration(
                image: backgroundImagePath.isNotEmpty
                    ? DecorationImage(
                        image: (kIsWeb
                                ? NetworkImage(backgroundImagePath)
                                : AssetImage(backgroundImagePath))
                            as ImageProvider<Object>,
                        fit: BoxFit.fill,
                      )
                    : null,
              ),
              child: artboard == null
                  ? const CircularProgressIndicator()
                  : Stack(children: [
                      Positioned(
                        left: robotPosition.x,
                        top: robotPosition.y,
                        child: Draggable(
                          onDragEnd: (detail) {
                            setState(() {
                              robotPosition.x = detail.offset.dx;
                              robotPosition.y = detail.offset.dy - riveDy;
                            });
                            print(
                                "onDraEnd:${detail.offset - Offset(0, riveDy)}");
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
                                    imagePosition.y = detail.offset.dy - riveDy;
                                  });
                                  print(
                                      "onDraEnd:${detail.offset - Offset(0, riveDy)}");
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
                    ]),
            ),
          )
        ],
      ),
    );
  }
}
