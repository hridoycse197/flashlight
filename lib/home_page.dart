import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:torch_light/torch_light.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool checkTourch = true;
  stt.SpeechToText? _speech;
  bool isListening = false;
  String showText = 'Press the button to talk';
  double _confidence = 1.0;

  //bg

  String result = "Say something!";
  String confirmation = "";
  String confirmationReply = "";
  String voiceReply = "";
  var isListening1 = false;

  double _currentPitchValue = 100;
  double _currentRateValue = 100;
  @override
  initState() {
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();

    _listen;
    setState(() {
      if (mounted) isListening = true;
    });
    FlutterBackground.initialize(androidConfig: androidConfig);
    super.initState();
  }

  final androidConfig = const FlutterBackgroundAndroidConfig(
    notificationTitle: "flutter_background example app",
    notificationText:
        "Background notification for keeping the example app running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(isListening ? Icons.mic_none : Icons.mic_off),
        onPressed: () {
          setState(() {
            _listen();
          });
        },
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _isTorchAvailable(context),
          builder: (context, AsyncSnapshot snapshot) {
            return Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        checkTourch = !checkTourch;
                      });
                      print(checkTourch);
                    },
                    child: Text(confirmation == 'yes' ? 'Icon' : 'false'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FlutterBackground.enableBackgroundExecution();
                      if (FlutterBackground.isBackgroundExecutionEnabled) {
                        bool available = await _speech!.initialize(
                          finalTimeout: const Duration(minutes: 5),
                          onStatus: (val) => print('onStatus: $val'),
                          onError: (val) => print('onError: $val'),
                        );
                        if (available) {
                          setState(() => isListening = true);
                          _speech!.listen(
                            onResult: (val) => setState(() {
                              setState(() {
                                showText = val.recognizedWords;
                                showText == 'light on'
                                    ? _enableTorch(context)
                                    : showText == 'light off'
                                        ? _disableTorch(context)
                                        : Null;
                              });
                              showText = val.recognizedWords;
                              if (val.hasConfidenceRating &&
                                  val.confidence > 0) {
                                _confidence = val.confidence;
                              }
                            }),
                          );
                        }
                      }
                    },
                    child: Text("enable"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FlutterBackground.disableBackgroundExecution();
                      setState(() => isListening = false);
                      _speech!.stop();
                    },
                    child: Text("disable"),
                  ),
                  Text(showText)
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _isTorchAvailable(BuildContext context) async {
    try {
      return await TorchLight.isTorchAvailable();
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> _enableTorch(BuildContext context) async {
    try {
      await TorchLight.enableTorch();
    } on Exception catch (_) {}
  }

  Future<void> _disableTorch(BuildContext context) async {
    try {
      await TorchLight.disableTorch();
    } on Exception catch (_) {}
  }

  void _listen() async {
    if (!isListening) {
      bool available = await _speech!.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => isListening = true);
        _speech!.listen(
          onResult: (val) => setState(() {
            setState(() {
              showText = val.recognizedWords;
              showText == 'light on'
                  ? _enableTorch(context)
                  : showText == 'light off'
                      ? _disableTorch(context)
                      : Null;
            });
            showText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => isListening = false);
      _speech!.stop();
    }
  }
}
