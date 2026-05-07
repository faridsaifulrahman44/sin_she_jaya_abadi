# Supabase Schema & Migration Guide

## Source Of Truth

- Baseline schema final: `supabase/schema.sql`
- Fase saat ini menganggap `schema.sql` sebagai representasi final tunggal.
- Tabel `transaksi`, `transaksi_item`, dan `kunjungan_pasien` sekarang sudah
  masuk di `schema.sql` (ditambahkan STEP 2 sinkronisasi, 2026-04-17).
  Tidak ada migration terpisah untuk tabel-tabel ini.
- RPC function `fn_transaksi_insert` dipakai oleh `TransaksiRepository`
  sebagai jalur atomik utama. Aplikasi tidak memakai fallback insert manual
  untuk transaksi pembayaran agar policy SELECT riwayat tetap owner-only.
- Baseline schema final: `supabase/schema.sql`
- Fase saat ini menganggap `schema.sql` adalah representasi final tunggal.

## Status Migration
- `migration_add_tanggal_janjian.sql` -> `RETAINED` (legacy upgrade: tambah `tanggal_janjian`).
- `migration_create_stock_opname.sql` -> `RETAINED` (legacy filename; bootstrap tabel final `sinkronisasi_stok`).
- `migration_obat_keluar_item_final.sql` -> `RETAINED` (final redesign `obat_keluar_item`, backfill legacy aman).
- `migration_fase1_stock_engine.sql` -> `RETAINED` (tambah/backfill `stok_awal`).
- `migration_fase2_obat_keluar_atomic.sql` -> `RETAINED` (RPC atomik transaksi keluar + stok).
- `migration_fase2_transaksi.sql` -> `RETAINED` (kontrak transaksi + RPC `fn_transaksi_insert`).
- `migration_fase3_schema_cleanup.sql` -> `RETAINED` (sinkronisasi final untuk environment campuran).
- `migration_fase5_fix_stock_double_count.sql` -> `RETAINED` (hotfix normalisasi `stok_awal` legacy untuk cegah double count).
- `migration_fase6_obat_masuk_stock_opname_atomic.sql` -> `RETAINED` (RPC atomik obat masuk + sinkronisasi stok; nama RPC stock_opname dipertahankan untuk kompatibilitas Flutter).
- `migration_fase7_stock_opname_delete_by_tanggal_atomic.sql` -> `RETAINED` (bulk delete sinkronisasi stok per tanggal; nama RPC stock_opname dipertahankan).
- `migration_fase7_kunjungan.sql` -> `RETAINED` (backward compat; tabel `kunjungan_pasien` sudah ada di schema.sql; migration ini tidak dipakai langsung oleh app tetapi definisinya tidak bertentangan).
- `migration_fase8_obat_delete_guard.sql` -> `RETAINED` (delete obat atomik dengan guard histori agar referensi transaksi tetap aman).
- `migration_fase9_pasien_delete_guard.sql` -> `RETAINED` (guard delete pasien versi awal).
- `migration_fase10_pasien_delete_cascade.sql` -> `RETAINED` (selaraskan FK `kehadiran_pasien` ke `ON DELETE CASCADE` dan hilangkan blocker kehadiran pada flow hapus pasien).
- `migration_refactor_obat_stok.sql` -> `OBSOLETE` (DROP kolom `stok_awal` yang diperlukan engine final; JANGAN apply).
- `migration_redesign_obat_keluar.sql` -> `OBSOLETE` (draft awal; overlap dengan `migration_obat_keluar_item_final.sql` dan punya mismatch nullable `id_obat`).
- `migration_fase_etalase_constraint_repair.sql` -> `RETAINED` (repair data etalase + pastikan `obat_etalase_check` terpasang; AMAN untuk semua environment).
- `migration_fase11_oversell_guard.sql` -> `RETAINED` (guard oversell di RPC insert/update transaksi keluar; WAJIB untuk semua environment).
- `migration_fase12_rls_harden.sql` -> `RETAINED` (RLS hardening awal; digantikan/ditingkatkan oleh FASE 20 untuk role owner/admin).
- `migration_fase13_pasien_renumber_after_delete.sql` -> `REQUIRED` (auto-renumber `nomor_pasien` 1..N setelah delete pasien; MEWAJIBKAN apply ke semua environment). **Migration ini wajib di-apply agar fitur delete pasien tidak error.**
- `migration_fase15_pasien_contract_cleanup.sql` -> `REQUIRED` (hapus RPC legacy `fn_pasien_delete_if_unused` agar kontrak pasien tidak ambigu; tetapkan `fn_pasien_delete_and_renumber` sebagai kontrak final).
- `migration_fase16_obat_image_storage.sql` -> `REQUIRED` (buat bucket `obat-images` + policy storage untuk fitur foto obat di Master Obat).
- `migration_fase18_ecer_satuan_terjual.sql` -> `REQUIRED` (tambah `transaksi_item.satuan_terjual` untuk transaksi ecer/satuan jual).
- `migration_fase19_supabase_p0_sync.sql` -> `REQUIRED` (patch P0 idempotent: sinkronisasi stok final, kolom foto, dan RPC transaksi/stock_opname kompatibel Flutter).
- `migration_fase20_rls_owner_admin_harden.sql` -> `REQUIRED` (P1: helper role admin, RLS owner/petugas, validasi RPC SECURITY DEFINER).
- `migration_fase21_transaksi_history_owner_only.sql` -> `REQUIRED` (P2: riwayat/detail transaksi owner-only; petugas tetap tambah transaksi via RPC).
- `migration_fase22_recalculate_include_transaksi_items.sql` -> `REQUIRED` (P2: recalculate stok menghitung `transaksi_item` ready-stock).

