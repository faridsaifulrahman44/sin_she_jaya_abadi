import 'package:flutter/material.dart';

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/kehadiran_model.dart';
import '../data/models/kunjungan_model.dart';
import '../data/models/pasien_model.dart';
import '../data/models/transaksi_model.dart';
import '../data/repositories/pasien_detail_repository.dart';
import '../features/pasien/pasien_detail_aggregator.dart';
import 'kunjungan_form_page.dart';
import '../features/pasien/pasien_detail_summary.dart';

class PasienDetailPage extends StatefulWidget {
  const PasienDetailPage({super.key});

  static const routeName = '/pasien-detail';

  @override
  State<PasienDetailPage> createState() => _PasienDetailPageState();
}

class _PasienDetailPageState extends State<PasienDetailPage> {
  static const int _defaultVisibleRiwayat = 6;

  final PasienDetailRepository _repository = PasienDetailRepository();
  Future<PasienDetailSummary>? _future;
  int? _idPasien;
  bool _initialized = false;
  bool _showAllKehadiran = false;
  bool _showAllTransaksi = false;
  bool _showAllKunjungan = false;
  bool _isOwner = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;

    _idPasien = _resolveIdPasien(ModalRoute.of(context)?.settings.arguments);
    if ((_idPasien ?? 0) > 0) {
      _future = _loadData(_idPasien!);
    }
  }

  int? _resolveIdPasien(dynamic args) {
    if (args is PasienModel) {
      return args.idPasien;
    }
    if (args is int) {
      return args;
    }
    if (args is String) {
      return int.tryParse(args.trim());
    }
    if (args is Map<String, dynamic>) {
      final dynamic raw = args['id_pasien'] ?? args['idPasien'];
      if (raw is int) {
        return raw;
      }
      return int.tryParse(raw?.toString() ?? '');
    }
    return null;
  }

  Future<PasienDetailSummary> _loadData(int idPasien) async {
    final isOwner = await AdminSession.isOwner();
    final bundle = await _repository.getDetail(
      idPasien,
      includeRiwayatTransaksi: isOwner,
    );
    if (!mounted) {
      return buildPasienDetailSummary(
        pasien: bundle.pasien,
        riwayatKehadiran: bundle.riwayatKehadiran,
        riwayatTransaksi: bundle.riwayatTransaksi,
        riwayatKunjungan: bundle.riwayatKunjungan,
      );
    }
    setState(() => _isOwner = isOwner);
    return buildPasienDetailSummary(
      pasien: bundle.pasien,
      riwayatKehadiran: bundle.riwayatKehadiran,
      riwayatTransaksi: bundle.riwayatTransaksi,
      riwayatKunjungan: bundle.riwayatKunjungan,
    );
  }

  Future<void> _reload() async {
    final idPasien = _idPasien;
    if (idPasien == null || idPasien <= 0) {
      return;
    }
    final future = _loadData(idPasien);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Detail Pasien',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: cteal(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: future == null
          ? AppErrorView(message: 'Data pasien tidak valid.', onRetry: _reload)
          : FutureBuilder<PasienDetailSummary>(
              future: future,
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

                final summary = snapshot.data;
                if (summary == null) {
                  return const AppEmptyView(
                    title: 'Data detail pasien belum tersedia',
                    message: 'Silakan tarik ulang untuk memuat data pasien.',
                    icon: AppSymbols.person,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  color: cteal(context),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(summary),
                        const SizedBox(height: 16),
                        _buildRingkasan(summary),
                        const SizedBox(height: 16),
                        _buildDataPribadiSection(summary),
                        const SizedBox(height: 16),
                        _buildInformasiTambahanSection(summary),
                        const SizedBox(height: 16),
                        _buildKunjunganSection(summary),
                        const SizedBox(height: 16),
                        _buildKehadiranSection(summary),
                        if (_isOwner) ...[
                          const SizedBox(height: 16),
                          _buildTransaksiSection(summary),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                final id = _idPasien;
                if (id != null) _navigateToKunjunganForm(id);
              },
              backgroundColor: cteal(context),
              foregroundColor: conPrimary(context),
              icon: const Icon(
                AppSymbols.addBox,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Tambah Kunjungan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonListCard(),
        SizedBox(height: 10),
        SkeletonListCard(),
        SizedBox(height: 10),
        SkeletonListCard(),
      ],
    );
  }

  Widget _buildHeader(PasienDetailSummary summary) {
    final pasien = summary.pasien;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cteal(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppSymbols.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pasien.namaPasien,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No. Pasien ${pasien.nomorPasien}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderChip(
                label:
                    'Terakhir datang: ${_formatNullableMediumDate(summary.terakhirHadir)}',
              ),
              _buildHeaderChip(
                label:
                    'Terakhir tercatat: ${_formatNullableMediumDate(summary.terakhirTercatat)}',
              ),
              if (summary.kontrolBerikutnya != null)
                _buildHeaderChip(
                  label:
                      'Kontrol: ${_formatNullableMediumDate(summary.kontrolBerikutnya)}',
                  color: Colors.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip({required String label, Color? color}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRingkasan(PasienDetailSummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _buildRingkasanCard(
          title: 'Total Kehadiran',
          value: '${summary.totalKehadiran}',
          subtitle:
              'Hadir ${summary.totalHadir} • Tidak ${summary.totalTidakHadir}',
          icon: AppSymbols.event,
          accentColor: cteal(context),
        ),
        if (_isOwner) ...[
          _buildRingkasanCard(
            title: 'Total Transaksi',
            value: '${summary.totalTransaksi}',
            subtitle: rupiah(summary.totalNominalTransaksi),
            icon: AppSymbols.receipt,
            accentColor: csuccess(context),
          ),
          _buildRingkasanCard(
            title: 'Transaksi Terakhir',
            value: _formatNullableMediumDate(
              summary.transaksiTerakhir?.tanggal,
            ),
            subtitle: summary.transaksiTerakhir?.jenisTransaksi.label ?? '-',
            icon: AppSymbols.payment,
            accentColor: cindigo(context),
          ),
        ],
        _buildRingkasanCard(
          title: 'Terakhir Datang',
          value: _formatNullableMediumDate(summary.terakhirHadir),
          subtitle: 'Status hadir terakhir',
          icon: AppSymbols.calendar03,
          accentColor: cwarning(context),
        ),
      ],
    );
  }

  Widget _buildRingkasanCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: ctextSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: ctextMuted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPribadiSection(PasienDetailSummary summary) {
    final pasien = summary.pasien;

    return _buildSectionCard(
      title: 'Data Pribadi',
      child: Column(
        children: [
          _buildInfoRow(label: 'Nomor Pasien', value: pasien.nomorPasien),
          _buildInfoRow(label: 'Nama Pasien', value: pasien.namaPasien),
          _buildInfoRow(label: 'Usia', value: '${pasien.usia} tahun'),
          _buildInfoRow(label: 'Gender', value: pasien.jenisKelaminLabel),
          _buildInfoRow(label: 'Alamat', value: pasien.alamat ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInformasiTambahanSection(PasienDetailSummary summary) {
    final pasien = summary.pasien;
    final tanggalData = pasien.createdAt ?? pasien.tanggalJanjian;

    return _buildSectionCard(
      title: 'Informasi Tambahan',
      child: Column(
        children: [
          _buildInfoRow(
            label: 'Tanggal Data',
            value: _formatNullableMediumDate(tanggalData),
          ),
          _buildInfoRow(
            label: 'Tanggal Janjian',
            value: _formatNullableMediumDate(pasien.tanggalJanjian),
          ),
          _buildInfoRow(
            label: 'Terakhir Hadir',
            value: _formatNullableMediumDate(summary.terakhirHadir),
          ),
          _buildInfoRow(
            label: 'Terakhir Tercatat',
            value: _formatNullableMediumDate(summary.terakhirTercatat),
          ),
          _buildInfoRow(
            label: 'Kontrol Berikutnya',
            value: _formatNullableMediumDate(summary.kontrolBerikutnya),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    final labelStyle = TextStyle(
      fontSize: 12,
      color: ctextSecondary(context),
      fontWeight: FontWeight.w600,
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      color: ctextPrimary(context),
      fontWeight: FontWeight.w600,
      height: 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 3),
                Text(value, style: valueStyle),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 124, child: Text(label, style: labelStyle)),
              const SizedBox(width: 10),
              Expanded(child: Text(value, style: valueStyle)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitleRow({required String title, Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ctextPrimary(context),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Flexible(child: trailing),
        ],
      ],
    );
  }

  Widget _buildCountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: csurface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cdivider(context)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: ctextSecondary(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHistoryBadge({required String label, required Color color}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildKehadiranSection(PasienDetailSummary summary) {
    final allItems = summary.riwayatKehadiran;
    final visibleItems = _showAllKehadiran
        ? allItems
        : allItems.take(_defaultVisibleRiwayat).toList(growable: false);

    return _buildSectionCard(
      title: 'Riwayat Kehadiran',
      trailing: _buildCountBadge('${summary.totalKehadiran} data'),
      child: allItems.isEmpty
          ? const AppEmptyView(
              title: 'Belum ada riwayat kehadiran',
              message: 'Kehadiran pasien akan muncul setelah dicatat.',
              icon: AppSymbols.calendar03,
            )
          : Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    return _buildKehadiranItem(item);
                  },
                ),
                if (allItems.length > _defaultVisibleRiwayat)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllKehadiran = !_showAllKehadiran;
                        });
                      },
                      child: Text(
                        _showAllKehadiran
                            ? 'Sembunyikan kehadiran'
                            : 'Lihat semua kehadiran',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildKehadiranItem(KehadiranModel item) {
    final isHadir = item.statusHadir == StatusHadir.hadir;
    final badgeColor = isHadir ? csuccess(context) : cdanger(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cscaffoldBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cdivider(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isHadir ? 'Hadir' : 'Tidak Hadir',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asMediumDate(item.tanggalHadir),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ctextPrimary(context),
                  ),
                ),
                if ((item.keterangan ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.keterangan!.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: ctextSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiSection(PasienDetailSummary summary) {
    final allItems = summary.riwayatTransaksi;
    final visibleItems = _showAllTransaksi
        ? allItems
        : allItems.take(_defaultVisibleRiwayat).toList(growable: false);

    return _buildSectionCard(
      title: 'Riwayat Transaksi',
      trailing: _buildCountBadge('${summary.totalTransaksi} data'),
      child: allItems.isEmpty
          ? const AppEmptyView(
              title: 'Belum ada transaksi terhubung',
              message:
                  'Riwayat transaksi akan tampil jika transaksi dikaitkan ke pasien ini.',
              icon: AppSymbols.receipt,
            )
          : Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    return _buildTransaksiItem(item);
                  },
                ),
                if (allItems.length > _defaultVisibleRiwayat)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllTransaksi = !_showAllTransaksi;
                        });
                      },
                      child: Text(
                        _showAllTransaksi
                            ? 'Sembunyikan transaksi'
                            : 'Lihat semua transaksi',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTransaksiItem(TransaksiModel item) {
    final metode = item.metodeBayar?.label ?? '-';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cscaffoldBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cdivider(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asMediumDate(item.tanggal),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.jenisTransaksi.label} • $metode',
                  style: TextStyle(
                    fontSize: 12,
                    color: ctextSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  buildTransaksiRingkasan(item),
                  style: TextStyle(fontSize: 12, color: ctextMuted(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              rupiah(item.total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: csuccess(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToKunjunganForm(int idPasien) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KunjunganFormPage(),
        settings: RouteSettings(arguments: {'id_pasien': idPasien}),
      ),
    );
    if (result == true) {
      _reload();
    }
  }

  void _navigateToEditKunjungan(KunjunganModel kunjungan) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const KunjunganFormPage(),
        settings: RouteSettings(arguments: {'kunjungan': kunjungan}),
      ),
    );
    if (result == true) {
      _reload();
    }
  }

  Widget _buildKunjunganSection(PasienDetailSummary summary) {
    final allItems = summary.riwayatKunjungan;
    final visibleItems = _showAllKunjungan
        ? allItems
        : allItems.take(_defaultVisibleRiwayat).toList(growable: false);

    return _buildSectionCard(
      title: 'Riwayat Kunjungan',
      trailing: _buildCountBadge('${allItems.length} data'),
      child: allItems.isEmpty
          ? const AppEmptyView(
              title: 'Belum ada riwayat kunjungan',
              message: 'Klik tombol + untuk mencatat kunjungan pertama.',
              icon: AppSymbols.calendar03,
            )
          : Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    return _buildKunjunganItem(item);
                  },
                ),
                if (allItems.length > _defaultVisibleRiwayat)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllKunjungan = !_showAllKunjungan;
                        });
                      },
                      child: Text(
                        _showAllKunjungan
                            ? 'Sembunyikan kunjungan'
                            : 'Lihat semua kunjungan',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildKunjunganItem(KunjunganModel item) {
    return InkWell(
      onTap: _isOwner ? () => _navigateToEditKunjungan(item) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cscaffoldBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cdivider(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildHistoryBadge(
                        label: asMediumDate(item.tanggalKunjungan),
                        color: cteal(context),
                      ),
                      if (item.hasKontrolBerikutnya)
                        _buildHistoryBadge(
                          label: 'Kontrol: ${item.tanggalKontrolLabel}',
                          color: cwarning(context),
                        ),
                    ],
                  ),
                ),
                if (_isOwner) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: ctextMuted(context),
                  ),
                ],
              ],
            ),
            if ((item.catatanHasil ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.catatanHasil!.trim(),
                style: TextStyle(fontSize: 12, color: ctextSecondary(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if ((item.tindakLanjut ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tindak lanjut: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: ctextMuted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.tindakLanjut!.trim(),
                      style: TextStyle(
                        fontSize: 11,
                        color: ctextSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitleRow(title: title, trailing: trailing),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  String _formatNullableMediumDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return asMediumDate(value);
  }
}
