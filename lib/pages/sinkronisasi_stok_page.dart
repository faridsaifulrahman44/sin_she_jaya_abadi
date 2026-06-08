import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:printing/printing.dart';

import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/csv_exporter.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/sinkronisasi_stok_model.dart';
import '../data/repositories/obat_repository.dart';
import '../data/repositories/sinkronisasi_stok_repository.dart';
import '../data/repositories/transaksi_repository.dart';
import '../features/stok/services/stock_service.dart';
import '../widgets/app_bottom_nav_stock.dart';
import 'sinkronisasi_stok/widgets/sinkronisasi_audit_log_card.dart';
import 'sinkronisasi_stok_form_page.dart';

/// Halaman 7 (KEEP #7 Stitch) — Sinkronisasi Inventaris.
/// Route: /sinkronisasi-stok
///
/// F0.5 redesign (2026-06-08): Stitch KEEP #7 parity — summary cards
/// redesigned to "Total Item Diperiksa" / "Perbedaan Ditemukan" /
/// "Nilai Selisih (Estimasi)" with warning/error colors per Stitch,
/// GradientFAB removed (Stitch has no FAB), sticky bottom Setujui
/// pill via `bottomNavigationBar`, dan 3-card KPI summary dengan
/// sublabel "Diperiksa Oleh".
class SinkronisasiStokPage extends StatefulWidget {
  const SinkronisasiStokPage({super.key});

  static const routeName = '/sinkronisasi-stok';
  // backward-compat legacy alias
  static const routeNameLegacy = '/stock-opname';

  @override
  State<SinkronisasiStokPage> createState() => _SinkronisasiStokPageState();
}

