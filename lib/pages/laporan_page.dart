import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/csv_exporter.dart';
import '../core/utils/date_range_validator.dart';
import '../core/utils/formatters.dart';
import '../core/utils/pdf_exporter.dart';
import '../core/widgets/app_error_view.dart';
import '../data/models/obat_etalase.dart';
import '../data/models/obat_model.dart';
import '../data/models/transaksi_model.dart';
import '../data/repositories/laporan_repository.dart';
import '../features/laporan/laporan_aggregator.dart';
import '../features/laporan/laporan_summary.dart';
import 'laporan/widgets/laporan_components.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  static const routeName = '/laporan';

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  final LaporanRepository _repository = LaporanRepository();

  bool _isLoading = true;
  bool _accessDenied = false;
  String? _errorMessage;
  LaporanDataBundle? _bundle;
  LaporanSummary? _summary;

  late TabController _tabController;
  int _activeTab = 0;

  // Date range per tab
  late DateTime _tabStartDate;
  late DateTime _tabEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initDefaultDateRange();
    _checkAccess();
  }

  void _initDefaultDateRange() {
    final now = DateTime.now();
    _tabStartDate = DateTime(now.year, now.month, now.day);
    _tabEndDate = DateTime(now.year, now.month, now.day);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabController.index;
    if (tab == _activeTab) return;
    setState(() => _activeTab = tab);
    _updateDateRangeForTab(tab);
    _loadData();
  }

  void _updateDateRangeForTab(int tab) {
    final now = DateTime.now();
    switch (tab) {
      case 0: // Harian
        _tabStartDate = DateTime(now.year, now.month, now.day);
        _tabEndDate = DateTime(now.year, now.month, now.day);
        break;
      case 1: // Bulanan
        _tabStartDate = DateTime(now.year, now.month, 1);
        _tabEndDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 2: // Tahunan
        _tabStartDate = DateTime(now.year, 1, 1);
        _tabEndDate = DateTime(now.year, 12, 31);
        break;
    }
  }

  Future<void> _checkAccess() async {
    try {
      final canView = await AdminSession.canViewReports();
      if (!canView) {
        if (mounted) {
          setState(() {
            _accessDenied = true;
            _isLoading = false;
          });
        }
        return;
      }
      _loadData();
    } catch (_) {
      if (mounted) {
        setState(() {
          _accessDenied = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    final validation = validateDateRange(
      startDate: _tabStartDate,
      endDate: _tabEndDate,
    );

    if (!validation.isValid) {
      if (mounted) {
        setState(() {
          _errorMessage = validation.message;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bundle = await _repository.getReportData(
        startDate: _tabStartDate,
        endDate: _tabEndDate,
      );

      final summary = buildLaporanSummary(
        startDate: _tabStartDate,
        endDate: _tabEndDate,
        transaksiPeriode: bundle.transaksiPeriode,
        transaksiAllTime: bundle.transaksiAllTime,
        transaksiItemsAllTime: bundle.transaksiItemsAllTime,
        pasienPeriode: bundle.pasienPeriode,
        pasienAllTime: bundle.pasienAllTime,
        kehadiranPeriode: bundle.kehadiranPeriode,
        obatAllTime: bundle.obatAllTime,
      );

      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _summary = summary;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppErrorMapper.toMessage(error, stackTrace);
        _isLoading = false;
      });
    }
  }

  // ─── Export handlers ───────────────────────────────────────────────

  Future<void> _exportCsv() async {
    if (_summary == null) return;
    String csv;
    switch (_activeTab) {
      case 0:
        csv = CsvExporter.exportLaporanHarian(
          _bundle!.transaksiPeriode,
          formatDateRangeLabel(_tabStartDate, _tabEndDate),
        );
        break;
      case 1:
        csv = CsvExporter.exportLaporanBulanan(
          _summary!,
          formatDateRangeLabel(_tabStartDate, _tabEndDate),
        );
        break;
      default:
        csv = CsvExporter.exportLaporanTahunan(
          _summary!,
          _tabStartDate.year.toString(),
        );
    }

    try {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(csv.codeUnits),
        filename: 'laporan_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export CSV: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_summary == null) return;
    try {
      final doc = _activeTab == 2
          ? await PdfExporter.exportLaporanTahunan(
              _summary!,
              _tabStartDate.year.toString(),
            )
          : await PdfExporter.exportLaporanBulanan(
              _summary!,
              formatDateRangeLabel(_tabStartDate, _tabEndDate),
            );
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'laporan_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e')),
        );
      }
    }
  }

  // ─── Date pickers per tab ─────────────────────────────────────────

  Future<void> _pickDateHarian() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tabStartDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: cprimary(ctx)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _tabStartDate = picked;
      _tabEndDate = picked;
    });
    _loadData();
  }

  Future<void> _pickDateBulanan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tabStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: cprimary(ctx)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final start = DateTime(picked.year, picked.month, 1);
    final end = DateTime(picked.year, picked.month + 1, 0);
    setState(() {
      _tabStartDate = start;
      _tabEndDate = end;
    });
    _loadData();
  }

  Future<void> _pickDateTahunan() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _YearPickerDialog(initialYear: _tabStartDate.year),
    );
    if (picked == null) return;
    setState(() {
      _tabStartDate = DateTime(picked, 1, 1);
      _tabEndDate = DateTime(picked, 12, 31);
    });
    _loadData();
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) return _buildAccessDenied(context);

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: cindigo(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.12),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _errorMessage != null
                    ? AppErrorView(
                        message: _errorMessage!,
                        onRetry: _loadData,
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _TabHarian(
                            bundle: _bundle!,
                            summary: _summary!,
                            startDate: _tabStartDate,
                            endDate: _tabEndDate,
                            onPickDate: _pickDateHarian,
                            onExportCsv: _exportCsv,
                            onExportPdf: _exportPdf,
                          ),
                          _TabBulanan(
                            bundle: _bundle!,
                            summary: _summary!,
                            startDate: _tabStartDate,
                            endDate: _tabEndDate,
                            onPickDate: _pickDateBulanan,
                            onExportCsv: _exportCsv,
                            onExportPdf: _exportPdf,
                          ),
                          _TabTahunan(
                            summary: _summary!,
                            startDate: _tabStartDate,
                            endDate: _tabEndDate,
                            onPickYear: _pickDateTahunan,
                            onExportCsv: _exportCsv,
                            onExportPdf: _exportPdf,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: conPrimary(context),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: cindigo(context),
        unselectedLabelColor: ctextSecondary(context),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Harian'),
          Tab(text: 'Bulanan'),
          Tab(text: 'Tahunan'),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        LaporanLoadingBox(height: 100),
        SizedBox(height: 12),
        LaporanLoadingBox(height: 160),
        SizedBox(height: 12),
        LaporanLoadingBox(height: 220),
      ],
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Laporan', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cindigo(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cdanger(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, size: 48, color: cdanger(context)),
              ),
              const SizedBox(height: 24),
              Text(
                'Akses Ditolak',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ctextPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Anda tidak memiliki akses untuk melihat halaman laporan.\nHanya owner yang dapat mengakses fitur ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: ctextSecondary(context)),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cprimary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab: Harian ─────────────────────────────────────────────────────────────

