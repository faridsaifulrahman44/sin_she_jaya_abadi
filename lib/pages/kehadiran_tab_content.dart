import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/obat_foto_resolver.dart';
import '../data/models/obat_masuk_model.dart';
import '../data/repositories/obat_masuk_repository.dart';
import '../core/design_system/app_tokens.dart';

enum _KehadiranViewMode { bulan, tahun }

/// Body-widget (embeddable) untuk halaman "Daftar Kehadiran".
///
/// Dipakai langsung oleh [KehadiranPage] — halaman standalone.
/// Tidak memiliki Scaffold/AppBar sendiri.
class KehadiranTabContent extends StatefulWidget {
  const KehadiranTabContent({
    super.key,
    this.onRefresh,
  });

  /// Callback opsional untuk refresh parent setelah input kehadiran tersimpan.
  final VoidCallback? onRefresh;

  @override
  State<KehadiranTabContent> createState() => _KehadiranTabContentState();
}

class _KehadiranTabContentState extends State<KehadiranTabContent> {
  final ObatMasukRepository _obatMasukRepository = ObatMasukRepository();

  /// Tanggal filter aktif. Default = hari ini.
  late DateTime _selectedDate;

  // ── View mode ──────────────────���──────────────────────────────────────────
  _KehadiranViewMode _viewMode = _KehadiranViewMode.bulan;

  // ── Calendar scroll controller ──────────────────────────────────────────
  final ScrollController _calendarScrollController = ScrollController();

  // ── Riwayat obat masuk ───────────────────────────────────────────────────
  late Future<List<ObatMasukModel>> _obatMasukFuture;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _obatMasukFuture = _fetchObatMasuk(_selectedDate);
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<List<ObatMasukModel>> _fetchObatMasuk(DateTime tanggal) {
    return _obatMasukRepository.getObatMasuk(tanggal: tanggal);
  }

  // ── Date helpers ─────────────────────────────────────────────────────────────

  void _setDate(DateTime date) {
    if (_selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day) {
      return;
    }
    setState(() {
      _selectedDate = date;
      _obatMasukFuture = _fetchObatMasuk(date);
    });
  }

