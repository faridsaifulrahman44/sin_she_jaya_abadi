import 'package:flutter/material.dart';

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/obat_masuk_model.dart';
import '../data/models/obat_model.dart';
import '../data/repositories/obat_repository.dart';
import '../features/stok/services/stock_service.dart';
import '../widgets/page_header.dart';

class ObatMasukFormPage extends StatefulWidget {
  const ObatMasukFormPage({super.key});

  static const routeName = '/obat-masuk-form';

  @override
  State<ObatMasukFormPage> createState() => _ObatMasukFormPageState();
}

class _ObatMasukFormPageState extends State<ObatMasukFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final StockService _stockService = StockService();
  final ObatRepository _obatRepo = ObatRepository();
  final TextEditingController _jumlahController = TextEditingController();
  bool _loading = false;
  bool _initialized = false;
  int? _idMasuk;
  int? _selectedIdObat;
  DateTime _selectedDate = DateTime.now();
  String _selectedNamaObat = '';
  List<ObatModel> _obatList = [];
  late Future<List<ObatModel>> _obatFuture;

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

    if (args is ObatMasukModel) {
      _idMasuk = args.idMasuk;
      _selectedIdObat = args.idObat;
      _selectedDate = args.tanggalMasuk;
      _jumlahController.text = args.jumlahMasuk.toString();
      return;
    }

    if (args is Map<String, dynamic>) {
      final item = ObatMasukModel.fromMap(args);
      _idMasuk = item.idMasuk;
      _selectedIdObat = item.idObat;
      _selectedDate = item.tanggalMasuk;
      _jumlahController.text = item.jumlahMasuk.toString();
      return;
    }

    if (args is DateTime) {
      _selectedDate = args;
      return;
    }

    if (args is String && args.isNotEmpty) {
      _selectedDate = DateTime.tryParse(args) ?? _selectedDate;
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
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
      final jumlah = int.parse(_jumlahController.text.trim());

      if (_idMasuk == null) {
        await _stockService.stokMasuk(
          idObat: _selectedIdObat!,
          tanggalMasuk: _selectedDate,
          jumlahMasuk: jumlah,
          idAdmin: await AdminSession.getCurrentId(),
        );
      } else {
        await _stockService.updateStokMasuk(
          idMasuk: _idMasuk!,
          idObat: _selectedIdObat!,
          tanggalMasuk: _selectedDate,
          jumlahMasuk: jumlah,
          idAdmin: await AdminSession.getCurrentId(),
        );
      }

      if (!mounted) return;
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
    final n = int.parse(value.trim());
    if (n <= 0) return 'Harus lebih dari 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _idMasuk != null;

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Obat Masuk' : 'Tambah Obat Masuk'),
        backgroundColor: cobatGreen(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: FutureBuilder<List<ObatModel>>(
        future: _obatFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cteal(ctx)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(AppErrorMapper.toMessage(
                  snapshot.error!,
                  snapshot.stackTrace,
                )),
              ),
            );
          }

          _obatList = snapshot.data ?? [];

          if (_selectedIdObat != null && _selectedNamaObat.isEmpty) {
            final selected =
                _obatList.where((o) => o.idObat == _selectedIdObat).toList();
            if (selected.isNotEmpty) {
              _selectedNamaObat = selected.first.namaObat;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(isEdit ? 'Edit Obat Masuk' : 'Tambah Obat Masuk'),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal: ${asDate(_selectedDate)}',
                    style: TextStyle(
                      color: ctextSecondary(ctx),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Obat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ctextSecondary(ctx),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedIdObat,
                    decoration: InputDecoration(
                      hintText: 'Pilih obat',
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
                          '${obat.namaObat} (Stok: ${obat.stokSaatIni})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) return 'Wajib diisi';
                      return null;
                    },
                    onChanged: isEdit
                        ? null
                        : (value) {
                            setState(() {
                              _selectedIdObat = value;
                              final selected = _obatList
                                  .where((o) => o.idObat == value)
                                  .toList();
                              _selectedNamaObat = selected.isNotEmpty
                                  ? selected.first.namaObat
                                  : '';
                            });
                          },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Jumlah Masuk',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ctextSecondary(ctx),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    validator: _validatePositiveInt,
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah unit yang masuk',
                      filled: true,
                      fillColor: ccardBg(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cteal(ctx),
                        foregroundColor: conPrimary(ctx),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _save,
                      child: Text(
                        _loading
                            ? 'Menyimpan...'
                            : (isEdit ? 'Update' : 'Simpan'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
