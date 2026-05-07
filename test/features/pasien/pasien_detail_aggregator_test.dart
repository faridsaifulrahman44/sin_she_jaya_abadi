import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/kehadiran_model.dart';
import 'package:klinik_mobile_app/data/models/pasien_model.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/features/pasien/pasien_detail_aggregator.dart';

PasienModel pasien({
  required int id,
  DateTime? createdAt,
  DateTime? tanggalJanjian,
}) {
  return PasienModel(
    idPasien: id,
    nomorPasien: '$id',
    namaPasien: 'Pasien $id',
    usia: 25,
    jenisKelamin: 'L',
    createdAt: createdAt,
    tanggalJanjian: tanggalJanjian,
  );
}

KehadiranModel kehadiran({
  required int id,
  required DateTime tanggal,
  required StatusHadir status,
  String? keterangan,
}) {
  return KehadiranModel(
    idKehadiran: id,
    idPasien: 1,
    tanggalHadir: tanggal,
    statusHadir: status,
    keterangan: keterangan,
    idAdmin: 1,
  );
}

TransaksiModel transaksi({
  required int id,
  required DateTime tanggal,
  required JenisTransaksi jenis,
  required double total,
  MetodeBayarTransaksi? metode,
  String? keterangan,
  int? durasi,
}) {
  return TransaksiModel(
    idTransaksi: id,
    tanggal: tanggal,
    jenisTransaksi: jenis,
    total: total,
    metodeBayar: metode,
    idPasien: 1,
    keterangan: keterangan,
    durasiHarian: durasi,
    idAdmin: 1,
  );
}

void main() {
  group('buildPasienDetailSummary', () {
    test('menghitung ringkasan pasien dari riwayat kehadiran dan transaksi',
        () {
      final summary = buildPasienDetailSummary(
        pasien: pasien(id: 1, createdAt: DateTime(2026, 1, 1)),
        riwayatKehadiran: [
          kehadiran(
            id: 1,
            tanggal: DateTime(2026, 3, 1),
            status: StatusHadir.hadir,
          ),
          kehadiran(
            id: 2,
            tanggal: DateTime(2026, 3, 3),
            status: StatusHadir.tidakHadir,
          ),
          kehadiran(
            id: 3,
            tanggal: DateTime(2026, 3, 4),
            status: StatusHadir.hadir,
          ),
        ],
        riwayatTransaksi: [
          transaksi(
            id: 2,
            tanggal: DateTime(2026, 3, 5),
            jenis: JenisTransaksi.praktekCustom,
            total: 200000,
            metode: MetodeBayarTransaksi.qris,
          ),
          transaksi(
            id: 1,
            tanggal: DateTime(2026, 3, 2),
            jenis: JenisTransaksi.obatReadyStock,
            total: 100000,
            metode: MetodeBayarTransaksi.cash,
          ),
        ],
        riwayatKunjungan: const [],
      );

      expect(summary.totalKehadiran, 3);
      expect(summary.totalHadir, 2);
      expect(summary.totalTidakHadir, 1);
      expect(summary.totalTransaksi, 2);
      expect(summary.totalNominalTransaksi, 300000);

      expect(summary.riwayatKehadiran.first.tanggalHadir, DateTime(2026, 3, 4));
      expect(summary.riwayatTransaksi.first.idTransaksi, 2);
      expect(summary.transaksiTerakhir?.idTransaksi, 2);

      expect(summary.terakhirHadir, DateTime(2026, 3, 4));
      expect(summary.terakhirTercatat, DateTime(2026, 3, 5));
    });

    test('tetap aman saat belum ada riwayat', () {
      final summary = buildPasienDetailSummary(
        pasien: pasien(id: 1, createdAt: DateTime(2026, 1, 1)),
        riwayatKehadiran: const [],
        riwayatTransaksi: const [],
        riwayatKunjungan: const [],
      );

      expect(summary.totalKehadiran, 0);
      expect(summary.totalTransaksi, 0);
      expect(summary.totalNominalTransaksi, 0);
      expect(summary.terakhirHadir, isNull);
      expect(summary.transaksiTerakhir, isNull);
      expect(summary.terakhirTercatat, DateTime(2026, 1, 1));
    });
  });

  group('buildTransaksiRingkasan', () {
    test('obat tanpa info tambahan', () {
      final value = buildTransaksiRingkasan(
        transaksi(
          id: 1,
          tanggal: DateTime(2026, 3, 1),
          jenis: JenisTransaksi.obatReadyStock,
          total: 100000,
        ),
      );

      expect(value, 'Pembelian obat');
    });

    test('praktek dengan durasi dan catatan', () {
      final value = buildTransaksiRingkasan(
        transaksi(
          id: 1,
          tanggal: DateTime(2026, 3, 1),
          jenis: JenisTransaksi.praktekCustom,
          total: 100000,
          durasi: 7,
          keterangan: 'Kontrol lanjutan',
        ),
      );

      expect(
        value,
        'Transaksi praktek • Durasi 7 hari • Kontrol lanjutan',
      );
    });
  });
}
