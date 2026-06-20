// =======================================================
// auth_page.dart
// Halaman Login & Register
// =======================================================
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'user_config.dart';
// MQTTPage di-import dari main.dart — hindari circular import
// dengan menggunakan typedef/callback navigasi

// ── Warna ringkas ──
const _teal   = Color(0xFF1D9E75);
const _tealLt = Color(0xFFE1F5EE);
const _tealDk = Color(0xFF04342C);
const _surf   = Color(0xFFF8F8F8);
const _bord   = Color(0xFFE8E8E8);
const _gray   = Color(0xFF5F5E5A);
const _redLt  = Color(0xFFFCEBEB);
const _redMd  = Color(0xFFE24B4A);

// =======================================================
// AUTH WRAPPER — cek session, auto-navigate
// =======================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (snap.hasData && snap.data != null) {
          return const KolamListPage();  // sudah login → daftar kolam
        }
        return const AuthPage();         // belum login → login/register
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: _surf,
    body: Center(child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(_teal),
    )),
  );
}

// =======================================================
// AUTH PAGE — Login & Register
// =======================================================
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {

  late TabController _tab;

  final _loginEmail    = TextEditingController();
  final _loginPass     = TextEditingController();
  final _regEmail      = TextEditingController();
  final _regPass       = TextEditingController();
  final _regConfirm    = TextEditingController();
  final _regNama       = TextEditingController();
  final _regKolam      = TextEditingController();

  bool _loginLoading  = false;
  bool _regLoading    = false;
  bool _lpHide = true, _rpHide = true, _rcHide = true;
  String? _err;

  static const _broker   = '007d3469a2244841a48f1259a6b6494e.s1.eu.hivemq.cloud';
  static const _mqttUser = 'Test123';
  static const _mqttPass = 'Test1234';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() => _err = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_loginEmail, _loginPass, _regEmail, _regPass,
                     _regConfirm, _regNama, _regKolam]) c.dispose();
    super.dispose();
  }

  // ── Login ──
  Future<void> _login() async {
    setState(() { _loginLoading = true; _err = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmail.text.trim(), password: _loginPass.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _err = _authErr(e.code));
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  // ── Register ──
  Future<void> _register() async {
    if (_regNama.text.trim().isEmpty)   { setState(() => _err = "Nama tidak boleh kosong"); return; }
    if (_regKolam.text.trim().isEmpty)  { setState(() => _err = "Nama kolam tidak boleh kosong"); return; }
    if (_regPass.text != _regConfirm.text) { setState(() => _err = "Password tidak cocok"); return; }
    if (_regPass.text.length < 6)       { setState(() => _err = "Password minimal 6 karakter"); return; }

    setState(() { _regLoading = true; _err = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _regEmail.text.trim(), password: _regPass.text);
      final uid = cred.user!.uid;

      // Buat dokumen kolam di collection 'kolam'
      final kolamRef = FirebaseFirestore.instance.collection('kolam').doc();
      final prefix   = 'kolam_${uid.substring(0, 8)}';

      await kolamRef.set(KolamConfig(
        kolamId:      kolamRef.id,
        ownerUid:     uid,
        kolamName:    _regKolam.text.trim(),
        mqttBroker:   _broker,
        mqttUser:     _mqttUser,
        mqttPassword: _mqttPass,
        topicPrefix:  prefix,
        isOwner:      true,
      ).toMap());

      // Simpan profil user + referensi kolam miliknya
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nama':       _regNama.text.trim(),
        'email':      _regEmail.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Tambah akses kolam sendiri
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('kolam_access').doc(kolamRef.id)
          .set({'added_at': FieldValue.serverTimestamp(), 'is_owner': true});

    } on FirebaseAuthException catch (e) {
      setState(() => _err = _authErr(e.code));
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  String _authErr(String code) {
    switch (code) {
      case 'user-not-found':       return "Akun tidak ditemukan";
      case 'wrong-password':       return "Password salah";
      case 'invalid-email':        return "Format email tidak valid";
      case 'email-already-in-use': return "Email sudah terdaftar";
      case 'weak-password':        return "Password terlalu lemah";
      case 'invalid-credential':   return "Email atau password salah";
      default:                     return "Terjadi kesalahan, coba lagi";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surf,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.water, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("IoT Kolam Ikan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  Text("Sistem monitoring kualitas air", style: TextStyle(fontSize: 12, color: Color(0xFF888680))),
                ]),
              ]),
              const SizedBox(height: 28),

              // Tab bar
              Container(
                decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tab,
                  onTap: (_) => setState(() {}),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0,2))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF1A1A1A),
                  unselectedLabelColor: _gray,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: const [Tab(text: "Masuk"), Tab(text: "Daftar")],
                ),
              ),
              const SizedBox(height: 20),

              // Error
              if (_err != null) _errBox(_err!),

              // Form
              _tab.index == 0 ? _loginForm() : _registerForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errBox(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(color: _redLt, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _redMd.withOpacity(0.25), width: 0.5)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, size: 16, color: _redMd),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: _redMd))),
    ]),
  );

  Widget _loginForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _lbl("Email"),
    _field(ctrl: _loginEmail, hint: "email@contoh.com", icon: Icons.email_outlined, type: TextInputType.emailAddress),
    const SizedBox(height: 12),
    _lbl("Password"),
    _field(ctrl: _loginPass, hint: "Password", icon: Icons.lock_outline_rounded, hide: _lpHide,
        toggleHide: () => setState(() => _lpHide = !_lpHide)),
    const SizedBox(height: 20),
    _btn("Masuk", _loginLoading, _login),
  ]);

  Widget _registerForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _lbl("Nama Lengkap"),
    _field(ctrl: _regNama, hint: "Nama Anda", icon: Icons.person_outline_rounded),
    const SizedBox(height: 12),
    _lbl("Nama Kolam"),
    _field(ctrl: _regKolam, hint: "Contoh: Kolam Nila Pak Budi", icon: Icons.water_outlined),
    const SizedBox(height: 12),
    _lbl("Email"),
    _field(ctrl: _regEmail, hint: "email@contoh.com", icon: Icons.email_outlined, type: TextInputType.emailAddress),
    const SizedBox(height: 12),
    _lbl("Password"),
    _field(ctrl: _regPass, hint: "Minimal 6 karakter", icon: Icons.lock_outline_rounded, hide: _rpHide,
        toggleHide: () => setState(() => _rpHide = !_rpHide)),
    const SizedBox(height: 12),
    _lbl("Konfirmasi Password"),
    _field(ctrl: _regConfirm, hint: "Ulangi password", icon: Icons.lock_outline_rounded, hide: _rcHide,
        toggleHide: () => setState(() => _rcHide = !_rcHide)),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _tealLt, borderRadius: BorderRadius.circular(10)),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, size: 15, color: _teal),
        SizedBox(width: 8),
        Expanded(child: Text(
          "Topic MQTT unik dibuat otomatis untuk kolam Anda. Gunakan topic prefix ini di ESP32.",
          style: TextStyle(fontSize: 12, color: _tealDk),
        )),
      ]),
    ),
    const SizedBox(height: 20),
    _btn("Buat Akun", _regLoading, _register),
  ]);

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool hide = false,
    VoidCallback? toggleHide,
    TextInputType type = TextInputType.text,
  }) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bord, width: 0.5)),
    child: TextField(
      controller: ctrl, obscureText: hide, keyboardType: type,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB4B2A9)),
        prefixIcon: Icon(icon, size: 18, color: _gray),
        suffixIcon: toggleHide != null
            ? IconButton(
                icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _gray),
                onPressed: toggleHide)
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  Widget _btn(String label, bool loading, VoidCallback onPressed) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: _teal.withOpacity(0.5),
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );
}

