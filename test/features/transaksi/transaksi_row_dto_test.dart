import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/features/transaksi/dto/transaksi_row_dto.dart';

void main() {
  group('TransaksiRowDto', () {
    test('maps nullable and required fields safely', () {
      final dto = TransaksiRowDto.fromMap({
        'id_transaksi': '12',
        'tanggal': '2026-05-07',
        'jenis_transaksi': 'obat_ready_stock',
        'total': '150000',
        'metode_bayar': 'cash',
        'id_pasien': null,
        'keterangan': null,
        'durasi_harian': null,
        'id_admin': 2,
        'created_at': null,
      });

      final model = dto.toDomain();
      expect(model.idTransaksi, 12);
      expect(model.total, 150000);
      expect(model.jenisTransaksi.value, 'obat_ready_stock');
      expect(model.idPasien, isNull);
      expect(model.metodeBayar?.value, 'cash');
    });
  });
}