  void _goToToday() {
    _setDate(DateTime.now());
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _relatifText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = selected.difference(today).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff < 0) {
      final abs = diff.abs();
      return '$abs hari yang lalu';
    }
    return '$diff hari lagi';
  }

  void _setViewMode(_KehadiranViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
  }

  void _onMonthSelected(int month, int year) {
    _setDate(DateTime(year, month, 1));
    _setViewMode(_KehadiranViewMode.bulan);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _editObatMasuk(ObatMasukModel item) async {
    // ignore: use_build_context_synchronously
    final result = await Navigator.pushNamed<bool>(
      context,
      'ObatMasukFormPage',
      arguments: {'isEdit': true, 'editData': item},
    );
    if (result == true) {
      setState(() {
        _obatMasukFuture = _fetchObatMasuk(_selectedDate);
      });
    }
  }

  Future<void> _deleteObatMasuk(ObatMasukModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat Obat Masuk'),
        content: Text(
          'Hapus riwayat obat masuk "${item.namaObat ?? 'ini'}" pada '
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _obatMasukRepository.deleteObatMasuk(item.idMasuk);
      setState(() {
        _obatMasukFuture = _fetchObatMasuk(_selectedDate);
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header: bulan/tahun + relatif ─────────────────────────────────
        _buildCalendarHeader(),
        // ── Kalender / Toggle ──────────────────────────────────────────────
        _buildViewModeToggle(),
        if (_viewMode == _KehadiranViewMode.bulan)
          _buildHorizontalCalendar()
        else
          _buildYearPicker(),
        // ── Riwayat Obat Masuk ────────────────────────────────────────────
        Expanded(
          child: _buildRiwayatSection(),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${_selectedDate.month} / ${_selectedDate.year}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ctextPrimary(context),
            ),
          ),
          Text(
            _relatifText,
            style: TextStyle(
              fontSize: 12,
              color: ctextMuted(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    final tealColor = cteal(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Row(
        children: [
          _ViewToggleBtn(
            label: 'Bulan',
            isActive: _viewMode == _KehadiranViewMode.bulan,
            activeColor: tealColor,
            onTap: () => _setViewMode(_KehadiranViewMode.bulan),
          ),
          const SizedBox(width: 8),
          _ViewToggleBtn(
            label: 'Tahun',
            isActive: _viewMode == _KehadiranViewMode.tahun,
            activeColor: tealColor,
            onTap: () => _setViewMode(_KehadiranViewMode.tahun),
          ),
          const Spacer(),
          if (!_isToday)
            GestureDetector(
              onTap: _goToToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tealColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tealColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(icon: AppIcons.calendar03, color: tealColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Hari Ini',
                      style: TextStyle(
                        color: tealColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    final now = DateTime.now();
    // Build 35 days: centered around selectedDate (show ~2 weeks before and after)
    final firstDay = _selectedDate.subtract(Duration(days: 20));
    final days = List.generate(
      41,
      (i) => DateTime(firstDay.year, firstDay.month, firstDay.day + i),
    );

    // Auto-scroll to today index after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_calendarScrollController.hasClients) {
        final todayIndex = days.indexWhere((d) =>
            d.year == now.year && d.month == now.month && d.day == now.day);
        if (todayIndex >= 0) {
          final itemWidth = 44.0;
          final screenWidth = MediaQuery.of(context).size.width;
          final targetOffset = (todayIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
          if (_calendarScrollController.offset != targetOffset.clamp(0.0, _calendarScrollController.position.maxScrollExtent)) {
            _calendarScrollController.animateTo(
              targetOffset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        }
      }
    });

    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (ctx, index) {
          final date = days[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _CalendarDayItem(
              dayName: dayNames[date.weekday % 7],
              date: date.day,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => _setDate(date),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearPicker() {
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final today = DateTime.now();
    final currentYear = _selectedDate.year;
    final selectedMonth = _selectedDate.month;

    return Expanded(
      child: Column(
        children: [
          // Header: tahun + panah kiri/kanan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month, 1);
                  }),
                  icon: HugeIcon(icon: AppIcons.arrowBack, color: cteal(context), size: 18),
                  tooltip: 'Tahun sebelumnya',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setViewMode(_KehadiranViewMode.bulan),
                    child: Center(
                      child: Text(
                        '$currentYear',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ctextPrimary(context),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month, 1);
                  }),
                  icon: HugeIcon(icon: AppIcons.arrowRight, color: cteal(context), size: 18),
                  tooltip: 'Tahun berikutnya',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // Grid 4x3 bulan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (ctx, index) {
                  final month = index + 1;
                  final isSelected = month == selectedMonth;
                  final isCurrentMonth = today.year == currentYear && today.month == month;

                  return _MonthGridItem(
                    label: monthNames[index],
                    isSelected: isSelected,
                    isCurrentMonth: isCurrentMonth,
                    onTap: () => _onMonthSelected(month, currentYear),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            'Riwayat Obat Masuk',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ctextPrimary(context),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ObatMasukModel>>(
            future: _obatMasukFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: AppIcons.warning,
                        color: ctextMuted(context),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gagal memuat data',
                        style: TextStyle(
                          fontSize: 13,
                          color: ctextMuted(context),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: AppIcons.obatMasuk,
                        color: ctextMuted(context),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isToday
                            ? 'Belum ada obat masuk hari ini'
                            : 'Tidak ada obat masuk pada tanggal ini',
                        style: TextStyle(
                          fontSize: 13,
                          color: ctextMuted(context),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: items.length,
                itemBuilder: (ctx, index) {
                  return _buildObatMasukItem(items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildObatMasukItem(ObatMasukModel item) {
    final fotoUri = ObatFotoResolver.resolveStorageUrl(
      fotoKey: item.fotoKey,
      fotoUpdatedAt: item.fotoUpdatedAt,
      fotoUrl: item.fotoUrl,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cdivider(context)),
      ),
      child: Row(
        children: [
          // Foto obat / placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: fotoUri != null
                  ? Image.network(
                      fotoUri.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFotoPlaceholder(),
                    )
                  : _buildFotoPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Nama + jumlah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaObat ?? 'Obat #${item.idObat}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '+ ${item.jumlahMasuk} unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.positive,
                  ),
                ),
              ],
            ),
          ),
          // Popup menu
          PopupMenuButton<String>(
            icon: HugeIcon(
              icon: AppIcons.more,
              color: ctextMuted(context),
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _editObatMasuk(item);
              } else if (value == 'hapus') {
                _deleteObatMasuk(item);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    HugeIcon(icon: AppIcons.edit, color: ctextSecondary(context), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Edit',
                      style: TextStyle(color: ctextSecondary(context)),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hapus',
                child: Row(
                  children: [
                    HugeIcon(icon: AppIcons.hapus, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPlaceholder() {
    return Container(
      color: cdivider(context),
      child: Center(
        child: HugeIcon(
          icon: AppIcons.obat,
          color: ctextMuted(context),
          size: 24,
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ViewToggleBtn extends StatelessWidget {
  const _ViewToggleBtn({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = activeColor;
    final activeFg = Colors.white;

    final inactiveBg = isDark
        ? DarkColors.surface
        : activeColor.withValues(alpha: 0.06);
    final inactiveFg = isDark ? DarkColors.textSecondary : activeColor;
    final inactiveBorder = isDark
        ? DarkColors.borderActive
        : activeColor.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : inactiveBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayItem extends StatelessWidget {
  const _CalendarDayItem({
    required this.dayName,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final String dayName;
  final int date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tealColor = cteal(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = tealColor;
    final activeFg = Colors.white;

    final todayBg = isDark
        ? tealColor.withValues(alpha: 0.15)
        : tealColor.withValues(alpha: 0.08);
    final todayFg = isDark ? Colors.white : tealColor;
    final todayBorder = tealColor.withValues(alpha: 0.4);

    final normalFg = isDark ? DarkColors.textSecondary : ctextMuted(context);

    Color bg;
    Color fg;
    Border? border;

    if (isSelected) {
      bg = activeBg;
      fg = activeFg;
    } else if (isToday) {
      bg = todayBg;
      fg = todayFg;
      border = Border.all(color: todayBorder, width: 1.5);
    } else {
      bg = isDark ? DarkColors.surface : Colors.white;
      fg = normalFg;
      border = Border.all(
        color: isDark ? DarkColors.borderActive : cdivider(context),
        width: 1,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? activeFg.withValues(alpha: 0.7)
                    : fg.withValues(alpha: isSelected ? 1 : 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeFg : fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGridItem extends StatelessWidget {
  const _MonthGridItem({
    required this.label,
    required this.isSelected,
    required this.isCurrentMonth,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tealColor = cteal(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isSelected
        ? tealColor
        : isCurrentMonth
            ? (isDark ? DarkColors.surface : tealColor.withValues(alpha: 0.08))
            : (isDark ? DarkColors.surface : ccardBg(context));
    final fg = isSelected
        ? Colors.white
        : (isDark ? DarkColors.textPrimary : ctextPrimary(context));
    final border = isDark ? DarkColors.borderActive : cdivider(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentMonth && !isSelected ? tealColor.withValues(alpha: 0.4) : border,
            width: isCurrentMonth && !isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected || isCurrentMonth ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
