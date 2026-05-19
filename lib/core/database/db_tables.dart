class DbTables {
  const DbTables._();

  static const admin = 'admin';
  static const pasien = 'pasien';
  static const transaksi = 'transaksi';
  static const transaksiItem = 'transaksi_item';
  static const obat = 'obat';
  static const obatMasuk = 'obat_masuk';
  static const obatKeluar = 'obat_keluar';
  static const obatKeluarItem = 'obat_keluar_item';
  static const sinkronisasiStok = 'sinkronisasi_stok';
  static const stockMovements = 'stock_movements';
  static const kasKeluar = 'kas_keluar';
}

class DbColumns {
  const DbColumns._();

  static const idAdmin = 'id_admin';
  static const role = 'role';
  static const authUserId = 'auth_user_id';

  static const idPasien = 'id_pasien';
  static const namaPasien = 'nama_pasien';

  static const idTransaksi = 'id_transaksi';
  static const tanggal = 'tanggal';
  static const jenisTransaksi = 'jenis_transaksi';
  static const total = 'total';
  static const metodeBayar = 'metode_bayar';
  static const keterangan = 'keterangan';
  static const createdAt = 'created_at';

  static const idOpname = 'id_opname';
  static const idObat = 'id_obat';
  static const tanggalOpname = 'tanggal_opname';
  static const stokSistem = 'stok_sistem';
  static const stokFisik = 'stok_fisik';

  static const idMasuk = 'id_masuk';
  static const tanggalMasuk = 'tanggal_masuk';
  static const jumlahMasuk = 'jumlah_masuk';

  static const idTerjual = 'id_terjual';
  static const tanggalTerjual = 'tanggal_terjual';

  static const stockMovementId = 'id';
  static const stockMovementQty = 'qty';
  static const stockMovementType = 'movement_type';
  static const stockMovementReferenceType = 'reference_type';
  static const stockMovementReferenceId = 'reference_id';
  static const stockMovementCreatedBy = 'created_by';
}

class DbRpc {
  const DbRpc._();

  static const transaksiInsertAtomic = 'fn_transaksi_insert';
  static const createTransactionAtomic = 'fn_create_transaction';
  static const obatMasukInsertAtomic = 'fn_obat_masuk_insert_atomic';
  static const obatMasukUpdateAtomic = 'fn_obat_masuk_update_atomic';
  static const obatMasukDeleteAtomic = 'fn_obat_masuk_delete_atomic';
  static const obatMasukDeleteByTanggalAtomic =
      'fn_obat_masuk_delete_by_tanggal_atomic';

  static const obatKeluarInsertAtomic = 'fn_obat_keluar_insert_atomic';
  static const obatKeluarUpdateAtomic = 'fn_obat_keluar_update_atomic';
  static const obatKeluarDeleteAtomic = 'fn_obat_keluar_delete_atomic';
  static const obatKeluarDeleteByTanggalAtomic =
      'fn_obat_keluar_delete_by_tanggal_atomic';

  static const stockOpnameInsertAtomic = 'fn_stock_opname_insert_atomic';
  static const stockOpnameUpdateAtomic = 'fn_stock_opname_update_atomic';
  static const stockOpnameDeleteAtomic = 'fn_stock_opname_delete_atomic';
  static const stockOpnameDeleteByTanggalAtomic =
      'fn_stock_opname_delete_by_tanggal_atomic';
}
