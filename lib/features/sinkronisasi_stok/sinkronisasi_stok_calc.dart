/// Helper untuk label selisih pada fitur Sinkronisasi Stok.
///
/// Tabel Supabase: `sinkronisasi_stok`.
/// Nama fitur di aplikasi adalah Sinkronisasi Stok.
String sinkronisasiStokSelisihLabel(int selisih) {
  if (selisih == 0) return 'Sesuai';
  if (selisih > 0) return '+$selisih';
  return '$selisih';
}
