import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/error/app_error_mapper.dart';
import '../core/services/receipt_printer_service_bw.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../features/stok/stok_alert_logic.dart';
import '../data/repositories/obat_repository.dart';
import 'dashboard_page.dart';

/// Halaman Stok Alert — owner only.
/// Route: /stok-alert
///
/// Menampilkan:
/// - Summary card 3 kolom: [Habis: X] [Menipis: X] [Aman: X]
/// - Section "Obat Habis" (jika ada)
/// - Section "Obat Menipis" (jika ada)
/// - Tombol "Cetak Laporan" (owner only)
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

  // Clock state
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
    _checkOwnerAndLoad();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textOnPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stok Alert',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textOnPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SinShe Jaya Abadi',
                              style: TextStyle(
                                fontSize: 13,
                                color: textOnPrimary.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildClock(isDark, textOnPrimary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ringkasan status stok obat',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textOnPrimary.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── CONTENT ─────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildError()
                      : _summary == null
                          ? _buildEmpty()
                          : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClock(bool isDark, Color textOnPrimary) {
    final clockColor = isDark ? DarkColors.textPrimary : Colors.white;
    final dateColor =
        isDark ? DarkColors.textSecondary : Colors.white.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatClock(_now),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: clockColor,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatDashboardDate(_now),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: dateColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: TextStyle(
                fontSize: 14,
                color: ctextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text(
            'Tidak ada alert stok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua obat dalam kondisi aman',
            style: TextStyle(
              fontSize: 14,
              color: ctextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StokAlertSummaryCard(summary: summary),
          const SizedBox(height: 20),

          if (summary.hasHabis) ...[
            _buildSectionHeader('Obat Habis', summary.totalHabis, cdanger(context)),
            const SizedBox(height: 12),
            ...summary.habis.map((item) => _ObatAlertCard(
                  item: item,
                  color: cdanger(context),
                )),
            const SizedBox(height: 20),
          ],

          if (summary.hasMenipis) ...[
            _buildSectionHeader('Obat Menipis', summary.totalMenipis, cwarning(context)),
            const SizedBox(height: 12),
            ...summary.menipis.map((item) => _ObatAlertCard(
                  item: item,
                  color: cwarning(context),
                )),
            const SizedBox(height: 20),
          ],

          ElevatedButton.icon(
            onPressed: _cetakLaporan,
            icon: const Icon(AppSymbols.computer),
            label: const Text('Cetak Laporan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(AppSymbols.warning, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ctextPrimary(context),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

class _StokAlertSummaryCard extends StatelessWidget {
  const _StokAlertSummaryCard({required this.summary});

  final StokAlertSummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _SummaryColumn(
              label: 'Habis',
              count: summary.totalHabis,
              color: cdanger(context),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: borderColor.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _SummaryColumn(
              label: 'Menipis',
              count: summary.totalMenipis,
              color: cwarning(context),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: borderColor.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _SummaryColumn(
              label: 'Aman',
              count: summary.aman.length,
              color: csuccess(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ctextSecondary(context),
          ),
        ),
      ],
    );
  }
}

class _ObatAlertCard extends StatelessWidget {
  const _ObatAlertCard({
    required this.item,
    required this.color,
  });

  final ObatAlertItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;

    final stokLabel = item.stokSaatIni == 0
        ? 'Stok: Habis'
        : 'Stok: ${item.stokSaatIni}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              item.stokSaatIni == 0 ? AppSymbols.error : AppSymbols.warning,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaObat,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ctextPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.etalaseLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$stokLabel | Min: ${item.stokMinimum}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ctextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}