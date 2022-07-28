extension NumberExtension on int {
  String get toHexa => toRadixString(16);
}

extension ListStringExtension on List<String> {
  List<int> parseToListInt() {
    return map((e) => e.toInt()).toList();
  }
}

extension StringExtension on String {
  String formatHexLength(int length) {
    return padLeft(length, '0');
  }

  List<String> splitByLength(int length) {
    int index = 0;
    List<String> data = [];
    while (index < this.length) {
      data.add(substring(
          index, index + length < this.length ? index + length : this.length));
      index = index + length;
    }
    //check last = fixedLength;

    assert(data.last.length % 2 == 0);
    if (data.last.length < length) {
      data.last += '0' * (length - data.last.length);
    }
    return data;
  }

  int toInt() {
    return int.parse(this, radix: 16);
  }

  int toIntParse() {
    return int.parse(this);
  }
}

extension IntExtension on int {
  String toHex() {
    return toRadixString(16);
  }
}
