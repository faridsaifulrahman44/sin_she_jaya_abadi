import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klinik_mobile_app/core/auth/admin_session.dart';
import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/core/feedback/app_feedback.dart';
import 'package:klinik_mobile_app/core/theme/app_theme.dart';
import 'package:klinik_mobile_app/core/ui/app_symbols.dart';
import 'package:klinik_mobile_app/core/utils/formatters.dart';
import 'package:klinik_mobile_app/core/utils/parsers.dart';
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/data/models/pasien_model.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/data/repositories/obat_repository.dart';
import 'package:klinik_mobile_app/data/repositories/pasien_repository.dart';
import 'package:klinik_mobile_app/data/repositories/print_queue_repository.dart';
import 'package:klinik_mobile_app/data/repositories/transaksi_repository.dart';
import 'package:klinik_mobile_app/features/transaksi/usecases/create_transaction_usecase.dart';
import 'package:klinik_mobile_app/pages/transaksi/struk_pembayaran_page.dart';

/// Halaman form tambah transaksi.
class TransaksiFormPage extends StatefulWidget {
  const TransaksiFormPage({super.key});

  static const routeName = '/transaksi-form';

  @override
  State<TransaksiFormPage> createState() => _TransaksiFormPageState();
}

class _TransaksiFormPageState extends State<TransaksiFormPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = TransaksiRepository();
  final _pasienRepository = PasienRepository();
  final _obatRepository = ObatRepository();
  final _printQueueRepository = PrintQueueRepository();
  final _createTransactionUseCase = CreateTransactionUseCase();

  // Filter etalase per tab (F10)
  static const _obatTabEtalases = [Etalase.etalase1, Etalase.etalase2];
  static const _praktekTabEtalases = [Etalase.etalase3];

  // Common state
  bool _loading = false;
  int _activeTabIndex = 0;
  MetodeBayarTransaksi? _selectedMetodeBayar;
  int? _selectedPasienId;
  PasienModel? _selectedPasien;
  final _catatanController = TextEditingController();
  final _durasiController = TextEditingController();

  // Ready Stock mode
  final List<_SelectedObat> _selectedObats = [];
  List<ObatModel> _availableObats = [];

  // Custom mode
  final _totalCustomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _loadAvailableObats(allowedEtalases: _obatTabEtalases);
  }

  void _handleTabChanged() {
    final nextIndex = _tabController.index;
    if (nextIndex == _activeTabIndex) {
      return;
    }

    // Jika ada item di cart, minta konfirmasi sebelum switch tab.
    if (_selectedObats.isNotEmpty) {
      _confirmCartClearBeforeTabSwitch(nextIndex);
      return;
    }

    _applyTabSwitch(nextIndex);
  }

  Future<void> _confirmCartClearBeforeTabSwitch(int nextIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Tab?'),
        content: const Text(
          'Cart akan dikosongkan jika Anda mengganti tab. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ganti Tab'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      // Kembalikan tab controller ke posisi sebelumnya.
      _tabController.index = _activeTabIndex;
      return;
    }

    if (!mounted) return;
    _applyTabSwitch(nextIndex);
  }

  void _applyTabSwitch(int nextIndex) {
    setState(() {
      _activeTabIndex = nextIndex;
      if (nextIndex == 0) {
        _clearSelectedPasien();
      }
      // Kosongkan cart setiap ganti tab.
      _selectedObats.clear();
    });

    final allowedEtalases = nextIndex == 0
        ? _obatTabEtalases
        : _praktekTabEtalases;
    _loadAvailableObats(allowedEtalases: allowedEtalases);
  }

  void _clearSelectedPasien() {
    _selectedPasienId = null;
    _selectedPasien = null;
  }

  Future<void> _loadAvailableObats({List<Etalase>? allowedEtalases}) async {
    try {
      setState(() => _loading = true);

      // F10: pakai filter etalase jika diberikan, fallback ke getObatReadyStock.
      final obats = allowedEtalases != null
          ? await _obatRepository.getObatsByEtalase(etalases: allowedEtalases)
          : await _repository.getObatReadyStock();

      if (mounted) {
        setState(() {
          _availableObats = obats;
          _loading = false;
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        AppFeedback.showError(context, error, stackTrace);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _catatanController.dispose();
    _durasiController.dispose();
    _totalCustomController.dispose();
    super.dispose();
  }

  double get _totalReadyStock =>
      _selectedObats.fold(0.0, (sum, o) => sum + o.subtotal);

  Future<void> _saveTransaksi() async {
    // Validation
    final isReadyStock = _tabController.index == 0;

    if (_selectedMetodeBayar == null) {
      _showError('Pilih metode pembayaran');
      return;
    }

    if (isReadyStock) {
      if (_selectedObats.isEmpty) {
        _showError('Pilih minimal 1 obat');
        return;
      }
      if (_selectedObats.any((o) => o.jumlah <= 0)) {
        _showError('Jumlah obat harus lebih dari 0');
        return;
      }
      // F10: validasi etalase — semua item harus dari etalase yang diizinkan
      // untuk tab aktif (Obat = 1&2, Praktek = 3).
      final allowedEtalases = _obatTabEtalases;
      final offenders = _selectedObats
          .where((o) => !allowedEtalases.contains(o.obat.etalase))
          .map((o) => o.obat.namaObat)
          .toList();
      if (offenders.isNotEmpty) {
        _showError(
          'Item berikut bukan dari Etalase 1/2: ${offenders.join(', ')}',
        );
        return;
      }
    } else {
      // Tab Praktek — tidak boleh ada item obat (hanya transaksi nominal).
      if (_selectedObats.isNotEmpty) {
        _showError(
          'Transaksi Praktek tidak boleh memiliki item obat. '
          'Kosongkan cart terlebih dahulu.',
        );
        return;
      }
      if (_selectedPasienId == null) {
        _showError('Pilih pasien terlebih dahulu untuk transaksi praktek.');
        return;
      }
      final totalCustom = parseDouble(_totalCustomController.text, fallback: 0);
      if (totalCustom <= 0) {
        _showError('Total transaksi harus lebih dari 0');
        return;
      }
    }

    try {
      setState(() => _loading = true);

      final idAdmin = await AdminSession.getCurrentId();
      final now = DateTime.now();
      final jenis = isReadyStock
          ? JenisTransaksi.obatReadyStock
          : JenisTransaksi.praktekCustom;
      final total = isReadyStock
          ? _totalReadyStock
          : parseDouble(_totalCustomController.text, fallback: 0);
      final durasi = parseInt(_durasiController.text);

      final transaksi = TransaksiModel(
        idTransaksi: 0, // placeholder, will be set by DB
        tanggal: now,
        jenisTransaksi: jenis,
        total: total,
        metodeBayar: _selectedMetodeBayar,
        idPasien: isReadyStock ? null : _selectedPasienId,
        keterangan:
            _catatanController.text.isEmpty ? null : _catatanController.text,
        durasiHarian: durasi > 0 ? durasi : null,
        idAdmin: idAdmin,
      );

      // Build items for ready stock
      final items = _selectedObats
          .map((o) => TransaksiItemModel(
                idItem: 0,
                idTransaksi: 0,
                idObat: o.obat.idObat,
                namaObat: o.obat.namaObat,
                jumlah: o.jumlah,
                hargaSatuan: o.hargaJual,
                subtotal: o.subtotal,
                satuanTerjual: o.satuanTerjual,
                idAdmin: idAdmin,
              ))
          .toList();

      // Save and get inserted transaction with ID
      final savedTransaksi = await _createTransactionUseCase.execute(
        transaksi: transaksi,
        items: items,
        idAdmin: idAdmin,
      );

      // F9: enqueue print job (best-effort, jangan block simpan jika gagal)
      try {
        await _printQueueRepository.enqueue(
          idTransaksi: savedTransaksi.idTransaksi,
        );
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Print queue enqueue failed (non-fatal): $e');
      }

      if (mounted) {
        final selectedNamaPasien =
            isReadyStock ? null : _selectedPasien?.namaPasien;

        String? namaAdmin;
        try {
          namaAdmin = await _repository.getNamaAdminById(idAdmin);
        } catch (_) {
          namaAdmin = null;
        }

        if (!mounted) return;

        final receiptItems = items
            .map((item) => TransaksiItemModel(
                  idItem: item.idItem,
                  idTransaksi: savedTransaksi.idTransaksi,
                  idObat: item.idObat,
                  namaObat: item.namaObat,
                  jumlah: item.jumlah,
                  hargaSatuan: item.hargaSatuan,
                  subtotal: item.subtotal,
                  idAdmin: item.idAdmin,
                  satuanTerjual: item.satuanTerjual,
                ))
            .toList(growable: false);

        // Show success message first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaksi berhasil disimpan'),
            backgroundColor: csuccess(context),
          ),
        );

        // Navigate to receipt page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StrukPembayaranPage(
              idTransaksi: savedTransaksi.idTransaksi,
              initialTransaksi: savedTransaksi,
              initialItems: receiptItems,
              initialNamaPasien: selectedNamaPasien,
              initialNamaAdmin: namaAdmin,
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        AppFeedback.showError(context, error, stackTrace);
      }
    }
  }

  void _showError(String msg) {
    AppFeedback.showError(context, ValidationException(msg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Tambah Transaksi',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cteal(context),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Obat'),
            Tab(text: 'Praktek'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReadyStockTab(),
                      _buildCustomTab(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildReadyStockTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // F10: Filter indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: ctextSecondary(context)),
              const SizedBox(width: 4),
              Text(
                _activeTabIndex == 0
                    ? 'Menampilkan: Etalase 1 & 2'
                    : 'Menampilkan: Etalase 3',
                style: TextStyle(
                  fontSize: 12,
                  color: ctextSecondary(context),
                ),
              ),
            ],
          ),
        ),
        // Selected items
        if (_selectedObats.isNotEmpty) ...[
          Text(
            'Item Terpilih',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          ..._selectedObats.map((o) => _buildSelectedObatItem(o)),
          const Divider(height: 24),
        ],

        // Add item button
        OutlinedButton.icon(
          onPressed: _showAddObatDialog,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Obat'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cteal(context),
            side: BorderSide(color: cteal(context)),
          ),
        ),

        const SizedBox(height: 16),

        // Total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cteal(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ctextPrimary(context),
                ),
              ),
              Text(
                rupiah(_totalReadyStock),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cteal(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedObatItem(_SelectedObat selected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.obat.namaObat,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${selected.jumlah} ${selected.satuanTerjual} x ${rupiah(selected.hargaJual)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: ctextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              rupiah(selected.subtotal),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cprimary(context),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedObats.remove(selected);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total input
        Text(
          'Total Transaksi Praktek',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ctextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _totalCustomController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: 'Rp ',
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Durasi (optional)
        Text(
          'Durasi Obat (hari) - Opsional',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ctextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durasiController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Misal: 5, 10',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Catatan
        Text(
          'Catatan - Opsional',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ctextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _catatanController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan jika diperlukan',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isReadyStock = _activeTabIndex == 0;
    final total = isReadyStock
        ? _totalReadyStock
        : parseDouble(_totalCustomController.text, fallback: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Metode Bayar
          Row(
            children: [
              Text(
                'Metode Bayar:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ctextPrimary(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<MetodeBayarTransaksi>(
                  emptySelectionAllowed: true,
                  segments: const [
                    ButtonSegment(
                      value: MetodeBayarTransaksi.cash,
                      label: Text('Tunai'),
                      icon: Icon(AppSymbols.tunai, size: 18),
                    ),
                    ButtonSegment(
                      value: MetodeBayarTransaksi.qris,
                      label: Text('QRIS'),
                      icon: Icon(AppSymbols.qris, size: 18),
                    ),
                  ],
                  selected: _selectedMetodeBayar != null
                      ? {_selectedMetodeBayar!}
                      : {},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedMetodeBayar = selected.firstOrNull;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (!isReadyStock) ...[
            Row(
              children: [
                Text(
                  'Pasien:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildPasienPickerField()),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Total display & Save button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Transaksi',
                      style: TextStyle(
                        fontSize: 12,
                        color: ctextSecondary(context),
                      ),
                    ),
                    Text(
                      rupiah(total),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cteal(context),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _saveTransaksi,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cteal(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasienPickerField() {
    final selectedPasien = _selectedPasien;
    final hasSelection = selectedPasien != null;

    return InkWell(
      onTap: _showPasienPickerSheet,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'Tanpa pasien',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: SizedBox(
            width: hasSelection ? 88 : 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSelection)
                  IconButton(
                    tooltip: 'Tanpa pasien',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedPasienId = null;
                        _selectedPasien = null;
                      });
                    },
                  ),
                const Icon(Icons.search),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
        child: Text(
          selectedPasien?.namaPasien ?? 'Tanpa pasien',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                hasSelection ? ctextPrimary(context) : ctextSecondary(context),
            fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Future<void> _showPasienPickerSheet() async {
    final result = await showModalBottomSheet<_PasienPickerResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PasienPickerSheet(
        repository: _pasienRepository,
        selectedPasienId: _selectedPasienId,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPasien = result.pasien;
      _selectedPasienId = result.pasien?.idPasien;
    });
  }

  Future<void> _showAddObatDialog() async {
    // Show bottom sheet to select obat
    final selected = await showModalBottomSheet<_SelectedObat>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ObatPickerSheet(
        availableObats: _availableObats,
        selectedObats: _selectedObats,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedObats.add(selected);
      });
    }
  }
}

class _PasienPickerResult {
  const _PasienPickerResult(this.pasien);

  final PasienModel? pasien;
}

class _PasienPickerSheet extends StatefulWidget {
  const _PasienPickerSheet({
    required this.repository,
    required this.selectedPasienId,
  });

  final PasienRepository repository;
  final int? selectedPasienId;

  @override
  State<_PasienPickerSheet> createState() => _PasienPickerSheetState();
}

class _PasienPickerSheetState extends State<_PasienPickerSheet> {
  static const int _limit = 20;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<PasienModel> _items = const [];
  bool _loading = true;
  String? _errorMessage;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = parseString(value);
    _debounce?.cancel();

    if (query.isNotEmpty && query.length < 2) {
      _requestVersion += 1;
      setState(() {
        _items = const [];
        _loading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        _loadInitial();
      } else {
        _search(query);
      }
    });
  }

  Future<void> _loadInitial() {
    return _loadItems(
      () => widget.repository.getPasienPickerInitial(limit: _limit),
    );
  }

  Future<void> _search(String query) {
    return _loadItems(
      () => widget.repository.searchPasien(query, limit: _limit),
    );
  }

  Future<void> _loadItems(Future<List<PasienModel>> Function() loader) async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final items = await loader();
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }
      setState(() {
        _items = const [];
        _loading = false;
        _errorMessage = 'Gagal memuat pasien. Coba lagi.';
      });
    }
  }

  void _selectPasien(PasienModel? pasien) {
    Navigator.pop(context, _PasienPickerResult(pasien));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final query = parseString(_searchController.text);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: media.size.height * 0.82,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cdivider(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pilih Pasien',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ctextPrimary(context),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, nomor, atau alamat pasien',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: const Text('Tanpa pasien'),
                subtitle: const Text('Simpan transaksi tanpa data pasien'),
                trailing: widget.selectedPasienId == null
                    ? Icon(Icons.check_circle, color: cteal(context))
                    : null,
                onTap: () => _selectPasien(null),
              ),
              const Divider(height: 1),
              Expanded(child: _buildResultList(query)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultList(String query) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: ctextSecondary(context)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  if (query.length >= 2) {
                    _search(query);
                  } else {
                    _loadInitial();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (query.isNotEmpty && query.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ketik minimal 2 karakter untuk mencari pasien.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ctextSecondary(context)),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            query.isEmpty
                ? 'Belum ada pasien untuk ditampilkan.'
                : 'Pasien tidak ditemukan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ctextSecondary(context)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final pasien = _items[index];
        final isSelected = pasien.idPasien == widget.selectedPasienId;
        final detailParts = <String>[
          if (pasien.nomorPasien.isNotEmpty) 'No. ${pasien.nomorPasien}',
          if (pasien.tanggalJanjian != null)
            'Janjian ${formatDateDb(pasien.tanggalJanjian!)}',
          if ((pasien.alamat ?? '').isNotEmpty) pasien.alamat!,
        ];

        return ListTile(
          title: Text(
            pasien.namaPasien,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: detailParts.isEmpty
              ? null
              : Text(
                  detailParts.join(' - '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: cteal(context))
              : null,
          onTap: () => _selectPasien(pasien),
        );
      },
    );
  }
}

/// Model helper for selected obat in form.
class _SelectedObat {
  final ObatModel obat;
  final int jumlah;
  final double hargaJual;
  final String satuanTerjual;

  _SelectedObat({
    required this.obat,
    required this.jumlah,
    required this.hargaJual,
    required this.satuanTerjual,
  });

  double get subtotal => jumlah * hargaJual;
}

/// Bottom sheet to pick obat.
class _ObatPickerSheet extends StatefulWidget {
  final List<ObatModel> availableObats;
  final List<_SelectedObat> selectedObats;

  const _ObatPickerSheet({
    required this.availableObats,
    required this.selectedObats,
  });

  @override
  State<_ObatPickerSheet> createState() => _ObatPickerSheetState();
}

class _ObatPickerSheetState extends State<_ObatPickerSheet> {
  final _searchController = TextEditingController();
  final _jumlahController = TextEditingController(text: '1');
  final _hargaController = TextEditingController();
  List<ObatModel> _filteredObats = [];
  ObatModel? _selectedObat;

  /// ── Ecer Sederhana (FASE 3, 2026-04-27) ───────────────────────────
  /// True saat user memilih mode "Ecer" (satuan_ecer).
  /// False/null = mode utama (satuan_jual).
  bool _ecerMode = false;

  /// Satuan yang sedang aktif — " Utama" atau " Ecer".
  String get _activeSatuanLabel {
    if (_selectedObat == null) return '';
    return _ecerMode
        ? (_selectedObat!.satuanEcer ?? 'Ecer')
        : (_selectedObat!.satuanJual ?? 'Satuan');
  }
  // ─────────────────────────────────────────────────────────────────

  /// Real-time subtotal — di-update saat jumlah/harga berubah.
  double get _liveSubtotal {
    final jumlah = int.tryParse(_jumlahController.text) ?? 0;
    final harga = double.tryParse(_hargaController.text) ?? 0;
    return jumlah * harga;
  }

  @override
  void initState() {
    super.initState();
    _filteredObats = widget.availableObats;
    _jumlahController.addListener(_onInputChanged);
    _hargaController.addListener(_onInputChanged);
  }

  void _onInputChanged() => setState(() {});

  /// Reset state saat obat baru dipilih.
  void _selectObat(ObatModel obat) {
    setState(() {
      _selectedObat = obat;
      _ecerMode = false; // reset ke satuan utama
      _jumlahController.text = '1';

      // ── Auto-fill harga dari Master Obat (FASE 2) ───────────────────
      if (obat.hasHargaJual) {
        _hargaController.text = obat.hargaJual!.toStringAsFixed(0);
      } else {
        _hargaController.text = '0';
      }
    });
  }

  /// Toggle antara mode utama dan ecer. Update harga + satuan.
  void _toggleSatuan(bool isEcer) {
    if (_selectedObat == null) return;
    setState(() {
      _ecerMode = isEcer;
      if (isEcer) {
        // Gunakan harga ecer
        if (_selectedObat!.hasEceran) {
          _hargaController.text = _selectedObat!.hargaEcer!.toStringAsFixed(0);
        }
      } else {
        // Kembali ke harga utama
        if (_selectedObat!.hasHargaJual) {
          _hargaController.text = _selectedObat!.hargaJual!.toStringAsFixed(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jumlahController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredObats = widget.availableObats;
      } else {
        _filteredObats = widget.availableObats
            .where(
                (o) => o.namaObat.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedObat;
    final canEcer = selected?.hasEceran ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Obat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ctextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),

              // Search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari obat...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _filter,
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredObats.length,
                  itemBuilder: (context, index) {
                    final obat = _filteredObats[index];
                    final isSelected = selected?.idObat == obat.idObat;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected
                          ? cteal(context).withValues(alpha: 0.1)
                          : null,
                      child: ListTile(
                        title: Text(obat.namaObat),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stok: ${obat.stokSaatIni} | Etalase: ${obat.etalase.label}',
                            ),
                            if (obat.hasHargaJual) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${rupiah(obat.hargaJual!)} / ${obat.satuanJual ?? '-'}'
                                '${obat.hasEceran ? '   |   Ecer: ${rupiah(obat.hargaEcer!)} / ${obat.satuanEcer}' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cteal(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: cteal(context))
                            : null,
                        onTap: () => _selectObat(obat),
                      ),
                    );
                  },
                ),
              ),

              // ── Controls saat obat dipilih (FASE 3 — Ecer) ──────────────
              if (selected != null) ...[
                const Divider(),

                // ── Ecer toggle (FASE 3) ───────────────────────────────────
                // Tampilkan hanya jika obat bisa ecer
                if (canEcer) ...[
                  _buildLabel('Satuan Jual', context),
                  const SizedBox(height: 6),
                  _SatuanToggle(
                    satuanUtama: selected.satuanJual ?? 'Botol',
                    satuanEcer: selected.satuanEcer ?? 'Ecer',
                    hargaUtama: selected.hargaJual!,
                    hargaEcer: selected.hargaEcer!,
                    isEcer: _ecerMode,
                    onChanged: _toggleSatuan,
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Jumlah + Harga ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah',
                          suffixText: canEcer ? _activeSatuanLabel : null,
                          suffixStyle: TextStyle(
                            color: ctextSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _hargaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga / $_activeSatuanLabel',
                          prefixText: 'Rp ',
                          helperText: selected.hasHargaJual
                              ? (_ecerMode ? 'Harga ecer' : 'Dari Master Obat')
                              : 'Input manual',
                          helperStyle: TextStyle(
                            fontSize: 10,
                            color: ctextSecondary(context),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                // ── Real-time subtotal ──────────────────────────────────────
                if (_liveSubtotal > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cteal(context).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ctextSecondary(context),
                          ),
                        ),
                        Text(
                          rupiah(_liveSubtotal),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cteal(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Tombol Tambah ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final jumlah = int.tryParse(_jumlahController.text) ?? 1;
                      final harga = double.tryParse(_hargaController.text) ?? 0;

                      if (jumlah <= 0 || harga <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Jumlah dan harga harus lebih dari 0'),
                          ),
                        );
                        return;
                      }

                      // Stock check: untuk ecer, stok tidak dibatasi
                      // (eceran tidak track per-unit stock)
                      if (!_ecerMode && jumlah > (selected.stokSaatIni)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Stok tidak cukup. Tersedia: ${selected.stokSaatIni}'),
                          ),
                        );
                        return;
                      }

                      // ── Satuan terjual final (FASE 3) ─────────────────────
                      String satuanFinal;
                      if (canEcer) {
                        satuanFinal = _ecerMode
                            ? (selected.satuanEcer ?? 'Ecer')
                            : (selected.satuanJual ?? 'Satuan');
                      } else {
                        satuanFinal = selected.satuanJual ?? 'Satuan';
                      }

                      Navigator.pop(
                        context,
                        _SelectedObat(
                          obat: selected,
                          jumlah: jumlah,
                          hargaJual: harga,
                          satuanTerjual: satuanFinal,
                        ),
                      );
                    },
                    child: const Text('Tambah'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ctextSecondary(context),
      ),
    );
  }
}

/// Widget toggle satuan jual — pilih antara satuan utama dan ecer.
/// (FASE 3: Ecer Sederhana, 2026-04-27)
class _SatuanToggle extends StatelessWidget {
  const _SatuanToggle({
    required this.satuanUtama,
    required this.satuanEcer,
    required this.hargaUtama,
    required this.hargaEcer,
    required this.isEcer,
    required this.onChanged,
  });

  final String satuanUtama;
  final String satuanEcer;
  final num hargaUtama;
  final num hargaEcer;
  final bool isEcer;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SatuanOption(
            label: satuanUtama,
            harga: hargaUtama,
            isSelected: !isEcer,
            color: cteal(context),
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SatuanOption(
            label: satuanEcer,
            harga: hargaEcer,
            isSelected: isEcer,
            color: csuccess(context),
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _SatuanOption extends StatelessWidget {
  const _SatuanOption({
    required this.label,
    required this.harga,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final num harga;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : ccardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : cdivider(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : ctextPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rupiah(harga),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white70 : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
