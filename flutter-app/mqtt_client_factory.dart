// =======================================================
// mqtt_client_factory.dart
//
// Factory untuk membuat MQTT client yang sesuai dengan
// platform tempat app berjalan:
//   - Native (Android/iOS/Windows/macOS/Linux) → MqttServerClient
//     (koneksi TCP+TLS langsung ke broker, port 8883)
//   - Web (browser)                            → MqttBrowserClient
//     (koneksi WebSocket/TLS ke broker, port 8884)
//
// Pemilihan implementasi terjadi otomatis saat compile time
// lewat conditional import di bawah — tidak perlu if/else
// manual di kode pemanggil (main.dart).
// =======================================================
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_io.dart'
    if (dart.library.html) 'mqtt_client_web.dart' as platform;

/// Buat MQTT client sesuai platform.
/// [server] = hostname broker TANPA scheme/port, contoh:
///   "007d3469a2244841a48f1259a6b6494e.s1.eu.hivemq.cloud"
/// [clientId] = identifier unik untuk koneksi MQTT ini.
MqttClient createMqttClient(String server, String clientId) {
  return platform.createMqttClient(server, clientId);
}