### Kontrak Final Pasien
- Function delete pasien yang dipakai aplikasi: `public.fn_pasien_delete_and_renumber(bigint)`.
- `fn_pasien_delete_if_unused` adalah kontrak lama dan wajib dibersihkan via `migration_fase15_pasien_contract_cleanup.sql`.

## Urutan Apply Aman (Existing DB / Legacy DB)
1. `migration_create_stock_opname.sql`
2. `migration_add_tanggal_janjian.sql`
3. `migration_obat_keluar_item_final.sql`
4. `migration_fase1_stock_engine.sql`
5. `migration_fase2_obat_keluar_atomic.sql`
6. `migration_fase3_schema_cleanup.sql`
7. `migration_fase5_fix_stock_double_count.sql`
8. `migration_fase6_obat_masuk_stock_opname_atomic.sql`
9. `migration_fase7_stock_opname_delete_by_tanggal_atomic.sql`
10. `migration_fase8_obat_delete_guard.sql`
11. `migration_fase9_pasien_delete_guard.sql`
12. `migration_fase10_pasien_delete_cascade.sql`
13. `migration_fase_etalase_constraint_repair.sql`
14. `migration_fase11_oversell_guard.sql`
15. `migration_fase12_rls_harden.sql`
16. `migration_fase13_pasien_renumber_after_delete.sql` **<- WAJIB**
17. `migration_fase15_pasien_contract_cleanup.sql` **<- WAJIB**
18. `migration_fase16_obat_image_storage.sql` **<- WAJIB**
19. `migration_fase18_ecer_satuan_terjual.sql` **<- WAJIB**
20. `migration_fase19_supabase_p0_sync.sql` **<- WAJIB**
21. `migration_fase20_rls_owner_admin_harden.sql` **<- WAJIB**
22. `migration_fase21_transaksi_history_owner_only.sql` **<- WAJIB**
23. `migration_fase22_recalculate_include_transaksi_items.sql` **<- WAJIB**

## Urutan Apply Aman (Fresh Environment)
1. `schema.sql`

## Model Akses Data (Access Control)

### Lapisan Keamanan
| Layer | Mekanisme | Enforcement |
|---|---|---|
| Primary | RPC functions (Dart `ObatRepository`, dll.) | `AdminSession.getCurrentId()` memvalidasi auth session â†’ id_admin â†’ RPC call |
| Secondary | RLS Policies (PostgreSQL) | Defense-in-depth untuk akses PostgREST langsung |

**Penting**: RLS bukan satu-satunya enforcement. RPC functions yang dipanggil dari aplikasi adalah primary security boundary. RLS melindungi terhadap akses PostgREST langsung (misalnya via Supabase Dashboard SQL Editor atau API lain yang menggunakan token).

