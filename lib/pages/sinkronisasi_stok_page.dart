import 'dart:typed_data';

import 'package:flutter/material.dart';
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
import 'sinkronisasi_stok/widgets/sinkronisasi_audit_log_card.dart';
import 'sinkronisasi_stok_form_page.dart';

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
    if (_keyword.isEmpty) return items;
    return items.where((item) {
      return formatDateDb(item.tanggalOpname).contains(_keyword) ||
          asDate(item.tanggalOpname).contains(_keyword) ||
          item.alasanPenyesuaian?.toLowerCase().contains(_keyword) == true;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Sinkronisasi Stok',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cteal(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
        actions: [
          if (_isOwner)
            IconButton(
              tooltip: 'Export CSV',
              onPressed: _exporting ? null : _exportCsv,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(AppSymbols.input),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: cteal(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ModernSearchBar(
                  controller: _searchController,
                  hintText: 'Cari tanggal atau alasan...',
                  onClear: () => setState(() => _keyword = ''),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_isOwner) const SinkronisasiAuditLogCard(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cscaffoldBg(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
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

                      final items = _filter(snapshot.data ?? const []);

                      if (items.isEmpty) {
                        return AppEmptyView(
                          icon: AppSymbols.refresh,
                          title: _keyword.isEmpty
                              ? 'Belum ada riwayat sinkronisasi'
                              : 'Entri tidak ditemukan',
                          message: _keyword.isEmpty
                              ? 'Gunakan fitur ini untuk menyesuaikan stok sistem dengan stok fisik di klinik.'
                              : 'Coba kata kunci lain.',
                          color: cteal(context),
                        );
                      }

                      // Load nama_obat lazily once; FutureBuilder rebuilds the
                      // list when the name map arrives. Names are optional —
                      // empty map falls back to the existing "ID Obat: X" label.
                      return FutureBuilder<Map<int, String>>(
                        future: _loadObatNameMap(),
                        builder: (ctx, namesSnap) {
                          final names = namesSnap.data ?? const <int, String>{};
                          return RefreshIndicator(
                            onRefresh: _reload,
                            color: cteal(context),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, index) {
                                final item = items[index];
                                return _SinkronisasiStokCard(
                                  item: item,
                                  namaObat: names[item.idObat],
                                  onTap: () => _openForm(item),
                                  onDelete: () => _deleteItem(item),
                                  selisihColor: _selisihColor(item, ctx),
                                  selisihLabel: _selisihLabel(item),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GradientFAB(
        icon: AppSymbols.refresh,
        label: 'Sinkronkan Stok',
        onPressed: () => _openForm(),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cteal(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    AppSymbols.refresh,
                    color: cteal(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaObat ?? 'Obat #${item.idObat}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ctextPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (namaObat != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'ID Obat: ${item.idObat}',
                          style: TextStyle(
                            color: ctextMuted(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Tanggal: ${asDate(item.tanggalOpname)}',
                        style: TextStyle(
                          color: ctextSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      if (item.alasanPenyesuaian != null &&
                          item.alasanPenyesuaian!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.alasanPenyesuaian!,
                          style: TextStyle(
                            color: ctextMuted(context),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Sistem: ${item.stokSistem}  •  Fisik: ${item.stokFisik}',
                        style: TextStyle(
                          color: ctextSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selisihColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        selisihLabel,
                        style: TextStyle(
                          color: selisihColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        AppSymbols.deleteOutline,
                        color: cdanger(context),
                        size: 20,
                      ),
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
