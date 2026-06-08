import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_system/app_tokens.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman Riwayat Transaksi (KEEP #10 Stitch).
/// Route: /riwayat-transaksi
///
/// F0.5 redesign: white surface header (avatar + title + bell), per-tab
/// sub-filter, summary cards per tab, search bar, pull-to-refresh, and
/// pill-style type chips.
class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  static const routeName = '/riwayat-transaksi';

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _TransaksiTab(),
                  _RiwayatStokTab(),
                ],
              ),
            ),
            const AppBottomNav(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ccardBg(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: AppSpacing.sm5,
                height: AppSpacing.sm5,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  AppSymbols.klinik,
                  size: AppIconSize.size28,
                  color: cteal(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Riwayat Transaksi',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: ctextPrimary(context),
                  ),
                ),
              ),
              _NotificationBell(
                onTap: () {
                  showModernSnackBar(
                    context,
                    'Notifikasi belum tersedia',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: AppSpacing.sm5,
            decoration: BoxDecoration(
              color: cscaffoldBg(context),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: cteal(context),
              unselectedLabelColor: ctextSecondary(context),
              indicator: BoxDecoration(
                color: cteal(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: AppTextStyles.menuTitle,
              unselectedLabelStyle: AppTextStyles.menuTitle,
              tabs: const [
                Tab(text: 'Transaksi'),
                Tab(text: 'Riwayat Stok'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1 — TRANSAKSI
// ============================================================================

class _TransaksiTab extends StatefulWidget {
  const _TransaksiTab();

  @override
  State<_TransaksiTab> createState() => _TransaksiTabState();
}

class _TransaksiTabState extends State<_TransaksiTab> {
  List<Map<String, dynamic>> _transaksi = [];
  bool _loading = true;
  String _filter = 'semua';
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Supabase.instance.client
          .from('transaksi')
          .select('*, pasien(nama_pasien)')
          .order('created_at', ascending: false)
          .limit(100);

      _transaksi = List<Map<String, dynamic>>.from(results);
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    Iterable<Map<String, dynamic>> rows = _transaksi;
    if (_filter != 'semua') {
      rows = rows.where((t) => t['jenis_transaksi'] == _filter);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      rows = rows.where((t) {
        final nama =
            (t['pasien']?['nama_pasien'] ?? '').toString().toLowerCase();
        final metode = (t['metode_bayar'] ?? '').toString().toLowerCase();
        return nama.contains(q) || metode.contains(q);
      });
    }
    return rows.toList();
  }

  Map<String, int> get _summary {
    final praktek =
        _transaksi.where((t) => t['jenis_transaksi'] == 'praktekCustom').length;
    final obat =
        _transaksi.where((t) => t['jenis_transaksi'] == 'obatReadyStock').length;
    final totalNominal = _transaksi.fold<double>(
      0,
      (acc, t) => acc + ((t['total'] ?? 0).toDouble()),
    );
    return {
      'count': _transaksi.length,
      'praktek': praktek,
      'obat': obat,
      'nominal': totalNominal.toInt(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Column(
      children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _RiwayatSummaryCard(
                  icon: AppSymbols.receipt,
                  color: cteal(context),
                  label: 'Total',
                  value: '${summary['count']}',
                  sublabel: 'transaksi',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _RiwayatSummaryCard(
                  icon: Symbols.medical_services_rounded,
                  color: cwarning(context),
                  label: 'Praktek',
                  value: '${summary['praktek']}',
                  sublabel: 'kunjungan',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _RiwayatSummaryCard(
                  icon: Symbols.medication_rounded,
                  color: csuccess(context),
                  label: 'Obat',
                  value: '${summary['obat']}',
                  sublabel: 'item',
                ),
              ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: _SearchField(
            controller: _searchCtl,
            hint: 'Cari nama pasien atau metode bayar',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              _PillChip(
                label: 'Semua',
                active: _filter == 'semua',
                onTap: () => setState(() => _filter = 'semua'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PillChip(
                label: 'Praktek',
                active: _filter == 'praktekCustom',
                onTap: () => setState(() => _filter = 'praktekCustom'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PillChip(
                label: 'Obat',
                active: _filter == 'obatReadyStock',
                onTap: () => setState(() => _filter = 'obatReadyStock'),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            color: cteal(context),
            onRefresh: _loadData,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          _EmptyView(
                            icon: AppSymbols.receipt,
                            title: 'Belum ada transaksi',
                            subtitle: 'Transaksi yang tercatat akan muncul di sini',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final tx = _filtered[index];
                          final jenis = tx['jenis_transaksi'] ?? '';
                          final isPraktek = jenis == 'praktekCustom';
                          final namaPasien =
                              tx['pasien']?['nama_pasien'] ?? '-';
                          final total = (tx['total'] ?? 0).toDouble();
                          final metode = tx['metode_bayar'] ?? '-';
                          final tanggal = tx['created_at'] != null
                              ? asDate(DateTime.parse(tx['created_at']))
                              : '-';
                          final color =
                              isPraktek ? cwarning(context) : csuccess(context);
                          final badgeLabel = isPraktek ? 'Praktek' : 'Obat';

                          return _RiwayatItemCard(
                            color: color,
                            badgeLabel: badgeLabel,
                            icon: isPraktek
                                ? Symbols.medical_services_rounded
                                : Symbols.medication_rounded,
                            title: namaPasien,
                            subtitle: '$tanggal • $metode',
                            trailing: rupiah(total),
                            trailingColor: ctextPrimary(context),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 2 — RIWAYAT STOK
// ============================================================================

class _RiwayatStokTab extends StatefulWidget {
  const _RiwayatStokTab();

  @override
  State<_RiwayatStokTab> createState() => _RiwayatStokTabState();
}

class _RiwayatStokTabState extends State<_RiwayatStokTab> {
  List<Map<String, dynamic>> _masuk = [];
  List<Map<String, dynamic>> _keluar = [];
  bool _loading = true;
  String _filter = 'semua';
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('obat_masuk')
            .select('*, obat(nama_obat)')
            .order('created_at', ascending: false)
            .limit(100),
        Supabase.instance.client
            .from('obat_keluar')
            .select('*, obat(nama_obat)')
            .order('created_at', ascending: false)
            .limit(100),
      ]);
      _masuk = (results[0] as List).cast<Map<String, dynamic>>();
      _keluar = (results[1] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    Iterable<Map<String, dynamic>> rows;
    if (_filter == 'semua') {
      rows = [
        ..._masuk.map((e) => {...e, '_source': 'masuk'}),
        ..._keluar.map((e) => {...e, '_source': 'keluar'}),
      ];
    } else if (_filter == 'restock') {
      rows = _masuk.map((e) => {...e, '_source': 'masuk'});
    } else {
      rows = _keluar.map((e) => {...e, '_source': 'keluar'});
    }

    final list = rows.toList();
    list.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
      final bTime =
          DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      return list
          .where((item) =>
              (item['obat']?['nama_obat'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Map<String, int> get _summary {
    final masukTotal =
        _masuk.fold<int>(0, (acc, e) => acc + ((e['jumlah'] ?? 0) as int));
    final keluarTotal =
        _keluar.fold<int>(0, (acc, e) => acc + ((e['jumlah'] ?? 0) as int));
    return {
      'masuk': masukTotal,
      'keluar': keluarTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Column(
      children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _RiwayatSummaryCard(
                  icon: Symbols.add_box_rounded,
                  color: csuccess(context),
                  label: 'Stok Masuk',
                  value: '+${summary['masuk']}',
                  sublabel: 'unit',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _RiwayatSummaryCard(
                  icon: Symbols.remove_done_rounded,
                  color: cdanger(context),
                  label: 'Stok Keluar',
                  value: '-${summary['keluar']}',
                  sublabel: 'unit',
                ),
              ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: _SearchField(
            controller: _searchCtl,
            hint: 'Cari nama obat',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              _PillChip(
                label: 'Semua',
                active: _filter == 'semua',
                onTap: () => setState(() => _filter = 'semua'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PillChip(
                label: 'Restock',
                active: _filter == 'restock',
                onTap: () => setState(() => _filter = 'restock'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PillChip(
                label: 'Obat Keluar',
                active: _filter == 'keluar',
                onTap: () => setState(() => _filter = 'keluar'),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            color: cteal(context),
            onRefresh: _loadData,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          _EmptyView(
                            icon: Symbols.inventory_2_rounded,
                            title: 'Belum ada riwayat stok',
                            subtitle: 'Perubahan stok akan tercatat di sini',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          final source = item['_source'] as String;
                          final isMasuk = source == 'masuk';
                          final namaObat = item['obat']?['nama_obat'] ?? '-';
                          final jumlah = item['jumlah'] ?? 0;
                          final tanggal = item['created_at'] != null
                              ? asDate(DateTime.parse(item['created_at']))
                              : '-';
                          final color = isMasuk
                              ? csuccess(context)
                              : cdanger(context);
                          final badgeLabel = isMasuk ? 'Masuk' : 'Keluar';

                          return _RiwayatItemCard(
                            color: color,
                            badgeLabel: badgeLabel,
                            icon: isMasuk
                                ? Symbols.add_circle_rounded
                                : Symbols.remove_circle_rounded,
                            title: namaObat,
                            subtitle: tanggal,
                            trailing: isMasuk ? '+$jumlah' : '-$jumlah',
                            trailingColor: color,
                            trailingStyle: AppTextStyles.bodyLg.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: AppSpacing.sm5,
        height: AppSpacing.sm5,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cscaffoldBg(context),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Symbols.notifications_rounded,
          size: AppIconSize.size20,
          color: ctextSecondary(context),
        ),
      ),
    );
  }
}

class _RiwayatSummaryCard extends StatelessWidget {
  const _RiwayatSummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md14),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm10),
            ),
            child: Icon(icon, color: color, size: AppIconSize.size20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.heroMetric.copyWith(color: color, height: 1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: ctextPrimary(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sublabel,
            style: AppTextStyles.caption.copyWith(color: ctextMuted(context)),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.sm5,
      decoration: BoxDecoration(
        color: cscaffoldBg(context),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: cdivider(context), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Icon(
            Symbols.search_rounded,
            size: AppIconSize.size20,
            color: ctextMuted(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMd.copyWith(
                color: ctextPrimary(context),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.bodyMd.copyWith(
                  color: ctextMuted(context),
                ),
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Symbols.close_rounded,
                size: AppIconSize.size20,
                color: ctextMuted(context),
              ),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active
              ? cteal(context)
              : ccardBg(context),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: active
              ? null
              : Border.all(color: cdivider(context), width: 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: active ? Colors.white : ctextSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _RiwayatItemCard extends StatelessWidget {
  const _RiwayatItemCard({
    required this.color,
    required this.badgeLabel,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    this.trailingStyle,
  });

  final Color color;
  final String badgeLabel;
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final TextStyle? trailingStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm10),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cdivider(context), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: AppIconSize.size20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTextStyles.labelXs.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    title,
                    style: AppTextStyles.title.copyWith(
                      color: ctextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: ctextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              trailing,
              style: trailingStyle ??
                  AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w800,
                    color: trailingColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.size160 / 2, color: ctextMuted(context)),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w700,
                color: ctextPrimary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(color: ctextSecondary(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
