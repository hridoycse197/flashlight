import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:porcupine/porcupine_error.dart';
import 'package:rhino_flutter/rhino.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:torch_light/torch_light.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';

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
  PicovoiceManager? _picovoiceManager;
  //bg

  String result = "Say something!";
  String confirmation = "";
  String confirmationReply = "";
  String voiceReply = "";
  var isListening1 = false;

  @override
  initState() {
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();

    _listen;
    setState(() {
      if (mounted) isListening = true;
    });
    _initPicovoice();
    FlutterBackground.initialize(androidConfig: androidConfig);
    super.initState();
  }

  final String accessKey = "..."; // your Picovoice AccessKey

  void _initPicovoice() async {
    String platform = Platform.isAndroid ? "android" : "ios";
    String keywordPath = "assets/$platform/pico_clock_$platform.ppn";
    String contextPath = "assets/$platform/flutter_clock_$platform.rhn";

    try {
      _picovoiceManager = await PicovoiceManager.create(accessKey, keywordPath,
          _wakeWordCallback, contextPath, _inferenceCallback);
      _picovoiceManager!.start();
    } on PvError catch (ex) {
      print(ex);
    }
  }

  void _wakeWordCallback() {
    setState(() {});
  }

  void _inferenceCallback(RhinoInference inference) {
    if (inference.intent == 'light on') {
      setState(() {
        showText = inference.intent!;
      });
      _enableTorch(context);
    } else if (inference.intent == 'light off') {
      _disableTorch(context);
      showText = inference.intent!;
    }
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
                        _picovoiceManager!.start();
                        bool available = await _speech!.initialize(
                          options: [],
                          finalTimeout: const Duration(minutes: 5),
                          onStatus: (val) => print('onStatus: $val'),
                          onError: (val) => print('onError: $val'),
                        );
                        if (available) {
                          setState(() => isListening = true);
                          _speech!.listen(
                            onResult: (val) => setState(() {
                              setState(() {
                                showText = val.recognizedWords.toLowerCase();
                                showText == 'light on'
                                    ? _enableTorch(context)
                                    : showText == 'light off'
                                        ? _disableTorch(context)
                                        : Null;
                              });
                              showText = val.recognizedWords.toLowerCase();
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
                    showText = val.recognizedWords.toLowerCase();
                    showText == 'light on'
                        ? _enableTorch(context)
                        : showText == 'light off'
                            ? _disableTorch(context)
                            : Null;
                  });
                  showText = val.recognizedWords.toLowerCase();
                }));
      }
    } else {
      setState(() => isListening = false);
      _speech!.stop();
    }
  }
}
