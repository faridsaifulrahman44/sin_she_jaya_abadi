import 'dart:async';

import 'package:flutter/material.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../core/utils/jadwal_praktek_helper.dart';
import '../data/models/pasien_model.dart';
import '../data/repositories/pasien_repository.dart';
import '../widgets/page_header.dart';

class PasienFormPage extends StatefulWidget {
  const PasienFormPage({super.key});

  static const routeName = '/pasien-form';

  @override
  State<PasienFormPage> createState() => _PasienFormPageState();
}

class _PasienFormPageState extends State<PasienFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PasienRepository _repo = PasienRepository();
  final TextEditingController _nomorController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usiaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  DateTime? _tanggalJanjian;
  String _jenisKelamin = 'L';
  bool _loading = false;
  bool _initialized = false;
  int? _idPasien;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final pasien = args is PasienModel
        ? args
        : args is Map<String, dynamic>
            ? PasienModel.fromMap(args)
            : null;

    if (pasien != null) {
      // ── Edit mode ──────────────────────────────────────────────────────────
      _idPasien = pasien.idPasien;
      _nomorController.text = pasien.nomorPasien;
      _namaController.text = pasien.namaPasien;
      _usiaController.text = pasien.usia.toString();
      _alamatController.text = pasien.alamat ?? '';
      _jenisKelamin = pasien.jenisKelamin;
      _tanggalJanjian = pasien.tanggalJanjian;
    } else {
      // ── Tambah mode — auto-generate nomor pasien ───────────────────────────
      _loadNextNomorPasien();
    }
  }

  Future<void> _loadNextNomorPasien() async {
    try {
      final next = await _repo.getNextNomorPasien();
      if (mounted) {
        setState(() => _nomorController.text = next);
      }
    } catch (_) {
      // Gagal fetch auto-generate, biarkan kosong — user bisa ketik manual
    }
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _namaController.dispose();
    _usiaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalJanjian() async {
    // Suggest practice day: today if practice day, else next practice day
    final initial =
        JadwalPraktekHelper.isHariPraktek(_tanggalJanjian ?? DateTime.now())
            ? (_tanggalJanjian ?? DateTime.now())
            : JadwalPraktekHelper.nextPracticeDay();

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _tanggalJanjian ?? initial,
      selectableDayPredicate: (date) => JadwalPraktekHelper.isHariPraktek(date),
    );
    if (picked != null) {
      setState(() => _tanggalJanjian = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalJanjian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal janjian wajib dipilih')),
      );
      return;
    }

    final validationError =
        JadwalPraktekHelper.validateHariPraktek(_tanggalJanjian!);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      if (_idPasien == null) {
        await _repo.insertPasien(
          nomorPasien: _nomorController.text.trim(),
          namaPasien: _namaController.text.trim(),
          alamat: _alamatController.text.trim(),
          usia: int.parse(_usiaController.text.trim()),
          jenisKelamin: _jenisKelamin,
          tanggalJanjian: _tanggalJanjian!,
        );
      } else {
        await _repo.updatePasien(
          idPasien: _idPasien!,
          nomorPasien: _nomorController.text.trim(),
          namaPasien: _namaController.text.trim(),
          alamat: _alamatController.text.trim(),
          usia: int.parse(_usiaController.text.trim()),
          jenisKelamin: _jenisKelamin,
          tanggalJanjian: _tanggalJanjian!,
        );
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _idPasien == null
                ? 'Data pasien berhasil disimpan'
                : 'Data pasien berhasil diupdate',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on TimeoutException catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.toMessage(error, stackTrace))),
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      // Duplicate nomor_pasien
      final mapped = AppErrorMapper.map(error, stackTrace);
      final isDuplicate = mapped.code == '23505' ||
          mapped.userMessage.toLowerCase().contains('duplicate') ||
          mapped.userMessage.toLowerCase().contains('unique');
      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor pasien sudah dipakai. Gunakan nomor lain.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapped.userMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }
    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }
    if (int.tryParse(value.trim()) == null) {
      return 'Harus berupa angka bulat';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _idPasien != null;
    final tanggalLabel = _tanggalJanjian == null
        ? 'Pilih tanggal janjian'
        : formatDateDb(_tanggalJanjian!);

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(isEdit ? 'Edit Data Pasien' : 'Tambah Data Pasien'),
              const SizedBox(height: 18),
              const Text('Nomor Pasien'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nomorController,
                readOnly: true,
                validator: _validateRequired,
                decoration: InputDecoration(
                  hintText: _idPasien == null
                      ? 'Memuat nomor pasien...'
                      : _nomorController.text,
                  helperText:
                      _idPasien == null ? 'Nomor pasien dibuat otomatis' : null,
                  helperStyle: TextStyle(
                    fontSize: 11,
                    color: ctextMuted(context).withValues(alpha: 0.70),
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: _idPasien == null
                      ? ccardBg(context).withValues(alpha: 0.5)
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              const Text('Nama'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _namaController,
                validator: _validateRequired,
                decoration: const InputDecoration(hintText: 'Masukkan nama'),
              ),
              const SizedBox(height: 14),
              const Text('Usia'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usiaController,
                keyboardType: TextInputType.number,
                validator: _validateNumber,
                decoration: const InputDecoration(hintText: 'Masukkan usia'),
              ),
              const SizedBox(height: 14),
              const Text('Tanggal Janjian'),
              const SizedBox(height: 4),
              Text(
                'Hanya hari practise: Senin, Rabu, Jumat',
                style: TextStyle(
                  fontSize: 11,
                  color: ctextMuted(context),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickTanggalJanjian,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    hintText: 'Pilih tanggal janjian',
                    suffixIcon: Icon(AppSymbols.calendar03),
                  ),
                  child: Text(tanggalLabel),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Jenis Kelamin'),
              Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'L',
                    // ignore: deprecated_member_use
                    groupValue: _jenisKelamin,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _jenisKelamin = value);
                      }
                    },
                    title: const Text('Laki-laki'),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'P',
                    // ignore: deprecated_member_use
                    groupValue: _jenisKelamin,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _jenisKelamin = value);
                      }
                    },
                    title: const Text('Perempuan'),
                  ),
                ],
              ),
              const Text('Alamat'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _alamatController,
                validator: _validateRequired,
                decoration: const InputDecoration(hintText: 'Masukkan alamat'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cprimary(context),
                    foregroundColor: conPrimary(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _loading ? 'Menyimpan...' : (isEdit ? 'Update' : 'Simpan'),
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
}
