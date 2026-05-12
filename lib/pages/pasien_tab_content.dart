import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/kehadiran_model.dart';
import '../data/models/pasien_model.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/pasien_repository.dart';
import 'kehadiran_form_page.dart';
import 'pasien_detail_page.dart';
import 'pasien_form_page.dart';

enum _PasienListAction { detail, edit, delete, jadwalkanHadir }
enum _PasienFilter { total, jadwal, hadir }

/// Body widget untuk halaman "Data Pasien".
///
/// Dipakai langsung oleh [PasienPage] — halaman standalone.
/// Tidak memiliki tab atau navigasi ke halaman lain.
class PasienTabContent extends StatefulWidget {
  const PasienTabContent({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  State<PasienTabContent> createState() => _PasienTabContentState();
}

class _PasienTabContentState extends State<PasienTabContent> {
  final PasienRepository _repo = PasienRepository();
  final KehadiranRepository _kehadiranRepo = KehadiranRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<PasienModel>> _future;

  // Filter state
  _PasienFilter _activeFilter = _PasienFilter.total;

  @override
  void initState() {
    super.initState();
    _future = _buildFilteredFuture();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PasienModel>> _buildFilteredFuture() async {
    final today = DateTime.now();
    final keyword = _searchController.text.trim();

    if (_activeFilter == _PasienFilter.jadwal) {
      final semua = await _repo.getPasienByTanggalJanjian(today);
      if (keyword.isEmpty) return semua;
      return semua
          .where((p) =>
              p.namaPasien.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    if (_activeFilter == _PasienFilter.hadir) {
      final allPasien =
          await (keyword.isEmpty
              ? _repo.getPasien()
              : _repo.getPasien(keyword: keyword));
      final semuaKehadiran = await _kehadiranRepo.getKehadiranByTanggal(today);
      final hadirIds = semuaKehadiran
          .where((k) => k.statusHadir == StatusHadir.hadir)
          .map((k) => k.idPasien)
          .toSet();
      return allPasien.where((p) => hadirIds.contains(p.idPasien)).toList();
    }

    // total
    return keyword.isEmpty
        ? _repo.getPasien()
        : _repo.getPasien(keyword: keyword);
  }

  Future<void> _reload() async {
    final future = _buildFilteredFuture();
    setState(() {
      _future = future;
    });
    try {
      await future;
      widget.onRefresh?.call();
    } catch (_) {}
  }

  void _setFilter(_PasienFilter filter) {
    if (_activeFilter == filter) return;
    setState(() {
      _activeFilter = filter;
      _future = _buildFilteredFuture();
    });
  }

  Future<void> _openForm([PasienModel? item]) async {
    await Navigator.pushNamed(
      context,
      PasienFormPage.routeName,
      arguments: item,
    );
    await _reload();
  }

  Future<void> _openDetail(PasienModel item) async {
    await Navigator.pushNamed(
      context,
      PasienDetailPage.routeName,
      arguments: item,
    );
    await _reload();
  }

  Future<void> _jadwalkanHadir(PasienModel item) async {
    await Navigator.pushNamed(
      context,
      KehadiranFormPage.routeName,
      arguments: {
        'tanggal': DateTime.now(),
        'id_pasien': item.idPasien,
        'nama_pasien': item.namaPasien,
      },
    );
  }

  Future<void> _delete(PasienModel item) async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Pasien',
      message:
          'Yakin ingin menghapus "${item.namaPasien}"? Tindakan ini tidak dapat dibatalkan.',
    );
    if (!confirm) return;

    try {
      await _repo.deletePasien(item.idPasien);
      if (!mounted) return;
      showModernSnackBar(context, 'Pasien berhasil dihapus');
      await _reload();
      widget.onRefresh?.call();
    } catch (error, stackTrace) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        AppErrorMapper.toMessage(error, stackTrace),
        isError: true,
      );
    }
  }

  Future<void> _handleAction(_PasienListAction action, PasienModel item) async {
    if (action == _PasienListAction.detail) {
      await _openDetail(item);
      return;
    }
    if (action == _PasienListAction.edit) {
      await _openForm(item);
      return;
    }
    if (action == _PasienListAction.jadwalkanHadir) {
      await _jadwalkanHadir(item);
      return;
    }
    await _delete(item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ModernSearchBar(
                  controller: _searchController,
                  hintText: 'Cari nama pasien...',
                  onChanged: (_) => _reload(),
                  onClear: _reload,
                ),
              ),
              const SizedBox(width: 10),
              _AddPatientIconButton(onPressed: () => _openForm()),
            ],
          ),
        ),
        _buildFilterChips(),
        Expanded(
          child: FutureBuilder<List<PasienModel>>(
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

              final items = snapshot.data ?? const <PasienModel>[];
              if (items.isEmpty) {
                return AppEmptyView(
                  icon: AppIcons.person,
                  title: _emptyTitle,
                  message: _emptyMessage,
                  color: cteal(context),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                color: cteal(context),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _PasienCard(
                      item: item,
                      onTap: () => _openDetail(item),
                      onAction: (action) => _handleAction(action, item),
                    );
                  },
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: GradientFAB(
                icon: AppIcons.tambah,
                label: 'Tambah Pasien',
                onPressed: () => _openForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _emptyTitle {
    switch (_activeFilter) {
      case _PasienFilter.total:
        return 'Belum ada data pasien';
      case _PasienFilter.jadwal:
        return 'Tidak ada pasien dijadwalkan';
      case _PasienFilter.hadir:
        return 'Belum ada pasien hadir';
    }
  }

  String? get _emptyMessage {
    switch (_activeFilter) {
      case _PasienFilter.total:
        return 'Tambah pasien pertama Anda.';
      case _PasienFilter.jadwal:
      case _PasienFilter.hadir:
        return null;
    }
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _FilterChip(
            label: 'Total Pasien',
            icon: AppIcons.person,
            isActive: _activeFilter == _PasienFilter.total,
            color: cteal(context),
            onTap: () => _setFilter(_PasienFilter.total),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Jadwal Hari Ini',
            icon: AppIcons.kalender,
            isActive: _activeFilter == _PasienFilter.jadwal,
            color: const Color(0xFF6366F1),
            onTap: () => _setFilter(_PasienFilter.jadwal),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Hadir Hari Ini',
            icon: AppIcons.pasienHadir,
            isActive: _activeFilter == _PasienFilter.hadir,
            color: const Color(0xFF10B981),
            onTap: () => _setFilter(_PasienFilter.hadir),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const SkeletonListCard(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = color;
    final activeFg = Colors.white;
    final activeBorder = color;

    final inactiveBg = isDark
        ? DarkColors.surface
        : color.withValues(alpha: 0.06);
    final inactiveFg = isDark ? DarkColors.textSecondary : color;
    final inactiveBorder = isDark
        ? DarkColors.borderActive
        : color.withValues(alpha: 0.35);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeBorder : inactiveBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: isActive ? activeFg : inactiveFg,
                size: 14,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? activeFg : inactiveFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPatientIconButton extends StatelessWidget {
  const _AddPatientIconButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tambah Pasien',
      child: Material(
        color: cteal(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 50,
            height: 50,
            child: Center(
              child: HugeIcon(
                icon: AppIcons.tambah,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasienCard extends StatelessWidget {
  const _PasienCard({
    required this.item,
    required this.onTap,
    required this.onAction,
  });

  final PasienModel item;
  final VoidCallback onTap;
  final ValueChanged<_PasienListAction> onAction;

  @override
  Widget build(BuildContext context) {
    final tanggalJanjian = item.tanggalJanjian == null
        ? 'Belum dijadwalkan'
        : asMediumDate(item.tanggalJanjian!);
    final alamat = item.alamat?.trim();

    return Container(
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cdivider(context)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cteal(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: AppIcons.person,
                          color: cteal(context),
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaPasien,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ctextPrimary(context),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'No. ${item.nomorPasien}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cteal(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<_PasienListAction>(
                      tooltip: 'Aksi',
                      icon: HugeIcon(
                        icon: AppIcons.more,
                        color: ctextSecondary(context),
                      ),
                      onSelected: onAction,
                      itemBuilder: (ctx) => const [
                        PopupMenuItem<_PasienListAction>(
                          value: _PasienListAction.detail,
                          child: Text('Detail'),
                        ),
                        PopupMenuItem<_PasienListAction>(
                          value: _PasienListAction.edit,
                          child: Text('Edit'),
                        ),
                        PopupMenuItem<_PasienListAction>(
                          value: _PasienListAction.jadwalkanHadir,
                          child: Text('Jadwalkan Hadir'),
                        ),
                        PopupMenuItem<_PasienListAction>(
                          value: _PasienListAction.delete,
                          child: Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: AppIcons.person,
                      label: '${item.usia} tahun',
                    ),
                    _InfoChip(
                      icon: AppIcons.peopleGroup,
                      label: item.jenisKelaminLabel,
                    ),
                    _InfoChip(icon: AppIcons.kalender, label: tanggalJanjian),
                  ],
                ),
                if (alamat != null && alamat.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _AddressLine(text: alamat),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: csurface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cdivider(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 14, color: ctextMuted(context)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ctextSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: HugeIcon(
            icon: AppIcons.description,
            size: 15,
            color: ctextMuted(context),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: ctextSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}
