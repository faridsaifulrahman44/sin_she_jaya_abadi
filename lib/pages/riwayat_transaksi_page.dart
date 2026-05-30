import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../widgets/app_bottom_nav.dart';

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
    final primary = cprimary(context);

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Riwayat Transaksi'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Transaksi'),
            Tab(text: 'Riwayat Stok'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TransaksiTab(),
                _RiwayatStokTab(),
              ],
            ),
          ),
          const AppBottomNav(currentIndex: 1),
        ],
      ),
    );
  }
}

// ─── Tab 1: Transaksi ──────────────────────────────────────────────────────────

class _TransaksiTab extends StatefulWidget {
  const _TransaksiTab();

  @override
  State<_TransaksiTab> createState() => _TransaksiTabState();
}

class _TransaksiTabState extends State<_TransaksiTab> {
  List<Map<String, dynamic>> _transaksi = [];
  bool _loading = true;
  String _filter = 'semua';

  @override
  void initState() {
    super.initState();
    _loadData();
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
    } catch (e) {
      // handle error silently
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'semua') return _transaksi;
    return _transaksi
        .where((t) => t['jenis_transaksi'] == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = cprimary(context);
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final textMuted = ctextMuted(context);
    final cardBg = ccardBg(context);
    final dividerColor = cdivider(context);
    final warning = cwarning(context);
    final success = csuccess(context);

    final chips = <_ChipData>[
      _ChipData('Semua', 'semua'),
      _ChipData('Praktek', 'praktekCustom'),
      _ChipData('Obat', 'obatReadyStock'),
    ];

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: chips.map((chip) {
              final active = _filter == chip.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = chip.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? primary
                          : cardBg,
                      borderRadius: BorderRadius.circular(100),
                      border: active
                          ? null
                          : Border.all(color: dividerColor, width: 1),
                    ),
                    child: Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        final badgeColor = isPraktek ? warning : success;
                        final badgeLabel =
                            isPraktek ? 'Praktek' : 'Obat';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: dividerColor,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              // Navigate to detail
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isPraktek
                                          ? Icons.medical_services_outlined
                                          : Icons.medication_outlined,
                                      color: badgeColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: badgeColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                              child: Text(
                                                badgeLabel,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: badgeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          namaPasien,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$tanggal • $metode',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        rupiah(total),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ─── Tab 2: Riwayat Stok ───────────────────────────────────────────────────────

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
    } catch (e) {
      // handle silently
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'semua') {
      final combined = [
        ..._masuk.map((e) => {...e, '_source': 'masuk'}),
        ..._keluar.map((e) => {...e, '_source': 'keluar'}),
      ];
      combined.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      return combined;
    }
    if (_filter == 'restock') {
      return _masuk
          .map((e) => {...e, '_source': 'masuk'})
          .toList();
    }
    return _keluar
        .map((e) => {...e, '_source': 'keluar'})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = cprimary(context);
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final textMuted = ctextMuted(context);
    final cardBg = ccardBg(context);
    final dividerColor = cdivider(context);
    final success = csuccess(context);
    final danger = cdanger(context);

    final chips = <_ChipData>[
      _ChipData('Semua', 'semua'),
      _ChipData('Restock', 'restock'),
      _ChipData('Obat Keluar', 'keluar'),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: chips.map((chip) {
              final active = _filter == chip.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = chip.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? primary
                          : cardBg,
                      borderRadius: BorderRadius.circular(100),
                      border: active
                          ? null
                          : Border.all(color: dividerColor, width: 1),
                    ),
                    child: Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada riwayat stok',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        final badgeColor = isMasuk ? success : danger;
                        final badgeLabel = isMasuk ? 'Masuk' : 'Keluar';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isMasuk
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline,
                                    color: badgeColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: Text(
                                              badgeLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        namaObat,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tanggal,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isMasuk ? '+$jumlah' : '-$jumlah',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ─── Chip data helper ───────────────────────────────────────────────────────────

class _ChipData {
  final String label;
  final String value;

  const _ChipData(this.label, this.value);
}