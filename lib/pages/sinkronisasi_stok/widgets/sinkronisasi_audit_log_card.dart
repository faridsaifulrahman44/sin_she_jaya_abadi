import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_symbols.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/sinkronisasi_stok_model.dart';
import '../../../../data/repositories/obat_repository.dart';
import '../../../../data/repositories/sinkronisasi_stok_repository.dart';
import '../../../../data/repositories/transaksi_repository.dart';

/// F12.4 — Audit log visual untuk sinkronisasi stok.
///
/// Owner-only (di halaman utama). Menampilkan 5–10 entri opname terakhir
/// dengan: nama obat, stok sistem vs fisik, selisih, dan admin yang mengoreksi.
class SinkronisasiAuditLogCard extends StatefulWidget {
  const SinkronisasiAuditLogCard({
    super.key,
    this.limit = 6,
    this.onViewAll,
  });

  final int limit;
  final VoidCallback? onViewAll;

  @override
  State<SinkronisasiAuditLogCard> createState() =>
      _SinkronisasiAuditLogCardState();
}

class _SinkronisasiAuditLogCardState extends State<SinkronisasiAuditLogCard> {
  final SinkronisasiStokRepository _sinkRepo = SinkronisasiStokRepository();
  final ObatRepository _obatRepo = ObatRepository();
  final TransaksiRepository _adminRepo = TransaksiRepository();

  late Future<_AuditLogData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AuditLogData> _load() async {
    final items =
        await _sinkRepo.getRecentSinkronisasiStok(limit: widget.limit);
    final allObat = await _obatRepo.getObat();
    final obatById = {for (final o in allObat) o.idObat: o.namaObat};

    // Resolve admin names for the visible set only.
    final adminIds = items.map((e) => e.idAdmin).toSet();
    final adminById = <int, String>{};
    for (final id in adminIds) {
      final name = await _adminRepo.getNamaAdminById(id);
      if (name != null && name.isNotEmpty) {
        adminById[id] = name;
      }
    }
    return _AuditLogData(
      items: items,
      obatById: obatById,
      adminById: adminById,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cdivider(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onRefresh: _refresh, onViewAll: widget.onViewAll),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<_AuditLogData>(
              future: _future,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return _EmptyHint(
                    text: 'Gagal memuat audit log.',
                    color: ctextMuted(ctx),
                  );
                }
                final data = snapshot.data!;
                if (data.items.isEmpty) {
                  return _EmptyHint(
                    text: 'Belum ada aktivitas sinkronisasi.',
                    color: ctextMuted(ctx),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < data.items.length; i++) ...[
                      _AuditRow(
                        item: data.items[i],
                        namaObat: data.obatById[data.items[i].idObat],
                        namaAdmin: data.adminById[data.items[i].idAdmin],
                      ),
                      if (i != data.items.length - 1)
                        Divider(
                          height: 1,
                          color: cdivider(ctx).withValues(alpha: 0.6),
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, required this.onViewAll});

  final VoidCallback onRefresh;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: cteal(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(AppSymbols.riwayat, size: 18, color: cteal(context)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Log Koreksi',
                style: AppTextStyles.title.copyWith(color: ctextPrimary(context)),
              ),
              const SizedBox(height: 2),
              Text(
                '6 entri sinkronisasi terakhir',
                style: AppTextStyles.caption.copyWith(
                  color: ctextSecondary(context),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: Icon(AppSymbols.refresh, size: 18, color: ctextMuted(context)),
          tooltip: 'Refresh',
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(foregroundColor: cteal(context)),
            child: const Text('Semua'),
          ),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.item,
    required this.namaObat,
    required this.namaAdmin,
  });

  final SinkronisasiStokModel item;
  final String? namaObat;
  final String? namaAdmin;

  @override
  Widget build(BuildContext context) {
    final accent = _selisihAccent(context, item.selisih);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(_iconFor(item.selisih), size: 18, color: accent.fg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaObat ?? 'Obat #${item.idObat}',
                  style: AppTextStyles.title.copyWith(
                    color: ctextPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${asDate(item.tanggalOpname)} • '
                  '${namaAdmin ?? "Admin #${item.idAdmin}"} • '
                  'Sistem ${item.stokSistem} → Fisik ${item.stokFisik}',
                  style: AppTextStyles.caption.copyWith(
                    color: ctextSecondary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SelisihBadge(selisih: item.selisih, accent: accent),
        ],
      ),
    );
  }
}

class _SelisihBadge extends StatelessWidget {
  const _SelisihBadge({required this.selisih, required this.accent});

  final int selisih;
  final _Accent accent;

  @override
  Widget build(BuildContext context) {
    final label = selisih == 0
        ? 'Sesuai'
        : (selisih > 0 ? '+$selisih' : '$selisih');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: accent.fg),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Diff-accent helpers ─────────────────────────────────────────────────────

class _Accent {
  const _Accent(this.fg, this.bg);
  final Color fg;
  final Color bg;
}

_Accent _selisihAccent(BuildContext context, int selisih) {
  final abs = selisih.abs();
  if (selisih == 0) {
    return _Accent(ctextSecondary(context), cdivider(context));
  }
  if (abs <= 2) {
    return _Accent(AppColors.warning, AppColors.warning.withValues(alpha: 0.12));
  }
  if (selisih > 0) {
    return _Accent(
      AppColors.positive,
      AppColors.positive.withValues(alpha: 0.12),
    );
  }
  return _Accent(cdanger(context), cdanger(context).withValues(alpha: 0.12));
}

IconData _iconFor(int selisih) {
  if (selisih == 0) return AppSymbols.daftarHadir; // checklist
  if (selisih > 0) return AppSymbols.tambah; // up
  return AppSymbols.refresh; // adjust
}

class _AuditLogData {
  const _AuditLogData({
    required this.items,
    required this.obatById,
    required this.adminById,
  });
  final List<SinkronisasiStokModel> items;
  final Map<int, String> obatById;
  final Map<int, String> adminById;
}