class _TabHarian extends StatelessWidget {
  const _TabHarian({
    required this.bundle,
    required this.summary,
    required this.startDate,
    required this.endDate,
    required this.onPickDate,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  final LaporanDataBundle bundle;
  final LaporanSummary summary;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPickDate;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final transaksi = bundle.transaksiPeriode;
    final totalNominal = transaksi.fold<double>(0, (s, t) => s + t.total);
    final totalObat = transaksi
        .where((t) => t.jenisTransaksi == JenisTransaksi.obatReadyStock)
        .fold<double>(0, (s, t) => s + t.total);
    final totalPraktek = transaksi
        .where((t) => t.jenisTransaksi == JenisTransaksi.praktekCustom)
        .fold<double>(0, (s, t) => s + t.total);
    final totalTunai = transaksi
        .where((t) => t.metodeBayar == MetodeBayarTransaksi.cash)
        .fold<double>(0, (s, t) => s + t.total);
    final totalQris = transaksi
        .where((t) => t.metodeBayar == MetodeBayarTransaksi.qris)
        .fold<double>(0, (s, t) => s + t.total);

    // Best day = today (only one day for harian)
    final bestDay = totalNominal;
    final bestDayLabel = asDate(startDate);

    return RefreshIndicator(
      onRefresh: () async {},
      color: cindigo(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DatePickerRow(
              label: formatDateRangeLabel(startDate, endDate),
              onTap: onPickDate,
            ),
            const SizedBox(height: 12),
            _StatGrid(
              items: [
                _StatItem(label: 'Total Penjualan', value: rupiah(totalNominal)),
                _StatItem(label: 'Jumlah Transaksi', value: '${transaksi.length}'),
              ],
            ),
            const SizedBox(height: 12),
            _StatGrid(
              items: [
                _StatItem(label: 'Obat', value: rupiah(totalObat)),
                _StatItem(label: 'Praktek', value: rupiah(totalPraktek)),
              ],
            ),
            const SizedBox(height: 12),
            _buildHourlyChart(context, transaksi),
            const SizedBox(height: 12),
            _BdRow(label: 'Tunai', value: rupiah(totalTunai)),
            _BdRow(label: 'QRIS', value: rupiah(totalQris)),
            _BdRow(label: 'Best Day', value: '$bestDayLabel — ${rupiah(bestDay)}'),
            const SizedBox(height: 12),
            _ExportRow(onExportCsv: onExportCsv, onExportPdf: onExportPdf),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChart(BuildContext context, List<TransaksiModel> transaksi) {
    // Group by hour
    final hourly = <int, double>{};
    for (final t in transaksi) {
      hourly[t.tanggal.hour] = (hourly[t.tanggal.hour] ?? 0) + t.total;
    }
    if (hourly.isEmpty) {
      return _LapCard(
        title: 'Tren Per Jam',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Tidak ada transaksi', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    // Show max 8 bars (most active hours)
    final sortedHours = hourly.keys.toList()..sort();
    final displayHours = sortedHours.length > 8
        ? (sortedHours..sort((a, b) => hourly[b]!.compareTo(hourly[a]!))).take(8).toList()
        : sortedHours;

    final maxY = hourly.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return _LapCard(
      title: 'Tren Per Jam',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final hour = displayHours[value.toInt()];
                    return Text(
                      hour.toString().padLeft(2, '0'),
                      style: TextStyle(fontSize: 9, color: ctextMuted(context)),
                    );
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: displayHours.toList().asMap().entries.map((e) {
              final idx = e.key;
              final hour = e.value;
              final val = hourly[hour]!;
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: val,
                    color: cteal(context),
                    width: 10,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Tab: Bulanan ─────────────────────────────────────────────────────────────

class _TabBulanan extends StatelessWidget {
  const _TabBulanan({
    required this.bundle,
    required this.summary,
    required this.startDate,
    required this.endDate,
    required this.onPickDate,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  final LaporanDataBundle bundle;
  final LaporanSummary summary;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPickDate;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final transaksi = bundle.transaksiPeriode;
    final totalNominal = transaksi.fold<double>(0, (s, t) => s + t.total);
    final totalObat = transaksi
        .where((t) => t.jenisTransaksi == JenisTransaksi.obatReadyStock)
        .fold<double>(0, (s, t) => s + t.total);
    final totalPraktek = transaksi
        .where((t) => t.jenisTransaksi == JenisTransaksi.praktekCustom)
        .fold<double>(0, (s, t) => s + t.total);
    final totalTunai = transaksi
        .where((t) => t.metodeBayar == MetodeBayarTransaksi.cash)
        .fold<double>(0, (s, t) => s + t.total);
    final totalQris = transaksi
        .where((t) => t.metodeBayar == MetodeBayarTransaksi.qris)
        .fold<double>(0, (s, t) => s + t.total);

    // Best day in the month
    final dailyTotals = <DateTime, double>{};
    for (final t in transaksi) {
      final key = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      dailyTotals[key] = (dailyTotals[key] ?? 0) + t.total;
    }
    DateTime? bestDayKey;
    double bestDayVal = 0;
    dailyTotals.forEach((k, v) {
      if (v > bestDayVal) {
        bestDayVal = v;
        bestDayKey = k;
      }
    });

    // Top 10 obat
    final topObat = _computeTopObat(bundle.transaksiItemsAllTime, bundle.obatAllTime);

    return RefreshIndicator(
      onRefresh: () async {},
      color: cindigo(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DatePickerRow(
              label: formatDateRangeLabel(startDate, endDate),
              onTap: onPickDate,
            ),
            const SizedBox(height: 12),
            _StatGrid(
              items: [
                _StatItem(label: 'Total Penjualan', value: rupiah(totalNominal)),
                _StatItem(label: 'Jumlah Transaksi', value: '${transaksi.length}'),
              ],
            ),
            const SizedBox(height: 12),
            _StatGrid(
              items: [
                _StatItem(label: 'Obat', value: rupiah(totalObat)),
                _StatItem(label: 'Praktek', value: rupiah(totalPraktek)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDailyChart(context, transaksi),
            const SizedBox(height: 12),
            _BdRow(label: 'Tunai', value: rupiah(totalTunai)),
            _BdRow(label: 'QRIS', value: rupiah(totalQris)),
            if (bestDayKey != null)
              _BdRow(
                label: 'Best Day',
                value: '${asDate(bestDayKey!)} — ${rupiah(bestDayVal)}',
              ),
            const SizedBox(height: 12),
            if (topObat.isNotEmpty) ...[
              _LapCard(
                title: 'Top 10 Obat',
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topObat.length,
                  itemBuilder: (ctx, i) => _TopObatRow(item: topObat[i]),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _LapCard(
              title: 'Operasional — ${_monthName(startDate.month)} ${startDate.year}',
              child: Column(
                children: [
                  _OpRow(label: 'Obat Masuk', value: 'N/A', valueColor: ctextSecondary(context)),
                  _OpRow(label: 'Obat Keluar', value: 'N/A', valueColor: ctextSecondary(context)),
                  _OpRow(label: 'Sinkronisasi Stok', value: 'N/A', valueColor: ctextSecondary(context)),
                  _OpRow(
                    label: 'Pasien Baru',
                    value: '${bundle.pasienPeriode.length}',
                    valueColor: csuccess(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ExportRow(onExportCsv: onExportCsv, onExportPdf: onExportPdf),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart(BuildContext context, List<TransaksiModel> transaksi) {
    final dailyMap = <int, double>{};
    for (final t in transaksi) {
      dailyMap[t.tanggal.day] = (dailyMap[t.tanggal.day] ?? 0) + t.total;
    }
    if (dailyMap.isEmpty) {
      return _LapCard(
        title: 'Tren Harian',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Tidak ada transaksi', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    final days = dailyMap.keys.toList()..sort();
    final maxY = dailyMap.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return _LapCard(
      title: 'Tren Harian',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final dayLabels = [1, 5, 10, 15, 20, 25];
                    final day = days[value.toInt()];
                    if (dayLabels.contains(day)) {
                      return Text(
                        '$day',
                        style: TextStyle(fontSize: 9, color: ctextMuted(context)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: days.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    color: cindigo(context),
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<_TopObatData> _computeTopObat(
    List<TransaksiItemModel> items,
    List<ObatModel> obatList,
  ) {
    final obatById = {for (final o in obatList) o.idObat: o};
    final grouped = <int, _TopObatData>{};

    for (final item in items) {
      final obat = obatById[item.idObat];
      if (obat == null) continue;
      if (obat.etalase != Etalase.etalase1 && obat.etalase != Etalase.etalase2) {
        continue;
      }
      final existing = grouped[item.idObat];
      if (existing != null) {
        grouped[item.idObat] = _TopObatData(
          idObat: item.idObat,
          namaObat: obat.namaObat,
          jumlahTerjual: existing.jumlahTerjual + item.jumlah,
          totalNominal: existing.totalNominal + item.subtotal,
        );
      } else {
        grouped[item.idObat] = _TopObatData(
          idObat: item.idObat,
          namaObat: obat.namaObat,
          jumlahTerjual: item.jumlah,
          totalNominal: item.subtotal,
        );
      }
    }

    final sorted = grouped.values.toList()
      ..sort((a, b) => b.totalNominal.compareTo(a.totalNominal));

    return sorted.take(10).toList();
  }
}

class _TopObatData {
  _TopObatData({
    required this.idObat,
    required this.namaObat,
    required this.jumlahTerjual,
    required this.totalNominal,
  });
  final int idObat;
  final String namaObat;
  final int jumlahTerjual;
  final double totalNominal;
}

// ─── Tab: Tahunan ─────────────────────────────────────────────────────────────

class _TabTahunan extends StatelessWidget {
  const _TabTahunan({
    required this.summary,
    required this.startDate,
    required this.endDate,
    required this.onPickYear,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  final LaporanSummary summary;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPickYear;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final year = startDate.year;
    final chartPoints = summary.chartPoints;

    // Group by month
    final monthlyMap = <int, double>{};
    for (final p in chartPoints) {
      monthlyMap[p.date.month] = (monthlyMap[p.date.month] ?? 0) + p.totalNominal;
    }

    // Stok overview
    final obatList = summary.stokKritis;
    final stokHabis = obatList.where((o) => o.statusStok == StokStatus.habis).length;
    final stokMenipis = obatList.where((o) => o.statusStok == StokStatus.menipis).length;
    final stokAman = summary.jumlahStokKritis == 0
        ? 'Semua stok aman'
        : '${summary.jumlahStokKritis} item kritis';

    return RefreshIndicator(
      onRefresh: () async {},
      color: cindigo(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DatePickerRow(
              label: 'Tahun $year',
              onTap: onPickYear,
            ),
            const SizedBox(height: 12),
            _StatGrid(
              items: [
                _StatItem(
                  label: 'Total Penjualan YTD',
                  value: rupiah(summary.totalPendapatanKeseluruhan),
                ),
                _StatItem(
                  label: 'Total Transaksi',
                  value: '${summary.jumlahTransaksi}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatGrid(
              items: [
                _StatItem(
                  label: 'Transaksi Obat',
                  value: '${summary.jumlahTransaksiReadyStock}',
                ),
                _StatItem(
                  label: 'Transaksi Praktek',
                  value: '${summary.jumlahTransaksiPraktekCustom}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMonthlyChart(context, monthlyMap),
            const SizedBox(height: 12),
            _BdRow(label: 'Etalase 1', value: rupiah(summary.pendapatanEtalase1)),
            _BdRow(label: 'Etalase 2', value: rupiah(summary.pendapatanEtalase2)),
            _BdRow(label: 'Etalase 3 / Praktek', value: rupiah(summary.pendapatanEtalase3Custom)),
            _BdRow(label: 'Pasien Baru', value: '${summary.jumlahPasienTerdaftar}'),
            const SizedBox(height: 12),
            _LapCard(
              title: 'Stok Overview',
              child: Column(
                children: [
                  _OpRow(
                    label: 'Habis',
                    value: '$stokHabis item',
                    valueColor: cdanger(context),
                  ),
                  _OpRow(
                    label: 'Menipis',
                    value: '$stokMenipis item',
                    valueColor: cwarning(context),
                  ),
                  _OpRow(
                    label: 'Status',
                    value: stokAman,
                    valueColor: csuccess(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ExportRow(onExportCsv: onExportCsv, onExportPdf: onExportPdf),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(BuildContext context, Map<int, double> monthlyMap) {
    final months = List.generate(12, (i) => i + 1);
    final maxY = monthlyMap.values.isEmpty
        ? 100000.0
        : monthlyMap.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return _LapCard(
      title: 'Tren Bulanan',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                    return Text(
                      labels[value.toInt()],
                      style: TextStyle(fontSize: 9, color: ctextMuted(context)),
                    );
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: months.map((m) {
              return BarChartGroupData(
                x: m - 1,
                barRods: [
                  BarChartRodData(
                    toY: monthlyMap[m] ?? 0,
                    color: cteal(context),
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ccardBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: ctextSecondary(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ctextPrimary(context),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: ctextSecondary(context)),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              color: ctextSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ctextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _LapCard extends StatelessWidget {
  const _LapCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cisDark(context)
                  ? DarkColors.surface
                  : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ctextPrimary(context),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _BdRow extends StatelessWidget {
  const _BdRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cdivider(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: ctextSecondary(context)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ctextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpRow extends StatelessWidget {
  const _OpRow({
    required this.label,
    required this.value,
    Color? valueColor,
  }) : _valueColor = valueColor;

  final String label;
  final String value;
  final Color? _valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cisDark(context)
            ? DarkColors.surface
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: ctextSecondary(context)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _valueColor ?? ctextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportRow extends StatelessWidget {
  const _ExportRow({
    required this.onExportCsv,
    required this.onExportPdf,
  });

  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onExportCsv,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cteal(context),
              side: BorderSide(color: cteal(context)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onExportPdf,
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Export PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ctextSecondary(context),
              side: BorderSide(color: cdivider(context)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopObatRow extends StatelessWidget {
  const _TopObatRow({required this.item});

  final _TopObatData item;

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (item.totalNominal > 0) {
      rankColor = cteal(context);
    } else {
      rankColor = ctextMuted(context);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cisDark(context)
            ? DarkColors.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '•',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaObat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ctextPrimary(context),
                  ),
                ),
                Text(
                  '${item.jumlahTerjual} terjual',
                  style: TextStyle(fontSize: 10, color: ctextMuted(context)),
                ),
              ],
            ),
          ),
          Text(
            rupiah(item.totalNominal),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: cteal(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Year Picker Dialog ─────────────────────────────────────────────────────

class _YearPickerDialog extends StatefulWidget {
  const _YearPickerDialog({required this.initialYear});

  final int initialYear;

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 2019, (i) => currentYear - i);

    return AlertDialog(
      title: const Text('Pilih Tahun'),
      content: SizedBox(
        width: 200,
        height: 300,
        child: ListView.builder(
          itemCount: years.length,
          itemBuilder: (ctx, i) {
            final year = years[i];
            final isSelected = year == _selectedYear;
            return ListTile(
              title: Text(
                '$year',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                  color: isSelected ? cprimary(context) : ctextPrimary(context),
                ),
              ),
              onTap: () => Navigator.pop(context, year),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _monthName(int month) {
  const names = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return names[month];
}
