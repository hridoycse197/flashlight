import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
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
  void initState() async {
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();

    await _listen;
    setState(() {
      if (mounted) isListening = true;
    });

    super.initState();
  }

  // void _doOnSpeechCommandMatch(String? command) {
  //   if (command == "start") {
  //     _service.confirmIntent(
  //         confirmationText: "Do you want to start?",
  //         positiveCommand: "yes",
  //         negativeCommand: "no");
  //   } else if (command == "stop") {
  //     _service.confirmIntent(
  //         confirmationText: "Do you want to stop?",
  //         positiveCommand: "yes",
  //         negativeCommand: "no");
  //   } else if (command == "hello") {
  //     _service.confirmIntent(
  //         confirmationText: "Hello to you!",
  //         positiveCommand: "hi",
  //         negativeCommand: "bye");
  //   } else if (command == "address") {
  //     _service.confirmIntent(
  //         confirmationText: "What is the address?",
  //         positiveCommand: "yes",
  //         negativeCommand: "no",
  //         voiceInputMessage: "Is the address correct?",
  //         voiceInput: true);
  //   }

  //   setState(() {
  //     confirmation = "$command [Confirmation Mode]";
  //   });
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;
    final isBackGround = state = AppLifecycleState.paused;
  }

  void updateSpeaker() {
    print("setSpeaker: pitch($_currentPitchValue) rate($_currentRateValue)");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(isListening ? Icons.mic_none : Icons.mic_off),
        onPressed: () {
          _listen();
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
                      // showText == 'yes'
                      //     ? _disableTorch(context)
                      //     : _enableTorch(context);
                    },
                    child: Text(confirmation == 'yes' ? 'Icon' : 'false'),
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
              showText == 'on'
                  ? _enableTorch(context)
                  : showText == 'Off'
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
