import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/pasien_model.dart';
import '../data/repositories/pasien_repository.dart';
import 'kehadiran_form_page.dart';
import 'pasien_detail_page.dart';
import 'pasien_form_page.dart';
import 'pasien_hub_page.dart';

enum _PasienListAction { detail, edit, delete, jadwalkanHadir }

/// Body widget untuk tab "Data Pasien".
class PasienTabContent extends StatefulWidget {
  const PasienTabContent({super.key, this.onRefresh, this.domainSummary});

  final VoidCallback? onRefresh;
  final DomainSummaryPasien? domainSummary;

  @override
  State<PasienTabContent> createState() => _PasienTabContentState();
}

class _PasienTabContentState extends State<PasienTabContent> {
  final PasienRepository _repo = PasienRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<PasienModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getPasien();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = _repo.getPasien(keyword: _searchController.text);
    setState(() {
      _future = future;
    });
    try {
      await future;
      widget.onRefresh?.call();
    } catch (_) {}
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
        _buildSummary(widget.domainSummary),
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
                  title: 'Belum ada data pasien',
                  message: 'Tambah pasien pertama Anda.',
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

  Widget _buildSummary(DomainSummaryPasien? summary) {
    final cards = [
      _StatCardData(
        label: 'Total Pasien',
        value: summary?.totalPasien.toString() ?? '-',
        icon: AppIcons.person,
        accentColor: cteal(context),
        onTap: () => widget.domainSummary?.navigateToTab(0),
      ),
      _StatCardData(
        label: 'Jadwal Hari Ini',
        value: summary?.jadwalHariIni.toString() ?? '-',
        icon: AppIcons.kalender,
        accentColor: const Color(0xFF6366F1),
        onTap: () => widget.domainSummary?.navigateToTab(1),
      ),
      _StatCardData(
        label: 'Hadir Hari Ini',
        value: summary?.hadirHariIni.toString() ?? '-',
        icon: AppIcons.pasienHadir,
        accentColor: const Color(0xFF10B981),
        onTap: () => widget.domainSummary?.navigateToTab(1),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ctextSecondary(context),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        SizedBox(width: 132, child: _StatCard(data: cards[i])),
                        if (i != cards.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: _StatCard(data: cards[i])),
                    if (i != cards.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
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

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final Color accentColor;
  final VoidCallback onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final softBg = isDark
        ? data.accentColor.withValues(alpha: 0.15)
        : data.accentColor.withValues(alpha: 0.10);
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final shadowColor = isDark
        ? DarkColors.shadowLight.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.05);
    final dividerColor = isDark ? DarkColors.divider : LightColors.divider;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dividerColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: data.icon,
                        color: data.accentColor,
                        size: 17,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ctextPrimary(context),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: ctextSecondary(context),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: data.accentColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
