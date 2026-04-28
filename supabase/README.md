# Supabase Schema & Migration Guide

## Source Of Truth

- Baseline schema final: `supabase/schema.sql`
- Fase saat ini menganggap `schema.sql` sebagai representasi final tunggal.
- Tabel `transaksi`, `transaksi_item`, dan `kunjungan_pasien` sekarang sudah
  masuk di `schema.sql` (ditambahkan STEP 2 sinkronisasi, 2026-04-17).
  Tidak ada migration terpisah untuk tabel-tabel ini.
- RPC function `fn_transaksi_insert` (dari `migration_fase2_transaksi.sql`)
  saat ini TIDAK dipakai oleh kode aplikasi. Aplikasi insert transaksi via
  Supabase client langsung. Function tetap dipertahankan di schema untuk
  backward compatibility jika nanti dibutuhkan.
- Baseline schema final: `supabase/schema.sql`
- Fase saat ini menganggap `schema.sql` adalah representasi final tunggal.

## Status Migration
- `migration_add_tanggal_janjian.sql` -> `RETAINED` (legacy upgrade: tambah `tanggal_janjian`).
- `migration_create_stock_opname.sql` -> `RETAINED` (legacy upgrade: bootstrap `stock_opname`).
- `migration_obat_keluar_item_final.sql` -> `RETAINED` (final redesign `obat_keluar_item`, backfill legacy aman).
- `migration_fase1_stock_engine.sql` -> `RETAINED` (tambah/backfill `stok_awal`).
- `migration_fase2_obat_keluar_atomic.sql` -> `RETAINED` (RPC atomik transaksi keluar + stok).
- `migration_fase2_transaksi.sql` -> `RETAINED` (backward compat; function `fn_transaksi_insert` tidak dipakai app, tetapi definisi function dan `fn_obat_kurangi_stok` masih ada di schema).
- `migration_fase3_schema_cleanup.sql` -> `RETAINED` (sinkronisasi final untuk environment campuran).
- `migration_fase5_fix_stock_double_count.sql` -> `RETAINED` (hotfix normalisasi `stok_awal` legacy untuk cegah double count).
- `migration_fase6_obat_masuk_stock_opname_atomic.sql` -> `RETAINED` (RPC atomik obat masuk + stock opname + recalc stok dalam satu transaksi).
- `migration_fase7_stock_opname_delete_by_tanggal_atomic.sql` -> `RETAINED` (bulk delete stock opname per tanggal secara atomik + recalc stok terdampak).
- `migration_fase7_kunjungan.sql` -> `RETAINED` (backward compat; tabel `kunjungan_pasien` sudah ada di schema.sql; migration ini tidak dipakai langsung oleh app tetapi definisinya tidak bertentangan).
- `migration_fase8_obat_delete_guard.sql` -> `RETAINED` (delete obat atomik dengan guard histori agar referensi transaksi tetap aman).
- `migration_fase9_pasien_delete_guard.sql` -> `RETAINED` (guard delete pasien versi awal).
- `migration_fase10_pasien_delete_cascade.sql` -> `RETAINED` (selaraskan FK `kehadiran_pasien` ke `ON DELETE CASCADE` dan hilangkan blocker kehadiran pada flow hapus pasien).
- `migration_refactor_obat_stok.sql` -> `OBSOLETE` (DROP kolom `stok_awal` yang diperlukan engine final; JANGAN apply).
- `migration_redesign_obat_keluar.sql` -> `OBSOLETE` (draft awal; overlap dengan `migration_obat_keluar_item_final.sql` dan punya mismatch nullable `id_obat`).
- `migration_fase_etalase_constraint_repair.sql` -> `RETAINED` (repair data etalase + pastikan `obat_etalase_check` terpasang; AMAN untuk semua environment).
- `migration_fase11_oversell_guard.sql` -> `RETAINED` (guard oversell di RPC insert/update transaksi keluar; WAJIB untuk semua environment).
- `migration_fase12_rls_harden.sql` -> `RETAINED` (RLS policy ketat: admin dilindungi per-user, business tables menggunakan `auth.uid() IS NOT NULL`; WAJIB untuk semua environment).
- `migration_fase13_pasien_renumber_after_delete.sql` -> `REQUIRED` (auto-renumber `nomor_pasien` 1..N setelah delete pasien; MEWAJIBKAN apply ke semua environment). **Migration ini wajib di-apply agar fitur delete pasien tidak error.**
- `migration_fase15_pasien_contract_cleanup.sql` -> `REQUIRED` (hapus RPC legacy `fn_pasien_delete_if_unused` agar kontrak pasien tidak ambigu; tetapkan `fn_pasien_delete_and_renumber` sebagai kontrak final).
- `migration_fase16_obat_image_storage.sql` -> `REQUIRED` (buat bucket `obat-images` + policy storage untuk fitur foto obat di Master Obat).

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
| `admin` | `auth.uid() = auth_user_id` | Hanya baris miliknya sendiri |
| `obat` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `obat_masuk` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `obat_keluar` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `obat_keluar_item` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `stock_opname` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `pasien` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `kehadiran_pasien` | `auth.uid() IS NOT NULL` | Semua authenticated |

