import 'kehadiran_model.dart';

class KehadiranFormArgs {
  const KehadiranFormArgs({
    required this.tanggal,
    this.idPasien,
    this.namaPasien,
    this.statusHadir,
    this.keterangan,
  });

  final DateTime tanggal;
  final int? idPasien;
  final String? namaPasien;
  final StatusHadir? statusHadir;
  final String? keterangan;
}
