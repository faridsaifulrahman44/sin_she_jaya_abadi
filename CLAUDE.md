# CLAUDE.md — Klinik Sin She Jaya Abadi
# Panduan kerja untuk Claude Code (claude-sonnet-4-6)
# Letakkan file ini di root project: flutter_klinik_starter/CLAUDE.md

---

## 🏥 KONTEKS PROYEK

Aplikasi mobile Flutter untuk operasional klinik/obat herbal **Klinik Sin She Jaya Abadi**.
Bukan sekadar demo — aplikasi ini akan dipakai di lapangan jangka panjang (bertahun-tahun).

- **Platform target:** Android (APK, sideload / direct install ke HP staf klinik)
- **Backend:** Supabase (project ref: `cdfklvbzbffqvhgifesk`)
- **Framework:** Flutter + Dart, Supabase Flutter client, Riverpod, go_router
- **Pengguna lapangan:** Owner + 1–2 admin/petugas klinik

---

## 👥 ROLE & AKSES

| Fitur                              | Owner | Admin/Petugas |
|------------------------------------|-------|---------------|
| Input transaksi                    | ✅    | ✅            |
| Kelola obat, pasien, kehadiran     | ✅    | ✅            |
| Obat masuk, keluar, sinkronisasi   | ✅    | ✅            |
| Lihat laporan / nominal uang       | ✅    | ❌            |
| Lihat riwayat transaksi lengkap    | ✅    | ❌            |

**Aturan penting:**
- Role dideteksi lewat `AdminSession` — jangan bypass atau hardcode role.
- Jangan pernah menampilkan laporan/nominal ke admin, meski hanya di debug/dummy.
- `id_pasien` WAJIB null untuk transaksi jenis Obat.
- `id_pasien` WAJIB diisi untuk transaksi jenis Praktek — tolak simpan dengan pesan ramah jika belum pilih.

---

## 🌿 GIT WORKFLOW

- **Branch utama/stabil:** `master`
- **Workflow:** branch per fitur → test → merge ke master
- **Sebelum mulai task apapun:** pastikan tahu branch aktif saat ini
- Untuk perubahan UI minor (tidak menyentuh DB/auth), boleh langsung di `master`
- Untuk perubahan yang menyentuh logika stok, transaksi, auth, atau DB → **wajib buat branch baru dulu**

Contoh nama branch yang disarankan:
```
fix/foto-key-upload
feat/dashboard-owner-final
feat/qris-tunai-icon
fix/test-harness-supabase
```

---

## 🗄️ DATABASE — SUPABASE

### Aturan Utama (TIDAK BOLEH DILANGGAR)

1. **Untuk SELECT:** boleh langsung eksekusi via MCP.
2. **Untuk INSERT / UPDATE:** tampilkan SQL final terlebih dahulu, tunggu pengguna mengetik **LANJUT**.
3. **DILARANG KERAS tanpa izin eksplisit:**
   - `DELETE`, `DROP`, `TRUNCATE`
   - `ALTER TABLE`, `CREATE TABLE`
   - Mengubah migration / apply_migration
   - Mengubah RLS policy, RPC function, trigger, schema
4. Jangan ubah tabel selain yang diminta secara eksplisit.
5. Jangan simpan secret/API key dalam kode.
6. Jangan hapus file Storage tanpa izin.

### Tabel Utama

```
public.obat           — master data obat
public.transaksi      — header transaksi
public.transaksi_item — item per transaksi
public.pasien         — data pasien
public.admin          — data user/admin
public.kehadiran_pasien
public.kunjungan_pasien
public.obat_masuk     — penambahan stok
public.obat_keluar    — pengeluaran stok non-penjualan
public.sinkronisasi_stok — koreksi/audit stok fisik
```

### Kolom Kritis `public.obat`

| Kolom           | Keterangan                                                      |
|-----------------|-----------------------------------------------------------------|
| `foto_key`      | Path Storage utama. Format: `etalase-1/nama_file.webp`          |
| `foto_url`      | Legacy fallback — candidat deprecation, jangan tulis baru ke sini |
| `foto_updated_at` | Timestamp update foto — untuk cache busting                   |
| `deskripsi`     | Teks deskripsi obat — tampilkan "Deskripsi belum tersedia." jika null/kosong |
| `harga_jual`    | Source of truth harga jual satuan                               |
| `bisa_ecer`     | Boolean — jika true, tampilkan opsi harga ecer                  |

