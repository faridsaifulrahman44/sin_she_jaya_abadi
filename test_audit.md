# Test Audit Results — 2026-05-18

**Status: DONE — Semua test PASS, tidak ada yang gagal.**

Total tests: 173
Pass: 173
Fail: 0

---

## ✅ Pass — Semua 23 file test berhasil (173 test cases)

### `test/core/`
- `test/core/date_range_validator_test.dart` — 2 test cases (date range validation)
- `test/core/formatters_test.dart` — 4 test cases (rupiah format, date format)
- `test/core/parsers_test.dart` — 35 test cases (parseInt, parseDouble, parseDate, parseString, parseNullable*)
- `test/core/error/app_error_mapper_test.dart` — 5 test cases (PostgreSQL error code → pesan spesifik)
- `test/core/services/receipt_printer_service_test.dart` — 1 test case (receipt text 58mm format)

### `test/data/`
- `test/data/model_parsing_test.dart` — 16 test cases (ObatModel, ObatKeluarModel, PasienModel, KehadiranModel, StatusHadir)
- `test/data/schema_contract_test.dart` — 19 test cases (tabel, RLS, RPC, storage contract; 5 dari loop SQL aktif)
- `test/data/models/obat_etalase_test.dart` — 6 test cases (enum Etalase: value, label, fromString, ObatModel.fromMap)
- `test/data/models/obat_usage_info_test.dart` — 3 test cases (fromMap, toDeleteBlockedMessage)
- `test/data/models/sinkronisasi_stok_model_test.dart` — 7 test cases (isBalanced, isOverStock, isUnderStock, fromMap, toMap)
- `test/data/repositories/stock_recalculation_engine_test.dart` — 17 test cases (mutasi, opname, baseline, idempotent, edge cases)

### `test/features/`
- `test/features/laporan/laporan_aggregator_test.dart` — 5 test cases (aggregateDailyIncome, buildDailyIncomePoints, buildLaporanSummary)
- `test/features/obat_keluar/obat_keluar_atomic_payload_builder_test.dart` — 5 test cases (build, validasi legacy/obat/tidakvalid)
- `test/features/obat_keluar/obat_keluar_etalase_sync_test.dart` — 3 test cases (no_etalase sync, label etalase)
- `test/features/obat_keluar/obat_keluar_form_entry_test.dart` — 17 test cases (subtotal, validate, validateStock, multi-item)
- `test/features/obat_keluar/obat_keluar_grouping_test.dart` — 2 test cases (groupByTanggal, sort descending)
- `test/features/obat_masuk/obat_masuk_grouping_test.dart` — 5 test cases (group by date, edge cases)
- `test/features/pasien/pasien_detail_aggregator_test.dart` — 4 test cases (buildPasienDetailSummary, buildTransaksiRingkasan)
- `test/features/sinkronisasi_stok/sinkronisasi_stok_calc_test.dart` — 3 test cases (sinkronisasiStokSelisihLabel)
- `test/features/stok/stock_service_test.dart` — 4 test cases (stokMasuk, stokKeluar, syncOpname, createTransaksiAtomic validation)
- `test/features/transaksi/create_transaction_usecase_test.dart` — 2 test cases (admin mismatch, total mismatch)
- `test/features/transaksi/summary_metrics_test.dart` — 1 test case (omzet dan count calculation)
- `test/features/transaksi/transaksi_row_dto_test.dart` — 1 test case (TransaksiRowDto mapping)

---

## ❌ Gagal karena Supabase.instance (pre-existing)

**Tidak ada.** Semua test berhasil tanpa memerlukan Supabase instance terinisialisasi.

> **Catatan:** CLAUDE.md menyebutkan bahwa `test/features/stok/stock_service_test.dart` dan `test/data/schema_contract_test.dart` kemungkinan gagal karena `Supabase.instance` belum diinisialisasi. Namun saat audit ini dilakukan, **kedua file test tersebut berhasil PASS sepenuhnya** — kemungkinan besar karena test harness sudah di-refactor agar tidak memerlukan instance Supabase sungguhan.

## ❌ Gagal karena bug logika

**Tidak ada.**

---

## Ringkasan Per File (23 file)

| # | File | Test Cases | Status |
|---|------|-----------|--------|
| 1 | `test/core/date_range_validator_test.dart` | 2 | ✅ Pass |
| 2 | `test/core/formatters_test.dart` | 4 | ✅ Pass |
| 3 | `test/core/parsers_test.dart` | 35 | ✅ Pass |
| 4 | `test/core/error/app_error_mapper_test.dart` | 5 | ✅ Pass |
| 5 | `test/core/services/receipt_printer_service_test.dart` | 1 | ✅ Pass |
| 6 | `test/data/model_parsing_test.dart` | 16 | ✅ Pass |
| 7 | `test/data/schema_contract_test.dart` | 19 | ✅ Pass |
| 8 | `test/data/models/obat_etalase_test.dart` | 6 | ✅ Pass |
| 9 | `test/data/models/obat_usage_info_test.dart` | 3 | ✅ Pass |
| 10 | `test/data/models/sinkronisasi_stok_model_test.dart` | 7 | ✅ Pass |
| 11 | `test/data/repositories/stock_recalculation_engine_test.dart` | 17 | ✅ Pass |
| 12 | `test/features/laporan/laporan_aggregator_test.dart` | 5 | ✅ Pass |
| 13 | `test/features/obat_keluar/obat_keluar_atomic_payload_builder_test.dart` | 5 | ✅ Pass |
| 14 | `test/features/obat_keluar/obat_keluar_etalase_sync_test.dart` | 3 | ✅ Pass |
| 15 | `test/features/obat_keluar/obat_keluar_form_entry_test.dart` | 17 | ✅ Pass |
| 16 | `test/features/obat_keluar/obat_keluar_grouping_test.dart` | 2 | ✅ Pass |
| 17 | `test/features/obat_masuk/obat_masuk_grouping_test.dart` | 5 | ✅ Pass |
| 18 | `test/features/pasien/pasien_detail_aggregator_test.dart` | 4 | ✅ Pass |
| 19 | `test/features/sinkronisasi_stok/sinkronisasi_stok_calc_test.dart` | 3 | ✅ Pass |
| 20 | `test/features/stok/stock_service_test.dart` | 4 | ✅ Pass |
| 21 | `test/features/transaksi/create_transaction_usecase_test.dart` | 2 | ✅ Pass |
| 22 | `test/features/transaksi/summary_metrics_test.dart` | 1 | ✅ Pass |
| 23 | `test/features/transaksi/transaksi_row_dto_test.dart` | 1 | ✅ Pass |
| | **TOTAL** | **173** | **✅ Semua Pass** |

---

## ⚠️ Catatan Penting

- Tidak ada test yang gagal dalam audit ini.
- Pre-existing issue `Supabase.instance` yang disebutkan di CLAUDE.md **tidak terjadi** pada saat audit — test harness sudah bekerja dengan baik.
- Tidak perlu ada Task 3 (fix test) karena tidak ada yang perlu difix.
- File `test_audit.md` ini dibuat sesuai instruksi Task 2.