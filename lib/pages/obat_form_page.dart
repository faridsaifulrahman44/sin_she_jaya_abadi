import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/error/app_error_mapper.dart';
import '../core/services/foto_obat_upload_service.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../data/models/obat_etalase.dart';
import '../data/models/obat_model.dart';
import '../data/repositories/obat_repository.dart';
import '../widgets/page_header.dart';

class ObatFormPage extends StatefulWidget {
  const ObatFormPage({super.key});

  static const routeName = '/obat-form';

  @override
  State<ObatFormPage> createState() => _ObatFormPageState();
}

class _ObatFormPageState extends State<ObatFormPage> {
  static const int _maxFotoSizeBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedFotoExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ObatRepository _repo = ObatRepository();
  final FotoObatUploadService _uploadService = FotoObatUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _stokSaatIniController = TextEditingController();
  final TextEditingController _stokMinimumController = TextEditingController();
  final TextEditingController _satuanController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  // ── Harga Source of Truth (FASE 1, 2026-04-27) ──────────────────────────
  final TextEditingController _hargaJualController = TextEditingController();
  final TextEditingController _satuanJualController = TextEditingController();
  bool _bisaEcer = false;
  final TextEditingController _hargaEcerController = TextEditingController();
  final TextEditingController _satuanEcerController = TextEditingController();
  // ─────────────────────────────────────────────────────────────────────
  bool _loading = false;
  bool _initialized = false;
  bool _isEdit = false;
  int? _idObat;
  Etalase _etalase = Etalase.etalase1;
  Uint8List? _selectedFotoBytes;
  String? _selectedFotoFileName;
  // ── Foto Obat — Source of Truth (FASE 2, 2026-05-12) ──────────────────
  // Upload fix: uploadFotoObat() sekarang menulis ke foto_key + foto_updated_at.
  // Field ini sudah aktif dan dipakai resolver saat render foto obat.
  String? _existingFotoKey;
  DateTime? _existingFotoUpdatedAt;
  String? _existingFotoUrl;
  bool _hapusFoto = false;
  bool _processingFoto = false;
  String? _fotoCompressionInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final obat = args is ObatModel
        ? args
        : args is Map<String, dynamic>
            ? ObatModel.fromMap(args)
            : null;

    if (obat != null) {
      _isEdit = true;
      _idObat = obat.idObat;
      _namaController.text = obat.namaObat;
      _stokSaatIniController.text = obat.stokSaatIni.toString();
      _stokMinimumController.text = obat.stokMinimum.toString();
      _etalase = obat.etalase;
      _satuanController.text = obat.satuan ?? '';
      _keteranganController.text = obat.keterangan ?? '';
      _existingFotoKey = obat.fotoKey;
      _existingFotoUpdatedAt = obat.fotoUpdatedAt;
      _existingFotoUrl = obat.fotoUrl;
      // ── Harga (FASE 1, 2026-04-27) ──────────────────────────────────
      if (obat.hargaJual != null) {
        _hargaJualController.text = obat.hargaJual!.toStringAsFixed(0);
      }
      _satuanJualController.text = obat.satuanJual ?? '';
      _bisaEcer = obat.bisaEcer;
      if (obat.hargaEcer != null) {
        _hargaEcerController.text = obat.hargaEcer!.toStringAsFixed(0);
      }
      _satuanEcerController.text = obat.satuanEcer ?? '';
    } else {
      _stokMinimumController.text = '10';
      _stokSaatIniController.text = '0';
      _etalase = Etalase.etalase1;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stokSaatIniController.dispose();
    _stokMinimumController.dispose();
    _satuanController.dispose();
    _keteranganController.dispose();
    _hargaJualController.dispose();
    _satuanJualController.dispose();
    _hargaEcerController.dispose();
    _satuanEcerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _loading = true);
      String? warningMessage;

      final stokMinimum = int.parse(_stokMinimumController.text.trim());
      final stokSaatIni = int.tryParse(_stokSaatIniController.text.trim()) ?? 0;
      final previousFotoUrl = _existingFotoUrl;
      late final ObatModel savedObat;