// =======================================================
// KOLAM LIST PAGE — daftar semua kolam yang bisa diakses
// =======================================================
// Typedef untuk navigasi ke dashboard — diisi dari main.dart
typedef KolamTapCallback = void Function(BuildContext context, KolamConfig config);

// Global callback — di-set dari main.dart sebelum runApp
KolamTapCallback? onKolamTap;

class KolamListPage extends StatefulWidget {
  const KolamListPage({super.key});
  @override
  State<KolamListPage> createState() => _KolamListPageState();
}

class _KolamListPageState extends State<KolamListPage> {

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<List<KolamConfig>> _loadKolam() async {
    // Ambil semua kolamId yang bisa diakses user ini
    final accessSnap = await _firestore
        .collection('users').doc(_uid)
        .collection('kolam_access')
        .get();

    final List<KolamConfig> result = [];
    for (final doc in accessSnap.docs) {
      final kolamDoc = await _firestore.collection('kolam').doc(doc.id).get();
      if (kolamDoc.exists) {
        result.add(KolamConfig.fromMap(doc.id, kolamDoc.data()!, currentUid: _uid));
      }
    }
    return result;
  }

  // =====================================================
  // BUAT KOLAM BARU MILIK SENDIRI
  // Dipakai saat: akun belum punya kolam sama sekali,
  // atau ingin menambah kolam ke-2/3/dst miliknya sendiri
  // =====================================================
  static const _broker   = '007d3469a2244841a48f1259a6b6494e.s1.eu.hivemq.cloud';
  static const _mqttUser = 'Test123';
  static const _mqttPass = 'Test1234';