---

## 📦 STORAGE — FOTO OBAT

### Format `foto_key` yang BENAR

```
etalase-1/die_da_tay_ping_yao_jing.webp   ✅
etalase-2/sanjin_tablets.webp             ✅
obat-images/etalase-1/nama.webp           ❌  (jangan pakai prefix bucket)
/etalase-1/nama.webp                      ❌  (jangan pakai leading slash)
```

### Struktur Bucket

```
Bucket: obat-images
├── etalase-1/   → 13 obat (sudah ada foto)
├── etalase-2/   → 12 obat (perlu foto)
└── etalase-3/   → kosong
```

### BUG AKTIF — Upload Foto (BELUM DIPERBAIKI)

`obat_repository.dart` → `uploadFotoObat()` masih:
- Menyimpan ke path `obat/{idObat}/{timestamp}.{ext}` — **SALAH**, seharusnya `etalase-X/nama_obat.webp`
- Menulis ke kolom `foto_url` — **SALAH**, seharusnya tulis ke `foto_key` DAN `foto_updated_at`

Saat memperbaiki ini, gunakan etalase dari `ObatModel.etalase` untuk menentukan subfolder.
Jangan hapus fallback `foto_url` — masih dipakai untuk data lama.

Query untuk cek mismatch foto_key vs Storage:
```sql
SELECT o.id_obat, o.nama_obat, o.etalase, o.foto_key
FROM public.obat o
WHERE o.foto_key IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM storage.objects s
    WHERE s.bucket_id = 'obat-images' AND s.name = o.foto_key
  )
ORDER BY o.etalase, o.nama_obat;
```

---

## 💊 LOGIKA TRANSAKSI

### Jenis Transaksi (value internal — JANGAN DIUBAH)

| Value Internal          | Label User-Facing |
|-------------------------|-------------------|
| `obatReadyStock`        | "Obat"            |
| `praktekCustom`         | "Praktek"         |

> ⚠️ Jika hanya mengubah label tampilan, jangan ubah value enum/database.

### Alur Stok

- **Obat Masuk** → stok bertambah
- **Transaksi Obat** → stok berkurang otomatis (via RPC/trigger DB)
- **Obat Keluar** → pengeluaran non-penjualan (rusak, hilang, kedaluwarsa)
- **Sinkronisasi Stok** → koreksi/audit, menyamakan sistem dengan fisik

> Jangan ubah logika stok sembarangan. Stok dikomputasi oleh SQL/RPC di sisi DB.

---

## 📊 DASHBOARD

### Dashboard Owner (card biru/header)
Konten yang harus ada:
- "Halo, Owner" + "Klinik Sin She Jaya Abadi"
- "Laporan Hari Ini:" + "Penjualan : Rp xxx.xxx"
- Jam real-time + tanggal (format: "15.25 | Senin, 11 Mei 2026") → pojok kanan atas
- Tombol dark mode + logout → pojok kanan bawah card biru

### Dashboard Admin
- Fokus operasional: Jadwal Hari Ini, Hadir Hari Ini
- TIDAK boleh ada nominal uang atau ringkasan laporan

---

## 💳 METODE PEMBAYARAN

Opsi: **Tunai** dan **QRIS** — keduanya harus punya ikon di kiri label.
Status saat ini: `SegmentedButton` sudah ada, tapi ikon belum ditambahkan.

```dart
// Target tampilan:
// [ 💵 Tunai ]  [ 📱 QRIS ]
```

Gunakan ikon dari `HugeIcons` atau `AppIcons` yang sudah ada di project.

---

## 🧪 TEST

File test ada di `test/` — jalankan setelah setiap perubahan:

```bash
flutter analyze
flutter test
```

### Catatan Test Harness

Beberapa test gagal karena `Supabase.instance` belum diinisialisasi di test environment.
Ini adalah **pre-existing issue** — bukan akibat perubahan UI/logika baru.
Jika test gagal karena ini, **laporkan secara eksplisit** jangan dianggap sebagai regresi baru.

Test yang kemungkinan terdampak:
- `test/features/stok/stock_service_test.dart`
- `test/data/schema_contract_test.dart`

