import 'package:flutter/material.dart' hide RadioGroup;

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_widgets.dart';
import '../core/ui/app_icons.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_view.dart';
import '../core/widgets/app_error_view.dart';
import '../core/widgets/app_loading_view.dart';
import '../data/models/kehadiran_form_args.dart';
import '../data/models/kehadiran_model.dart';
import '../data/models/pasien_model.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/pasien_repository.dart';
import '../widgets/page_header.dart';

class KehadiranFormPage extends StatefulWidget {
  const KehadiranFormPage({super.key});

  static const routeName = '/kehadiran-form';

  @override
  State<KehadiranFormPage> createState() => _KehadiranFormPageState();
}

class _KehadiranFormPageState extends State<KehadiranFormPage> {
  final PasienRepository _pasienRepository = PasienRepository();
  final KehadiranRepository _kehadiranRepository = KehadiranRepository();
  int? _selectedPasienId;
  String _selectedPasienNama = '';
  StatusHadir _status = StatusHadir.hadir;
  final TextEditingController _keteranganController = TextEditingController();
  late Future<List<PasienModel>> _pasienFuture;
  bool _loading = false;
  DateTime _tanggal = DateTime.now();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is KehadiranFormArgs) {
      _tanggal = args.tanggal;
      _selectedPasienId = args.idPasien;
      _selectedPasienNama = args.namaPasien ?? '';
      _status = args.statusHadir ?? StatusHadir.hadir;
      _keteranganController.text = args.keterangan ?? '';
    } else if (args is Map<String, dynamic>) {
      _tanggal =
          DateTime.tryParse(args['tanggal']?.toString() ?? '') ?? _tanggal;
      _selectedPasienId = args['id_pasien'] as int?;
      _selectedPasienNama = args['nama_pasien']?.toString() ?? '';
      final statusArg = args['status_hadir']?.toString();
      if (statusArg == 'hadir' || statusArg == 'tidak_hadir') {
        _status = StatusHadir.fromDbString(statusArg!);
      }
      _keteranganController.text = args['keterangan']?.toString() ?? '';
    } else if (args is DateTime) {
      _tanggal = args;
    } else if (args is String) {
      _tanggal = DateTime.tryParse(args) ?? _tanggal;
    }

    _pasienFuture = _pasienRepository.getPasienByTanggalJanjian(_tanggal);
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedPasienId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pasien terlebih dahulu')),
      );
      return;
    }

    try {
      setState(() => _loading = true);
      await _kehadiranRepository.upsertKehadiran(
        idPasien: _selectedPasienId!,
        tanggalHadir: _tanggal,
        statusHadir: _status.toDbString(),
        idAdmin: await AdminSession.getCurrentId(),
        keterangan: _keteranganController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.toMessage(error, stackTrace))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('Input Kehadiran Pasien'),
            const SizedBox(height: 16),
            Text('Tanggal Janjian: ${asDate(_tanggal)}'),
            const SizedBox(height: 16),
            FutureBuilder<List<PasienModel>>(
              future: _pasienFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingView();
                }
                if (snapshot.hasError) {
                  return AppErrorView(
                    message: AppErrorMapper.toMessage(
                      snapshot.error!,
                      snapshot.stackTrace,
                    ),
                  );
                }

                final items = snapshot.data ?? const <PasienModel>[];
                if (items.isEmpty && _selectedPasienId == null) {
                  return const AppEmptyView(
                    title: 'Pasien belum tersedia',
                    message: 'Tidak ada pasien dengan tanggal janjian ini.',
                    icon: AppIcons.pasienTidakHadir,
                  );
                }

                if (_selectedPasienId != null &&
                    _selectedPasienNama.isNotEmpty) {
                  return InputDecorator(
                    decoration: const InputDecoration(labelText: 'Nama Pasien'),
                    child: Text(_selectedPasienNama),
                  );
                }

                return DropdownButtonFormField<int>(
                  initialValue: _selectedPasienId,
                  decoration: const InputDecoration(labelText: 'Nama Pasien'),
                  items: items.map((item) {
                    return DropdownMenuItem<int>(
                      value: item.idPasien,
                      child: Text(item.namaPasien),
                    );
                  }).toList(),
                  onChanged: (value) {
                    PasienModel? pasien;
                    for (final item in items) {
                      if (item.idPasien == value) {
                        pasien = item;
                        break;
                      }
                    }
                    setState(() {
                      _selectedPasienId = value;
                      _selectedPasienNama = pasien?.namaPasien ?? '';
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Status Kehadiran'),
            RadioGroup<StatusHadir>(
              groupValue: _status,
              onChanged: (value) =>
                  setState(() => _status = value ?? StatusHadir.hadir),
              child: Column(
                children: [
                  RadioListTile<StatusHadir>(
                    contentPadding: EdgeInsets.zero,
                    value: StatusHadir.hadir,
                    title: const Text('Hadir'),
                  ),
                  RadioListTile<StatusHadir>(
                    contentPadding: EdgeInsets.zero,
                    value: StatusHadir.tidakHadir,
                    title: const Text('Tidak Hadir'),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _keteranganController,
              decoration: const InputDecoration(labelText: 'Keterangan'),
              minLines: 1,
              maxLines: 3,
            ),
            const Spacer(),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: Text(_loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
