import 'package:flutter/material.dart';

import '../core/design_system/app_tokens.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/obat_keluar_daily_summary.dart';
import '../data/models/obat_keluar_model.dart';
import '../data/repositories/obat_keluar_repository.dart';
import '../features/obat_keluar/obat_keluar_grouping.dart';
import '../features/stok/services/stock_service.dart';
import 'obat_keluar_detail_page.dart';
import 'obat_keluar_form_page.dart';
import 'obat_keluar_tanggal_form_page.dart';

/// Page: Pengeluaran Stok — blue-accent composition.
/// Tidak memiliki Scaffold/AppBar sendiri; dirancang untuk di-embed
/// di dalam ObatHubPage (tab body).
class ObatKeluarPage extends StatefulWidget {
  const ObatKeluarPage({super.key});

  static const routeName = '/obat-keluar';

  @override
  State<ObatKeluarPage> createState() => _ObatKeluarPageState();
}

class _ObatKeluarPageState extends State<ObatKeluarPage> {
  final ObatKeluarRepository _repo = ObatKeluarRepository();
  final StockService _stockService = StockService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<ObatKeluarModel>> _future;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _future = _repo.getObatKeluar();
    _searchController.addListener(() {
      final nextKeyword = _searchController.text.trim().toLowerCase();
      if (_keyword != nextKeyword) {
        setState(() => _keyword = nextKeyword);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = _repo.getObatKeluar();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _openTambahTanggal() async {
    final selectedDate = await Navigator.pushNamed(
      context,
      ObatKeluarTanggalFormPage.routeName,
    );

    if (!mounted || selectedDate == null) return;

    final date = selectedDate is DateTime
        ? selectedDate
        : DateTime.tryParse(selectedDate.toString());
    if (date == null) return;

    await Navigator.pushNamed(
      context,
      ObatKeluarFormPage.routeName,
      arguments: date,
    );
    await _reload();
  }

  Future<void> _openDetail(DateTime tanggal) async {
    await Navigator.pushNamed(
      context,
      ObatKeluarDetailPage.routeName,
      arguments: tanggal,
    );
    await _reload();
  }

  Future<void> _deleteTanggal(ObatKeluarDailySummary item) async {
    final displayTanggal = asDate(item.tanggal);

    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Pengeluaran Stok',
      message:
          'Hapus semua pengeluaran stok pada $displayTanggal?\nJumlah data: ${item.jumlahItem}',
    );
    if (!confirm) return;

    try {
      await _stockService.deleteStokKeluarByTanggal(item.tanggal);
      if (!mounted) return;
      showModernSnackBar(context, 'Pengeluaran stok berhasil dihapus');
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

  List<ObatKeluarDailySummary> _buildSummary(List<ObatKeluarModel> items) {
    final summaries = groupObatKeluarByTanggal(items);
    if (_keyword.isEmpty) return summaries;

    return summaries.where((item) {
      final dbDate = formatDateDb(item.tanggal).toLowerCase();
      final displayDate = asDate(item.tanggal).toLowerCase();
      return dbDate.contains(_keyword) || displayDate.contains(_keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = cobatBlue(context);
    final softBg = cobatBlueSoft(context);

    return Column(
      children: [
        // ── Soft header strip ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: softBg,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                ModernSearchBar(
                  controller: _searchController,
                  hintText: 'Cari pengeluaran stok...',
                  onClear: () => setState(() => _keyword = ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Riwayat pengeluaran stok non-penjualan dikelompokkan per tanggal.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ctextSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Transaction list ──────────────────────────────────────────
        Expanded(
          child: FutureBuilder<List<ObatKeluarModel>>(
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

              final items = snapshot.data ?? const <ObatKeluarModel>[];
              final summaryItems = _buildSummary(items);

              if (summaryItems.isEmpty) {
                return AppEmptyView(
                  icon: AppSymbols.receipt,
                  title: _keyword.isEmpty
                      ? 'Belum ada pengeluaran stok'
                      : 'Pengeluaran stok tidak ditemukan',
                  message: _keyword.isEmpty
                      ? 'Catat stok keluar non-penjualan seperti rusak, kedaluwarsa, hilang, dipakai internal, atau koreksi.'
                      : 'Coba kata kunci atau tanggal yang berbeda.',
                  color: accentColor,
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                color: accentColor,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: summaryItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = summaryItems[index];
                    return ModernListCard(
                      title: asDate(item.tanggal),
                      subtitle:
                          '${item.jumlahItem} item  •  ${item.jumlahNota} pengeluaran',
                      trailingText: rupiah(item.totalNominal),
                      icon: AppSymbols.receipt,
                      accentColor: accentColor,
                      onTap: () => _openDetail(item.tanggal),
                      onDelete: () => _deleteTanggal(item),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // ── FAB ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: _BlueFAB(
              icon: AppSymbols.tambah,
              label: 'Tambah Pengeluaran Stok',
              accentColor: accentColor,
              onPressed: _openTambahTanggal,
            ),
          ),
        ),
      ],
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

// ── Domain-colored FAB ────────────────────────────────────────────────────────

class _BlueFAB extends StatelessWidget {
  const _BlueFAB({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
