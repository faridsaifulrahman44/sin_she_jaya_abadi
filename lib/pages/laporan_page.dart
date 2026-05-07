import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/date_range_validator.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/obat_model.dart';
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

class _LaporanPageState extends State<LaporanPage> {
  final LaporanRepository _repository = LaporanRepository();

  bool _isLoading = true;
  bool _accessDenied = false;
  String? _errorMessage;
  String _selectedFilter = 'bulan_ini';
  late DateTime _startDate;
  late DateTime _endDate;
  LaporanSummary? _summary;
  List<FlSpot> _chartSpots = const <FlSpot>[];
  double _maxChartY = 0;

  @override
  void initState() {
    super.initState();
    _checkAccess();
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

      _initDateRange(_selectedFilter);
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

  void _initDateRange(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'hari_ini':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'minggu_ini':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'bulan_ini':
      default:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
    }
  }

  Future<void> _loadData() async {
    final validation = validateDateRange(
      startDate: _startDate,
      endDate: _endDate,
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
      final data = await _repository.getReportData(
        startDate: _startDate,
        endDate: _endDate,
      );

      final summary = buildLaporanSummary(
        startDate: _startDate,
        endDate: _endDate,
        transaksiPeriode: data.transaksiPeriode,
        transaksiAllTime: data.transaksiAllTime,
        transaksiItemsAllTime: data.transaksiItemsAllTime,
        pasienPeriode: data.pasienPeriode,
        pasienAllTime: data.pasienAllTime,
        kehadiranPeriode: data.kehadiranPeriode,
        obatAllTime: data.obatAllTime,
      );

      final spots = summary.chartPoints
          .asMap()
          .entries
          .map(
              (entry) => FlSpot(entry.key.toDouble(), entry.value.totalNominal))
          .toList(growable: false);

      final maxChartY = spots.fold<double>(
        0,
        (double current, FlSpot item) => item.y > current ? item.y : current,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _chartSpots = spots;
        _maxChartY = maxChartY;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppErrorMapper.toMessage(error, stackTrace);
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    if (filter == 'custom') {
      _showCustomDatePicker();
      return;
    }

    setState(() => _selectedFilter = filter);
    _initDateRange(filter);
    _loadData();
  }

  Future<void> _showCustomDatePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: cprimary(ctx)),
          ),
          child: child!,
        );
      },
    );

    if (range == null) {
      return;
    }

    final validation = validateDateRange(
      startDate: range.start,
      endDate: range.end,
    );

    if (!validation.isValid) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message ?? 'Range tanggal tidak valid'),
        ),
      );
      return;
    }

    setState(() {
      _selectedFilter = 'custom';
      _startDate = range.start;
      _endDate = range.end;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return _buildAccessDenied(context);
    }

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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? AppLoadingView(
                key: const ValueKey('loading'),
                child: _buildLoading(),
              )
            : _errorMessage != null
                ? AppErrorView(
                    key: const ValueKey('error'),
                    message: _errorMessage!,
                    onRetry: _loadData,
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        LaporanLoadingBox(height: 150),
        SizedBox(height: 16),
        LaporanLoadingBox(height: 46),
        SizedBox(height: 16),
        LaporanLoadingBox(height: 220),
        SizedBox(height: 16),
        LaporanLoadingBox(height: 260),
      ],
    );
  }

  Widget _buildContent() {
    final summary = _summary;
    if (summary == null) {
      return const AppEmptyView(
        title: 'Data laporan belum tersedia',
        message: 'Silakan tarik ulang untuk memuat laporan.',
        icon: AppIcons.laporan,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: cindigo(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(summary),
            const SizedBox(height: 16),
            _buildFilterRow(),
            const SizedBox(height: 16),
            _buildPrimarySummary(summary),
            const SizedBox(height: 16),
            _buildPendapatanSection(summary),
            const SizedBox(height: 16),
            _buildTransaksiSection(summary),
            const SizedBox(height: 16),
            _buildPasienKehadiranSection(summary),
            const SizedBox(height: 16),
            _buildStokSection(summary),
            const SizedBox(height: 16),
            _buildChartSection(summary),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(LaporanSummary summary) {
    final heroColor =
        cisDark(context) ? DarkColors.navy : const Color(0xFF1E3A8A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: heroColor.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: heroColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: AppIcons.laporan,
                  color: conPrimary(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Klinik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: conPrimary(context),
                      ),
                    ),
                    Text(
                      formatDateRangeLabel(_startDate, _endDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: ctextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            rupiah(summary.pendapatanPeriodeAktif),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: conPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pendapatan periode aktif',
            style: TextStyle(
              fontSize: 12,
              color: ctextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total seluruh waktu: ${rupiah(summary.totalPendapatanKeseluruhan)}',
            style: TextStyle(
              fontSize: 12,
              color: ctextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          LaporanFilterChip(
            label: 'Hari Ini',
            selected: _selectedFilter == 'hari_ini',
            onTap: () => _onFilterChanged('hari_ini'),
          ),
          const SizedBox(width: 8),
          LaporanFilterChip(
            label: 'Minggu Ini',
            selected: _selectedFilter == 'minggu_ini',
            onTap: () => _onFilterChanged('minggu_ini'),
          ),
          const SizedBox(width: 8),
          LaporanFilterChip(
            label: 'Bulan Ini',
            selected: _selectedFilter == 'bulan_ini',
            onTap: () => _onFilterChanged('bulan_ini'),
          ),
          const SizedBox(width: 8),
          LaporanFilterChip(
            label: 'Custom',
            selected: _selectedFilter == 'custom',
            onTap: () => _onFilterChanged('custom'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimarySummary(LaporanSummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildKpiCard(
          title: 'Pendapatan',
          value: rupiah(summary.pendapatanPeriodeAktif),
          subtitle: 'Periode aktif',
          icon: AppIcons.payment,
          accentColor: csuccess(context),
        ),
        _buildKpiCard(
          title: 'Transaksi',
          value: '${summary.jumlahTransaksi}',
          subtitle: 'Ready + custom',
          icon: AppIcons.receipt,
          accentColor: cindigo(context),
        ),
        _buildKpiCard(
          title: 'Kehadiran',
          value: '${summary.jumlahHadir}/${summary.jumlahKehadiran}',
          subtitle: 'Hadir / total kehadiran',
          icon: AppIcons.event,
          accentColor: cteal(context),
        ),
        _buildKpiCard(
          title: 'Stok Kritis',
          value: '${summary.jumlahStokKritis}',
          subtitle:
              'Menipis ${summary.jumlahStokMenipis} • Habis ${summary.jumlahStokHabis}',
          icon: AppIcons.inventory,
          accentColor: summary.jumlahStokKritis == 0
              ? csuccess(context)
              : cdanger(context),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required List<List<dynamic>> icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ctextSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ctextPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: ctextMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendapatanSection(LaporanSummary summary) {
    return LaporanSectionCard(
      title: 'Ringkasan Pendapatan',
      subtitle: formatDateRangeLabel(_startDate, _endDate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricRow(
            label: 'Total Pendapatan (Semua Waktu)',
            value: rupiah(summary.totalPendapatanKeseluruhan),
          ),
          _buildMetricRow(
            label: 'Pendapatan Periode Aktif',
            value: rupiah(summary.pendapatanPeriodeAktif),
            highlight: true,
          ),
          const SizedBox(height: 8),
          Divider(color: cdivider(context)),
          const SizedBox(height: 8),
          _buildMetricRow(
            label: 'Obat',
            value: rupiah(summary.pendapatanReadyStock),
          ),
          _buildMetricRow(
            label: 'Praktek',
            value: rupiah(summary.pendapatanPraktekCustomBundled),
          ),
          const SizedBox(height: 8),
          Divider(color: cdivider(context)),
          const SizedBox(height: 8),
          Text(
            'Breakdown Etalase',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            label: 'Etalase 1',
            value: rupiah(summary.pendapatanEtalase1),
          ),
          _buildMetricRow(
            label: 'Etalase 2',
            value: rupiah(summary.pendapatanEtalase2),
          ),
          _buildMetricRow(
            label: 'Etalase 3 / Praktek',
            value: rupiah(summary.pendapatanEtalase3Custom),
          ),
          if (summary.hasSelisihEtalase) ...[
            _buildMetricRow(
              label: 'Belum Terpetakan',
              value: _signedRupiah(summary.selisihPendapatanBelumTerpetakan),
              valueColor: cwarning(context),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cwarning(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Sebagian pendapatan belum terpetakan ke etalase (biasanya karena detail item transaksi obat tidak lengkap).',
                style: TextStyle(
                  fontSize: 12,
                  color: ctextSecondary(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransaksiSection(LaporanSummary summary) {
    return LaporanSectionCard(
      title: 'Ringkasan Transaksi',
      subtitle: 'Total transaksi dan metode bayar pada periode aktif',
      child: Column(
        children: [
          _buildMetricRow(
            label: 'Jumlah transaksi',
            value: '${summary.jumlahTransaksi}',
            highlight: true,
          ),
          _buildMetricRow(
            label: 'Transaksi obat',
            value: '${summary.jumlahTransaksiReadyStock}',
          ),
          _buildMetricRow(
            label: 'Transaksi praktek',
            value: '${summary.jumlahTransaksiPraktekCustom}',
          ),
          const SizedBox(height: 8),
          Divider(color: cdivider(context)),
          const SizedBox(height: 8),
          _buildMetricRow(
            label: 'Pembayaran cash',
            value:
                '${summary.jumlahTransaksiCash} transaksi • ${rupiah(summary.nominalCash)}',
          ),
          _buildMetricRow(
            label: 'Pembayaran QRIS',
            value:
                '${summary.jumlahTransaksiQris} transaksi • ${rupiah(summary.nominalQris)}',
          ),
        ],
      ),
    );
  }

  Widget _buildPasienKehadiranSection(LaporanSummary summary) {
    return LaporanSectionCard(
      title: 'Pasien dan Kehadiran',
      subtitle: 'Kehadiran dihitung dari status hadir / tidak_hadir',
      child: Column(
        children: [
          _buildMetricRow(
            label: 'Jumlah pasien terdaftar',
            value: '${summary.jumlahPasienTerdaftar}',
          ),
          _buildMetricRow(
            label: 'Pasien dijadwalkan periode aktif',
            value: '${summary.jumlahPasienTerjadwalPeriode}',
          ),
          const SizedBox(height: 8),
          Divider(color: cdivider(context)),
          const SizedBox(height: 8),
          _buildMetricRow(
            label: 'Hadir',
            value: '${summary.jumlahHadir}',
            valueColor: csuccess(context),
          ),
          _buildMetricRow(
            label: 'Tidak hadir',
            value: '${summary.jumlahTidakHadir}',
            valueColor: cdanger(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStokSection(LaporanSummary summary) {
    return LaporanSectionCard(
      title: 'Stok Kritis',
      subtitle:
          'Menipis: ${summary.jumlahStokMenipis} • Habis: ${summary.jumlahStokHabis}',
      child: summary.stokKritis.isEmpty
          ? const AppEmptyView(
              title: 'Tidak ada stok kritis',
              message: 'Semua stok berada pada kondisi aman.',
              icon: AppIcons.inventory,
            )
          : Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.stokKritis.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildStokItem(summary.stokKritis[index]),
                ),
              ],
            ),
    );
  }

  Widget _buildStokItem(ObatModel item) {
    final isHabis = item.statusStok == StokStatus.habis;
    final statusColor = isHabis ? cdanger(context) : cwarning(context);
    final satuanSuffix = item.satuan == null ? '' : ' ${item.satuan}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cscaffoldBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cdivider(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: AppIcons.inventory,
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaObat,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.etalase.label} • Stok ${item.stokSaatIni}$satuanSuffix • Min ${item.stokMinimum}$satuanSuffix',
                  style: TextStyle(
                    fontSize: 12,
                    color: ctextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isHabis ? 'Habis' : 'Menipis',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(LaporanSummary summary) {
    return LaporanSectionCard(
      title: 'Tren Pendapatan Harian',
      subtitle: '${summary.chartPoints.length} hari hingga ${asDate(_endDate)}',
      child: SizedBox(
        height: 220,
        child: Builder(
          builder: (ctx) {
            final chartColor = cindigo(ctx);
            final divColor = cdivider(ctx);
            final mutedColor = ctextMuted(ctx);
            return LineChart(
              LineChartData(
                minY: 0,
                maxY: _maxChartY <= 0 ? 100000 : _maxChartY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: divColor,
                    strokeWidth: 1,
                  ),
                  checkToShowHorizontalLine: (value) => value == 0,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value >= 1000000
                              ? '${(value / 1000000).toStringAsFixed(1)}jt'
                              : value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(0)}rb'
                                  : value.toStringAsFixed(0),
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= summary.chartPoints.length) {
                          return const SizedBox.shrink();
                        }
                        final item = summary.chartPoints[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            item.date.day.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartSpots,
                    isCurved: true,
                    color: chartColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          chartColor.withValues(alpha: 0.25),
                          chartColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    bool highlight = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: ctextSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? ctextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  String _signedRupiah(double value) {
    final absValue = rupiah(value.abs());
    if (value > 0) {
      return '+$absValue';
    }
    if (value < 0) {
      return '-$absValue';
    }
    return absValue;
  }

  Widget _buildAccessDenied(BuildContext context) {
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
                child: Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: cdanger(context),
                ),
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
                style: TextStyle(
                  fontSize: 14,
                  color: ctextSecondary(context),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cprimary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
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
