import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/obat_keluar_model.dart';
import '../data/repositories/obat_keluar_repository.dart';
import '../widgets/page_header.dart';
import 'obat_keluar_form_page.dart';

class ObatKeluarDetailPage extends StatefulWidget {
  const ObatKeluarDetailPage({super.key});

  static const routeName = '/obat-keluar-detail';

  @override
  State<ObatKeluarDetailPage> createState() => _ObatKeluarDetailPageState();
}

class _ObatKeluarDetailPageState extends State<ObatKeluarDetailPage> {
  final ObatKeluarRepository _repo = ObatKeluarRepository();
  late DateTime _tanggal;
  late Future<List<ObatKeluarModel>> _future;
  bool _initialized = false;
  List<ObatKeluarModel> _cachedItems = const [];
  double _grandTotal = 0;
  int _grandItemCount = 0;

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
    _future = _repo.getObatKeluar(tanggal: _tanggal);
    _reload();
  }

  Future<void> _reload() async {
    final future = _repo.getObatKeluar(tanggal: _tanggal);
    setState(() => _future = future);
    try {
      final items = await future;
      if (!mounted) return;
      setState(() {
        _cachedItems = items;
        _grandTotal = items.fold(0.0, (s, t) => s + t.displayTotalNominal);
        _grandItemCount = items.fold(0, (s, t) => s + t.displayJumlahItem);
      });
    } catch (_) {}
  }

  Future<void> _openForm([ObatKeluarModel? item]) async {
    final args = item ?? _tanggal;
    await Navigator.pushNamed(
      context,
      ObatKeluarFormPage.routeName,
      arguments: args,
    );
    await _reload();
  }

  Future<void> _deleteItem(ObatKeluarModel item) async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Transaksi',
      message: 'Yakin ingin menghapus transaksi ini?',
    );
    if (confirm != true) return;

    try {
      await _repo.deleteObatKeluar(item.idTerjual);
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
          'Yakin ingin menghapus semua transaksi pada ${asDate(_tanggal)}?\n\nTindakan ini tidak dapat dibatalkan.',
    );
    if (!confirm) return;

    try {
      await _repo.deleteObatKeluarByTanggal(_tanggal);
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

  PopupMenuButton<int> _buildRowPopup(ObatKeluarModel item) {
    return PopupMenuButton<int>(
      icon: HugeIcon(
        icon: AppIcons.more,
        color: ctextSecondary(context),
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (ctx) => [
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              HugeIcon(
                  icon: AppIcons.editOutline,
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
              HugeIcon(
                  icon: AppIcons.deleteOutline, size: 18, color: cdanger(ctx)),
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
        title: const Text('Detail Obat Keluar',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cobatAmber(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: HugeIcon(
                icon: AppIcons.deleteOutline, color: conPrimary(context)),
            tooltip: 'Hapus semua transaksi',
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    HugeIcon(
                        icon: AppIcons.hapusSweep,
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
            const PageHeader('Rincian Transaksi'),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tanggal Transaksi: ${asDate(_tanggal)}',
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
              child: FutureBuilder<List<ObatKeluarModel>>(
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

                  final items = snapshot.data ?? const <ObatKeluarModel>[];
                  if (items.isEmpty) {
                    return AppEmptyView(
                      icon: AppIcons.receipt,
                      title: 'Belum ada transaksi',
                      message: 'Tambahkan transaksi baru untuk tanggal ini.',
                      color: cwarning(context),
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
                        return ModernListCard(
                          title: 'Etalase ${item.noEtalase ?? '-'}',
                          subtitle:
                              '${item.displayJumlahItem} item${item.isLegacyOnly ? ' (legacy)' : ''}',
                          trailingText: rupiah(item.displayTotalNominal),
                          icon: AppIcons.receipt,
                          accentColor: cwarning(ctx),
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
            if (_cachedItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ($_grandItemCount item dari ${_cachedItems.length} transaksi)',
                      style: TextStyle(
                        color: ctextSecondary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      rupiah(_grandTotal),
                      style: TextStyle(
                        color: cwarning(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cobatAmber(context),
                  foregroundColor: conPrimary(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _openForm(),
                child: const Text(
                  'Tambah Transaksi',
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
