# Architecture Upgrade Notes (Incremental)

Dokumen ini menjelaskan upgrade arsitektur yang diterapkan tanpa memutus fitur existing.

## 1) Riverpod Foundation

- `ProviderScope` aktif di `main.dart`.
- Provider modul transaksi ditambahkan:
  - `adminRoleProvider`
  - `transaksiHistoryByRangeProvider`
  - `transaksiHistoryRepositoryProvider`
- Halaman `TransaksiHubPage` telah dimigrasikan ke `ConsumerStatefulWidget` untuk state async yang lebih terstruktur.

## 2) Stock Logic Isolation

- Service baru: `lib/features/stok/services/stock_service.dart`
- Semua operasi mutasi stok utama (masuk/keluar/opname) disatukan ke satu gateway service.
- Validasi dasar anti-negatif dipusatkan.

## 3) Supabase Sync Safety

- Konstanta tabel/kolom/RPC terpusat:
  - `lib/core/database/db_tables.dart`
- DTO transaksi terpisah dari domain model:
  - `lib/features/transaksi/dto/transaksi_row_dto.dart`
- Repository typed transaksi history:
  - `lib/features/transaksi/repositories/transaksi_history_repository.dart`
- Runtime schema guard opsional:
  - `lib/core/supabase/schema_guard.dart`
  - aktif via `--dart-define=VERIFY_SCHEMA_CONTRACT=true`

## 4) Routing Scalability

- Registry route dipisahkan dari `app.dart`:
  - `lib/core/routing/app_route_registry.dart`
- Scaffold go_router disiapkan untuk migrasi bertahap:
  - `lib/core/routing/app_router.dart`

## 5) Error Handling & UI Feedback

- Error mapping existing dipertahankan.
- Unified feedback helper:
  - `lib/core/feedback/app_feedback.dart`

## 6) Design System Tokens

- Token reusable ditambahkan:
  - `lib/core/design_system/app_tokens.dart`
  - `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppColors`

## 7) Supabase Migration Workflow

- Folder migration terstruktur:
  - `supabase/migrations/README.md`

## 8) Testing Foundation (Added)

- `test/features/stok/stock_service_test.dart`
- `test/features/transaksi/transaksi_row_dto_test.dart`
- `test/features/transaksi/summary_metrics_test.dart`
