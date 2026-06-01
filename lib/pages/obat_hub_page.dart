import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/design_system/emil_design.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/widgets/domain_tab_navigation.dart';
import '../core/widgets/keep_alive_tab.dart';
import '../widgets/app_bottom_nav.dart';
import '../data/repositories/obat_repository.dart';
import '../features/stok/stok_alert_logic.dart';
import 'obat_keluar_page.dart';
import 'obat_masuk_page.dart';
import 'obat_page.dart';
import 'sinkronisasi_stok_page.dart';

/// Tab count: 5 for owner, 4 for petugas.
/// "Keterangan Stok" → tab ke-4 (renamed from Stok Alert)
/// "Sinkronisasi" → tab ke-5 (owner only)
///
/// Routes:
///   /obat-hub       → ObatHubPage (shell + bottom nav)
///   /stok-alert     → redirect ke tab Keterangan Stok di ObatHub
class ObatHubPage extends StatefulWidget {
  const ObatHubPage({super.key});

  static const routeName = '/obat-hub';

  @override
  State<ObatHubPage> createState() => _ObatHubPageState();
}

class _ObatHubPageState extends State<ObatHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOwner = false;
  int _tabCount = 4; // default: petugas

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final owner = await AdminSession.isOwner();
    if (!mounted) return;
    final count = owner ? 5 : 4;
    setState(() {
      _isOwner = owner;
      _tabCount = count;
      _tabController = TabController(length: _tabCount, vsync: this);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = cprimary(context);
    const duration = Duration(milliseconds: 300); // Emil Design normal

    // Show loading while checking role
    if (_tabCount == 4 && !_isOwner && _tabController.length == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner = _isOwner;
    final tabs = isOwner
        ? const [
            Tab(text: 'Master Obat'),
            Tab(text: 'Obat Masuk'),
            Tab(text: 'Pengeluaran Stok'),
            Tab(text: 'Keterangan Stok'),
            Tab(text: 'Sinkronisasi'),
          ]
        : const [
            Tab(text: 'Master Obat'),
            Tab(text: 'Obat Masuk'),
            Tab(text: 'Pengeluaran Stok'),
            Tab(text: 'Keterangan Stok'),
          ];

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      body: Column(
        children: [
          // ── CUSTOM APP BAR ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── Title Row ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/dashboard'),
                          child: AnimatedContainer(
                            duration: duration,
                            curve: EmilDesign.toggle,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              AppSymbols.arrowBack,
                              color: conPrimary(context),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Data Obat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: conPrimary(context),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        // Sinkronisasi shortcut — owner only
                        if (isOwner)
                          GestureDetector(
                            onTap: () {
                              if (_tabController.length > 4) {
                                _tabController.animateTo(4);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                AppSymbols.refresh,
                                color: conPrimary(context),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Tab Bar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DomainTabBar(
                      controller: _tabController,
                      tabs: tabs,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TAB CONTENT ───────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: SwipeableTabBarView(
                key: ValueKey(_tabCount),
                controller: _tabController,
                children: [
                  const KeepAliveTab(child: ObatTabContent()),
                  const KeepAliveTab(child: ObatMasukPage()),
                  const KeepAliveTab(child: ObatKeluarPage()),
                  KeepAliveTab(
                    child: isOwner
                        ? const _KeteranganStokEmbedded()
                        : const _KeteranganStokEmbedded(),
                  ),
                  if (isOwner)
                    const KeepAliveTab(child: SinkronisasiStokPage()),
                ],
              ),
            ),
          ),

          // ── BOTTOM NAV ─────────────────────────────────────────────────────
          const AppBottomNav(currentIndex: 1),
        ],
      ),
    );
  }
}

// ─── Keterangan Stok (Embedded) ─────────────────────────────────────────────

/// Embedded content — does NOT have its own Scaffold/AppBar.
/// Used as tab in ObatHubPage (replaces standalone StokAlertPage).
///
/// Logic: show "Stok Alert" if owner, show locked screen if petugas.
/// Note: StokAlertPage has owner-only guard that redirects.
/// For embedded version, we inline the logic directly.
class _KeteranganStokEmbedded extends StatefulWidget {
  const _KeteranganStokEmbedded();

  @override
  State<_KeteranganStokEmbedded> createState() =>
      _KeteranganStokEmbeddedState();
}

class _KeteranganStokEmbeddedState extends State<_KeteranganStokEmbedded> {
  bool _loading = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkOwner();
  }

  Future<void> _checkOwner() async {
    final isOwner = await AdminSession.isOwner();
    if (!mounted) return;
    setState(() {
      _isOwner = isOwner;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_isOwner) {
      return _buildOwnerOnlyMessage();
    }

    // Owner: render the StokAlertPage content directly
    return const _StokAlertContent();
  }

  Widget _buildOwnerOnlyMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: cwarning(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                AppSymbols.lock,
                size: 48,
                color: cwarning(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Halaman Owner Only',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ctextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keterangan Stok hanya bisa diakses oleh Owner.',
              style: TextStyle(
                fontSize: 14,
                color: ctextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stok Alert Content (Embedded) ───────────────────────────────────────────

/// Reuses StokAlertPage logic but embedded without its own Scaffold.
/// We wrap StokAlertPage in a Builder to strip the Scaffold.
class _StokAlertContent extends StatelessWidget {
  const _StokAlertContent();

  @override
  Widget build(BuildContext context) {
    // Re-use StokAlertPage but strip its Scaffold wrapper
    // by using the _StokAlertBody directly
    return const _StokAlertBody();
  }
}

class _StokAlertBody extends StatefulWidget {
  const _StokAlertBody();

  @override
  State<_StokAlertBody> createState() => _StokAlertBodyState();
}

class _StokAlertBodyState extends State<_StokAlertBody> {
  bool _loading = true;
  Map<String, dynamic>? _summary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ObatRepository();
      final obatList = await repo.getObat();
      if (!mounted) return;

      final summary = buildStokAlertSummary(obatList);
      setState(() {
        _summary = {
          'habis': summary.habis,
          'menipis': summary.menipis,
          'aman': summary.aman,
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  // No more dynamic imports needed

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_summary == null) {
      return _buildEmpty();
    }

    return _buildContent();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppSymbols.error, size: 48, color: cdanger(context)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: TextStyle(fontSize: 14, color: ctextSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(AppSymbols.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppSymbols.checkCircle, size: 48, color: csuccess(context)),
          const SizedBox(height: 12),
          Text(
            'Tidak ada alert stok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Semua obat dalam kondisi aman',
            style: TextStyle(fontSize: 14, color: ctextSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;

    // Get section data
    final habis = summary['habis'] as List? ?? [];
    final menipis = summary['menipis'] as List? ?? [];
    final aman = summary['aman'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: borderColor.withValues(alpha: 0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryColumn(
                    label: 'Habis',
                    count: habis.length,
                    color: cdanger(context),
                  ),
                ),
                Container(width: 1, height: 50, color: borderColor.withValues(alpha: 0.3)),
                Expanded(
                  child: _SummaryColumn(
                    label: 'Menipis',
                    count: menipis.length,
                    color: cwarning(context),
                  ),
                ),
                Container(width: 1, height: 50, color: borderColor.withValues(alpha: 0.3)),
                Expanded(
                  child: _SummaryColumn(
                    label: 'Aman',
                    count: aman.length,
                    color: csuccess(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Obat Habis
          if (habis.isNotEmpty) ...[
            _buildSectionHeader('Obat Habis', habis.length, cdanger(context)),
            const SizedBox(height: 12),
            ...habis.map<Widget>((item) => _ObatAlertCard(
                  item: item,
                  color: cdanger(context),
                )),
            const SizedBox(height: 20),
          ],

          // Section: Obat Menipis
          if (menipis.isNotEmpty) ...[
            _buildSectionHeader('Obat Menipis', menipis.length, cwarning(context)),
            const SizedBox(height: 12),
            ...menipis.map<Widget>((item) => _ObatAlertCard(
                  item: item,
                  color: cwarning(context),
                )),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(AppSymbols.warning, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ctextPrimary(context),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, height: 1),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ctextSecondary(context)),
        ),
      ],
    );
  }
}

class _ObatAlertCard extends StatelessWidget {
  const _ObatAlertCard({required this.item, required this.color});

  final Map<String, dynamic> item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final nama = item['nama'] ?? item['namaObat'] ?? 'Unknown';
    final etalase = item['etalaseLabel'] ?? item['etalase'] ?? '';
    final stok = item['stok'] ?? item['stokSaatIni'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              stok == 0 ? AppSymbols.error : AppSymbols.warning,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama.toString(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ctextPrimary(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        etalase.toString(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stok: $stok',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ctextSecondary(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}