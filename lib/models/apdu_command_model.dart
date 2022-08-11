import 'package:pcsc_example/extensions.dart';

class ApduCommand {
  final int cla, ins, p1, p2;
  final List<int>? data;

  ApduCommand(
      {required this.cla,
      required this.ins,
      required this.p1,
      required this.p2,
      this.data});

  factory ApduCommand.connect({required List<int> appletID}) =>
      ApduCommand(cla: 0x00, ins: 0xA4, p1: 0x04, p2: 0x00, data: appletID);

  List<int> toListInt() {
    List<int> command = [
      cla,
      ins,
      p1,
      p2,
    ];
    if (data != null) {
      if (data!.length < 256) {
        command.addAll([data!.length, ...?data]);
      } else if (data!.length <= 65536) {
        command.addAll([
          ...data!.length
              .toHex()
              .formatHexLength(6)
              .splitByLength(2)
              .parseToListInt(),
          ...?data
        ]);
      } else {
        throw Exception(
            "invalid_data_length: 0<=data.length<=65536, currrent datalength is ${data!.length}");
      }
    }
    return command;
  }

  @override
  String toString() {
    return 'ApduCommand{cla: $cla, ins: $ins, p1: $p1, p2: $p2, data: $data}';
  }
}
