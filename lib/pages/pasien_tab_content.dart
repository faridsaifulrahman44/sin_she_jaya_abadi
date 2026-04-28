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

enum _PasienListAction {
  detail,
  edit,
  delete,
  jadwalkanHadir,
}

/// Body-widget (embeddable) untuk tab "Data Pasien".
///
/// Tidak memiliki Scaffold/AppBar sendiri — dirancang untuk di-embed
/// di dalam TabBarView milik [PasienHubPage].
class PasienTabContent extends StatefulWidget {
  const PasienTabContent({
    super.key,
    this.onRefresh,
    this.domainSummary,
  });

  /// Callback opsional untuk refresh domain summary saat data berubah.
  final VoidCallback? onRefresh;

  /// Summary data dari parent (PasienHubPage).
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

  @override
  Widget build(BuildContext context) {
    final s = widget.domainSummary;
    final isLoading = s == null;

    return Column(
      children: [
        // ── Search bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ModernSearchBar(
            controller: _searchController,
            hintText: 'Cari nama pasien...',
            onChanged: (_) => _reload(),
            onClear: _reload,
          ),
        ),

        // ── Aksi Cepat ───────────────────────────────────────────────────────
        Padding(
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
              Row(
                children: [
                  _StatCard(
                    label: 'Total Pasien',
                    value: isLoading ? '-' : '${s.totalPasien}',
                    icon: AppIcons.person,
                    accentColor: cteal(context),
                    onTap: () => widget.domainSummary?.navigateToTab(0),
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: 'Jadwal Hari Ini',
                    value: isLoading ? '-' : '${s.jadwalHariIni}',
                    icon: AppIcons.kalender,
                    accentColor: const Color(0xFF6366F1),
                    onTap: () => widget.domainSummary?.navigateToTab(1),
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: 'Hadir Hari Ini',
                    value: isLoading ? '-' : '${s.hadirHariIni}',
                    icon: AppIcons.pasienHadir,
                    accentColor: const Color(0xFF10B981),
                    onTap: () => widget.domainSummary?.navigateToTab(1),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Patient list ────────────────────────────────────────────────────
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
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final tanggal = item.tanggalJanjian == null
                        ? '-'
                        : asDate(item.tanggalJanjian!);
                    return ModernListCard(
                      title: item.namaPasien,
                      subtitle:
                          '${item.usia} Tahun  •  ${item.jenisKelaminLabel}\nJanjian: $tanggal',
                      icon: AppIcons.person,
                      accentColor: cteal(context),
                      onTap: () => _openDetail(item),
                      trailingPopup: PopupMenuButton<_PasienListAction>(
                        tooltip: 'Aksi',
                        icon: HugeIcon(
                          icon: AppIcons.more,
                          color: ctextSecondary(context),
                        ),
                        onSelected: (action) async {
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
                        },
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
                    );
                  },
                ),
              );
            },
          ),
        ),

        // ── FAB ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: GradientFAB(
              icon: AppIcons.tambah,
              label: 'Tambah Pasien',
              onPressed: () => _openForm(),
            ),
          ),
        ),
      ],
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

// ── Stat card widget ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Soft tint color — derived from accent for background
    final softBg = isDark
        ? accentColor.withValues(alpha: 0.15)
        : accentColor.withValues(alpha: 0.10);
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final shadowColor = isDark
        ? DarkColors.shadowLight.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.05);
    final dividerColor = isDark ? DarkColors.divider : LightColors.divider;

    return Expanded(
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: HugeIcon(icon: icon, color: accentColor, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                // Value
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? DarkColors.textPrimary
                        : LightColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                // Accent dot indicator
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
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