---

## 🏗️ ARSITEKTUR & ATURAN KODING

### Struktur Folder

```
lib/
├── core/
│   ├── auth/          — AdminSession, role detection
│   ├── database/      — DbTables constants
│   ├── design_system/ — AppTokens (spacing, radius, text styles)
│   ├── error/         — AppErrorMapper, AppException
│   ├── routing/       — AppRouter, AppRouteRegistry
│   ├── services/      — ReceiptPrinterService
│   ├── supabase/      — KlinikRepository, SupabaseConfig
│   ├── theme/         — AppTheme, AppColors, AppWidgets
│   ├── ui/            — AppIcons, ObatAssetRegistry
│   └── utils/         — Formatters, Parsers, ObatFotoResolver
├── data/
│   ├── models/        — semua model data
│   └── repositories/  — semua repository
├── features/          — modul fitur dengan usecase/provider/dto
├── pages/             — semua halaman UI
└── widgets/           — shared widget kecil
```

### Prinsip Utama

1. **Jangan refactor besar** tanpa alasan dan tanpa izin eksplisit.
2. **Audit dulu** file terkait sebelum edit — pahami status awal, baru buat perubahan minimal.
3. **Jangan ubah value internal** enum/DB jika task-nya hanya mengubah label tampilan.
4. **Jangan ubah schema/RLS/RPC** kecuali diminta eksplisit.
5. `transaksi_form_page.dart` sudah 1.478 baris — berhati-hati saat edit, jangan tambah kompleksitas tanpa pertimbangan.
6. State management: beberapa halaman masih `setState`, sebagian sudah Riverpod. Jangan paksa migrasi ke Riverpod tanpa diminta.

### Foto Obat — Cara Resolve URL

Gunakan `ObatFotoResolver.resolveStorageUrl()` — jangan build URL Storage secara manual di tempat lain.
Prioritas resolver: `foto_key` → `foto_url` (legacy) → null (tampilkan placeholder).

---

## 📋 LAPORAN SETIAP SELESAI TASK

Setiap kali selesai mengerjakan task, laporkan:

```
✅ File yang diubah:
  - lib/xxx/yyy.dart — [ringkasan perubahan]

🔒 Yang TIDAK diubah:
  - [list logika/file sensitif yang sengaja tidak disentuh]

🧪 Hasil analyze & test:
  - flutter analyze: [clean / N warning / N error]
  - flutter test: [passed / N failed — sebutkan nama test yang gagal]

⚠️ Isu yang perlu diketahui:
  - [jika ada pre-existing issue atau hal yang perlu dikonfirmasi]
```

---

## 🚦 PRIORITAS SAAT INI (urutan pengerjaan)

1. **Finalisasi dashboard owner** — card biru dengan jam, tanggal, penjualan hari ini, tombol dark mode + logout
2. **Ikon QRIS/Tunai** — tambah ikon di SegmentedButton metode pembayaran
3. **Fix upload foto → `foto_key`** — perbaiki `uploadFotoObat()` agar tulis ke `foto_key` + `foto_updated_at` dengan path `etalase-X/nama.ext`
4. **Deskripsi obat etalase 1 & 2** — sinkronisasi data deskripsi di DB
5. **Fix test harness** — mock `Supabase.instance` di test environment
6. **Polishing UI global** — setelah fitur inti stabil

---

## ⛔ GARIS MERAH — TIDAK BOLEH DILANGGAR

| Larangan                                        | Konsekuensi jika dilanggar                    |
|-------------------------------------------------|-----------------------------------------------|
| Ubah RLS / policy / RPC tanpa izin eksplisit    | Bisa bocorkan data pasien atau laporan ke admin |
| Ubah logika stok tanpa izin                     | Stok bisa tidak sinkron dengan fisik klinik    |
| Ubah `core/auth/` tanpa izin                    | Bisa bypass role owner/admin                   |
| Eksekusi DELETE/DROP/TRUNCATE                   | Data permanen hilang                           |
| Tulis ke `foto_url` untuk upload foto baru      | Mismatch dengan resolver yang pakai `foto_key` |
| Tampilkan laporan/nominal ke role admin         | Pelanggaran privasi bisnis owner               |
