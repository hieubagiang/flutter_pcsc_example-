import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pcsc_example/smart_card_constant.dart';
import 'package:pcsc_example/smart_card_helper.dart';

import 'models/apdu_command_model.dart';

void main() {
  MyApp? myApp;

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      myApp?.addError(details.toString());
    };

    runApp(myApp = MyApp());
  }, (Object error, StackTrace stack) {
    myApp?.addError(error.toString());
  });
}

class MyApp extends StatelessWidget {
  final GlobalKey<_MyAppBodyState> _myAppKey = GlobalKey();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: MyAppBody(key: _myAppKey)),
    );
  }

  void addError(String msg) {
    _myAppKey.currentState?.messages.add(Message.error(msg));
  }
}

class MyAppBody extends StatefulWidget {
  const MyAppBody({required Key key}) : super(key: key);

  @override
  _MyAppBodyState createState() {
    return _MyAppBodyState();
  }
}

enum MessageType { info, error }

class Message {
  final String content;
  final MessageType type;
  Message(this.type, this.content);

  static info(String content) {
    return Message(MessageType.info, content);
  }

  static error(String content) {
    return Message(MessageType.error, content);
  }
}

class _MyAppBodyState extends State<MyAppBody> {
  final ScrollController _scrollController = ScrollController();

  final List<Message> messages = [];
  final SmartCardHelper _smartCardHelper = SmartCardHelper();
  @override
  void initState() {
    super.initState();
    _smartCardHelper
        .connectCard(SmartCardConstant.appletID)
        .then((isConnectSuccess) {
      if (isConnectSuccess) {
        messages.add(Message.info('Connect card success'));
      } else {
        messages.add(Message.error('Connect card Failed'));
      }
    });
  }

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    TextStyle errorStyle = const TextStyle(color: Colors.red);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Column(children: [
          Expanded(
              child: ListView(
                  controller: _scrollController,
                  children: messages
                      .map((e) => Text(e.content,
                          style:
                              e.type == MessageType.error ? errorStyle : null))
                      .toList())),
          Container(
              margin: const EdgeInsets.all(10),
              child: ElevatedButton(
                  onPressed: () async {
                    _smartCardHelper.sendApdu(ApduCommand(
                      cla: SmartCardConstant.appletCla,
                      ins: SmartCardConstant.getFirstMessage,
                      p1: 0,
                      p2: 0,
                    ));
                  },
                  child: const Text("Get first Message")))
        ]))
      ]),
    );
  }
}
