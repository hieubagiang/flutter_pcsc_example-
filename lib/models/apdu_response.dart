import 'package:pcsc_example/smart_card_helper.dart';

class ApduResponse {
  final List<int> sw;
  final List<int> sn;

  ApduResponse({required this.sw, required this.sn});

  factory ApduResponse.fromList(List<int> response) {
    var sw = response.sublist(response.length - 2);
    var sn = response.sublist(0, response.length - 2);
    return ApduResponse(sw: sw, sn: sn);
  }

  @override
  String toString() {
    return 'ApduResponse{sw: ${SmartCardHelper.hexDump(sw)}, sn: ${SmartCardHelper.hexDump(sn)}';
  }
}
