import 'dart:async';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:pcsc_example/extensions.dart';
import 'package:pcsc_example/smart_card_constant.dart';
import 'package:pcsc_example/smart_card_helper.dart';

import 'function_utils.dart';
import 'models/apdu_command_model.dart';
import 'models/message.dart';

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
            title: const Text('RSAKey example'),
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

class _MyAppBodyState extends State<MyAppBody> {
  final ScrollController _scrollController = ScrollController();

  final List<Message> messages = [];
  final SmartCardHelper _smartCardHelper = SmartCardHelper();
  RSAPublicKey? _publicKey;
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
            child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withOpacity(0.2)),
              ),
              width: MediaQuery.of(context).size.width / 2,
              child: ListView(
                  controller: _scrollController,
                  children: messages
                      .map((e) => SelectableText(e.content,
                          style:
                              e.type == MessageType.error ? errorStyle : null))
                      .toList()),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildButton(
                    title: 'Get first Message',
                    onPressed: () async {
                      await _sendApduCommand(ApduCommand(
                        cla: SmartCardConstant.appletCla,
                        ins: SmartCardConstant.getFirstMessage,
                        p1: 0,
                        p2: 0,
                      ));
                    }),
                _buildButton(
                    title: 'Get getPublicExponent',
                    onPressed: () async {
                      await _onTapGetPublicExponent();
                    }),
                _buildButton(
                    title: 'Get PublicModulus',
                    onPressed: () async {
                      await _onTapGetPublicModulus();
                    }),
                _buildButton(
                    title: 'Get getPublicKey',
                    onPressed: () async {
                      _publicKey = await getPublicKey();
                      if (_publicKey != null) {
                        messages.add(Message.info('Get PublicKey success'));
                        final String publicKeyPem =
                            CryptoUtils.encodeRSAPublicKeyToPemPkcs1(
                                _publicKey!);
                        messages.add(Message.info(publicKeyPem));
                        setState(() {});
                      } else {
                        messages.add(Message.error('Get PublicKey Failed'));
                      }
                    }),
                _buildButton(
                    title: 'Clear Message',
                    onPressed: () async {
                      messages.clear();
                      setState(() {});
                    }),
              ],
            ),
          ],
        ))
      ]),
    );
  }

  Future<void> _onTapGetPublicExponent() async {
    return await _sendApduCommand(ApduCommand(
      cla: SmartCardConstant.appletCla,
      ins: SmartCardConstant.getPublicExponent,
      p1: 0,
      p2: 0,
    ));
  }

  Future<void> _onTapGetPublicModulus() async {
    return await _sendApduCommand(ApduCommand(
      cla: SmartCardConstant.appletCla,
      ins: SmartCardConstant.getPublicModulus,
      p1: 0,
      p2: 0,
    ));
  }

  Container _buildButton({required String title, Function()? onPressed}) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: ElevatedButton(onPressed: onPressed, child: Text(title)));
  }

  Future<void> _sendApduCommand(ApduCommand apduCommand) async {
    messages.add(Message.info(
        'Send: ${apduCommand.toListInt().map((e) => e.toHex()).join(' ').toUpperCase()}'));
    final res = await _smartCardHelper.sendApdu(apduCommand);
    messages.add(Message.info(
        'Response: ${res!.sn.map((e) => e.toHex()).join(' ').toUpperCase()}'));
    setState(() {});
  }

  Future<RSAPublicKey?> getPublicKey() async {
    final exponentBytes = (await _smartCardHelper.sendApdu(ApduCommand(
      cla: SmartCardConstant.appletCla,
      ins: SmartCardConstant.getPublicExponent,
      p1: 0,
      p2: 0,
    )))
        ?.sn;

    final modulusBytes = (await _smartCardHelper.sendApdu(ApduCommand(
      cla: SmartCardConstant.appletCla,
      ins: SmartCardConstant.getPublicModulus,
      p1: 0,
      p2: 0,
    )))
        ?.sn;
    if ((exponentBytes?.isEmpty ?? false) || (modulusBytes?.isEmpty ?? false)) {
      return null;
    }

    ///TODO Call API to sav e public key
    final modulus = decodeBigInt(modulusBytes ?? []);
    final exponent = decodeBigInt(exponentBytes ?? []);

    return RSAPublicKey(modulus, exponent);
  }
}
