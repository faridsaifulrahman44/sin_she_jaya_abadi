import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/error/app_error_mapper.dart';
import '../core/services/receipt_printer_service_bw.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../data/repositories/obat_repository.dart';
import '../features/stok/stok_alert_logic.dart';
import '../widgets/app_bottom_nav_stock.dart';
import 'dashboard_page.dart';

/// Halaman Stok Alert — owner only (KEEP #6 Stitch).
/// Route: /stok-alert
///
/// F0.5 redesign: white surface header, avatar+title+bell, 3 separate
/// summary cards with icons, "Aman" section with shield icon, per-item
/// "Restock" CTA, "Batas min" line, and 5-tab bottom navigation.
class StokAlertPage extends StatefulWidget {
  const StokAlertPage({super.key});

  static const routeName = '/stok-alert';

  @override
  State<StokAlertPage> createState() => _StokAlertPageState();
}

class _StokAlertPageState extends State<StokAlertPage> {
  bool _loading = true;
  StokAlertSummary? _summary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkOwnerAndLoad();
  }

  Future<void> _checkOwnerAndLoad() async {
    try {
      final isOwner = await AdminSession.isOwner();
      if (!isOwner) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, DashboardPage.routeName);
        return;
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, DashboardPage.routeName);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final repo = ObatRepository();
      final obatList = await repo.getObat();
      final summary = buildStokAlertSummary(obatList);

      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _errorMessage = AppErrorMapper.toMessage(error, stackTrace);
          _loading = false;
        });
      }
    }
  }

  Future<void> _cetakLaporan() async {
    if (_summary == null) return;

    try {
      final receiptText =
          await ReceiptPrinterServiceBW().buildStokAlertReceiptBW(_summary!);
      if (!mounted) return;
      showModernSnackBar(
        context,
        'Laporan stok alert siap dicetak (${receiptText.split('\n').length} baris)',
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        AppErrorMapper.toMessage(error, stackTrace),
        isError: true,
      );
    }
  }

  void _onHeaderNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/pasien');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transaksi-hub');
        break;
      case 3:
        // Already on Stock
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/akun');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildError()
                      : _summary == null
                          ? _buildEmpty()
                          : _buildContent(),
            ),
            const AppBottomNavStock(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  // ── HEADER (F0.5 redesign: white surface) ─────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ccardBg(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: AppSpacing.sm5,
                height: AppSpacing.sm5,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  AppSymbols.klinik,
                  size: AppIconSize.size28,
                  color: cteal(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Stok Alert',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: ctextPrimary(context),
                  ),
                ),
              ),
              _NotificationBell(
                onTap: () {
                  // Notifications route not yet defined — show snackbar.
                  showModernSnackBar(
                    context,
                    'Notifikasi belum tersedia',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Horizontal 5-tab nav (Stock active)
          AppHeaderNavStock(
            currentIndex: 3,
            onTap: _onHeaderNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppSymbols.error, size: 64, color: cdanger(context)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: AppTextStyles.body.copyWith(color: ctextSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(AppSymbols.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppSymbols.checkCircle, size: 64, color: csuccess(context)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tidak ada alert stok',
            style: AppTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w700,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Semua obat dalam kondisi aman',
            style: AppTextStyles.body.copyWith(color: ctextSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final totalRisk = summary.totalHabis + summary.totalMenipis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page title row (Stitch KEEP #6): title + subtitle + Export action
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keterangan Stok',
                      style: AppTextStyles.headlineLg.copyWith(
                        color: ctextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Ringkasan inventaris klinik dan peringatan restock.',
                      style: AppTextStyles.body.copyWith(
                        color: ctextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Export Laporan — title row right (Stitch: text button with download icon, teal tint)
              InkWell(
                onTap: _cetakLaporan,
                borderRadius: BorderRadius.circular(AppRadius.sm10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: cteal(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.download_rounded,
                        size: AppIconSize.size16,
                        color: cteal(context),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Export Laporan',
                        style: AppTextStyles.menuTitle.copyWith(
                          color: cteal(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3 summary cards (Stitch KEEP #6): Total Risk Items / Stok Habis / Stok Menipis
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total Risk Items',
                  count: totalRisk,
                  color: cwarning(context),
                  icon: AppSymbols.warning,
                  sublabel: 'butuh perhatian',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryCard(
                  label: 'Stok Habis',
                  count: summary.totalHabis,
                  color: cdanger(context),
                  icon: AppSymbols.error,
                  sublabel: 'items',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryCard(
                  label: 'Stok Menipis',
                  count: summary.totalMenipis,
                  color: cwarning(context),
                  icon: AppSymbols.warning,
                  sublabel: 'items',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (summary.hasHabis) ...[
            _buildSectionHeader(
              'Obat Habis',
              summary.totalHabis,
              cdanger(context),
              pillLabel: 'Kritis',
              pillBg: AppColors.errorContainer,
              pillFg: AppColors.onErrorContainer,
            ),
            const SizedBox(height: AppSpacing.md),
            ...summary.habis.map((item) => _ObatAlertCard(
                  item: item,
                  color: cdanger(context),
                  showRestock: true,
                )),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (summary.hasMenipis) ...[
            _buildSectionHeader(
              'Obat Menipis',
              summary.totalMenipis,
              cwarning(context),
              pillLabel: 'Segera',
              pillBg: AppColors.warning.withValues(alpha: 0.14),
              pillFg: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            ...summary.menipis.map((item) => _ObatAlertCard(
                  item: item,
                  color: cwarning(context),
                  showRestock: true,
                )),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Aman section (Stitch KEEP #6 requires this)
          _buildSectionHeader(
            'Obat Aman',
            summary.aman.length,
            csuccess(context),
            pillLabel: 'Terpantau',
            pillBg: csuccess(context).withValues(alpha: 0.14),
            pillFg: csuccess(context),
            iconOverride: Symbols.shield_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          if (summary.aman.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: ccardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: csuccess(context).withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Text(
                'Belum ada data obat yang tercatat aman.',
                style: AppTextStyles.body.copyWith(color: ctextMuted(context)),
              ),
            )
          else
            ...summary.aman.take(10).map((item) => _ObatAlertCard(
                  item: item,
                  color: csuccess(context),
                  showRestock: false,
                )),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    Color color, {
    required String pillLabel,
    required Color pillBg,
    required Color pillFg,
    IconData? iconOverride,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm10),
          ),
          child: Icon(
            iconOverride ?? AppSymbols.warning,
            color: color,
            size: AppIconSize.size20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.menuTitle.copyWith(color: ctextPrimary(context)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            pillLabel,
            style: AppTextStyles.label.copyWith(color: pillFg),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.label.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: AppSpacing.sm5,
        height: AppSpacing.sm5,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cscaffoldBg(context),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Symbols.notifications_rounded,
          size: AppIconSize.size20,
          color: ctextSecondary(context),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.sublabel,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm10),
            ),
            child: Icon(icon, color: color, size: AppIconSize.size20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$count',
            style: AppTextStyles.heroJumbo.copyWith(color: color, height: 1),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: ctextSecondary(context)),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              sublabel!,
              style: AppTextStyles.caption.copyWith(color: ctextMuted(context)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ObatAlertCard extends StatelessWidget {
  const _ObatAlertCard({
    required this.item,
    required this.color,
    required this.showRestock,
  });

  final ObatAlertItem item;
  final Color color;
  final bool showRestock;

  @override
  Widget build(BuildContext context) {
    final stokLabel = item.stokSaatIni == 0
        ? 'Stok: Habis'
        : 'Stok: ${item.stokSaatIni} box';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.size14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  item.stokSaatIni == 0 ? AppSymbols.error : AppSymbols.warning,
                  color: color,
                  size: AppIconSize.size28,
                ),
              ),
              const SizedBox(width: AppSpacing.md14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaObat,
                      style: AppTextStyles.title.copyWith(
                        color: ctextPrimary(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            item.etalaseLabel,
                            style: AppTextStyles.caption.copyWith(color: color),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '$stokLabel | Min: ${item.stokMinimum}',
                            style: AppTextStyles.caption.copyWith(
                              color: ctextSecondary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.stokSaatIni > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Batas min: ${item.stokMinimum} box',
              style: AppTextStyles.caption.copyWith(
                color: ctextMuted(context),
              ),
            ),
          ],
          if (showRestock) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.sm5, // 48px touch target
              child: OutlinedButton.icon(
                onPressed: () {
                  showModernSnackBar(
                    context,
                    'Restock untuk ${item.namaObat} — fitur menyusul.',
                  );
                },
                icon: Icon(
                  item.stokSaatIni == 0
                      ? Symbols.shopping_cart_rounded
                      : Symbols.add_shopping_cart_rounded,
                  size: AppIconSize.size20,
                  color: cteal(context),
                ),
                label: Text(
                  'Restock',
                  style: AppTextStyles.menuTitle.copyWith(color: cteal(context)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cteal(context),
                  side: BorderSide(color: cteal(context), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