      // ── Parse harga (FASE 1, 2026-04-27) ──────────────────────────────
      final hargaJual = _hargaJualController.text.trim().isEmpty
          ? null
          : num.tryParse(_hargaJualController.text.trim());
      final satuanJual = _satuanJualController.text.trim().isEmpty
          ? null
          : _satuanJualController.text.trim();
      final hargaEcer = _hargaEcerController.text.trim().isEmpty
          ? null
          : num.tryParse(_hargaEcerController.text.trim());
      final satuanEcer = _satuanEcerController.text.trim().isEmpty
          ? null
          : _satuanEcerController.text.trim();

      if (_idObat == null) {
        savedObat = await _repo.insertObat(
          namaObat: _namaController.text.trim(),
          stokSaatIni: stokSaatIni,
          stokMinimum: stokMinimum,
          etalase: _etalase,
          satuan: _satuanController.text.trim(),
          keterangan: _keteranganController.text.trim(),
          // ── Harga ──────────────────────────────────────────────────────
          hargaJual: hargaJual,
          satuanJual: satuanJual,
          bisaEcer: _bisaEcer,
          hargaEcer: hargaEcer,
          satuanEcer: satuanEcer,
        );
      } else {
        savedObat = await _repo.updateObat(
          idObat: _idObat!,
          namaObat: _namaController.text.trim(),
          stokMinimum: stokMinimum,
          etalase: _etalase,
          satuan: _satuanController.text.trim(),
          keterangan: _keteranganController.text.trim(),
          // ── Harga ──────────────────────────────────────────────────────
          hargaJual: hargaJual,
          satuanJual: satuanJual,
          bisaEcer: _bisaEcer,
          hargaEcer: hargaEcer,
          satuanEcer: satuanEcer,
        );
      }
      _idObat = savedObat.idObat;

      if (_selectedFotoBytes != null) {
        try {
          final uploadResult = await _uploadService.uploadFoto(
            bytes: _selectedFotoBytes!,
            fileName: _selectedFotoFileName ?? 'obat.jpg',
            etalaseLabel: _etalase.value,
            namaObat: _namaController.text.trim(),
          );
          // Tulis foto_key + foto_updated_at ke DB (F12.3 step)
          await _repo.updateFotoKey(
            idObat: savedObat.idObat,
            fotoKey: uploadResult.fotoKey,
          );
          // Hapus foto lama di Storage (best effort, ignore 404)
          await _uploadService.deleteOldFoto(_existingFotoKey);
          // Update state dengan nilai baru setelah upload sukses
          _existingFotoKey = uploadResult.fotoKey;
          _existingFotoUpdatedAt = DateTime.now().toUtc();
          _existingFotoUrl = uploadResult.publicUrl;
          _hapusFoto = false;
        } catch (error, stackTrace) {
          warningMessage =
              'Data obat tersimpan, tetapi upload foto gagal. ${AppErrorMapper.toMessage(error, stackTrace)}';
        }
      } else if (_hapusFoto &&
          previousFotoUrl != null &&
          previousFotoUrl.trim().isNotEmpty) {
        try {
          await _repo.deleteFotoObat(
            savedObat.idObat,
            fotoUrl: previousFotoUrl,
          );
          _existingFotoUrl = null;
          _existingFotoKey = null;
          _existingFotoUpdatedAt = null;
          _hapusFoto = false;
        } catch (error, stackTrace) {
          warningMessage =
              'Data obat tersimpan, tetapi hapus foto gagal. ${AppErrorMapper.toMessage(error, stackTrace)}';
        }
      }

      if (!mounted) return;
      if (warningMessage != null && warningMessage.trim().isNotEmpty) {
        Navigator.pop(context, {
          'saved': true,
          'warning': warningMessage,
        });
        return;
      }

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

