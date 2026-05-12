import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:klinik_mobile_app/core/feedback/app_feedback.dart';
import 'package:klinik_mobile_app/core/error/app_error_mapper.dart';
import 'package:klinik_mobile_app/core/theme/app_theme.dart';
import 'package:klinik_mobile_app/core/utils/formatters.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/features/transaksi/providers/transaksi_history_providers.dart';
import 'package:klinik_mobile_app/pages/transaksi/struk_pembayaran_page.dart';
import 'package:klinik_mobile_app/pages/transaksi_form_page.dart';

enum TransaksiDateFilter {
  today,
  yesterday,
  last7Days,
  thisMonth,
  customDate,
}

class FilterChipOption<T> {
  const FilterChipOption({
    required this.label,
    required this.value,
    this.icon,
    this.isCustomDate = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool isCustomDate;
}

class SummaryMetrics {
  const SummaryMetrics({
    required this.totalOmzet,
    required this.totalTransaksi,
    required this.totalObat,
    required this.totalPraktek,
    required this.omzetObat,
    required this.omzetPraktek,
  });

  final double totalOmzet;
  final int totalTransaksi;
  final int totalObat;
  final int totalPraktek;
  final double omzetObat;
  final double omzetPraktek;

  factory SummaryMetrics.fromItems(List<TransaksiModel> items) {
    final totalOmzet = items.fold<double>(0, (sum, item) => sum + item.total);
    final totalObat = items
        .where((t) => t.jenisTransaksi == JenisTransaksi.obatReadyStock)
        .length;
    final totalPraktek = items
        .where((t) => t.jenisTransaksi == JenisTransaksi.praktekCustom)
        .length;
    final omzetObat = items
        .where((t) => t.jenisTransaksi == JenisTransaksi.obatReadyStock)
        .fold<double>(0, (sum, item) => sum + item.total);
    final omzetPraktek = items
        .where((t) => t.jenisTransaksi == JenisTransaksi.praktekCustom)
        .fold<double>(0, (sum, item) => sum + item.total);

    return SummaryMetrics(
      totalOmzet: totalOmzet,
      totalTransaksi: items.length,
      totalObat: totalObat,
      totalPraktek: totalPraktek,
      omzetObat: omzetObat,
      omzetPraktek: omzetPraktek,
    );
  }
}

class EmptyStateData {
  const EmptyStateData({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  EmptyStateData copyWith({
    String? title,
    String? description,
  }) {
    return EmptyStateData(
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}

/// Halaman list transaksi (hub).
class TransaksiHubPage extends ConsumerStatefulWidget {
  const TransaksiHubPage({super.key});

  static const routeName = '/transaksi-hub';

  @override
  ConsumerState<TransaksiHubPage> createState() => _TransaksiHubPageState();
}

class _TransaksiHubPageState extends ConsumerState<TransaksiHubPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, String> _pasienNameCache = {};
  final Set<int> _pendingPasienNameIds = {};
  String _searchQuery = '';
  TransaksiDateFilter _dateFilter = TransaksiDateFilter.today;
  DateTime _customDate = _dateOnly(DateTime.now());
  JenisTransaksi? _jenisFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final value = _searchController.text;
      if (_searchQuery == value) return;
      setState(() => _searchQuery = value);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime get _today => _dateOnly(DateTime.now());
  TransaksiHistoryQuery get _query => TransaksiHistoryQuery(
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );

  DateTime get _filterStartDate {
    final today = _today;
    switch (_dateFilter) {
      case TransaksiDateFilter.today:
        return today;
      case TransaksiDateFilter.yesterday:
        return today.subtract(const Duration(days: 1));
      case TransaksiDateFilter.last7Days:
        return today.subtract(const Duration(days: 6));
      case TransaksiDateFilter.thisMonth:
        return DateTime(today.year, today.month);
      case TransaksiDateFilter.customDate:
        return _customDate;
    }
  }

  DateTime get _filterEndDate {
    final today = _today;
    switch (_dateFilter) {
      case TransaksiDateFilter.today:
      case TransaksiDateFilter.last7Days:
      case TransaksiDateFilter.thisMonth:
        return today;
      case TransaksiDateFilter.yesterday:
        return today.subtract(const Duration(days: 1));
      case TransaksiDateFilter.customDate:
        return _customDate;
    }
  }

  String get _activeDateLabel {
    switch (_dateFilter) {
      case TransaksiDateFilter.today:
        return 'Hari Ini';
      case TransaksiDateFilter.yesterday:
        return 'Kemarin';
      case TransaksiDateFilter.last7Days:
        return '7 Hari';
      case TransaksiDateFilter.thisMonth:
        return 'Bulan Ini';
      case TransaksiDateFilter.customDate:
        return asDate(_customDate);
    }
  }

  List<TransaksiModel> _jenisFilteredItems(List<TransaksiModel> source) {
    final jenis = _jenisFilter;
    if (jenis == null) return source;
    return source.where((t) => t.jenisTransaksi == jenis).toList();
  }

  List<TransaksiModel> _visibleItems(List<TransaksiModel> source) {
    final base = _jenisFilteredItems(source);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return base;
    return base.where((t) => _buildSearchText(t).contains(query)).toList();
  }

  String _buildSearchText(TransaksiModel item) {
    return [
      _buildInvoiceLabel(item),
      item.idTransaksi.toString(),
      _patientNameFor(item),
      item.jenisTransaksi.label,
      item.metodeBayar?.label ?? '',
      item.keterangan ?? '',
      asDate(item.tanggal),
    ].join(' ').toLowerCase();
  }

  String _patientNameFor(TransaksiModel item) {
    final idPasien = item.idPasien;
    if (idPasien == null) return 'Pasien Umum';
    return _pasienNameCache[idPasien] ?? 'Pasien #$idPasien';
  }

  String _buildInvoiceLabel(TransaksiModel item) {
    return 'INV-${item.idTransaksi.toString().padLeft(5, '0')}';
  }

  Future<void> _refreshTransaksi() async {
    try {
      ref.invalidate(transaksiHistoryByRangeProvider(_query));
      await ref.read(transaksiHistoryByRangeProvider(_query).future);
    } catch (error, stackTrace) {
      if (!mounted) return;
      AppFeedback.showError(context, error, stackTrace);
    }
  }

  Future<void> _hydratePatientNames(List<TransaksiModel> items) async {
    var ids = <int>[];
    try {
      ids = items
          .map((item) => item.idPasien)
          .whereType<int>()
          .where(
            (id) =>
                !_pasienNameCache.containsKey(id) &&
                !_pendingPasienNameIds.contains(id),
          )
          .toSet()
          .toList();

      if (ids.isEmpty) return;
      _pendingPasienNameIds.addAll(ids);

      final entries = await Future.wait(
        ids.map((id) async {
          final nama = await ref
              .read(transaksiHistoryRepositoryProvider)
              .getNamaPasienById(id);
          return MapEntry(
            id,
            (nama == null || nama.isEmpty) ? 'Pasien #$id' : nama,
          );
        }),
      );

      if (!mounted || entries.isEmpty) return;
      setState(() {
        for (final entry in entries) {
          _pasienNameCache[entry.key] = entry.value;
          _pendingPasienNameIds.remove(entry.key);
        }
      });
    } catch (_) {
      for (final id in ids) {
        _pendingPasienNameIds.remove(id);
      }
      // Tetap tampilkan fallback "Pasien #id" agar dashboard tidak terganggu.
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(adminRoleProvider);
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Transaksi',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cteal(context),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.12),
            height: 1,
          ),
        ),
      ),
      body: roleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _buildError(message: AppErrorMapper.toMessage(error, stackTrace)),
        data: (role) {
          if (!role.isOwner) return _buildStaffAddOnly();
          final historyAsync = ref.watch(transaksiHistoryByRangeProvider(_query));
          return historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                _buildError(message: AppErrorMapper.toMessage(error, stackTrace)),
            data: (items) {
              unawaited(_hydratePatientNames(items));
              return _buildOwnerHistory(items);
            },
          );
        },
      ),
      floatingActionButton: roleAsync.maybeWhen(
        data: (role) => role.isOwner
            ? FloatingActionButton(
                onPressed: _addTransaksi,
                backgroundColor: cteal(context),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildStaffAddOnly() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.point_of_sale, size: 64, color: cteal(context)),
            const SizedBox(height: 16),
            Text(
              'Tambah Transaksi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ctextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Petugas dapat membuat transaksi baru dari halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ctextSecondary(context)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addTransaksi,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Transaksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cteal(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError({required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: cdanger(context)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: cdanger(context))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshTransaksi,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  EmptyStateData _buildEmptyStateData(List<TransaksiModel> source) {
    final hasTypeResults = _jenisFilteredItems(source).isNotEmpty;
    if (_searchQuery.trim().isNotEmpty) {
      return const EmptyStateData(
        title: 'Transaksi tidak ditemukan',
        description:
            'Coba kata kunci lain. Anda bisa cari nama pasien, invoice, atau catatan transaksi.',
      );
    }
    if (hasTypeResults) {
      return const EmptyStateData(
        title: 'Tidak ada transaksi di hasil filter',
        description:
            'Ubah kategori atau tanggal untuk melihat transaksi yang tersedia.',
      );
    }

    final title = switch (_dateFilter) {
      TransaksiDateFilter.today => 'Belum ada transaksi hari ini',
      TransaksiDateFilter.customDate => 'Tidak ada transaksi pada tanggal ini',
      _ => 'Tidak ada transaksi pada periode ini',
    };

    return const EmptyStateData(
      title: '',
      description: 'Tekan tombol + untuk menambahkan transaksi baru.',
    ).copyWith(title: title);
  }

  Widget _buildOwnerHistory(List<TransaksiModel> source) {
    final visibleItems = _visibleItems(source);
    final summary = SummaryMetrics.fromItems(_jenisFilteredItems(source));
    final emptyStateData = _buildEmptyStateData(source);

    return RefreshIndicator(
      onRefresh: _refreshTransaksi,
      color: cteal(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SummarySection(
                    activeDateLabel: _activeDateLabel,
                    metrics: summary,
                  ),
                  const SizedBox(height: 8),
                  TransactionSearchBar(
                    controller: _searchController,
                    onClear: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: 8),
                  TransactionFilterChips(
                    activeDateLabel: _activeDateLabel,
                    dateOptions: [
                      FilterChipOption(
                        label: 'Hari Ini',
                        value: TransaksiDateFilter.today,
                      ),
                      FilterChipOption(
                        label: 'Kemarin',
                        value: TransaksiDateFilter.yesterday,
                      ),
                      FilterChipOption(
                        label: '7 Hari',
                        value: TransaksiDateFilter.last7Days,
                      ),
                      FilterChipOption(
                        label: 'Bulan Ini',
                        value: TransaksiDateFilter.thisMonth,
                      ),
                      FilterChipOption(
                        label: _dateFilter == TransaksiDateFilter.customDate
                            ? asDate(_customDate)
                            : 'Pilih Tanggal',
                        value: TransaksiDateFilter.customDate,
                        icon: Icons.calendar_month,
                        isCustomDate: true,
                      ),
                    ],
                    selectedDate: _dateFilter,
                    onDateSelected: _setDateFilter,
                    onDatePickerTap: _pickCustomDate,
                    typeOptions: [
                      const FilterChipOption<JenisTransaksi?>(
                        label: 'Semua',
                        value: null,
                      ),
                      const FilterChipOption<JenisTransaksi?>(
                        label: 'Obat',
                        value: JenisTransaksi.obatReadyStock,
                      ),
                      const FilterChipOption<JenisTransaksi?>(
                        label: 'Praktek',
                        value: JenisTransaksi.praktekCustom,
                      ),
                    ],
                    selectedType: _jenisFilter,
                    onTypeSelected: (value) {
                      if (_jenisFilter == value) return;
                      setState(() => _jenisFilter = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (visibleItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 64),
                child: EmptyTransactionState(
                  icon: Icons.receipt_long_rounded,
                  title: emptyStateData.title,
                  description: emptyStateData.description,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 88),
              sliver: SliverList.builder(
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  return TransactionTile(
                    transaksi: item,
                    patientName: _patientNameFor(item),
                    invoiceLabel: _buildInvoiceLabel(item),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StrukPembayaranPage(idTransaksi: item.idTransaksi),
                        ),
                      );
                    },
                    onLongPress: () => _showTransaksiOptions(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _setDateFilter(TransaksiDateFilter filter) async {
    if (_dateFilter == filter) return;
    setState(() => _dateFilter = filter);
    await _refreshTransaksi();
  }

  Future<void> _pickCustomDate() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 1, 12, 31),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _customDate = _dateOnly(picked);
      _dateFilter = TransaksiDateFilter.customDate;
    });
    await _refreshTransaksi();
  }

  void _showTransaksiOptions(TransaksiModel t) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Lihat Struk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StrukPembayaranPage(idTransaksi: t.idTransaksi),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Tutup'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTransaksi() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TransaksiFormPage()),
    );

    if (result == true) {
      await _refreshTransaksi();
    } else if (result == false) {
      if (mounted) AppFeedback.showInfo(context, 'Transaksi dibatalkan.');
    }
  }
}

class TransactionFilterChips extends StatelessWidget {
  const TransactionFilterChips({
    super.key,
    required this.activeDateLabel,
    required this.dateOptions,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onDatePickerTap,
    required this.typeOptions,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final String activeDateLabel;
  final List<FilterChipOption<TransaksiDateFilter>> dateOptions;
  final TransaksiDateFilter selectedDate;
  final ValueChanged<TransaksiDateFilter> onDateSelected;
  final VoidCallback onDatePickerTap;
  final List<FilterChipOption<JenisTransaksi?>> typeOptions;
  final JenisTransaksi? selectedType;
  final ValueChanged<JenisTransaksi?> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Filter: $activeDateLabel',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ctextSecondary(context),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in dateOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CompactFilterChip(
                    label: option.label,
                    icon: option.icon,
                    selected: selectedDate == option.value,
                    onTap: option.isCustomDate
                        ? onDatePickerTap
                        : () => onDateSelected(option.value),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in typeOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CompactFilterChip(
                    label: option.label,
                    selected: selectedType == option.value,
                    onTap: () => onTypeSelected(option.value),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({
    super.key,
    required this.activeDateLabel,
    required this.metrics,
  });

  final String activeDateLabel;
  final SummaryMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Ringkasan $activeDateLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ctextSecondary(context),
            ),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final omzetWidth = compact ? 156.0 : 172.0;
            final countWidth = compact ? 146.0 : 160.0;

            return SizedBox(
              height: 116,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  CompactStatCard(
                    icon: Icons.payments_rounded,
                    value: rupiah(metrics.totalOmzet),
                    label: 'Total Omzet',
                    accentColor: csuccess(context),
                    emphasized: true,
                    width: omzetWidth,
                  ),
                  CompactStatCard(
                    icon: Icons.receipt_long_rounded,
                    value: '${metrics.totalTransaksi}',
                    label: 'Jumlah Transaksi',
                    accentColor: cteal(context),
                    emphasized: true,
                    width: countWidth,
                  ),
                  CompactStatCard(
                    icon: Icons.medication_rounded,
                    value: '${metrics.totalObat}',
                    helper: rupiah(metrics.omzetObat),
                    label: 'Obat',
                    accentColor: cprimary(context),
                  ),
                  CompactStatCard(
                    icon: Icons.healing_rounded,
                    value: '${metrics.totalPraktek}',
                    helper: rupiah(metrics.omzetPraktek),
                    label: 'Praktek',
                    accentColor: cwarning(context),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class TransactionSearchBar extends StatelessWidget {
  const TransactionSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cdivider(context)),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Cari pasien, invoice, atau transaksi',
          hintStyle: TextStyle(
            fontSize: 12,
            color: ctextMuted(context),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: ctextSecondary(context)),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, color: ctextSecondary(context)),
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

class CompactStatCard extends StatelessWidget {
  const CompactStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    this.helper,
    this.emphasized = false,
    this.width = 152,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;
  final String? helper;
  final bool emphasized;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96, minWidth: 148),
        width: width,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: emphasized
              ? accentColor.withValues(alpha: 0.12)
              : ccardBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: emphasized
                ? accentColor.withValues(alpha: 0.45)
                : cdivider(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accentColor),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: emphasized ? 16 : 15,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: ctextPrimary(context),
              ),
            ),
            if (helper != null)
              Text(
                helper!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: ctextSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ctextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactFilterChip extends StatelessWidget {
  const CompactFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final activeColor = cteal(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? activeColor.withValues(alpha: 0.16)
                : ccardBg(context),
            border: Border.all(
              color: selected ? activeColor : cdivider(context),
              width: selected ? 1.25 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? activeColor : ctextSecondary(context),
                ),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: selected ? activeColor : ctextPrimary(context),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaksi,
    required this.patientName,
    required this.invoiceLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final TransaksiModel transaksi;
  final String patientName;
  final String invoiceLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isReadyStock =
        transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock;
    final categoryColor = isReadyStock ? cprimary(context) : cwarning(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cdivider(context)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isReadyStock ? Icons.medication_rounded : Icons.healing_rounded,
                      color: categoryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ctextPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rupiah(transaksi.total),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: csuccess(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaChip(
                    icon: Icons.receipt_long_rounded,
                    label: invoiceLabel,
                  ),
                  _MetaChip(
                    icon: Icons.calendar_today_rounded,
                    label: asMediumDate(transaksi.tanggal),
                  ),
                  _MetaChip(
                    icon: isReadyStock
                        ? Icons.medication_outlined
                        : Icons.health_and_safety_outlined,
                    label: transaksi.jenisTransaksi.label,
                    color: categoryColor,
                  ),
                  if (transaksi.metodeBayar != null)
                    _MetaChip(
                      icon: Icons.verified_rounded,
                      label: transaksi.metodeBayar!.label,
                      color: cteal(context),
                    ),
                ],
              ),
              if ((transaksi.keterangan ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  transaksi.keterangan!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: ctextSecondary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? ctextSecondary(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyTransactionState extends StatelessWidget {
  const EmptyTransactionState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: cteal(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: cteal(context), size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: ctextSecondary(context),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
