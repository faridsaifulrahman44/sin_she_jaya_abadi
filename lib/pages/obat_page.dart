import 'package:flutter/material.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/obat_etalase.dart';
import '../data/models/obat_model.dart';
import '../data/repositories/obat_repository.dart';
import 'obat_detail_page.dart';
import 'obat_form_page.dart';

class ObatPage extends StatelessWidget {
  const ObatPage({super.key});

  static const routeName = '/obat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Data Obat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: cobatBlue(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: const ObatTabContent(),
    );
  }
}

/// Body-widget (embeddable) untuk master data obat.
///
/// Tidak memiliki Scaffold/AppBar sendiri sehingga bisa dipakai ulang
/// di dalam [ObatHubPage] sebagai tab "Master Obat".
class ObatTabContent extends StatefulWidget {
  const ObatTabContent({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  @override
  State<ObatTabContent> createState() => _ObatTabContentState();
}

// ─── Sort order ────────────────────────────────────────────────────────────────

enum _ObatSortOrder {
  operasional('Prioritas Operasional'),
  namaAZ('Nama A–Z'),
  stokTerbanyak('Stok Terbanyak'),
  stokTersedikit('Stok Tersedikit');

  const _ObatSortOrder(this.label);
  final String label;
}

// ─── State ────────────────────────────────────────────────────────────────────

class _ObatTabContentState extends State<ObatTabContent> {
  final ObatRepository _repo = ObatRepository();
  final TextEditingController _searchController = TextEditingController();

  StokStatus? _filterStatus;
  Etalase? _filterEtalase;
  _ObatSortOrder _sortOrder = _ObatSortOrder.operasional;

  // Snapshot of menipis item IDs last time the "Menipis" tab was opened.
  // Dot on "Menipis" shows only when current menipis items have new IDs not in this set.
  Set<int> _menipisAckSnapshot = {};

  // Dot indicators for status chips — updated when data loads.
  bool _hasMenipis = false;
  bool _hasHabis = false;
  bool _hasNewMenipis = false;

  late Future<List<ObatModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getObat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────

  Future<void> _reload() async {
    final future = _repo.getObat(keyword: _searchController.text);
    setState(() => _future = future);
    try {
      final items = await future;
      _cachedItems = items;
      final menipisItems =
          items.where((o) => o.statusStok == StokStatus.menipis).toList();
      final habisItems =
          items.where((o) => o.statusStok == StokStatus.habis).toList();
      _hasMenipis = menipisItems.isNotEmpty;
      _hasHabis = habisItems.isNotEmpty;
      _hasNewMenipis = _hasMenipis &&
          menipisItems.any((o) => !_menipisAckSnapshot.contains(o.idObat));
    } catch (_) {}

    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  List<ObatModel> _cachedItems = [];

  void _setStatusFilter(StokStatus? status) {
    if (status == StokStatus.menipis) {
      _menipisAckSnapshot = _cachedItems
          .where((o) => o.statusStok == StokStatus.menipis)
          .map((o) => o.idObat)
          .toSet();
    }
    setState(() => _filterStatus = status);
  }

  void _setEtalaseFilter(Etalase? etalase) {
    setState(() => _filterEtalase = etalase);
  }

  void _setSortOrder(_ObatSortOrder order) {
    setState(() => _sortOrder = order);
  }

  List<ObatModel> _filterItems(List<ObatModel> items) {
    var result = items.toList();
    if (_filterStatus != null) {
      result = result.where((o) => o.statusStok == _filterStatus).toList();
    }
    if (_filterEtalase != null) {
      result = result.where((o) => o.etalase == _filterEtalase).toList();
    }
    return result;
  }

  List<ObatModel> _sortItems(List<ObatModel> items) {
    final sorted = items.toList();
    sorted.sort((a, b) {
      switch (_sortOrder) {
        case _ObatSortOrder.operasional:
          return a.namaObat.toLowerCase().compareTo(b.namaObat.toLowerCase());

        case _ObatSortOrder.namaAZ:
          return a.namaObat.toLowerCase().compareTo(b.namaObat.toLowerCase());

        case _ObatSortOrder.stokTerbanyak:
          return b.stokSaatIni.compareTo(a.stokSaatIni);

        case _ObatSortOrder.stokTersedikit:
          return a.stokSaatIni.compareTo(b.stokSaatIni);
      }
    });
    return sorted;
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _openDetail(ObatModel item) async {
    await Navigator.pushNamed(context, ObatDetailPage.routeName,
        arguments: item);
    await _reload();
  }

  Future<void> _openForm([ObatModel? item]) async {
    final result = await Navigator.pushNamed(context, ObatFormPage.routeName,
        arguments: item);
    await _reload();

    if (!mounted) return;
    if (result is Map<String, dynamic>) {
      final warning = result['warning']?.toString();
      if (warning != null && warning.trim().isNotEmpty) {
        showModernSnackBar(context, warning, isError: true);
      }
    }
  }

  Future<void> _delete(ObatModel item) async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Hapus Obat',
      message:
          'Yakin ingin menghapus "${item.namaObat}"? Tindakan ini tidak dapat dibatalkan.',
    );
    if (!confirm) return;

    try {
      final usage = await _repo.checkObatUsage(item.idObat);
      if (usage.isUsed) {
        if (!mounted) return;
        showModernSnackBar(
            context, usage.toDeleteBlockedMessage(namaObat: item.namaObat),
            isError: true);
        return;
      }

      await _repo.deleteObat(item.idObat);
      if (!mounted) return;
      showModernSnackBar(context, 'Obat berhasil dihapus');
      await _reload();
    } catch (error, stackTrace) {
      if (!mounted) return;
      showModernSnackBar(context, AppErrorMapper.toMessage(error, stackTrace),
          isError: true);
    }
  }

  // ─── Build: filter chips (etalase) ────────────────────────────────────────

  Color _etalaseChipColor(Etalase? etalase) {
    if (etalase == null) return cprimary(context);
    switch (etalase) {
      case Etalase.etalase1:
        return cobatBlue(context);
      case Etalase.etalase2:
        return cobatGreen(context);
      case Etalase.etalase3:
        return cobatAmber(context);
    }
  }

  String _etalaseFilterChipLabel(Etalase etalase) {
    switch (etalase) {
      case Etalase.etalase1:
        return 'E1';
      case Etalase.etalase2:
        return 'E2';
      case Etalase.etalase3:
        return 'E3';
    }
  }

  Widget _buildEtalaseChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _EtalaseChip(
            label: 'Semua',
            isActive: _filterEtalase == null,
            color: cprimary(context),
            onTap: () => _setEtalaseFilter(null),
          ),
          const SizedBox(width: 6),
          ...Etalase.values.map((e) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _EtalaseChip(
                  label: _etalaseFilterChipLabel(e),
                  isActive: _filterEtalase == e,
                  color: _etalaseChipColor(e),
                  onTap: () => _setEtalaseFilter(e),
                ),
              )),
        ],
      ),
    );
  }

  // ─── Build: sort selector ──────────────────────────────────────────────────

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: cdivider(ctx), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Urutkan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ctextPrimary(ctx))),
            const SizedBox(height: 8),
            ..._ObatSortOrder.values.map((s) => ListTile(
                  leading: Icon(
                    _sortOrder == s
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _sortOrder == s
                        ? cobatBlue(context)
                        : ctextSecondary(context),
                  ),
                  title: Text(s.label,
                      style: TextStyle(
                          fontWeight: _sortOrder == s
                              ? FontWeight.w700
                              : FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setSortOrder(s);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    final isOperational = _sortOrder == _ObatSortOrder.operasional;
    final accent = cobatBlue(context);

    return Tooltip(
      message: 'Ubah urutan data obat',
      child: OutlinedButton.icon(
        onPressed: _showSortSheet,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          side: BorderSide(
            color: isOperational ? accent : cdivider(context),
          ),
          backgroundColor:
              isOperational ? accent.withValues(alpha: 0.10) : ccardBg(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          AppSymbols.sort,
          color: isOperational ? accent : ctextSecondary(context),
          size: 14,
        ),
        label: Text(
          _sortOrder.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isOperational ? accent : ctextSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSectionLabel(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ctextSecondary(context),
        letterSpacing: 0.2,
      ),
    );
  }

  // ─── Build: stok badge ─────────────────────────────────────────────────────

  Widget _buildStokBadge(StokStatus status, BuildContext context) {
    switch (status) {
      case StokStatus.habis:
        return _Badge('Habis', cdanger(context));
      case StokStatus.menipis:
        return _Badge('Menipis', cwarning(context));
      case StokStatus.aman:
        return _Badge('Aman', csuccess(context));
    }
  }

  // ─── Build: obat card ─────────────────────────────────────────────────────

  Widget _buildObatCard(ObatModel item) {
    return Container(
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cdivider(context)),
        boxShadow: [
          BoxShadow(
              color: ctextPrimary(context).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail / placeholder
                _ObatThumbnail(
                  namaObat: item.namaObat,
                  fotoKey: item.fotoKey,
                  fotoUpdatedAt: item.fotoUpdatedAt,
                  fotoUrl: item.fotoUrl,
                  size: 56,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.namaObat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: item.isStokHabis
                                    ? ctextMuted(context)
                                    : ctextPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStokBadge(item.statusStok, context),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _EtalaseLabel(etalase: item.etalase),
                          const SizedBox(width: 8),
                          Text(
                            'Stok: ${item.stokSaatIni}${item.satuan == null ? '' : ' ${item.satuan}'}  ·  Min: ${item.stokMinimum}',
                            style: TextStyle(
                                fontSize: 12,
                                color: ctextSecondary(context),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      // ── Harga (FASE 1, 2026-04-27) ──────────────────────────
                      if (item.hasHargaJual) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              rupiah(item.hargaJual!),
                              style: TextStyle(
                                fontSize: 12,
                                color: cprimary(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.satuanJual != null &&
                                item.satuanJual!.trim().isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '/ ${item.satuanJual}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ctextSecondary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (item.hasEceran) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      csuccess(context).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ecer: ${rupiah(item.hargaEcer!)} / ${item.satuanEcer ?? ''}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: csuccess(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      // ── Deskripsi Preview (dengan emoji support) ──────────────
                      if (item.deskripsi != null && item.deskripsi!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.deskripsi!,
                          style: TextStyle(
                            fontSize: 11,
                            color: ctextSecondary(context),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit obat',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _openForm(item),
                      icon: Icon(
                          AppSymbols.edit,
                          color: cprimary(context),
                          size: 18),
                    ),
                    IconButton(
                      tooltip: 'Hapus obat',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _delete(item),
                      icon: Icon(
                          AppSymbols.hapus,
                          color: cdanger(context),
                          size: 18),
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

  // ─── Build: status filter ─────────────────────────────────────────────────

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusChip(
              label: 'Habis',
              isActive: _filterStatus == StokStatus.habis,
              color: cdanger(context),
              showDot: _hasHabis,
              onTap: () => _setStatusFilter(StokStatus.habis)),
          const SizedBox(width: 6),
          _StatusChip(
              label: 'Menipis',
              isActive: _filterStatus == StokStatus.menipis,
              color: cwarning(context),
              showDot: _hasNewMenipis,
              onTap: () => _setStatusFilter(StokStatus.menipis)),
          const SizedBox(width: 6),
          _StatusChip(
              label: 'Aman',
              isActive: _filterStatus == StokStatus.aman,
              color: csuccess(context),
              onTap: () => _setStatusFilter(StokStatus.aman)),
          const SizedBox(width: 6),
          _StatusChip(
              label: 'Semua',
              isActive: _filterStatus == null,
              onTap: () => _setStatusFilter(null)),
        ],
      ),
    );
  }

  // ─── Build: empty / error / loading ───────────────────────────────────────

  Widget _buildEmpty(List<ObatModel> allItems) {
    if (allItems.isEmpty) {
      return AppEmptyView(
        icon: AppSymbols.pills,
        title: 'Belum ada data obat',
        message: 'Tambah obat pertama Anda.',
        color: cobatBlue(context),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                AppSymbols.filter, color: ctextMuted(context), size: 40),
            const SizedBox(height: 12),
            Text('Tidak ada obat sesuai filter',
                style: TextStyle(
                    color: ctextSecondary(context),
                    fontWeight: FontWeight.w600)),
          ],
        ),
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header panel
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          decoration: BoxDecoration(
            color: cobatBlueSoft(context),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master Data Obat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                ModernSearchBar(
                  controller: _searchController,
                  hintText: 'Cari nama obat...',
                  onChanged: (_) => _reload(),
                  onClear: _reload,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFilterSectionLabel('Etalase')),
                    _buildSortButton(),
                  ],
                ),
                const SizedBox(height: 4),
                _buildEtalaseChips(),
                const SizedBox(height: 6),
                _buildFilterSectionLabel('Status'),
                const SizedBox(height: 4),
                _buildStatusFilterChips(),
              ],
            ),
          ),
        ),
        // List
        Expanded(
          child: FutureBuilder<List<ObatModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppLoadingView(child: _buildLoading());
              }
              if (snapshot.hasError) {
                return AppErrorView(
                  message: AppErrorMapper.toMessage(
                      snapshot.error!, snapshot.stackTrace),
                  onRetry: _reload,
                );
              }

              final allItems = snapshot.data ?? const [];
              // Keep cache in sync even if _reload() hasn't run yet.
              _cachedItems = allItems;
              final filtered = _filterItems(allItems);
              final sorted = _sortItems(filtered);

              if (sorted.isEmpty) {
                return _buildEmpty(allItems);
              }

              return RefreshIndicator(
                onRefresh: _reload,
                color: cobatBlue(context),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildObatCard(sorted[index]),
                ),
              );
            },
          ),
        ),
        // Soft CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: _PrimaryTambahObatButton(
              onPressed: () => _openForm(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _PrimaryTambahObatButton extends StatelessWidget {
  const _PrimaryTambahObatButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accentColor = cobatBlue(context);

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppSymbols.tambah, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tambah Obat Baru',
                  style: TextStyle(
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

class _EtalaseChip extends StatelessWidget {
  const _EtalaseChip(
      {required this.label,
      required this.isActive,
      required this.color,
      required this.onTap});
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : ccardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: isActive ? null : Border.all(color: cdivider(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : ctextSecondary(context),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isActive,
    this.color,
    this.showDot = false,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final Color? color;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? cprimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : ccardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: isActive ? null : Border.all(color: cdivider(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : ctextSecondary(context),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 5),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: cdanger(context),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EtalaseLabel extends StatelessWidget {
  const _EtalaseLabel({required this.etalase});
  final Etalase etalase;

  Color get _color {
    switch (etalase) {
      case Etalase.etalase1:
        return const Color(0xFF2563EB);
      case Etalase.etalase2:
        return const Color(0xFF10B981);
      case Etalase.etalase3:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5)),
      child: Text(etalase.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: _color)),
    );
  }
}

class _ObatThumbnail extends StatelessWidget {
  const _ObatThumbnail({
    required this.namaObat,
    required this.fotoKey,
    required this.fotoUpdatedAt,
    this.fotoUrl,
    required this.size,
  });
  final String namaObat;
  final String? fotoKey;
  final DateTime? fotoUpdatedAt;
  final String? fotoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ObatImage(
      namaObat: namaObat,
      fotoKey: fotoKey,
      fotoUpdatedAt: fotoUpdatedAt,
      fotoUrl: fotoUrl,
      width: size,
      height: size,
      borderRadius: 12,
    );
  }
}