  Future<void> _pickFoto(ImageSource source) async {
    if (_processingFoto) {
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null) return;
      if (!mounted) return;

      setState(() {
        _processingFoto = true;
        _fotoCompressionInfo = null;
      });

      final sourceBytes = await picked.readAsBytes();
      final sourceFileName = _normalizeFileName(picked.name);

      // Validasi cepat di sisi UI — kompresi akhir & path Storage
      // diurus oleh FotoObatUploadService saat simpan.
      final errorMessage = _validatePickedFoto(
        fileName: sourceFileName,
        sizeInBytes: sourceBytes.length,
      );
      if (errorMessage != null) {
        if (!mounted) return;
        showModernSnackBar(context, errorMessage, isError: true);
        return;
      }

      setState(() {
        _selectedFotoBytes = sourceBytes;
        _selectedFotoFileName = sourceFileName;
        _hapusFoto = false;
        _fotoCompressionInfo = null; // service yang akan isi setelah simpan
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        _mapPickerErrorMessage(error, stackTrace),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingFoto = false;
        });
      }
    }
  }

  String _normalizeFileName(String rawFileName) {
    final trimmed = rawFileName.trim();
    final safeBaseName = 'obat_${DateTime.now().millisecondsSinceEpoch}';

    if (trimmed.isEmpty) {
      return '$safeBaseName.jpg';
    }

    final extension = _extractFileExtension(trimmed);
    if (extension == null) {
      return '$safeBaseName.jpg';
    }

    return trimmed;
  }

  Future<void> _showFotoActionSheet() async {
    if (_processingFoto) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final hasFoto = _selectedFotoBytes != null ||
            (_existingFotoUrl != null && _existingFotoUrl!.trim().isNotEmpty);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickFoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickFoto(ImageSource.camera);
                },
              ),
              if (hasFoto)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: cdanger(context)),
                  title: Text(
                    'Hapus Foto',
                    style: TextStyle(color: cdanger(context)),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _selectedFotoBytes = null;
                      _selectedFotoFileName = null;
                      _hapusFoto = true;
                      _fotoCompressionInfo = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String? _validatePickedFoto({
    required String fileName,
    required int sizeInBytes,
  }) {
    if (sizeInBytes <= 0) {
      return 'File gambar kosong.';
    }
    if (sizeInBytes > _maxFotoSizeBytes) {
      return 'Ukuran foto maksimal 5 MB.';
    }

    final extension = _extractFileExtension(fileName);
    if (extension == null || !_allowedFotoExtensions.contains(extension)) {
      return 'Format foto harus JPG, PNG, atau WEBP.';
    }
    return null;
  }

  String? _extractFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= fileName.length - 1) {
      return null;
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _mapPickerErrorMessage(Object error, StackTrace stackTrace) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('camera_access_denied') ||
        raw.contains('camera_access_restricted')) {
      return 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan perangkat.';
    }
    if (raw.contains('photo_access_denied') ||
        raw.contains('permission') ||
        raw.contains('denied')) {
      return 'Izin akses foto ditolak. Aktifkan izin media/foto di pengaturan perangkat.';
    }
    return AppErrorMapper.toMessage(error, stackTrace);
  }

  Widget _buildFotoPreview() {
    final selectedBytes = _selectedFotoBytes;
    if (selectedBytes != null && selectedBytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          selectedBytes,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    }

    final existingFotoUrl = _hapusFoto ? null : _existingFotoUrl;
    final existingFotoKey = _hapusFoto ? null : _existingFotoKey;
    final existingFotoUpdatedAt = _hapusFoto ? null : _existingFotoUpdatedAt;
    return ObatImage(
      namaObat:
          _namaController.text.trim().isEmpty ? 'Obat' : _namaController.text,
      fotoKey: existingFotoKey,
      fotoUpdatedAt: existingFotoUpdatedAt,
      fotoUrl: existingFotoUrl,
      width: 96,
      height: 96,
      borderRadius: 14,
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  String? _validatePositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    if (int.tryParse(value.trim()) == null) return 'Harus berupa angka bulat';
    final n = int.parse(value.trim());
    if (n < 0) return 'Tidak boleh negatif';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Obat' : 'Tambah Obat'),
        backgroundColor: cprimary(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(_isEdit ? 'Edit Obat' : 'Tambah Obat'),
              const SizedBox(height: 18),
              _buildLabel('Nama Obat'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _namaController,
                validator: _validateRequired,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama obat',
                  filled: true,
                  fillColor: ccardBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildLabel('Foto Obat (Opsional)'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ccardBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cdivider(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFotoPreview(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _processingFoto
                                ? 'Memproses foto...'
                                : _selectedFotoBytes != null
                                    ? 'Foto siap diunggah'
                                    : ((_hapusFoto ||
                                            _existingFotoUrl == null ||
                                            _existingFotoUrl!.trim().isEmpty)
                                        ? 'Belum ada foto'
                                        : 'Foto tersimpan'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ctextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gunakan foto untuk memudahkan identifikasi obat di list dan detail.',
                            style: TextStyle(
                              fontSize: 12,
                              color: ctextSecondary(context),
                              height: 1.3,
                            ),
                          ),
                          if (_fotoCompressionInfo != null &&
                              _fotoCompressionInfo!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _fotoCompressionInfo!,
                              style: TextStyle(
                                fontSize: 11,
                                color: ctextSecondary(context),
                                height: 1.25,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: (_loading || _processingFoto)
                                    ? null
                                    : _showFotoActionSheet,
                                icon: Icon(
                                  AppSymbols.pills,
                                  size: 16,
                                  color: cprimary(context),
                                ),
                                label: Text(
                                  _selectedFotoBytes == null &&
                                          (_existingFotoUrl == null ||
                                              _existingFotoUrl!
                                                  .trim()
                                                  .isEmpty ||
                                              _hapusFoto)
                                      ? 'Pilih Foto'
                                      : 'Ganti Foto',
                                ),
                              ),
                              if (_selectedFotoBytes != null ||
                                  (_existingFotoUrl != null &&
                                      _existingFotoUrl!.trim().isNotEmpty &&
                                      !_hapusFoto))
                                TextButton.icon(
                                  onPressed: (_loading || _processingFoto)
                                      ? null
                                      : () => setState(() {
                                            _selectedFotoBytes = null;
                                            _selectedFotoFileName = null;
                                            _hapusFoto = true;
                                            _fotoCompressionInfo = null;
                                          }),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  label: const Text('Hapus Foto'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildLabel('Etalase'),
              const SizedBox(height: 6),
              DropdownButtonFormField<Etalase>(
                initialValue: _etalase,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ccardBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value == null ? 'Wajib dipilih' : null,
                items: Etalase.values.map((e) {
                  return DropdownMenuItem<Etalase>(
                    value: e,
                    child: Text(e.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _etalase = value);
                },
              ),
              const SizedBox(height: 14),
              if (!_isEdit) ...[
                _buildLabel('Stok Saat Ini (Awal)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _stokSaatIniController,
                  keyboardType: TextInputType.number,
                  validator: _validatePositiveInt,
                  decoration: InputDecoration(
                    hintText: 'Jumlah stok awal di etalase',
                    filled: true,
                    fillColor: ccardBg(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _buildLabel('Stok Minimum'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _stokMinimumController,
                keyboardType: TextInputType.number,
                validator: _validatePositiveInt,
                decoration: InputDecoration(
                  hintText: 'Batas minimum untuk indikator menipis',
                  filled: true,
                  fillColor: ccardBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildLabel('Satuan'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _satuanController,
                decoration: InputDecoration(
                  hintText: 'Strip / Botol / Tablet',
                  filled: true,
                  fillColor: ccardBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildLabel('Satuan'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _satuanController,
                decoration: InputDecoration(
                  hintText: 'Strip / Botol / Tablet',
                  filled: true,
                  fillColor: ccardBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── HARGA (FASE 1, 2026-04-27) ─────────────────────────────────
              _buildLabel('Harga Jual Utama'),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _hargaJualController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 60000',
                        prefixText: 'Rp  ',
                        filled: true,
                        fillColor: ccardBg(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _satuanJualController,
                      decoration: InputDecoration(
                        hintText: 'Satuan',
                        hintStyle: TextStyle(fontSize: 14),
                        filled: true,
                        fillColor: ccardBg(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Eceran toggle
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _bisaEcer,
                      onChanged: (v) => setState(() => _bisaEcer = v ?? false),
                      activeColor: cprimary(context),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bisa dijual eceran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ctextSecondary(context),
                    ),
                  ),
                ],
              ),

              if (_bisaEcer) ...[
                const SizedBox(height: 10),
                _buildLabel('Harga Eceran'),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _hargaEcerController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Contoh: 1000',
                          prefixText: 'Rp  ',
                          filled: true,
                          fillColor: ccardBg(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _satuanEcerController,
                        decoration: InputDecoration(
                          hintText: 'Satuan ecer',
                          hintStyle: TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: ccardBg(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // ── END HARGA ─────────────────────────────────────────────────

              const SizedBox(height: 14),
              _buildLabel('Keterangan'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _keteranganController,
                decoration: InputDecoration(
                  hintText: 'Opsional',
                  filled: true,
                  fillColor: ccardBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_loading || _processingFoto) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cprimary(context),
                    foregroundColor: conPrimary(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _processingFoto
                        ? 'Memproses foto...'
                        : _loading
                            ? 'Menyimpan...'
                            : (_isEdit ? 'Update' : 'Simpan'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: ctextSecondary(context),
        fontSize: 13,
      ),
    );
  }
}