### Tabel & Policy
| Tabel | Policy | Akses |
|---|---|---|
| `admin` | `public.is_clinic_staff()` read; owner-only write | Staff terdaftar |
| `obat` | `public.is_clinic_staff()` | Owner + petugas |
| `obat_masuk` | read staff; write `current_admin_id() = id_admin` | Owner + petugas |
| `obat_keluar` | read staff; write `current_admin_id() = id_admin` | Owner + petugas |
| `obat_keluar_item` | `public.is_clinic_staff()` | Owner + petugas |
| `sinkronisasi_stok` | read staff; write `current_admin_id() = id_admin` | Owner + petugas |
| `pasien` | `public.is_clinic_staff()` | Owner + petugas |
| `kehadiran_pasien` | read/delete staff; write `current_admin_id() = id_admin` | Owner + petugas |

DELETE policy langsung hanya dibuka untuk data yang memang dihapus langsung oleh Flutter
(`kehadiran_pasien`, `kunjungan_pasien`) dan admin management owner-only.
Penghapusan stok/transaksi tetap lewat RPC tervalidasi.

### Tabel & Policy (lanjutan)
| Tabel | Policy | Akses |
|---|---|---|
| `transaksi` | SELECT owner-only; INSERT staff dengan `current_admin_id() = id_admin`; UPDATE owner-only | Owner lihat riwayat; petugas tambah |
| `transaksi_item` | SELECT owner-only; INSERT staff dengan `current_admin_id() = id_admin`; UPDATE owner-only | Owner lihat detail; petugas tambah |
| `kunjungan_pasien` | read/delete staff; write `current_admin_id() = id_admin` | Owner + petugas |

### Tabel Aktif (Steady-State)
Semua tabel berikut sudah ada di `schema.sql` dan dipakai oleh kode aplikasi:
| Tabel | Kode Repository | Steady-State |
|---|---|---|
| `admin` | `AdminSession` | Langsung |
| `obat` | `ObatRepository` | Langsung |
| `obat_masuk` | `ObatMasukRepository` | Langsung |
| `obat_keluar` | `ObatKeluarRepository` | Langsung |
| `obat_keluar_item` | `ObatKeluarRepository` | Langsung |
| `sinkronisasi_stok` | `SinkronisasiStokRepository` | Langsung |
| `pasien` | `PasienRepository` | Langsung |
| `kehadiran_pasien` | `KehadiranRepository` | Langsung |
| `transaksi` | `TransaksiRepository` | Langsung |
| `transaksi_item` | `TransaksiRepository` | Langsung |
| `kunjungan_pasien` | `KunjunganRepository` | Langsung |

### Kolom Tambahan Aktif
| Tabel | Kolom | Dipakai di |
|---|---|---|
| `obat` | `foto_url text` | `ObatModel.fotoUrl` (nullable, untuk foto produk obat) |
| `obat` | `foto_key text` | `ObatModel.fotoKey` (storage key final) |
| `obat` | `foto_updated_at timestamptz` | `ObatModel.fotoUpdatedAt` |
| `transaksi_item` | `satuan_terjual varchar(30)` | `TransaksiItemModel.satuanTerjual` |

### Storage Aktif
| Bucket | Public | Batas File | MIME |
|---|---|---|---|
| `obat-images` | Ya | 5 MB | `image/jpeg`, `image/png`, `image/webp` |

