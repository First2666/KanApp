class ApiConfig {
  /// 1) สำหรับ Android Emulator ต่อเข้าคอมตัวเอง (Local Backend Port 5088)
  static const String serverBaseUrl = 'http://10.0.2.2:5088';

  /// 2) สำหรับมือถือจริง ต่อ Hotspot วงเดียวกับคอม (IP คอมเครื่องนี้)
  // static const String serverBaseUrl = 'http://172.20.10.4:5088';

  /// 3) สำหรับยิงขึ้น Server มหาลัย (ต้องต่อเน็ตมหาลัย)
  // static const String serverBaseUrl = 'http://10.103.0.17/cs67/vue/s17/Kang';

  /// Base API URL for KanG Backend
  static const String baseUrl = '$serverBaseUrl/api';
}
