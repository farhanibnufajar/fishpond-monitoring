// =======================================================
// mqtt_client_io.dart
// Implementasi MQTT client untuk platform NATIVE
// (Android, iOS, Windows, macOS, Linux)
//
// File ini HANYA di-compile saat target BUKAN web —
// dipilih otomatis oleh conditional import di
// mqtt_client_factory.dart. Aman pakai dart:io di sini.
// =======================================================
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String server, String clientId) {
  final client = MqttServerClient(server, clientId);

  // Broker HiveMQ Cloud — koneksi TCP langsung dengan TLS
  client.port = 8883;
  client.secure = true;
  client.securityContext = SecurityContext.defaultContext;
  client.keepAlivePeriod = 20;
  client.autoReconnect = true;
  client.logging(on: false);

  return client;
}
