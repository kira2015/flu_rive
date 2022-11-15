import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  SMIInput<bool>? standInput;//动静
  SMIInput<bool>? byeInput;
  Artboard? artboard;
  late StateMachineController stateController;
  @override
  void initState() {
    rootBundle.load('assets/itv-robot.riv').then((data) async {
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
      body: Container(
        color: Colors.purple,
        child: Column(
          children: [
            //按钮区
            Row(
              children: [

                ElevatedButton(
                    onPressed: () {
                      standInput?.value = false;
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
            artboard == null
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 500,
                    child: Rive(artboard: artboard!),
                  )
          ],
        ),
      ),
    );
  }
}

/// An example showing how to drive a StateMachine via one numeric input.
class StateMachineSkills extends StatefulWidget {
  const StateMachineSkills({Key? key}) : super(key: key);

  @override
  _StateMachineSkillsState createState() => _StateMachineSkillsState();
}

class _StateMachineSkillsState extends State<StateMachineSkills> {
  /// Tracks if the animation is playing by whether controller is running.
  bool get isPlaying => _controller?.isActive ?? false;

  Artboard? _riveArtboard;
  StateMachineController? _controller;
  SMIInput<double>? _levelInput;

  @override
  void initState() {
    super.initState();

    // Load the animation file from the bundle, note that you could also
    // download this. The RiveFile just expects a list of bytes.
    rootBundle.load('assets/skills.riv').then(
      (data) async {
        // Load the RiveFile from the binary data.
        final file = RiveFile.import(data);

        // The artboard is the root of the animation and gets drawn in the
        // Rive widget.
        final artboard = file.mainArtboard;
        var controller =
            StateMachineController.fromArtboard(artboard, 'Designer\'s Test');
        if (controller != null) {
          artboard.addController(controller);
          _levelInput = controller.findInput('Level');
        }
        setState(() => _riveArtboard = artboard);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Skills Machine'),
      ),
      body: Center(
        child: _riveArtboard == null
            ? const SizedBox()
            : Stack(
                children: [
                  Positioned.fill(
                    child: Rive(
                      artboard: _riveArtboard!,
                    ),
                  ),
                  Positioned.fill(
                    bottom: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          child: const Text('Beginner'),
                          onPressed: () => _levelInput?.value = 0,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          child: const Text('Intermediate'),
                          onPressed: () => _levelInput?.value = 1,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          child: const Text('Expert'),
                          onPressed: () => _levelInput?.value = 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
