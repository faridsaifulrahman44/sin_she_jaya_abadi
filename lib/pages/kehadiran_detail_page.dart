import 'package:flutter/material.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/kehadiran_detail_item.dart';
import '../data/models/kehadiran_form_args.dart';
import '../data/models/kehadiran_model.dart';
import '../data/models/pasien_model.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/pasien_repository.dart';
import '../widgets/page_header.dart';
import 'kehadiran_form_page.dart';
import 'pasien_detail_page.dart';

class KehadiranDetailPage extends StatefulWidget {
  const KehadiranDetailPage({super.key});

  static const routeName = '/kehadiran-detail';

  @override
  State<KehadiranDetailPage> createState() => _KehadiranDetailPageState();
}

class _KehadiranDetailPageState extends State<KehadiranDetailPage> {
  final PasienRepository _pasienRepository = PasienRepository();
  final KehadiranRepository _kehadiranRepository = KehadiranRepository();

  late DateTime _tanggal;
  late Future<List<KehadiranDetailItem>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _tanggal = args is DateTime
        ? DateTime(args.year, args.month, args.day)
        : DateTime.tryParse(args?.toString() ?? '') ?? DateTime.now();
    _future = _loadData(_tanggal);
  }

  Future<List<KehadiranDetailItem>> _loadData(DateTime tanggal) async {
    final results = await Future.wait<dynamic>([
      _pasienRepository.getPasienByTanggalJanjian(tanggal),
      _kehadiranRepository.getKehadiranByTanggal(tanggal),
    ]);

    final pasienList = results[0] as List<PasienModel>;
    final kehadiranList = results[1] as List<KehadiranModel>;
    final kehadiranMap = <int, KehadiranModel>{
      for (final item in kehadiranList) item.idPasien: item,
    };

    return pasienList.map((pasien) {
      return KehadiranDetailItem(
        pasien: pasien,
        kehadiran: kehadiranMap[pasien.idPasien],
      );
    }).toList();
  }

  Future<void> _reload() async {
    final future = _loadData(_tanggal);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _delete(KehadiranDetailItem item) async {
    if (item.kehadiran == null) return;

    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Kehadiran',
      message: 'Hapus kehadiran ${item.pasien.namaPasien} pada tanggal ini?',
    );
    if (confirm != true) return;

    try {
      await _kehadiranRepository.deleteKehadiran(item.kehadiran!.idKehadiran);
      if (!mounted) return;
      showModernSnackBar(context, 'Kehadiran berhasil dihapus');
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

  Future<void> _openForm(KehadiranDetailItem item) async {
    await Navigator.pushNamed(
      context,
      KehadiranFormPage.routeName,
      arguments: KehadiranFormArgs(
        tanggal: _tanggal,
        idPasien: item.pasien.idPasien,
        namaPasien: item.pasien.namaPasien,
        statusHadir: item.kehadiran?.statusHadir,
        keterangan: item.keteranganKehadiran,
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openPasienDetail(PasienModel pasien) async {
    await Navigator.pushNamed(
      context,
      PasienDetailPage.routeName,
      arguments: pasien,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tealColor = cteal(context);
    final successColor = csuccess(context);
    final dangerColor = cdanger(context);
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Detail Daftar Hadir',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: tealColor,
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('Rincian Daftar Hadir'),
            const SizedBox(height: 8),
            Text(
              'Tanggal: ${asDate(_tanggal)}',
              style: TextStyle(
                color: ctextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<KehadiranDetailItem>>(
                future: _future,
                builder: (ctx, snapshot) {
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

                  final items = snapshot.data ?? const <KehadiranDetailItem>[];
                  if (items.isEmpty) {
                    return AppEmptyView(
                      title: 'Belum ada pasien pada tanggal ini',
                      message: 'Silakan pilih tanggal janjian lain.',
                      icon: AppSymbols.calendar03,
                      color: cteal(ctx),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        final status = item.statusHadirLabel;
                        final statusColor =
                            item.kehadiran?.statusHadir == StatusHadir.hadir
                                ? successColor
                                : dangerColor;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: ccardBg(ctx),
                            borderRadius: BorderRadius.circular(14),
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
                              onTap: () => _openForm(item),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        AppSymbols.person,
                                        color: statusColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.pasien.namaPasien,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: ctextPrimary(ctx),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'No. Pasien: ${item.pasien.nomorPasien}',
                                            style: TextStyle(
                                              color: ctextSecondary(ctx),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Status: $status',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _openPasienDetail(item.pasien),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          AppSymbols.detail,
                                          color: ctextSecondary(ctx),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    if (item.kehadiran != null)
                                      GestureDetector(
                                        onTap: () => _delete(item),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            AppSymbols.deleteOutline,
                                            color: cdanger(ctx),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
