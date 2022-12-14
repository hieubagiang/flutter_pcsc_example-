import 'package:flutter_pcsc/flutter_pcsc.dart';

import 'models/apdu_command_model.dart';
import 'models/apdu_response.dart';

class SmartCardHelper {
  CardStruct? card;
  int? ctx;
  List<int>? appletId;

  Future<bool> connectCard(List<int> appletId) async {
    this.appletId = appletId;
    bool isSuccess = false;
    try {
      ctx = await Pcsc.establishContext(PcscSCope.user);

      List<String> readers = await Pcsc.listReaders(ctx!);

      if (readers.isEmpty) {
        print('Could not detect any reader');
      } else {
        String reader = readers[0];
        print('Using reader: $reader');

        card = await Pcsc.cardConnect(
            ctx!, reader, PcscShare.shared, PcscProtocol.t1);
        final ApduResponse? response =
            await sendApdu(ApduCommand.connect(appletID: appletId));
        if (response != null) {
          var sw = response.sw;
          if (sw[0] != 0x90 || sw[1] != 0x00) {
            print('Card returned an error: ${hexDump(sw)}');
            return false;
          }
          print('Connected');
          isSuccess = true;
        }
      }
    } catch (e) {
      print('Card returned an error: $e');
    }
    return isSuccess;
  }

  Future<void> disconnect() async {
    if (card != null) {
      try {
        await Pcsc.cardDisconnect(card!.hCard, PcscDisposition.resetCard);
      } on Exception catch (e) {
        print(e.toString());
      }
    }
    try {
      await Pcsc.releaseContext(ctx!);
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  static String hexDump(List<int> csn) {
    return csn
        .map((i) => i.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  Future<ApduResponse?> sendApdu(ApduCommand apduCommand) async {
    try {
      var response = await Pcsc.transmit(card!, apduCommand.toListInt());
      return ApduResponse.fromList(response);
    } catch (e) {
      print(e.toString());
    }
    return null;
  }
}
