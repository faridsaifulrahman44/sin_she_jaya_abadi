import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../data/models/obat_keluar_item_model.dart';
import '../data/models/obat_keluar_model.dart';
import '../data/models/obat_model.dart';
import '../data/repositories/obat_keluar_repository.dart';
import '../data/repositories/obat_repository.dart';
import '../features/obat_keluar/obat_keluar_etalase_sync.dart';
import '../features/obat_keluar/obat_keluar_form_entry.dart';
import '../widgets/page_header.dart';
import 'obat_keluar/widgets/obat_keluar_item_row.dart';

class ObatKeluarFormPage extends StatefulWidget {
  const ObatKeluarFormPage({super.key});

  static const routeName = '/obat-keluar-form';

  @override
  State<ObatKeluarFormPage> createState() => _ObatKeluarFormPageState();
}

class _ObatKeluarFormPageState extends State<ObatKeluarFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ObatKeluarRepository();
  final _obatRepo = ObatRepository();
  final _keteranganCtrl = TextEditingController();

  bool _loading = false;
  bool _initialized = false;
  int? _idTerjual;
  DateTime _selectedDate = DateTime.now();
  final List<ObatKeluarFormEntry> _entries = [];

  late Future<List<ObatModel>> _obatFuture;
  List<ObatModel> _obatList = [];

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

    if (args is ObatKeluarModel) {
      _idTerjual = args.idTerjual;
      _selectedDate = args.tanggalTerjual;
      _keteranganCtrl.text = args.keterangan ?? '';
      _loadItemsForEdit(args.idTerjual);
      return;
    }

    if (args is Map<String, dynamic>) {
      final item = ObatKeluarModel.fromMap(args);
      _idTerjual = item.idTerjual;
      _selectedDate = item.tanggalTerjual;
      _keteranganCtrl.text = item.keterangan ?? '';
      _loadItemsForEdit(item.idTerjual);
      return;
    }

    if (args is DateTime) {
      _selectedDate = args;
      _entries.add(ObatKeluarFormEntry());
      return;
    }

    if (args is String && args.isNotEmpty) {
      _selectedDate = DateTime.tryParse(args) ?? _selectedDate;
    }
    _entries.add(ObatKeluarFormEntry());
  }

  Future<void> _loadItemsForEdit(int idTerjual) async {
    try {
      final full = await _repo.getObatKeluarWithItems(idTerjual);
      if (!mounted) return;
      setState(() {
        for (final item in full.items) {
          _entries.add(ObatKeluarFormEntry(
            idItem: item.idItem,
            idObat: item.idObat > 0 ? item.idObat : null,
            jumlah: item.jumlah,
            hargaSatuan: item.hargaSatuan,
          ));
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _entries.add(ObatKeluarFormEntry()));
    }
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  double get _grandTotal => _entries.fold(0.0, (sum, e) => sum + e.subtotal);

  void _addItem() {
    setState(() => _entries.add(ObatKeluarFormEntry()));
  }

  void _removeItem(int index) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi tiap item
    for (var i = 0; i < _entries.length; i++) {
      final err = _entries[i].validate();
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Item ${i + 1}: $err'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Ambil daftar obat terakhir untuk validasi stok (paling fresh)
    final sourceObat =
        _obatList.isNotEmpty ? _obatList : await _obatRepo.getObat();
    if (!mounted) return;

    // Validasi oversell UI (ecer tidak dibatasi stok FASE 3)
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final selectedObat =
          sourceObat.where((o) => o.idObat == entry.idObat).firstOrNull;
      final isEcer = entry.satuanTerjual != null &&
          selectedObat?.bisaEcer == true &&
          selectedObat?.satuanEcer == entry.satuanTerjual;
      final stockErr = entry.validateStock(selectedObat, isEcer: isEcer);
      if (stockErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item ${i + 1}: $stockErr'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      setState(() => _loading = true);

      final items = _entries
          .map((e) => ObatKeluarItemModel(
                idItem: e.idItem,
                idTerjual: _idTerjual ?? 0,
                idObat: e.idObat!,
                jumlah: e.jumlah!,
                hargaSatuan: e.hargaSatuan!,
                subtotal: e.subtotal,
              ))
          .toList();
      final headerNoEtalase = ObatKeluarEtalaseSync.resolveHeaderNoEtalase(
        entries: _entries,
        obatList: sourceObat,
      );

      if (_idTerjual == null) {
        await _repo.insertObatKeluar(
          tanggalTerjual: _selectedDate,
          noEtalase: headerNoEtalase,
          items: items,
          keterangan: _keteranganCtrl.text.trim().isEmpty
              ? null
              : _keteranganCtrl.text.trim(),
          idAdmin: await AdminSession.getCurrentId(),
        );
      } else {
        await _repo.updateObatKeluar(
          idTerjual: _idTerjual!,
          tanggalTerjual: _selectedDate,
          noEtalase: headerNoEtalase,
          items: items,
          keterangan: _keteranganCtrl.text.trim().isEmpty
              ? null
              : _keteranganCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = _idTerjual != null;

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Pengeluaran Stok' : 'Tambah Pengeluaran Stok',
        ),
        backgroundColor: cobatAmber(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: FutureBuilder<List<ObatModel>>(
        future: _obatFuture,
        builder: (ctx, snapshot) {
          final obatList = snapshot.data ?? [];
          _obatList = obatList;
          final headerNoEtalase = ObatKeluarEtalaseSync.resolveHeaderNoEtalase(
            entries: _entries,
            obatList: obatList,
          );
          final headerEtalaseLabel =
              ObatKeluarEtalaseSync.resolveHeaderDisplayLabel(
            entries: _entries,
            obatList: obatList,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    isEdit
                        ? 'Edit Pengeluaran Stok'
                        : 'Tambah Pengeluaran Stok',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan fitur ini untuk obat rusak, kedaluwarsa, hilang, dipakai internal, atau koreksi stok keluar. Untuk penjualan obat, gunakan Transaksi Obat. Untuk layanan konsultasi/tindakan, gunakan Transaksi Praktek.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ctextSecondary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tanggal Pengeluaran: ${asDate(_selectedDate)}',
                    style: TextStyle(
                      color: ctextSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Etalase Header (Otomatis)'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: ccardBg(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                            icon: AppIcons.etalase,
                            size: 18,
                            color: ctextMuted(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            headerEtalaseLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ctextPrimary(context),
                            ),
                          ),
                        ),
                        if (headerNoEtalase == null &&
                            headerEtalaseLabel == 'Campuran')
                          Text(
                            '(null)',
                            style: TextStyle(
                              fontSize: 11,
                              color: ctextMuted(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nilai header otomatis dari item. Jika beda etalase, header disimpan null.',
                    style: TextStyle(
                      fontSize: 11,
                      color: ctextMuted(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Keterangan (opsional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _keteranganCtrl,
                    maxLines: 2,
                    decoration: _inputDecoration('Catatan pengeluaran stok...'),
                  ),
                  const SizedBox(height: 24),

                  // Items section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Pengeluaran Stok',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ctextPrimary(context),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: HugeIcon(
                            icon: AppIcons.tambahCircle,
                            color: cwarning(context),
                            size: 18),
                        label: Text(
                          'Tambah Item',
                          style: TextStyle(color: cwarning(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_entries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ccardBg(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tekan "Tambah Item" untuk menambah obat.',
                        style: TextStyle(color: ctextMuted(context)),
                      ),
                    ),

                  ...List.generate(
                    _entries.length,
                    (i) => ObatKeluarItemRow(
                      index: i,
                      entry: _entries[i],
                      totalEntries: _entries.length,
                      obatList: obatList,
                      onRemove: () => _removeItem(i),
                      onObatChanged: (v) {
                        setState(() => _entries[i].idObat = v);
                        // ── Auto-fill harga dari Master Obat + satuan (FASE 2+3) ────
                        if (v != null) {
                          final selected =
                              _obatList.where((o) => o.idObat == v).firstOrNull;
                          if (selected != null) {
                            if (selected.hasHargaJual) {
                              _entries[i].hargaSatuan =
                                  selected.hargaJual!.toDouble();
                              _entries[i].satuanTerjual =
                                  selected.satuanJual ?? 'Satuan';
                            } else {
                              _entries[i].hargaSatuan = null;
                              _entries[i].satuanTerjual = null;
                            }
                          }
                        }
                      },
                      onJumlahChanged: (value) {
                        setState(
                            () => _entries[i].jumlah = int.tryParse(value));
                      },
                      onHargaChanged: (value) {
                        setState(() =>
                            _entries[i].hargaSatuan = double.tryParse(value));
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Grand total
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cwarning(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cwarning(context).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Nominal',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ctextPrimary(context),
                          ),
                        ),
                        Text(
                          rupiah(_grandTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cwarning(context),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cobatAmber(context),
                        foregroundColor: conPrimary(context),
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ctextSecondary(context),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: ccardBg(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
