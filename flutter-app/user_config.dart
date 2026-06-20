// =======================================================
// user_config.dart
// Model data kolam — satu akun bisa punya banyak kolam
// =======================================================

class KolamConfig {
  final String kolamId;       // document ID di Firestore
  final String ownerUid;      // uid pemilik asli kolam
  final String kolamName;
  final String mqttBroker;
  final String mqttUser;
  final String mqttPassword;
  final String topicPrefix;   // misal: "kolam_abc12345"
  final bool   isOwner;       // true = pemilik, false = tamu (scan QR)

  const KolamConfig({
    required this.kolamId,
    required this.ownerUid,
    required this.kolamName,
    required this.mqttBroker,
    required this.mqttUser,
    required this.mqttPassword,
    required this.topicPrefix,
    required this.isOwner,
  });

  factory KolamConfig.fromMap(String kolamId, Map<String, dynamic> map,
      {required String currentUid}) {
    return KolamConfig(
      kolamId:      kolamId,
      ownerUid:     map['owner_uid']     ?? '',
      kolamName:    map['kolam_name']    ?? 'Kolam',
      mqttBroker:   map['mqtt_broker']   ?? '',
      mqttUser:     map['mqtt_user']     ?? '',
      mqttPassword: map['mqtt_password'] ?? '',
      topicPrefix:  map['topic_prefix']  ?? 'kolam',
      isOwner:      map['owner_uid'] == currentUid,
    );
  }

  Map<String, dynamic> toMap() => {
    'owner_uid':     ownerUid,
    'kolam_name':    kolamName,
    'mqtt_broker':   mqttBroker,
    'mqtt_user':     mqttUser,
    'mqtt_password': mqttPassword,
    'topic_prefix':  topicPrefix,
  };

  // Helper: build topic lengkap dari prefix
  String topic(String path) => '$topicPrefix/$path';
}
