import 'package:flutter/material.dart';

import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../data/models/obat_model.dart';
import '../data/models/sinkronisasi_stok_model.dart';
import '../data/repositories/obat_repository.dart';
import '../features/sinkronisasi_stok/sinkronisasi_stok_calc.dart';
import '../features/stok/usecases/sync_stock_usecase.dart';
import '../widgets/page_header.dart';
import 'sinkronisasi_stok/widgets/sinkronisasi_stok_panels.dart';

class SinkronisasiStokFormPage extends StatefulWidget {
  const SinkronisasiStokFormPage({super.key});

  static const routeName = '/sinkronisasi-stok-form';
  // backward-compat legacy alias
  static const routeNameLegacy = '/stock-opname-form';

  @override
  State<SinkronisasiStokFormPage> createState() =>
      _SinkronisasiStokFormPageState();
}

class _SinkronisasiStokFormPageState extends State<SinkronisasiStokFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SyncStockUseCase _syncStockUseCase = SyncStockUseCase();
  final ObatRepository _obatRepo = ObatRepository();
  final TextEditingController _stokFisikController = TextEditingController();
  final TextEditingController _alasanController = TextEditingController();
  bool _loading = false;
  bool _initialized = false;
  bool _isEdit = false;
  int? _idOpname;
  int? _selectedIdObat;
  DateTime _selectedDate = DateTime.now();
  String _selectedNamaObat = '';
  int _stokSistem = 0;
  List<ObatModel> _obatList = [];
  late Future<List<ObatModel>> _obatFuture;

  int get _stokFisik {
    return int.tryParse(_stokFisikController.text.trim()) ?? 0;
  }

  int get _selisih => _stokFisik - _stokSistem;
  String get _selisihLabel => sinkronisasiStokSelisihLabel(_selisih);

  @override
  void initState() {
    super.initState();
    _obatFuture = _obatRepo.getObat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is SinkronisasiStokModel) {
      _isEdit = true;
      _idOpname = args.idOpname;
      _selectedIdObat = args.idObat;
      _selectedDate = args.tanggalOpname;
      _stokSistem = args.stokSistem;
      _stokFisikController.text = args.stokFisik.toString();
      _alasanController.text = args.alasanPenyesuaian ?? '';
      return;
    }

    if (args is Map<String, dynamic>) {
      final item = SinkronisasiStokModel.fromMap(args);
      _isEdit = true;
      _idOpname = item.idOpname;
      _selectedIdObat = item.idObat;
      _selectedDate = item.tanggalOpname;
      _stokSistem = item.stokSistem;
      _stokFisikController.text = item.stokFisik.toString();
      _alasanController.text = item.alasanPenyesuaian ?? '';
      return;
    }
  }

  @override
  void dispose() {
    _stokFisikController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: cteal(ctx)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onObatChanged(int? idObat) {
    setState(() {
      _selectedIdObat = idObat;
      _stokFisikController.text = '';
      _stokSistem = 0;
      _selectedNamaObat = '';
      if (idObat != null) {
        final selected = _obatList.where((o) => o.idObat == idObat).toList();
        if (selected.isNotEmpty) {
          _selectedNamaObat = selected.first.namaObat;
          _stokSistem = selected.first.stokSaatIni;
          _stokFisikController.text = selected.first.stokSaatIni.toString();
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIdObat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih obat terlebih dahulu')),
      );
      return;
    }

    try {
      setState(() => _loading = true);
      final stokFisik = int.parse(_stokFisikController.text.trim());

      await _syncStockUseCase.execute(
        idOpname: _idOpname,
        idObat: _selectedIdObat!,
        tanggalOpname: _selectedDate,
        stokSistem: _stokSistem,
        stokFisik: stokFisik,
        idAdmin: await AdminSession.getCurrentId(),
        alasanPenyesuaian: _alasanController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Sinkronisasi berhasil diperbarui'
                : 'Stok berhasil disinkronkan.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.toMessage(error, stackTrace))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validatePositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    if (int.tryParse(value.trim()) == null) return 'Harus berupa angka bulat';
    if (int.parse(value.trim()) < 0) return 'Tidak boleh negatif';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Sinkronisasi Stok' : 'Sinkronisasi Stok Baru'),
        backgroundColor: cteal(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: FutureBuilder<List<ObatModel>>(
        future: _obatFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: cteal(ctx)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  AppErrorMapper.toMessage(
                    snapshot.error!,
                    snapshot.stackTrace,
                  ),
                ),
              ),
            );
          }

          _obatList = snapshot.data ?? [];

          // Resolve nama obat for edit mode
          if (_isEdit && _selectedIdObat != null && _selectedNamaObat.isEmpty) {
            final selected =
                _obatList.where((o) => o.idObat == _selectedIdObat).toList();
            if (selected.isNotEmpty) {
              _selectedNamaObat = selected.first.namaObat;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                      _isEdit ? 'Edit Sinkronisasi Stok' : 'Sinkronisasi Stok Baru'),
                  const SizedBox(height: AppSpacing.lg),

                  // Tanggal
                  Text(
                    'Tanggal Sinkronisasi',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ctextSecondary(ctx)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        suffixIcon: Icon(
                            AppSymbols.calendar03, color: ctextMuted(ctx)),
                      ),
                      child: Text(asDate(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Obat dropdown
                  Text(
                    'Obat',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ctextSecondary(ctx)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedIdObat,
                    decoration: InputDecoration(
                      hintText: 'Pilih obat yang ingin disinkronkan',
                      filled: true,
                      fillColor: ccardBg(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _obatList.map((obat) {
                      return DropdownMenuItem<int>(
                        value: obat.idObat,
                        child: Text(
                          '${obat.namaObat} - Etalase ${obat.etalase.label}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Pilih obat' : null,
                    onChanged: _isEdit ? null : _onObatChanged,
                  ),
                  const SizedBox(height: 18),

                  StockSystemInfoCard(
                    stokSistem: _stokSistem,
                    isEdit: _isEdit,
                    selectedNamaObat: _selectedNamaObat,
                  ),
                  const SizedBox(height: 18),

                  // Stok Fisik (input)
                  Text(
                    'Stok Fisik (Aktual)',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ctextSecondary(ctx)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _stokFisikController,
                    keyboardType: TextInputType.number,
                    validator: _validatePositiveInt,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah stok fisik yang dihitung',
                      filled: true,
                      fillColor: ccardBg(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Selisih preview
                  if (_selectedIdObat != null) ...[
                    StockDifferencePreviewCard(
                      selisih: _selisih,
                      selisihLabel: _selisihLabel,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Alasan penyesuaian
                  Text(
                    'Alasan Penyesuaian',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ctextSecondary(ctx)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _alasanController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Barang jatuh, rusak, hitungan ulang...',
                      filled: true,
                      fillColor: ccardBg(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '* Stok sistem akan diperbarui sesuai stok fisik yang dimasukkan setelah disimpan.',
                    style: TextStyle(
                      color: ctextMuted(ctx),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cteal(context),
                        foregroundColor: conPrimary(context),
                      ),
                      onPressed: _loading ? null : _save,
                      child: Text(
                        _loading
                            ? 'Menyimpan...'
                            : (_isEdit
                                ? 'Perbarui Sinkronisasi'
                                : 'Sinkronkan Stok'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
