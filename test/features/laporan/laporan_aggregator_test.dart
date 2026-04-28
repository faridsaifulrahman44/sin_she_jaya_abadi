import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/kehadiran_model.dart';
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/data/models/pasien_model.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/features/laporan/laporan_aggregator.dart';

TransaksiModel transaksi({
  required int id,
  required DateTime tanggal,
  required JenisTransaksi jenis,
  required double total,
  MetodeBayarTransaksi? metode,
}) {
  return TransaksiModel(
    idTransaksi: id,
    tanggal: tanggal,
    jenisTransaksi: jenis,
    total: total,
    metodeBayar: metode,
    idAdmin: 1,
  );
}

TransaksiItemModel transaksiItem({
  required int id,
  required int idTransaksi,
  required int idObat,
  required int jumlah,
  required double subtotal,
}) {
  return TransaksiItemModel(
    idItem: id,
    idTransaksi: idTransaksi,
    idObat: idObat,
    jumlah: jumlah,
    hargaSatuan: subtotal / jumlah,
    subtotal: subtotal,
    idAdmin: 1,
  );
}

PasienModel pasien({
  required int id,
  DateTime? tanggalJanjian,
}) {
  return PasienModel(
    idPasien: id,
    nomorPasien: '$id',
    namaPasien: 'Pasien $id',
    usia: 20,
    jenisKelamin: 'L',
    tanggalJanjian: tanggalJanjian,
  );
}

KehadiranModel kehadiran({
  required int id,
  required StatusHadir status,
  required DateTime tanggal,
}) {
  return KehadiranModel(
    idKehadiran: id,
    idPasien: 1,
    tanggalHadir: tanggal,
    statusHadir: status,
    idAdmin: 1,
  );
}

ObatModel obat({
  required int id,
  required Etalase etalase,
  required int stok,
  required int minimum,
}) {
  return ObatModel(
    idObat: id,
    namaObat: 'Obat $id',
    stokSaatIni: stok,
    stokMinimum: minimum,
    etalase: etalase,
  );
}

