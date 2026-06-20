// =======================================================
// qr_generator_page.dart
// Halaman untuk generate & tampilkan QR code kolam
// Pemilik kolam share QR ini ke orang lain
// Package: qr_flutter
// =======================================================
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'user_config.dart';

const _teal   = Color(0xFF1D9E75);
const _tealLt = Color(0xFFE1F5EE);
const _surf   = Color(0xFFF8F8F8);
const _bord   = Color(0xFFE8E8E8);
const _gray   = Color(0xFF5F5E5A);

class QRGeneratorPage extends StatelessWidget {
  final KolamConfig config;
  const QRGeneratorPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surf,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text("QR Kolam Saya",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _bord),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ── Info kolam ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _tealLt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _teal.withOpacity(0.2), width: 0.5),
              ),
              child: Column(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.water, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(config.kolamName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text(config.topicPrefix,
                    style: const TextStyle(fontSize: 12, color: _teal)),
              ]),
            ),

            const SizedBox(height: 24),

            // ── QR Code ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _bord, width: 0.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: [
                // QR berisi kolamId
                QrImageView(
                  data: config.kolamId,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1A1A1A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text("ID: ${config.kolamId}",
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB4B2A9))),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Instruksi ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _bord, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cara berbagi akses",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 10),
                  _step("1", "Tampilkan QR ini ke orang yang ingin Anda beri akses"),
                  const SizedBox(height: 8),
                  _step("2", "Mereka scan QR dari menu utama aplikasi"),
                  const SizedBox(height: 8),
                  _step("3", "Kolam Anda otomatis muncul di daftar kolam mereka"),
                  const SizedBox(height: 8),
                  _step("4", "Mereka bisa monitoring & kontrol kolam Anda"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Info keamanan ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF9F27).withOpacity(0.3), width: 0.5),
              ),
              child: const Row(children: [
                Icon(Icons.shield_outlined, size: 15, color: Color(0xFF854F0B)),
                SizedBox(width: 8),
                Expanded(child: Text(
                  "Hanya bagikan QR ini ke orang yang Anda percaya. Mereka akan punya akses penuh ke kolam Anda.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF854F0B)),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
        child: Center(child: Text(num,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _gray))),
    ],
  );
}
