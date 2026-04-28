import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/domain_tab_navigation.dart';
import '../core/widgets/keep_alive_tab.dart';
import '../data/models/kehadiran_model.dart';
import '../data/models/pasien_model.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/pasien_repository.dart';
import 'kehadiran_tab_content.dart';
import 'pasien_tab_content.dart';

// ============================================================================
// PASIEN HUB PAGE
// FASE 1: Rapiakan struktur tab.
// FASE 2: Aksi Cepat — 3 kartu interaktif di bawah tab.
// FASE 3: Domain linkage.
// ============================================================================

class PasienHubPage extends StatefulWidget {
  const PasienHubPage({super.key});

  static const routeName = '/pasien-hub';

  @override
  State<PasienHubPage> createState() => _PasienHubPageState();
}

class _PasienHubPageState extends State<PasienHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Summary state ─────────────────────────────────────────────────────────
  // Simpan hasil summary sebagai state, bukan Future langsung.
  // Ini menjamin setState() memicu rebuild sinkron dengan loading indicator.
  DomainSummaryPasien? _domainSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load/reload summary. Memanggil setState secara eksplisit agar rebuild
  /// sinkron — loading indicator tampil saat refresh.
  Future<void> _loadSummary() async {
    if (!mounted) return;

    try {
      final repo = PasienRepository();
      final keRepo = KehadiranRepository();
      final today = DateTime.now();

      final results = await Future.wait([
        repo.getPasien(),
        repo.getPasienByTanggalJanjian(today),
        keRepo.getKehadiranByTanggal(today),
      ]);

      if (!mounted) return;

      final allPasien = results[0] as List<PasienModel>;
      final jadwalList = results[1] as List<PasienModel>;
      final semuaKehadiran = results[2] as List<KehadiranModel>;

      // FILTER: "Hadir Hari Ini" = hanya record dengan status hadir
      final hadirCount = semuaKehadiran
          .where((k) => k.statusHadir == StatusHadir.hadir)
          .length;

      setState(() {
        _domainSummary = DomainSummaryPasien(
          totalPasien: allPasien.length,
          jadwalHariIni: jadwalList.length,
          hadirHariIni: hadirCount,
          navigateToTab: (index) => _tabController.animateTo(index),
        );
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tealColor = cteal(context);

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Pasien',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: tealColor,
        foregroundColor: conPrimary(context),
        elevation: 0,
        bottom: DomainTabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Data Pasien'),
            Tab(text: 'Daftar Hadir Pasien'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: SwipeableTabBarView(
              controller: _tabController,
              children: [
                // Tab 0 — Data Pasien
                KeepAliveTab(
                  child: PasienTabContent(
                    onRefresh: _loadSummary,
                    domainSummary: _domainSummary,
                  ),
                ),
                // Tab 1 — Daftar Hadir Pasien
                KeepAliveTab(
                  child: KehadiranTabContent(
                    onRefresh: _loadSummary,
                    domainSummary: _domainSummary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary data model (public so child widgets can reference it) ─────────────

class DomainSummaryPasien {
  const DomainSummaryPasien({
    required this.totalPasien,
    required this.jadwalHariIni,
    required this.hadirHariIni,
    required this.navigateToTab,
  });

  final int totalPasien;
  final int jadwalHariIni;
  final int hadirHariIni;
  final void Function(int index) navigateToTab;
}