**Tidak ada DELETE policy** â€” semua penghapusan HARUS lewat RPC functions (ini disengaja).

### Tabel & Policy (lanjutan)
| Tabel | Policy | Akses |
|---|---|---|
| `transaksi` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `transaksi_item` | `auth.uid() IS NOT NULL` | Semua authenticated |
| `kunjungan_pasien` | `auth.uid() IS NOT NULL` | Semua authenticated |

### Tabel Aktif (Steady-State)
Semua tabel berikut sudah ada di `schema.sql` dan dipakai oleh kode aplikasi:
| Tabel | Kode Repository | Steady-State |
|---|---|---|
| `admin` | `AdminSession` | Langsung |
| `obat` | `ObatRepository` | Langsung |
| `obat_masuk` | `ObatMasukRepository` | Langsung |
| `obat_keluar` | `ObatKeluarRepository` | Langsung |
| `obat_keluar_item` | `ObatKeluarRepository` | Langsung |
| `stock_opname` | `StockOpnameRepository` | Langsung |
| `pasien` | `PasienRepository` | Langsung |
| `kehadiran_pasien` | `KehadiranRepository` | Langsung |
| `transaksi` | `TransaksiRepository` | Langsung |
| `transaksi_item` | `TransaksiRepository` | Langsung |
| `kunjungan_pasien` | `KunjunganRepository` | Langsung |

### Kolom Tambahan Aktif
| Tabel | Kolom | Dipakai di |
|---|---|---|
| `obat` | `foto_url text` | `ObatModel.fotoUrl` (nullable, untuk foto produk obat) |

### Storage Aktif
| Bucket | Public | Batas File | MIME |
|---|---|---|---|
| `obat-images` | Ya | 5 MB | `image/jpeg`, `image/png`, `image/webp` |

### RPC / Function Aktif (Dipakai Kode)
| Function | Dipakai di | Notes |
|---|---|---|
| `fn_recalculate_obat_stok_single(bigint)` | `TransaksiRepository.insertTransaksi` | Primary stok recalc |
| `fn_obat_kurangi_stok(int, int)` | `TransaksiRepository.insertTransaksi` | Fallback jika RPC utama gagal |
| `fn_obat_keluar_insert_atomic(...)` | `ObatKeluarRepository` | Obat keluar atomik |
| `fn_obat_keluar_update_atomic(...)` | `ObatKeluarRepository` | Update atomik |
| `fn_obat_keluar_delete_atomic(bigint)` | `ObatKeluarRepository` | Delete atomik |
| `fn_obat_keluar_delete_by_tanggal_atomic(date)` | `ObatKeluarRepository` | Bulk delete |
| `fn_obat_masuk_insert_atomic(...)` | `ObatMasukRepository` | Obat masuk atomik |
| `fn_obat_masuk_update_atomic(...)` | `ObatMasukRepository` | Update atomik |
| `fn_obat_masuk_delete_atomic(bigint)` | `ObatMasukRepository` | Delete atomik |
| `fn_obat_masuk_delete_by_tanggal_atomic(date)` | `ObatMasukRepository` | Bulk delete |
| `fn_stock_opname_insert_atomic(...)` | `StockOpnameRepository` | Stock opname atomik |
| `fn_stock_opname_update_atomic(...)` | `StockOpnameRepository` | Update atomik |
| `fn_stock_opname_delete_atomic(bigint)` | `StockOpnameRepository` | Delete atomik |
| `fn_stock_opname_delete_by_tanggal_atomic(date)` | `StockOpnameRepository` | Bulk delete |
| `fn_obat_delete_if_unused(bigint)` | `ObatRepository` | Guarded delete |
| `fn_pasien_delete_and_renumber(bigint)` | `PasienRepository` | Delete + renumber |
| `fn_recalculate_obat_stok_bulk(bigint[])` | `StockRecalculationEngine` | Bulk recalc |
| `get_auth_admin_id()` | RLS policies | Auth helper |

**Catatan**: `fn_transaksi_insert` (dari `migration_fase2_transaksi.sql`) **tidak dipakai** aplikasi saat ini. Aplikasi insert transaksi via Supabase client langsung.

### Asumsi
- Single-clinic, single-tenant (semua staff bisa mengakses semua data klinik)
- Role-based access (`petugas` vs `kepala_klinik`) belum diimplementasi di RLS
- Semua staff adalah `authenticated` user yang sudah ter-mapping ke `admin` row

### Gap / Next Enhancement
- [ ] Role-based RLS: petugas hanya read, kepala_klinik bisa write
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
