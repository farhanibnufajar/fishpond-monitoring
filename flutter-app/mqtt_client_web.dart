// =======================================================
// mqtt_client_web.dart
// Implementasi MQTT client untuk platform WEB (browser)
//
// File ini HANYA di-compile saat target web — dipilih
// otomatis oleh conditional import di
// mqtt_client_factory.dart. Browser TIDAK mengizinkan raw
// TCP socket, jadi koneksi ke broker HARUS lewat WebSocket
// (wss://), bukan MqttServerClient.
//
// HiveMQ Cloud mendukung MQTT over WebSocket di port 8884
// dengan path "/mqtt" (selalu TLS/wss, tidak ada opsi
// non-TLS untuk HiveMQ Cloud).
// =======================================================
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient(String server, String clientId) {
  // URL harus menyertakan scheme (wss://) dan path broker (/mqtt)
  final client = MqttBrowserClient('wss://$server/mqtt', clientId);

  client.port = 8884;
  client.keepAlivePeriod = 20;
  client.autoReconnect = true;
  client.logging(on: false);

  return client;
}