class _SinkronisasiStokPageState extends State<SinkronisasiStokPage> {
  final SinkronisasiStokRepository _repo = SinkronisasiStokRepository();
  final StockService _stockService = StockService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<SinkronisasiStokModel>> _future;
  String _keyword = '';
  bool _isOwner = false;
  bool _exporting = false;
  bool _onlySelisih = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.getSinkronisasiStok();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (_keyword != next) setState(() => _keyword = next);
    });
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    final isOwner = await AdminSession.isOwner();
    if (!mounted) return;
    setState(() => _isOwner = isOwner);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final f = _repo.getSinkronisasiStok();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _openForm([SinkronisasiStokModel? item]) async {
    await Navigator.pushNamed(
      context,
      SinkronisasiStokFormPage.routeName,
      arguments: item,
    );
    await _reload();
  }

  Future<void> _deleteItem(SinkronisasiStokModel item) async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Sinkronisasi',
      message:
          'Yakin ingin menghapus entri ini? Stok akan dikembalikan ke nilai sebelum penyesuaian.',
    );
    if (confirm != true) return;

    try {
      await _stockService.deleteSyncOpname(item.idOpname);
      if (!mounted) return;
      showModernSnackBar(context, 'Entri berhasil dihapus');
      await _reload();
    } catch (error, stackTrace) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        AppErrorMapper.toMessage(error, stackTrace),
        isError: true,
      );
    }
  }

  List<SinkronisasiStokModel> _filter(List<SinkronisasiStokModel> items) {
    Iterable<SinkronisasiStokModel> result = items;
    if (_onlySelisih) {
      result = result.where((it) => !it.isBalanced);
    }
    if (_keyword.isNotEmpty) {
      result = result.where((item) {
        return formatDateDb(item.tanggalOpname).contains(_keyword) ||
            asDate(item.tanggalOpname).contains(_keyword) ||
            item.alasanPenyesuaian?.toLowerCase().contains(_keyword) == true;
      });
    }
    return result.toList();
  }

  /// Resolve nama obat for the visible list. F12.4 — best-effort lookup;
  /// returns an empty map if the call fails (caller falls back to ID display).
  Future<Map<int, String>> _loadObatNameMap() async {
    try {
      final allObat = await ObatRepository().getObat();
      return {for (final o in allObat) o.idObat: o.namaObat};
    } catch (_) {
      return const {};
    }
  }

  /// Best-effort nilai selisih estimate (in rupiah). Joins `obat.harga_jual`
  /// to compute sum(selisih * hargaJual) across unbalanced items. Returns
  /// null if no join data available (model tidak expose harga_beli langsung).
  Future<int?> _loadNilaiSelisihEstimate(
    List<SinkronisasiStokModel> items,
  ) async {
    if (items.every((it) => it.isBalanced)) return 0;
    try {
      final allObat = await ObatRepository().getObat();
      final priceById = <int, num>{
        for (final o in allObat)
          if (o.hargaJual != null) o.idObat: o.hargaJual!,
      };
      if (priceById.isEmpty) return null;
      var total = 0;
      var anyComputed = false;
      for (final it in items) {
        if (it.isBalanced) continue;
        final price = priceById[it.idObat];
        if (price == null) continue;
        total += (it.selisih * price).round();
        anyComputed = true;
      }
      return anyComputed ? total : null;
    } catch (_) {
      return null;
    }
  }

  Color _selisihColor(SinkronisasiStokModel item, BuildContext ctx) {
    if (item.isBalanced) return ctextSecondary(ctx);
    final abs = item.selisih.abs();
    if (abs <= 2) return AppColors.warning;
    if (item.isOverStock) return AppColors.positive;
    return cdanger(ctx);
  }

  String _selisihLabel(SinkronisasiStokModel item) {
    if (item.isBalanced) return 'Sesuai';
    return item.isOverStock ? '+${item.selisih}' : '${item.selisih}';
  }

  Future<void> _exportCsv() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final items = await _repo.getSinkronisasiStok();
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
          );
        }
        return;
      }

      final obatRepo = ObatRepository();
      final adminRepo = TransaksiRepository();
      final allObat = await obatRepo.getObat();
      final obatById = {for (final o in allObat) o.idObat: o.namaObat};
      final adminIds = items.map((e) => e.idAdmin).toSet();
      final adminById = <int, String>{};
      for (final id in adminIds) {
        final name = await adminRepo.getNamaAdminById(id);
        if (name != null && name.isNotEmpty) {
          adminById[id] = name;
        }
      }

      final csv = CsvExporter.exportSinkronisasiAuditLog(
        items,
        obatNameById: obatById,
        adminNameById: adminById,
      );
      final filename =
          'sinkronisasi_audit_${formatDateDb(DateTime.now())}.csv';
      await Printing.sharePdf(
        bytes: Uint8List.fromList(csv.codeUnits),
        filename: filename,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export CSV: ${AppErrorMapper.toMessage(error, stackTrace)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _onHeaderNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/pasien');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transaksi-hub');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/stok-alert');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/akun');
        break;
    }
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
              child: FutureBuilder<List<SinkronisasiStokModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return AppLoadingView(child: _buildLoading());
                  }
                  if (snapshot.hasError) {
                    return AppErrorView(
                      message: AppErrorMapper.toMessage(
                        snapshot.error!,
                        snapshot.stackTrace,
                      ),
                      onRetry: _reload,
                    );
                  }

                  final allItems = snapshot.data ?? const [];
                  final items = _filter(allItems);

                  return RefreshIndicator(
                    onRefresh: _reload,
                    color: cteal(context),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      children: [
                        // Page title + subtitle (Stitch KEEP #7)
                        Text(
                          'Sinkronisasi Stok',
                          style: AppTextStyles.headlineLg.copyWith(
                            color: ctextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tinjau dan setujui perbedaan jumlah stok fisik dan sistem',
                          style: AppTextStyles.bodyLg.copyWith(
                            color: ctextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 3-card KPI summary (Stitch KEEP #7)
                        // Cards: Total Item Diperiksa / Perbedaan Ditemukan / Nilai Selisih (Estimasi)
                        FutureBuilder<int?>(
                          future: _loadNilaiSelisihEstimate(allItems),
                          builder: (ctx, snap) {
                            final nilai = snap.data; // null = no join data
                            return _SummaryCardsRow(
                              totalCount: allItems.length,
                              totalSelisih: allItems
                                  .where((it) => !it.isBalanced)
                                  .length,
                              nilaiSelisih: nilai,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // "Setujui Sinkronisasi (N)" pill CTA di header section
                        _SetujuiPill(
                          count: allItems
                              .where((it) => !it.isBalanced)
                              .length,
                          onPressed: _exporting
                              ? null
                              : () {
                                  if (allItems
                                      .where((it) => !it.isBalanced)
                                      .isEmpty) {
                                    showModernSnackBar(
                                      context,
                                      'Tidak ada item selisih untuk disetujui.',
                                    );
                                    return;
                                  }
                                  showModernSnackBar(
                                    context,
                                    'Setujui sinkronisasi: alur bulk menyusul.',
                                  );
                                },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Search bar
                        ModernSearchBar(
                          controller: _searchController,
                          hintText: 'Cari tanggal atau alasan...',
                          onClear: () => setState(() => _keyword = ''),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Filter chip "Hanya Selisih"
                        _FilterChipRow(
                          active: _onlySelisih,
                          count: allItems
                              .where((it) => !it.isBalanced)
                              .length,
                          onTap: () =>
                              setState(() => _onlySelisih = !_onlySelisih),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (_isOwner) ...[
                          const SinkronisasiAuditLogCard(),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Table header row (6 kolom)
                        if (items.isNotEmpty) ...[
                          const _TableHeaderRow(),
                          const SizedBox(height: AppSpacing.sm),
                        ],

                        if (items.isEmpty)
                          AppEmptyView(
                            icon: AppSymbols.refresh,
                            title: _keyword.isEmpty && !_onlySelisih
                                ? 'Belum ada riwayat sinkronisasi'
                                : 'Entri tidak ditemukan',
                            message: _keyword.isEmpty && !_onlySelisih
                                ? 'Gunakan fitur ini untuk menyesuaikan stok sistem dengan stok fisik di klinik.'
                                : 'Coba kata kunci lain atau matikan filter.',
                            color: cteal(context),
                          )
                        else
                          FutureBuilder<Map<int, String>>(
                            future: _loadObatNameMap(),
                            builder: (ctx, namesSnap) {
                              final names = namesSnap.data ??
                                  const <int, String>{};
                              return Column(
                                children: [
                                  for (final item in items)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md),
                                      child: _SinkronisasiStokCard(
                                        item: item,
                                        namaObat: names[item.idObat],
                                        onTap: () => _openForm(item),
                                        onDelete: () => _deleteItem(item),
                                        selisihColor:
                                            _selisihColor(item, ctx),
                                        selisihLabel:
                                            _selisihLabel(item),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const AppBottomNavStock(currentIndex: 3),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GradientFAB(
          icon: Symbols.sync_saved_locally_rounded,
          label: 'Sinkronkan Stok',
          onPressed: () => _openForm(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── HEADER (F0.5 redesign: white surface + logo + 5-tab nav) ────────
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
            children: [
              // Logo placeholder "PulseCare" (text brand)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpacing.sm5,
                    height: AppSpacing.sm5,
                    decoration: BoxDecoration(
                      color: cteal(context).withValues(alpha: 0.16),
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
                  Text(
                    'PulseCare',
                    style: AppTextStyles.headline.copyWith(
                      color: cteal(context),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Export action
              IconButton(
                tooltip: 'Export CSV',
                onPressed: _exporting ? null : _exportCsv,
                icon: _exporting
                    ? SizedBox(
                        width: AppIconSize.size16,
                        height: AppIconSize.size16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cteal(context),
                        ),
                      )
                    : const Icon(
                        Symbols.download_rounded,
                        size: AppIconSize.size20,
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // User avatar (right)
              Container(
                width: AppSpacing.sm5,
                height: AppSpacing.sm5,
                decoration: BoxDecoration(
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Horizontal 5-tab nav (Stock active)
          AppHeaderNavStock(
            currentIndex: 3,
            onTap: _onHeaderNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const SkeletonListCard(),
    );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

class _SummaryCardsRow extends StatelessWidget {
  const _SummaryCardsRow({
    required this.totalCount,
    required this.totalSelisih,
    required this.nilaiSelisih,
  });

  final int totalCount;
  final int totalSelisih;
  final int? nilaiSelisih; // null = no join data, tampilkan "—"

  @override
  Widget build(BuildContext context) {
    final nilaiLabel = nilaiSelisih == null
        ? '—'
        : rupiah(nilaiSelisih!);
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Total Item Diperiksa',
            count: totalCount,
            color: cteal(context),
            icon: Symbols.inventory_2_rounded,
            sublabel: 'Diperiksa Oleh',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiCard(
            label: 'Perbedaan Ditemukan',
            count: totalSelisih,
            color: AppColors.warning,
            icon: Symbols.warning_rounded,
            sublabel: 'item selisih',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiCard(
            label: 'Nilai Selisih (Estimasi)',
            count: null,
            countLabelOverride: nilaiLabel,
            color: cdanger(context),
            icon: Symbols.trending_down_rounded,
            sublabel: nilaiSelisih == null
                ? 'perlu harga jual'
                : 'estimasi rupiah',
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.sublabel,
    this.countLabelOverride,
  });

  final String label;
  final int? count; // null if using countLabelOverride (e.g. Rp value)
  final String? countLabelOverride;
  final Color color;
  final IconData icon;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTextStyles.heroJumbo.copyWith(color: color, height: 1);
    // If override is provided AND is longer than typical numeric (e.g. "-Rp 450.000"),
    // use a smaller display size to prevent overflow.
    final useOverride = countLabelOverride != null;
    final displayStyle = useOverride && (countLabelOverride!.length > 4)
        ? AppTextStyles.sectionTitle.copyWith(color: color, height: 1.1)
        : valueStyle;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: cdivider(context).withValues(alpha: 0.5),
          width: 1,
        ),
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
          const SizedBox(height: AppSpacing.md),
          Text(
            useOverride ? countLabelOverride! : '${count ?? 0}',
            style: displayStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: ctextSecondary(context)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              sublabel!,
              style: AppTextStyles.caption.copyWith(color: ctextMuted(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _SetujuiPill extends StatelessWidget {
  const _SetujuiPill({required this.count, required this.onPressed});
  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Symbols.sync_saved_locally_rounded,
          size: AppIconSize.size20,
        ),
        label: Text(
          'Setujui Sinkronisasi ($count)',
          style: AppTextStyles.menuTitle.copyWith(color: Colors.white),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: cteal(context),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.active,
    required this.count,
    required this.onTap,
  });

  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: active
                  ? cteal(context)
                  : cteal(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: active
                    ? cteal(context)
                    : cteal(context).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Symbols.filter_list_rounded,
                  size: AppIconSize.size16,
                  color: active ? Colors.white : cteal(context),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Hanya Selisih',
                  style: AppTextStyles.label.copyWith(
                    color: active ? Colors.white : cteal(context),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.3)
                          : cteal(context).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$count',
                      style: AppTextStyles.labelXs.copyWith(
                        color: active ? Colors.white : cteal(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'SKU / ITEM',
              style: AppTextStyles.labelXs,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'SISTEM',
              style: AppTextStyles.labelXs.copyWith(
                color: ctextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'FISIK',
              style: AppTextStyles.labelXs.copyWith(
                color: ctextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'SELISIH',
              style: AppTextStyles.labelXs.copyWith(
                color: ctextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'STATUS',
              style: AppTextStyles.labelXs.copyWith(
                color: ctextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'AKSI',
              style: AppTextStyles.labelXs.copyWith(
                color: ctextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SinkronisasiStokCard extends StatelessWidget {
  const _SinkronisasiStokCard({
    required this.item,
    this.namaObat,
    required this.onTap,
    required this.onDelete,
    required this.selisihColor,
    required this.selisihLabel,
  });

  final SinkronisasiStokModel item;
  final String? namaObat;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color selisihColor;
  final String selisihLabel;

  String _statusLabel() {
    if (item.isBalanced) return 'Sesuai';
    if (item.isOverStock) return 'Lebih';
    return 'Kurang';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge (tertiary color)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'SKU-${item.idObat}',
                    style: AppTextStyles.labelXs.copyWith(
                      color: AppColors.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Name
                Text(
                  namaObat ?? 'Obat #${item.idObat}',
                  style: AppTextStyles.title.copyWith(
                    color: ctextPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (namaObat != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID Obat: ${item.idObat}',
                    style: AppTextStyles.caption.copyWith(
                      color: ctextMuted(context),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // 3-column metrics row
                Row(
                  children: [
                    Expanded(
                      child: _MetricCell(
                        label: 'Sistem',
                        value: '${item.stokSistem}',
                        color: ctextSecondary(context),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: cdivider(context),
                    ),
                    Expanded(
                      child: _MetricCell(
                        label: 'Fisik',
                        value: '${item.stokFisik}',
                        color: ctextPrimary(context),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: cdivider(context),
                    ),
                    Expanded(
                      child: _MetricCell(
                        label: 'Selisih',
                        value: selisihLabel,
                        color: selisihColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Status pill + "Detail" text button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: selisihColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: AppTextStyles.label.copyWith(color: selisihColor),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    if (item.alasanPenyesuaian != null &&
                        item.alasanPenyesuaian!.isNotEmpty)
                      Expanded(
                        child: Text(
                          item.alasanPenyesuaian!,
                          style: AppTextStyles.caption.copyWith(
                            color: ctextMuted(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          asDate(item.tanggalOpname),
                          style: AppTextStyles.caption.copyWith(
                            color: ctextMuted(context),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: cteal(context),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: const Size(0, AppSpacing.sm5),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Detail'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.metric.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelXs.copyWith(
            color: ctextMuted(context),
          ),
        ),
      ],
    );
  }
}
