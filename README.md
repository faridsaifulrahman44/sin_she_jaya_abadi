# Flutter Klinik Starter

Aplikasi pencatatan klinik herbal / pengobatan alternatif modern.

## Fitur

- Login (Supabase Auth)
- Dashboard
- Data Obat (stok & etalase)
- Obat Masuk (restock)
- Obat Keluar (transaksi)
- Stock Opname
- Data Pasien
- Kehadiran Pasien
- Laporan

## Setup

### 1. Install dependencies

```bash
flutter clean
flutter pub get
```

### 2. Konfigurasi Supabase

Buka `lib/core/supabase/supabase_config.dart`, lalu isi:

```dart
const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 3. Setup Database

Jalankan SQL di folder `supabase/` secara berurutan. Urutan lengkap ada di `supabase/README.md`.

**Existing environment (incremental):**
```bash
# Jalankan semua migration secara berurutan sesuai supabase/README.md
# Fokus yang WAJIB:
supabase/migration_fase13_pasien_renumber_after_delete.sql  # ← WAJIB
```

**Fresh environment:**
```bash
# Jalankan schema.sql saja — sudah mencakup semua schema final
supabase/schema.sql
```

> **Penting:** Jika app error saat delete pasien dengan pesan `PGRST202 Could not find the function fn_pasien_delete_and_renumber`, berarti `migration_fase13_pasien_renumber_after_delete.sql` belum di-apply. Apply migration tersebut untuk mengaktifkan fitur delete + auto-renumber.

### 4. Jalankan Aplikasi

```bash
flutter run
```

## Build Android

Android package final:

- Application ID: `id.klinik.mobile`
- App label: `Klinik App`

### Debug APK

```bash
flutter build apk --debug
```

### Release APK

Release signing membaca file lokal `android/key.properties` jika tersedia. File ini di-ignore dan tidak boleh berisi password asli di repo. Salin contoh berikut lalu isi di mesin build:

```powershell
Copy-Item android/key.properties.example android/key.properties
```

Isi `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/path/outside/repo/upload-keystore.jks
```

Setelah keystore dan `android/key.properties` siap:

```bash
flutter build apk --release
```

Jika `android/key.properties` belum ada, release build tidak memakai debug signing.

File APK hasil build ada di `build/app/outputs/flutter-apk/`.

## Catatan Build Android

- NDK Version: `27.0.12077973` (sudah diset di `android/app/build.gradle.kts`)
- Java: 17
- minSdk: 21 (default Flutter, kompatibel dengan Supabase)
- Gradle properties sudah dikonfigurasi untuk build stabil (`android/gradle.properties`)

## Struktur Proyek

```
lib/
  app.dart                  # App routing & theme
  main.dart                 # Entry point
  core/
    error/                  # Error mapping
    supabase/               # Supabase client & config
    theme/                  # AppColors, widgets tema
    utils/                  # Formatters, parsers, validators
    widgets/                # Shared widgets (loading, error, empty)
  data/
    models/                 # Model data classes
    repositories/           # Repository layer
  features/
    laporan/                # Aggregator, summary, chart points
    obat_masuk/            # Grouping obat masuk
  pages/                   # Semua halaman UI
  widgets/                 # Shared widgets
supabase/
  schema.sql                # Schema database awal
  migration_add_tanggal_janjian.sql
```

## Testing

```bash
flutter test
```
