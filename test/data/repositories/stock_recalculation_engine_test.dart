import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/repositories/stock_recalculation_engine.dart';

void main() {
  group('StockRecalculationEngine', () {
    test('deriveInitialStock menghasilkan baseline konsisten', () {
      final stokAwal = StockRecalculationEngine.deriveInitialStock(
        stokSaatIni: 18,
        totalMasuk: 10,
        totalKeluar: 4,
      );

      expect(stokAwal, 12);
    });

    test(
        'deriveInitialStock mendeteksi baseline legacy agar tidak double count',
        () {
      final stokAwal = StockRecalculationEngine.deriveInitialStock(
        stokSaatIni: 11,
        totalMasuk: 11,
        totalKeluar: 0,
      );

      expect(stokAwal, 0);
    });

    test('stok awal tanpa mutasi tetap sama', () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 25,
        mutations: const [],
      );

      expect(stok, 25);
    });

    test('beberapa obat masuk menambah stok', () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 10,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 7,
            sequence: 2,
          ),
        ],
      );

      expect(stok, 22);
    });

    test('regresi: stok awal 11 ditambah masuk 11 harus jadi 22', () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 11,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 11,
            sequence: 1,
          ),
        ],
      );

      expect(stok, 22);
    });

    test('beberapa obat keluar mengurangi stok', () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 30,
        mutations: [
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 4,
            sequence: 1,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 6,
            sequence: 2,
          ),
        ],
      );

      expect(stok, 20);
    });

    test('edit transaksi mengubah hasil recalculation', () {
      final stokSebelumEdit = StockRecalculationEngine.calculate(
        stokAwal: 50,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 10,
            sequence: 1,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 8,
            sequence: 2,
          ),
        ],
      );

      // Simulasi edit: jumlah masuk dari 10 menjadi 15.
      final stokSesudahEdit = StockRecalculationEngine.calculate(
        stokAwal: 50,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 15,
            sequence: 1,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 8,
            sequence: 2,
          ),
        ],
      );

      expect(stokSebelumEdit, 52);
      expect(stokSesudahEdit, 57);
    });

    test('delete transaksi mengembalikan stok sesuai histori tersisa', () {
      final stokDenganSemuaTransaksi = StockRecalculationEngine.calculate(
        stokAwal: 40,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 10,
            sequence: 1,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 5,
            sequence: 2,
          ),
        ],
      );

      // Simulasi delete transaksi keluar.
      final stokSetelahDelete = StockRecalculationEngine.calculate(
        stokAwal: 40,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 10,
            sequence: 1,
          ),
        ],
      );

      expect(stokDenganSemuaTransaksi, 45);
      expect(stokSetelahDelete, 50);
    });

    test(
        'stock opname menjadi reset absolut lalu mutasi setelahnya tetap dihitung',
        () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 20,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 3,
            sequence: 2,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 3),
            stokFisik: 12,
            sequence: 3,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 4),
            jumlah: 6,
            sequence: 4,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 5),
            jumlah: 4,
            sequence: 5,
          ),
        ],
      );

      expect(stok, 14);
    });

    test('insert opname: stok akhir mengikuti stok fisik opname terbaru', () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 30,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 10,
            sequence: 1,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 5,
            sequence: 2,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 3),
            stokFisik: 18,
            sequence: 3,
          ),
        ],
      );

      expect(stok, 18);
    });

    test('update opname: perubahan stok_fisik mengubah stok akhir', () {
      final stokSebelumUpdate = StockRecalculationEngine.calculate(
        stokAwal: 12,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 4,
            sequence: 1,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 2),
            stokFisik: 10,
            sequence: 2,
          ),
        ],
      );

      // Simulasi update baris opname yang sama (stok_fisik 10 -> 16).
      final stokSesudahUpdate = StockRecalculationEngine.calculate(
        stokAwal: 12,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 4,
            sequence: 1,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 2),
            stokFisik: 16,
            sequence: 2,
          ),
        ],
      );

      expect(stokSebelumUpdate, 10);
      expect(stokSesudahUpdate, 16);
    });

    test(
        'delete opname: hapus opname terbaru mengembalikan replay histori sebelumnya',
        () {
      final stokDenganOpnameTerbaru = StockRecalculationEngine.calculate(
        stokAwal: 10,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 2),
            stokFisik: 20,
            sequence: 2,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 3),
            jumlah: 2,
            sequence: 3,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 4),
            stokFisik: 11,
            sequence: 4,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 5),
            jumlah: 3,
            sequence: 5,
          ),
        ],
      );

      // Simulasi delete opname terbaru (id sequence 4).
      final stokSetelahDeleteOpnameTerbaru = StockRecalculationEngine.calculate(
        stokAwal: 10,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 2),
            stokFisik: 20,
            sequence: 2,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 3),
            jumlah: 2,
            sequence: 3,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 5),
            jumlah: 3,
            sequence: 5,
          ),
        ],
      );

      expect(stokDenganOpnameTerbaru, 14);
      expect(stokSetelahDeleteOpnameTerbaru, 21);
    });

    test(
        'opname lama vs terbaru: edit/hapus opname lama tidak mengalahkan reset terbaru',
        () {
      final stokDenganDuaOpname = StockRecalculationEngine.calculate(
        stokAwal: 10,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 2),
            stokFisik: 30,
            sequence: 2,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 3),
            jumlah: 4,
            sequence: 3,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 4),
            stokFisik: 12,
            sequence: 4,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 5),
            jumlah: 2,
            sequence: 5,
          ),
        ],
      );

      // Simulasi "hapus opname lama" (sequence 2), opname terbaru tetap ada.
      final stokTanpaOpnameLama = StockRecalculationEngine.calculate(
        stokAwal: 10,
        mutations: [
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 3),
            jumlah: 4,
            sequence: 3,
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 4),
            stokFisik: 12,
            sequence: 4,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 5),
            jumlah: 2,
            sequence: 5,
          ),
        ],
      );

      expect(stokDenganDuaOpname, 14);
      expect(stokTanpaOpnameLama, 14);
    });

    test('recalculation ulang bersifat idempotent', () {
      final mutations = [
        StockMutation.masuk(
          tanggal: DateTime(2026, 4, 2),
          jumlah: 12,
          sequence: 2,
        ),
        StockMutation.keluar(
          tanggal: DateTime(2026, 4, 3),
          jumlah: 7,
          sequence: 3,
        ),
        StockMutation.opname(
          tanggal: DateTime(2026, 4, 5),
          stokFisik: 20,
          sequence: 5,
        ),
        StockMutation.masuk(
          tanggal: DateTime(2026, 4, 6),
          jumlah: 2,
          sequence: 6,
        ),
      ];

      final first = StockRecalculationEngine.calculate(
        stokAwal: 5,
        mutations: mutations,
      );
      final second = StockRecalculationEngine.calculate(
        stokAwal: 5,
        mutations: mutations,
      );

      expect(first, 22);
      expect(second, first);
    });

    test('opname diproses terakhir pada tanggal yang sama', () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 10,
        mutations: [
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 1),
            stokFisik: 20,
            sequence: 3,
          ),
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 4,
            sequence: 2,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
          StockMutation.masuk(
            tanggal: DateTime(2026, 4, 2),
            jumlah: 3,
            sequence: 4,
          ),
        ],
      );

      // Mutasi di tanggal 2026-04-01 akan dioverride oleh opname tanggal yang sama.
      expect(stok, 23);
    });

    test('opname pada hari yang sama diurutkan oleh recordedAt lalu sequence',
        () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 0,
        mutations: [
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 1),
            stokFisik: 12,
            sequence: 2,
            recordedAt: DateTime(2026, 4, 1, 9, 0),
          ),
          StockMutation.opname(
            tanggal: DateTime(2026, 4, 1),
            stokFisik: 7,
            sequence: 1,
            recordedAt: DateTime(2026, 4, 1, 10, 0),
          ),
        ],
      );

      // recordedAt yang lebih akhir harus menjadi hasil final.
      expect(stok, 7);
    });

    test('stok tidak pernah menjadi negatif', () {
      final stok = StockRecalculationEngine.calculate(
        stokAwal: 2,
        mutations: [
          StockMutation.keluar(
            tanggal: DateTime(2026, 4, 1),
            jumlah: 5,
            sequence: 1,
          ),
        ],
      );

      expect(stok, 0);
    });
  });
}
