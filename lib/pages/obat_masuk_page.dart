import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/obat_masuk_daily_summary.dart';
import '../data/models/obat_masuk_model.dart';
import '../data/repositories/obat_masuk_repository.dart';
import '../features/obat_masuk/obat_masuk_grouping.dart';
import 'obat_masuk_detail_page.dart';
import 'obat_masuk_form_page.dart';
import 'obat_masuk_tanggal_form_page.dart';

/// Page: Obat Masuk — blue-accent composition.
/// Tidak memiliki Scaffold/AppBar sendiri; dirancang untuk di-embed
/// di dalam ObatHubPage (tab body).
class ObatMasukPage extends StatefulWidget {
  const ObatMasukPage({super.key});

  static const routeName = '/obat-masuk';

  @override
  State<ObatMasukPage> createState() => _ObatMasukPageState();
}

class _ObatMasukPageState extends State<ObatMasukPage> {
  final ObatMasukRepository _repo = ObatMasukRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<ObatMasukModel>> _future;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _future = _repo.getObatMasuk();
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
    final future = _repo.getObatMasuk();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _openTambahTanggal() async {
    final selectedDate = await Navigator.pushNamed(
      context,
      ObatMasukTanggalFormPage.routeName,
    );

    if (!mounted || selectedDate == null) return;

    final date = selectedDate is DateTime
        ? selectedDate
        : DateTime.tryParse(selectedDate.toString());
    if (date == null) return;

    await Navigator.pushNamed(
      context,
      ObatMasukFormPage.routeName,
      arguments: date,
    );
    await _reload();
  }

  Future<void> _openDetail(DateTime tanggal) async {
    await Navigator.pushNamed(
      context,
      ObatMasukDetailPage.routeName,
      arguments: tanggal,
    );
    await _reload();
  }

  Future<void> _deleteTanggal(ObatMasukDailySummary item) async {
    final displayTanggal = asDate(item.tanggal);

    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Semua Transaksi',
      message:
          'Hapus semua transaksi masuk pada $displayTanggal?\nJumlah data: ${item.jumlahItem}',
    );
    if (!confirm) return;

    try {
      await _repo.deleteObatMasukByTanggal(item.tanggal);
      if (!mounted) return;
      showModernSnackBar(context, 'Semua transaksi berhasil dihapus');
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

  List<ObatMasukDailySummary> _buildSummary(List<ObatMasukModel> items) {
    final summaries = groupObatMasukByTanggal(items);
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
                  hintText: 'Cari transaksi...',
                  onClear: () => setState(() => _keyword = ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Riwayat obat masuk dikelompokkan per tanggal transaksi.',
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
          child: FutureBuilder<List<ObatMasukModel>>(
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

              final items = snapshot.data ?? const <ObatMasukModel>[];
              final summaryItems = _buildSummary(items);

              if (summaryItems.isEmpty) {
                return AppEmptyView(
                  icon: AppIcons.input,
                  title: _keyword.isEmpty
                      ? 'Belum ada transaksi masuk'
                      : 'Transaksi tidak ditemukan',
                  message: _keyword.isEmpty
                      ? 'Tambah transaksi masuk pertama Anda.'
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
                          '${item.jumlahItem} item masuk  •  Total: ${item.totalJumlahMasuk} unit',
                      trailingText: '${item.totalJumlahMasuk}',
                      icon: AppIcons.input,
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
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: _BlueFAB(
              icon: AppIcons.tambah,
              label: 'Tambah Obat Masuk',
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
      padding: const EdgeInsets.all(16),
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

  final List<List<dynamic>> icon;
  final String label;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: icon, color: Colors.white, size: 20),
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