void main() {
  group('aggregateDailyIncome', () {
    test('mengelompokkan total transaksi per hari', () {
      final result = aggregateDailyIncome([
        transaksi(
          id: 1,
          tanggal: DateTime(2026, 3, 1, 8),
          jenis: JenisTransaksi.obatReadyStock,
          total: 100000,
        ),
        transaksi(
          id: 2,
          tanggal: DateTime(2026, 3, 1, 12),
          jenis: JenisTransaksi.praktekCustom,
          total: 50000,
        ),
      ]);

      expect(result.length, 1);
      expect(result[DateTime(2026, 3, 1)], 150000);
    });
  });

  group('buildDailyIncomePoints', () {
    test('membuat titik harian sesuai jumlah hari', () {
      final points = buildDailyIncomePoints(
        items: [
          transaksi(
            id: 1,
            tanggal: DateTime(2026, 3, 10),
            jenis: JenisTransaksi.obatReadyStock,
            total: 100000,
          ),
        ],
        endDate: DateTime(2026, 3, 11),
        days: 2,
      );

      expect(points.length, 2);
      expect(points[0].date, DateTime(2026, 3, 10));
      expect(points[0].totalNominal, 100000);
      expect(points[1].date, DateTime(2026, 3, 11));
      expect(points[1].totalNominal, 0);
    });
  });

  group('buildLaporanSummary', () {
    test('menghitung metrik laporan operasional utama', () {
      final summary = buildLaporanSummary(
        startDate: DateTime(2026, 3, 10),
        endDate: DateTime(2026, 3, 11),
        transaksiPeriode: [
          transaksi(
            id: 1,
            tanggal: DateTime(2026, 3, 10),
            jenis: JenisTransaksi.obatReadyStock,
            total: 120000,
            metode: MetodeBayarTransaksi.cash,
          ),
          transaksi(
            id: 2,
            tanggal: DateTime(2026, 3, 10),
            jenis: JenisTransaksi.praktekCustom,
            total: 200000,
            metode: MetodeBayarTransaksi.qris,
          ),
          transaksi(
            id: 3,
            tanggal: DateTime(2026, 3, 11),
            jenis: JenisTransaksi.obatReadyStock,
            total: 80000,
            metode: MetodeBayarTransaksi.cash,
          ),
        ],
        transaksiAllTime: [
          transaksi(
            id: 1,
            tanggal: DateTime(2026, 3, 10),
            jenis: JenisTransaksi.obatReadyStock,
            total: 120000,
            metode: MetodeBayarTransaksi.cash,
          ),
          transaksi(
            id: 2,
            tanggal: DateTime(2026, 3, 10),
            jenis: JenisTransaksi.praktekCustom,
            total: 200000,
            metode: MetodeBayarTransaksi.qris,
          ),
          transaksi(
            id: 3,
            tanggal: DateTime(2026, 3, 11),
            jenis: JenisTransaksi.obatReadyStock,
            total: 80000,
            metode: MetodeBayarTransaksi.cash,
          ),
          transaksi(
            id: 4,
            tanggal: DateTime(2026, 3, 1),
            jenis: JenisTransaksi.praktekCustom,
            total: 50000,
            metode: MetodeBayarTransaksi.cash,
          ),
        ],
        transaksiItemsAllTime: [
          transaksiItem(
            id: 1,
            idTransaksi: 1,
            idObat: 1,
            jumlah: 1,
            subtotal: 70000,
          ),
          transaksiItem(
            id: 2,
            idTransaksi: 1,
            idObat: 2,
            jumlah: 1,
            subtotal: 50000,
          ),
          transaksiItem(
            id: 3,
            idTransaksi: 3,
            idObat: 2,
            jumlah: 1,
            subtotal: 80000,
          ),
        ],
        pasienPeriode: [
          pasien(id: 1, tanggalJanjian: DateTime(2026, 3, 10)),
        ],
        pasienAllTime: [
          pasien(id: 1, tanggalJanjian: DateTime(2026, 3, 10)),
          pasien(id: 2, tanggalJanjian: DateTime(2026, 3, 8)),
        ],
        kehadiranPeriode: [
          kehadiran(
            id: 1,
            status: StatusHadir.hadir,
            tanggal: DateTime(2026, 3, 10),
          ),
          kehadiran(
            id: 2,
            status: StatusHadir.tidakHadir,
            tanggal: DateTime(2026, 3, 10),
          ),
        ],
        obatAllTime: [
          obat(id: 1, etalase: Etalase.etalase1, stok: 0, minimum: 5),
          obat(id: 2, etalase: Etalase.etalase2, stok: 2, minimum: 5),
          obat(id: 3, etalase: Etalase.etalase3, stok: 20, minimum: 5),
        ],
      );

      expect(summary.totalPendapatanKeseluruhan, 450000);
      expect(summary.pendapatanPeriodeAktif, 400000);
      expect(summary.pendapatanReadyStock, 200000);
      expect(summary.pendapatanPraktekCustomBundled, 200000);

      expect(summary.pendapatanEtalase1, 70000);
      expect(summary.pendapatanEtalase2, 130000);
      expect(summary.pendapatanEtalase3Custom, 200000);
      expect(summary.selisihPendapatanBelumTerpetakan, 0);

      expect(summary.jumlahTransaksi, 3);
      expect(summary.jumlahTransaksiReadyStock, 2);
      expect(summary.jumlahTransaksiPraktekCustom, 1);
      expect(summary.jumlahTransaksiCash, 2);
      expect(summary.jumlahTransaksiQris, 1);
      expect(summary.nominalCash, 200000);
      expect(summary.nominalQris, 200000);

      expect(summary.jumlahPasienTerdaftar, 2);
      expect(summary.jumlahPasienTerjadwalPeriode, 1);
      expect(summary.jumlahHadir, 1);
      expect(summary.jumlahTidakHadir, 1);

      expect(summary.jumlahStokHabis, 1);
      expect(summary.jumlahStokMenipis, 1);
      expect(summary.stokKritis.length, 2);
      expect(summary.stokKritis.first.statusStok, isNot(StokStatus.aman));
    });

    test('menghasilkan selisih etalase bila detail item tidak lengkap', () {
      final summary = buildLaporanSummary(
        startDate: DateTime(2026, 3, 10),
        endDate: DateTime(2026, 3, 10),
        transaksiPeriode: [
          transaksi(
            id: 1,
            tanggal: DateTime(2026, 3, 10),
            jenis: JenisTransaksi.obatReadyStock,
            total: 100000,
            metode: MetodeBayarTransaksi.cash,
          ),
        ],
        transaksiAllTime: [
          transaksi(
            id: 1,
            tanggal: DateTime(2026, 3, 10),
            jenis: JenisTransaksi.obatReadyStock,
            total: 100000,
            metode: MetodeBayarTransaksi.cash,
          ),
        ],
        transaksiItemsAllTime: [
          transaksiItem(
            id: 1,
            idTransaksi: 1,
            idObat: 1,
            jumlah: 1,
            subtotal: 70000,
          ),
        ],
        pasienPeriode: const [],
        pasienAllTime: const [],
        kehadiranPeriode: const [],
        obatAllTime: [
          obat(id: 1, etalase: Etalase.etalase1, stok: 5, minimum: 5),
        ],
      );

      expect(summary.pendapatanPeriodeAktif, 100000);
      expect(summary.pendapatanEtalase1, 70000);
      expect(summary.selisihPendapatanBelumTerpetakan, 30000);
      expect(summary.hasSelisihEtalase, isTrue);
    });

    test('hanya menghitung hadir/tidak_hadir secara eksplisit', () {
      final summary = buildLaporanSummary(
        startDate: DateTime(2026, 3, 10),
        endDate: DateTime(2026, 3, 10),
        transaksiPeriode: const [],
        transaksiAllTime: const [],
        transaksiItemsAllTime: const [],
        pasienPeriode: const [],
        pasienAllTime: const [],
        kehadiranPeriode: [
          kehadiran(
            id: 1,
            status: StatusHadir.hadir,
            tanggal: DateTime(2026, 3, 10),
          ),
          kehadiran(
            id: 2,
            status: StatusHadir.tidakHadir,
            tanggal: DateTime(2026, 3, 10),
          ),
        ],
        obatAllTime: const [],
      );

      expect(summary.jumlahHadir, 1);
      expect(summary.jumlahTidakHadir, 1);
      expect(summary.jumlahKehadiran, 2);
    });
  });
}