### RPC / Function Aktif (Dipakai Kode)
| Function | Dipakai di | Notes |
|---|---|---|
| `fn_transaksi_insert(...)` | `TransaksiRepository` | Insert transaksi atomik + item `satuan_terjual`; jalur resmi tambah transaksi |
| `fn_recalculate_obat_stok_single(bigint)` | RPC stok dan repository obat | Recalculate stok single-obat |
| `fn_obat_kurangi_stok(int, int)` | Legacy RPC support | Dipertahankan untuk kompatibilitas DB lama; bukan fallback transaksi pembayaran |
| `fn_obat_keluar_insert_atomic(...)` | `ObatKeluarRepository` | Obat keluar atomik |
| `fn_obat_keluar_update_atomic(...)` | `ObatKeluarRepository` | Update atomik |
| `fn_obat_keluar_delete_atomic(bigint)` | `ObatKeluarRepository` | Delete atomik |
| `fn_obat_keluar_delete_by_tanggal_atomic(date)` | `ObatKeluarRepository` | Bulk delete |
| `fn_obat_masuk_insert_atomic(...)` | `ObatMasukRepository` | Obat masuk atomik |
| `fn_obat_masuk_update_atomic(...)` | `ObatMasukRepository` | Update atomik |
| `fn_obat_masuk_delete_atomic(bigint)` | `ObatMasukRepository` | Delete atomik |
| `fn_obat_masuk_delete_by_tanggal_atomic(date)` | `ObatMasukRepository` | Bulk delete |
| `fn_stock_opname_insert_atomic(...)` | `SinkronisasiStokRepository` | Sinkronisasi stok atomik |
| `fn_stock_opname_update_atomic(...)` | `SinkronisasiStokRepository` | Update atomik |
| `fn_stock_opname_delete_atomic(bigint)` | `SinkronisasiStokRepository` | Delete atomik |
| `fn_stock_opname_delete_by_tanggal_atomic(date)` | `SinkronisasiStokRepository` | Bulk delete |
| `fn_obat_delete_if_unused(bigint)` | `ObatRepository` | Guarded delete |
| `fn_pasien_delete_and_renumber(bigint)` | `PasienRepository` | Delete + renumber |
| `fn_recalculate_obat_stok_bulk(bigint[])` | `StockRecalculationEngine` | Bulk recalc |
| `get_auth_admin_id()` | RLS policies | Auth helper |
| `current_admin_id()` | RLS/RPC policies | Auth helper final |
| `current_admin_role()` | RLS/RPC policies | Role helper final |
| `is_owner()` / `is_petugas()` / `is_clinic_staff()` | RLS/RPC policies | Role gates |
| `can_view_laporan()` | Future DB report surfaces | Owner-only report gate |

**Catatan**: nama RPC `fn_stock_opname_*` dipertahankan untuk kompatibilitas aplikasi, tetapi seluruh operasi data memakai tabel final `sinkronisasi_stok`.

### RLS P1 Owner/Admin
- Semua akses operasional mensyaratkan user Supabase Auth memiliki mapping di `public.admin`.
- Role valid: `petugas` dan `kepala_klinik`.
- `kepala_klinik`/owner dapat mengakses fitur laporan di Flutter.
- Riwayat/detail transaksi (`transaksi`, `transaksi_item`) owner-only di database; petugas tetap menambah transaksi lewat `fn_transaksi_insert`.
- RPC `SECURITY DEFINER` yang mutasi data memanggil `require_clinic_staff(...)` agar tidak hanya bergantung pada token authenticated.

### Asumsi
- Single-clinic, single-tenant (semua staff bisa mengakses semua data klinik)
- Role-based access (`petugas` vs `kepala_klinik`) sudah tersedia di helper RLS P1; report-specific DB surface belum ada.
- Semua staff adalah `authenticated` user yang sudah ter-mapping ke `admin` row

### Gap / Next Enhancement
- [ ] Tambahkan view/RPC laporan owner-only jika laporan perlu dibatasi di database, bukan hanya UI.
- [ ] Audit log: setiap mutation catat `id_admin` dan timestamp
- [ ] Multi-tenant isolation (jika berkembang ke multi-klinik)
- [ ] API key / service role restrictions

## Catatan Legacy Data
- Jika dulu sempat menjalankan `migration_redesign_obat_keluar.sql`, pastikan `obat_keluar_item.id_obat` sudah nullable.
- Transaksi keluar lama yang belum punya detail item akan dibackfill sebagai `is_legacy = true`.
- `stok_awal` akan dibackfill dari snapshot + histori mutasi agar konsisten dengan engine stok final.
- Jika ditemukan kasus stok melonjak saat tambah obat masuk (contoh 11 -> 33), jalankan `migration_fase5_fix_stock_double_count.sql`.
- Kolom `obat_keluar.jumlah_transaksi` dan `obat_keluar.total_nominal` tetap dipertahankan sebagai summary cache karena masih dipakai kode saat ini.
- Guard oversell (`CHECK_STOCK_FAILED`) di `fn_obat_keluar_insert_atomic` dan `fn_obat_keluar_update_atomic` mencegah transaksi yang qty > stok tersedia. Guard ini idempotent â€” aman dijalankan ulang.
