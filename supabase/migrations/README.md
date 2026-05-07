# Supabase Migration Workflow

Gunakan folder ini sebagai single source of truth perubahan schema.

## Aturan

1. Jangan ubah tabel produksi manual dari dashboard tanpa migration file.
2. Setiap perubahan schema/RLS/RPC wajib dibuat sebagai file migration SQL baru.
3. Setelah migration dibuat:
   - jalankan migration ke environment dev/staging,
   - perbarui model/DTO/repository di Flutter,
   - jalankan test kontrak schema.

## Naming Convention

Gunakan format timestamp + deskripsi:

`YYYYMMDDHHmm__deskripsi_perubahan.sql`

Contoh:

`202605071230__add_transaksi_status_column.sql`

## Suggested Type Sync

Setelah schema berubah, regenerasi tipe Supabase (jika workflow CLI tersedia):

```bash
supabase gen types typescript --project-id <project_ref> --schema public > supabase/types.generated.ts
```

Lalu sinkronkan perubahan penting ke:

- `lib/core/database/db_tables.dart`
- DTO mapper di `lib/features/**/dto`
- repository query + parser
- provider state untuk field baru