  Future<void> _createNewKolam() async {
    final namaCtrl = TextEditingController();

    final namaKolam = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Buat Kolam Baru", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _bord, width: 0.5),
          ),
          child: TextField(
            controller: namaCtrl,
            autofocus: true,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: "Contoh: Kolam Nila Belakang Rumah",
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: _gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, namaCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Buat"),
          ),
        ],
      ),
    );

    if (namaKolam == null || namaKolam.isEmpty || !mounted) return;

    try {
      // Buat dokumen kolam baru
      final kolamRef = _firestore.collection('kolam').doc();
      // Topic prefix unik: kombinasi kolamId supaya tidak bentrok
      // walau 1 akun punya banyak kolam
      final prefix = 'kolam_${kolamRef.id.substring(0, 8)}';

      await kolamRef.set(KolamConfig(
        kolamId:      kolamRef.id,
        ownerUid:     _uid,
        kolamName:    namaKolam,
        mqttBroker:   _broker,
        mqttUser:     _mqttUser,
        mqttPassword: _mqttPass,
        topicPrefix:  prefix,
        isOwner:      true,
      ).toMap());

      // Tambah akses ke akun ini sebagai owner
      await _firestore
          .collection('users').doc(_uid)
          .collection('kolam_access').doc(kolamRef.id)
          .set({'added_at': FieldValue.serverTimestamp(), 'is_owner': true});

      if (mounted) {
        _showSnack("Kolam \"$namaKolam\" berhasil dibuat!");
        setState(() {}); // refresh list
      }
    } catch (e) {
      if (mounted) _showSnack("Gagal membuat kolam: $e", isError: true);
    }
  }

  Future<void> _scanAndAddKolam() async {
    // Gunakan package mobile_scanner untuk scan QR
    // QR berisi kolamId plain text
    final kolamId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScanPage()),
    );
    if (kolamId == null || !mounted) return;

    // Cek kolam valid
    final kolamDoc = await _firestore.collection('kolam').doc(kolamId).get();
    if (!kolamDoc.exists) {
      if (mounted) _showSnack("QR tidak valid atau kolam tidak ditemukan", isError: true);
      return;
    }

    // Cek sudah punya akses?
    final existing = await _firestore
        .collection('users').doc(_uid)
        .collection('kolam_access').doc(kolamId).get();
    if (existing.exists) {
      if (mounted) _showSnack("Kolam sudah ada di daftar Anda");
      return;
    }

    // Tambah akses permanen
    await _firestore
        .collection('users').doc(_uid)
        .collection('kolam_access').doc(kolamId)
        .set({'added_at': FieldValue.serverTimestamp(), 'is_owner': false});

    if (mounted) {
      _showSnack("Kolam berhasil ditambahkan!");
      setState(() {}); // refresh list
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _redMd : _teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Keluar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text("Yakin ingin keluar dari akun?", style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal", style: TextStyle(color: _gray))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _redMd, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
    if (ok == true) await _auth.signOut();
  }

  Future<void> _removeKolam(KolamConfig k) async {
    if (k.isOwner) {
      _showSnack("Tidak bisa menghapus kolam milik sendiri", isError: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus akses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text("Hapus akses ke ${k.kolamName}?", style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal", style: TextStyle(color: _gray))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _redMd, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _firestore.collection('users').doc(_uid)
          .collection('kolam_access').doc(k.kolamId).delete();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    return Scaffold(
      backgroundColor: _surf,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.water, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("IoT Kolam Ikan", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                      Text(user.email ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF888680))),
                    ],
                  )),
                  // Logout
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFB4B2A9)),
                    tooltip: "Keluar",
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1EFE8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(36, 36), padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // ── Daftar kolam ──
            Expanded(
              child: FutureBuilder<List<KolamConfig>>(
                future: _loadKolam(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_teal)));
                  }
                  final list = snap.data ?? [];
                  return list.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _kolamCard(list[i]),
                        );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB: pilihan Buat Kolam / Scan QR ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddKolamMenu,
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Tambah Kolam", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // =====================================================
  // MENU: Buat Kolam Baru / Scan QR Kolam
  // =====================================================
  void _showAddKolamMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(99)),
            ),
            _menuOption(
              icon: Icons.add_circle_outline_rounded,
              iconColor: _teal,
              iconBg: _tealLt,
              title: "Buat Kolam Baru",
              subtitle: "Daftarkan device kolam milik Anda sendiri",
              onTap: () { Navigator.pop(context); _createNewKolam(); },
            ),
            const SizedBox(height: 10),
            _menuOption(
              icon: Icons.qr_code_scanner_rounded,
              iconColor: const Color(0xFF534AB7),
              iconBg: const Color(0xFFEEEDFE),
              title: "Scan QR Kolam",
              subtitle: "Tambahkan akses ke kolam milik orang lain",
              onTap: () { Navigator.pop(context); _scanAndAddKolam(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bord, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: _gray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB4B2A9), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(color: Color(0xFFF1EFE8), shape: BoxShape.circle),
        child: const Icon(Icons.water_drop_outlined, size: 36, color: Color(0xFFB4B2A9)),
      ),
      const SizedBox(height: 16),
      const Text("Belum ada kolam", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
      const SizedBox(height: 6),
      const Text("Buat kolam sendiri atau scan QR kolam orang lain",
          style: TextStyle(fontSize: 13, color: Color(0xFF888680))),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _showAddKolamMenu,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text("Tambah Kolam", style: TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]),
  );

  Widget _kolamCard(KolamConfig k) {
    return GestureDetector(
      onTap: () {
        // Navigate ke MQTTPage — import dari main.dart di level app
        // Solusi: gunakan Navigator dengan named route atau
        // inject builder dari luar. Implementasi di main.dart melalui
        // KolamListPage.onKolamTap callback:
        onKolamTap?.call(context, k);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: k.isOwner ? _tealLt : const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                k.isOwner ? Icons.water : Icons.qr_code_rounded,
                color: k.isOwner ? _teal : const Color(0xFF534AB7),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k.kolamName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: k.isOwner ? _tealLt : const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      k.isOwner ? "Kolam saya" : "Tamu",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                          color: k.isOwner ? _teal : const Color(0xFF534AB7)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(k.topicPrefix, style: const TextStyle(fontSize: 11, color: Color(0xFFB4B2A9))),
                ]),
              ]),
            ),
            // Hapus akses (hanya untuk kolam tamu)
            if (!k.isOwner)
              IconButton(
                onPressed: () => _removeKolam(k),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFB4B2A9)),
                tooltip: "Hapus akses",
              ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB4B2A9), size: 20),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// QR SCAN PAGE — scan QR untuk dapat kolamId
// Menggunakan package: mobile_scanner
// =======================================================
class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});
  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Scan QR Kolam", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Kamera scanner ──
          MobileScanner(
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.first;
              final raw = barcode.rawValue;
              if (raw != null && raw.isNotEmpty) {
                _scanned = true;
                Navigator.pop(context, raw);
              }
            },
          ),

          // ── Overlay frame tengah ──
          Center(
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: _teal, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // ── Label bawah ──
          const Positioned(
            bottom: 40, left: 0, right: 0,
            child: Text(
              "Arahkan kamera ke QR kolam",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// MQTTPage navigation: lihat onKolamTap di atas