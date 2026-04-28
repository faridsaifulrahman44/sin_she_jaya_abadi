import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/kehadiran_detail_item.dart';
import '../data/models/kehadiran_form_args.dart';
import '../data/models/kehadiran_model.dart';
import '../data/models/pasien_model.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/kunjungan_repository.dart';
import '../data/repositories/pasien_repository.dart';
import 'kehadiran_form_page.dart';
import 'pasien_detail_page.dart';
import 'pasien_hub_page.dart';

/// Body-widget (embeddable) untuk tab "Daftar Hadir".
///
/// Tidak memiliki Scaffold/AppBar sendiri — dirancang untuk di-embed
/// di dalam TabBarView milik [PasienHubPage].
class KehadiranTabContent extends StatefulWidget {
  const KehadiranTabContent({
    super.key,
    this.onRefresh,
    this.domainSummary,
  });

  /// Callback opsional untuk refresh parent setelah input kehadiran tersimpan.
  final Future<void> Function()? onRefresh;

  /// Summary data dari parent (PasienHubPage).
  final DomainSummaryPasien? domainSummary;

  @override
  State<KehadiranTabContent> createState() => _KehadiranTabContentState();
}

class _KehadiranTabContentState extends State<KehadiranTabContent> {
  final PasienRepository _pasienRepository = PasienRepository();
  final KehadiranRepository _kehadiranRepository = KehadiranRepository();
  final KunjunganRepository _kunjunganRepository = KunjunganRepository();

  /// Tanggal filter aktif. Default = hari ini.
  late DateTime _selectedDate;
  late Future<List<KehadiranDetailItem>> _future;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _future = _loadData(_selectedDate);
  }

  // ── Data ────────────────────────────────────────────────────────────────────

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

    // Ambil tanggal kontrol berikutnya untuk semua pasien di list ini.
    final kontrolMap =
        await _kunjunganRepository.getKontrolBerikutnyaByPasienIds(
            pasienList.map((p) => p.idPasien).toList());

    return pasienList.map((pasien) {
      return KehadiranDetailItem(
        pasien: pasien,
        kehadiran: kehadiranMap[pasien.idPasien],
        tanggalKontrolBerikutnya: kontrolMap[pasien.idPasien],
      );
    }).toList();
  }

  Future<void> _reload() async {
    final future = _loadData(_selectedDate);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: cteal(ctx)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _setDate(picked);
    }
  }

  void _setDate(DateTime date) {
    if (_selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day) {
      return;
    }

    setState(() {
      _selectedDate = date;
      _future = _loadData(date);
    });
  }

  void _goToToday() {
    _setDate(DateTime.now());
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _openForm(KehadiranDetailItem item) async {
    await Navigator.pushNamed(
      context,
      KehadiranFormPage.routeName,
      arguments: KehadiranFormArgs(
        tanggal: _selectedDate,
        idPasien: item.pasien.idPasien,
        namaPasien: item.pasien.namaPasien,
        statusHadir: item.kehadiran?.statusHadir,
        keterangan: item.keteranganKehadiran,
      ),
    );
    await _reload();
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  Future<void> _openPasienDetail(PasienModel pasien) async {
    await Navigator.pushNamed(
      context,
      PasienDetailPage.routeName,
      arguments: pasien,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDateFull(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  String _formatDateShort(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tealColor = cteal(context);
    final successColor = csuccess(context);
    final dangerColor = cdanger(context);

    return Column(
      children: [
        // ── Date filter ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            children: [
              Text(
                'Pilih tanggal untuk melihat daftar pasien dijadwalkan hadir',
                style: TextStyle(
                  fontSize: 12,
                  color: ctextSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _isToday
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _HariIniChip(onTap: _goToToday),
                        ),
                  Expanded(
                    child: _DatePickerButton(
                      date: _selectedDate,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    color: tealColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isToday ? 'Hari Ini' : _formatDateShort(_selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(height: 10),
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

                      final items = snapshot.data ?? const [];
                      if (items.isEmpty) {
                        return AppEmptyView(
                          title: _isToday
                              ? 'Belum ada pasien dijadwalkan hadir hari ini'
                              : 'Belum ada pasien dijadwalkan hadir\n${_formatDateFull(_selectedDate)}',
                          message: _isToday
                              ? 'Pasien dijadwalkan hadir ${_formatDateFull(_selectedDate)} akan tampil di sini.'
                              : null,
                          icon: AppIcons.calendar03,
                          color: tealColor,
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
                                            color: statusColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: HugeIcon(
                                            icon: AppIcons.person,
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
                                              if (item.kehadiran != null) ...[
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
                                              if (item
                                                  .hasKontrolBerikutnya) ...[
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: cwarning(context)
                                                        .withValues(
                                                            alpha: 0.14),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      HugeIcon(
                                                        icon:
                                                            AppIcons.calendar03,
                                                        color:
                                                            cwarning(context),
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Kontrol: ${asMediumDate(item.tanggalKontrolBerikutnya!)}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              cwarning(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () =>
                                              _openPasienDetail(item.pasien),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: HugeIcon(
                                              icon: AppIcons.detail,
                                              color: ctextSecondary(ctx),
                                              size: 18,
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
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _HariIniChip extends StatelessWidget {
  const _HariIniChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cteal(context).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cteal(context).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: AppIcons.calendar03,
              color: cteal(context),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Hari Ini',
              style: TextStyle(
                color: cteal(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cteal(context).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cteal(context).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: AppIcons.calendar03,
              color: cteal(context),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd MMMM yyyy', 'id_ID').format(date),
              style: TextStyle(
                color: cteal(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
