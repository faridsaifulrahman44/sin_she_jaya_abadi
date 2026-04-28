import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../data/models/kunjungan_model.dart';
import '../data/repositories/kunjungan_repository.dart';

/// Guard: halaman form kunjungan hanya bisa diakses owner.
class _OwnerGate extends StatelessWidget {
  const _OwnerGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminSession.isOwner(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: AppIcons.error,
                    color: cdanger(context),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Akses ditolak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ctextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Fitur kunjungan hanya bisa diakses oleh Owner.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: ctextSecondary(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}

/// Form tambah/edit kunjungan pasien.
/// Entry point: dari halaman Detail Pasien.
class KunjunganFormPage extends StatefulWidget {
  const KunjunganFormPage({super.key});

  static const routeName = '/kunjungan-form';

  @override
  State<KunjunganFormPage> createState() => _KunjunganFormPageState();
}

class _KunjunganFormPageState extends State<KunjunganFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final KunjunganRepository _repo = KunjunganRepository();

  final TextEditingController _keluhanController = TextEditingController();
  final TextEditingController _catatanHasilController = TextEditingController();
  final TextEditingController _tindakLanjutController = TextEditingController();

  bool _loading = false;
  bool _initialized = false;
  bool _isEdit = false;
  int? _idKunjungan;
  int? _idPasien;
  DateTime _tanggalKunjungan = DateTime.now();
  DateTime? _tanggalKontrolBerikutnya;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is KunjunganModel) {
      _isEdit = true;
      _idKunjungan = args.idKunjungan;
      _idPasien = args.idPasien;
      _tanggalKunjungan = args.tanggalKunjungan;
      _tanggalKontrolBerikutnya = args.tanggalKontrolBerikutnya;
      _keluhanController.text = args.keluhanSingkat ?? '';
      _catatanHasilController.text = args.catatanHasil ?? '';
      _tindakLanjutController.text = args.tindakLanjut ?? '';
    } else if (args is Map<String, dynamic>) {
      final kunjungan = args['kunjungan'] as KunjunganModel?;
      _idPasien = args['id_pasien'] as int?;

      if (kunjungan != null) {
        _isEdit = true;
        _idKunjungan = kunjungan.idKunjungan;
        _idPasien = kunjungan.idPasien;
        _tanggalKunjungan = kunjungan.tanggalKunjungan;
        _tanggalKontrolBerikutnya = kunjungan.tanggalKontrolBerikutnya;
        _keluhanController.text = kunjungan.keluhanSingkat ?? '';
        _catatanHasilController.text = kunjungan.catatanHasil ?? '';
        _tindakLanjutController.text = kunjungan.tindakLanjut ?? '';
      }
    }
  }

  @override
  void dispose() {
    _keluhanController.dispose();
    _catatanHasilController.dispose();
    _tindakLanjutController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalKunjungan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalKunjungan,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalKunjungan = picked);
    }
  }

  Future<void> _pickTanggalKontrol() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalKontrolBerikutnya ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _tanggalKontrolBerikutnya = picked);
    }
  }

  Future<void> _clearKontrol() async {
    setState(() => _tanggalKontrolBerikutnya = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final idPasien = _idPasien;
    if (idPasien == null || idPasien <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pasien tidak valid.')),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      if (_isEdit && _idKunjungan != null) {
        await _repo.updateKunjungan(
          idKunjungan: _idKunjungan!,
          keluhanSingkat: _keluhanController.text.trim().isEmpty
              ? null
              : _keluhanController.text.trim(),
          catatanHasil: _catatanHasilController.text.trim().isEmpty
              ? null
              : _catatanHasilController.text.trim(),
          tindakLanjut: _tindakLanjutController.text.trim().isEmpty
              ? null
              : _tindakLanjutController.text.trim(),
          tanggalKontrolBerikutnya: _tanggalKontrolBerikutnya,
        );
      } else {
        final idAdmin = await AdminSession.getCurrentId();
        await _repo.insertKunjungan(
          idPasien: idPasien,
          tanggalKunjungan: _tanggalKunjungan,
          keluhanSingkat: _keluhanController.text.trim().isEmpty
              ? null
              : _keluhanController.text.trim(),
          catatanHasil: _catatanHasilController.text.trim().isEmpty
              ? null
              : _catatanHasilController.text.trim(),
          tindakLanjut: _tindakLanjutController.text.trim().isEmpty
              ? null
              : _tindakLanjutController.text.trim(),
          tanggalKontrolBerikutnya: _tanggalKontrolBerikutnya,
          idAdmin: idAdmin,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEdit ? 'Kunjungan diupdate' : 'Kunjungan ditambahkan'),
          backgroundColor: csuccess(context),
        ),
      );
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorMapper.toMessage(error, stackTrace)),
          backgroundColor: cdanger(context),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OwnerGate(
      child: Scaffold(
        backgroundColor: cscaffoldBg(context),
        appBar: AppBar(
          title: Text(
            _isEdit ? 'Edit Kunjungan' : 'Tambah Kunjungan',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: cteal(context),
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
                _buildSectionLabel('Tanggal Kunjungan'),
                const SizedBox(height: 6),
                _buildDateField(
                  value: asMediumDate(_tanggalKunjungan),
                  onTap: _pickTanggalKunjungan,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Keluhan Singkat'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _keluhanController,
                  hint: 'Contoh: Flu, Batuk, Sakit kepala',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Catatan Hasil'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _catatanHasilController,
                  hint: 'Hasil pemeriksaan, tindakan yang dilakukan...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Tindak Lanjut'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _tindakLanjutController,
                  hint: 'Saran, obat, atau rencana lanjutan...',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Tanggal Kontrol Berikutnya'),
                const SizedBox(height: 4),
                Text(
                  'Opsional',
                  style: TextStyle(
                    fontSize: 11,
                    color: ctextMuted(context),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                _buildKontrolField(),
                const SizedBox(height: 28),
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
                      _loading
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
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: ctextSecondary(context),
        fontSize: 13,
      ),
    );
  }

  Widget _buildDateField({
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: ccardBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cdivider(context)),
        ),
        child: Row(
          children: [
            HugeIcon(
                icon: AppIcons.calendar03,
                color: ctextSecondary(context),
                size: 18),
            const SizedBox(width: 10),
            Text(
              value,
              style: TextStyle(
                color: ctextPrimary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKontrolField() {
    final hasValue = _tanggalKontrolBerikutnya != null;

    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            value: hasValue
                ? asMediumDate(_tanggalKontrolBerikutnya!)
                : 'Pilih tanggal kontrol',
            onTap: _pickTanggalKontrol,
          ),
        ),
        if (hasValue) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: _clearKontrol,
            icon: Icon(Icons.clear, color: cdanger(context)),
            tooltip: 'Hapus tanggal kontrol',
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: ccardBg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cteal(context), width: 1.5),
        ),
      ),
    );
  }
}
