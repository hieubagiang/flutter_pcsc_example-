class SmartCardConstant {
  static List<int> selectCmd = [0x00, 0xA4, 0x04, 0x00];
  static List<int> appletID = [0x11, 0x22, 0x33, 0x44, 0x55, 0x03];

  static List<int> connectCMD() => [...selectCmd, appletID.length, ...appletID];
  static int appletCla = 0x00;

  static int getFirstMessage = 0x00;
}
