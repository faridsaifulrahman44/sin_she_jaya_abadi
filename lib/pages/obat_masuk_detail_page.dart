import 'package:flutter/material.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/obat_masuk_model.dart';
import '../data/repositories/obat_masuk_repository.dart';
import '../features/stok/services/stock_service.dart';
import '../widgets/page_header.dart';
import 'obat_masuk_form_page.dart';

class ObatMasukDetailPage extends StatefulWidget {
  const ObatMasukDetailPage({super.key});

  static const routeName = '/obat-masuk-detail';

  @override
  State<ObatMasukDetailPage> createState() => _ObatMasukDetailPageState();
}

class _ObatMasukDetailPageState extends State<ObatMasukDetailPage> {
  final ObatMasukRepository _repo = ObatMasukRepository();
  final StockService _stockService = StockService();
  late DateTime _tanggal;
  late Future<List<ObatMasukModel>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DateTime) {
      _tanggal = DateTime(args.year, args.month, args.day);
    } else {
      _tanggal = DateTime.tryParse(args?.toString() ?? '') ?? DateTime.now();
    }
    _future = _repo.getObatMasukDetailByTanggal(_tanggal);
  }

  Future<void> _reload() async {
    final future = _repo.getObatMasukDetailByTanggal(_tanggal);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _openForm([ObatMasukModel? item]) async {
    final args = item ?? _tanggal;
    await Navigator.pushNamed(
      context,
      ObatMasukFormPage.routeName,
      arguments: args,
    );
    await _reload();
  }

  Future<void> _deleteItem(ObatMasukModel item) async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Transaksi Masuk',
      message: 'Yakin ingin menghapus transaksi ini?',
    );
    if (confirm != true) return;

    try {
      await _stockService.deleteStokMasuk(item.idMasuk);
      if (!mounted) return;
      showModernSnackBar(context, 'Transaksi berhasil dihapus');
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

  Future<void> _deleteAllByTanggal() async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Semua Transaksi',
      message:
          'Yakin ingin menghapus semua transaksi masuk pada ${asDate(_tanggal)}?\n\nTindakan ini tidak dapat dibatalkan.',
    );
    if (!confirm) return;

    try {
      await _stockService.deleteStokMasukByTanggal(_tanggal);
      if (!mounted) return;
      showModernSnackBar(context, 'Semua transaksi berhasil dihapus');
      Navigator.pop(context);
    } catch (error, stackTrace) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        AppErrorMapper.toMessage(error, stackTrace),
        isError: true,
      );
    }
  }

  PopupMenuButton<int> _buildRowPopup(ObatMasukModel item) {
    return PopupMenuButton<int>(
      icon: Icon(
        AppSymbols.more,
        color: ctextSecondary(context),
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (ctx) => [
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(
                  AppSymbols.edit,
                  size: 18,
                  color: ctextSecondary(ctx)),
              const SizedBox(width: 10),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(
                  AppSymbols.hapus, size: 18, color: cdanger(ctx)),
              const SizedBox(width: 10),
              Text('Hapus', style: TextStyle(color: cdanger(ctx))),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 0) {
          _openForm(item);
        } else if (value == 1) {
          _deleteItem(item);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Detail Obat Masuk',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cobatGreen(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: Icon(
                AppSymbols.hapus,
                color: conPrimary(context)),
            tooltip: 'Hapus semua transaksi',
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                        AppSymbols.hapusSweep,
                        size: 18,
                        color: cdanger(ctx)),
                    const SizedBox(width: 10),
                    Text('Hapus Semua', style: TextStyle(color: cdanger(ctx))),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _deleteAllByTanggal(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('Rincian Obat Masuk'),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tanggal: ${asDate(_tanggal)}',
                style: TextStyle(
                  color: ctextSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Tap baris untuk edit. Tekan menu ⋮ untuk hapus.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ctextMuted(context), fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ObatMasukModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingView();
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
                  if (items.isEmpty) {
                    return AppEmptyView(
                      icon: AppSymbols.input,
                      title: 'Belum ada transaksi masuk',
                      message: 'Tambahkan transaksi untuk tanggal ini.',
                      color: cteal(context),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        final safeNamaObat =
                            (item.namaObat ?? '').trim().isNotEmpty
                                ? item.namaObat!.trim()
                                : 'Obat #${item.idObat}';
                        return ModernListCard(
                          title: safeNamaObat,
                          subtitle: 'Jumlah masuk: ${item.jumlahMasuk} unit',
                          trailingText: '+${item.jumlahMasuk}',
                          leading: ObatImage(
                            namaObat: safeNamaObat,
                            fotoKey: item.fotoKey,
                            fotoUpdatedAt: item.fotoUpdatedAt,
                            fotoUrl: item.fotoUrl,
                            width: 44,
                            height: 44,
                            borderRadius: 12,
                          ),
                          accentColor: cteal(ctx),
                          onTap: () => _openForm(item),
                          trailingPopup: _buildRowPopup(item),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cobatGreen(context),
                  foregroundColor: conPrimary(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _openForm(),
                child: const Text(
                  'Tambah Obat Masuk',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
