import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rive/rive.dart';

class RivePage extends StatefulWidget {
  const RivePage({super.key});

  @override
  State<RivePage> createState() => _RivePageState();
}

class _RivePageState extends State<RivePage> {
  /// 1眨眼睛  3说话  5浮动
  SMIInput<double>? level;
  SMIInput<bool>? rightInput;
  SMIInput<bool>? standInput; //动静
  SMIInput<bool>? byeInput;
  Artboard? artboard;
  late StateMachineController stateController;
  final ImagePicker picker = ImagePicker();
  String backgroundImagePath = "";
  String inputImagePath = "";

  @override
  void initState() {
    rootBundle.load('assets/itv-robot-new.riv').then((data) async {
      final file = RiveFile.import(data);
      final mainArtboard = file.mainArtboard;
      final controller =
          StateMachineController.fromArtboard(mainArtboard, "ActiveState");
      if (controller != null) {
        mainArtboard.addController(controller);
        level = controller.findInput("level");
        rightInput = controller.findInput("right");
        standInput = controller.findInput("stand");
        byeInput = controller.findInput("bye");

        standInput?.value = true;

        level?.value = 1;

        stateController = controller;
      }
      setState(() => artboard = mainArtboard);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                Wrap(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          standInput?.value = !(standInput?.value ?? false);
                        },
                        child: const Text('眨眼睛')),
                    ElevatedButton(
                        onPressed: () {
                          level?.value = 2;
                        },
                        child: const Text('说话+眨眼睛')),
                    ElevatedButton(
                        onPressed: () {
                          level?.value = 5;
                        },
                        child: const Text('浮动')),
                    ElevatedButton(
                        onPressed: () {
                          level?.value = 4;
                        },
                        child: const Text('说话+浮动+眨眼睛')),
                    ElevatedButton(
                        onPressed: () {
                          rightInput?.value = true;
                        },
                        child: const Text('向右看')),
                    ElevatedButton(
                        onPressed: () {
                          byeInput?.value = true;
                        },
                        child: const Text('再见')),
                  ],
                ),

                // 获取图片
                Row(
                  children: [
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
                    Card(
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
                    ),
                    //图片编辑
                    Card(
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
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
                        left: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 300,
                          height: 400,
                          child: Rive(artboard: artboard!),
                        ),
                      ),
                      inputImagePath.isNotEmpty
                          ? Positioned(
                              left: 0,
                              top: 0,
                              child: SizedBox(
                                width: 300,
                                height: 400,
                                child: Image.asset(
                                  inputImagePath,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            )
                          : Container()
                    ]),
            ),
          )
        ],
      ),
    );
  }
}
