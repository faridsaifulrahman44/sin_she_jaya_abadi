# design.md — Spesifikasi Teknis Klinik Sin She Jaya Abadi

> Dokumen ini adalah **spesifikasi teknis** untuk Flutter app Klinik Sin She Jaya Abadi.
> Gunakan ini sebagai referensi arsitektur, model data, repository, routing, lifecycle, dan aturan teknis.
> Jangan gunakan file ini sebagai catatan status kerja atau referensi visual utama.

## 1. Ruang lingkup
Dokumen ini membahas:
- batas arsitektur aplikasi
- model data inti
- repository layer
- role / auth
- routing
- lifecycle transaksi, stok, pasien, laporan, dan print queue
- token visual tingkat teknis

Yang **tidak** dibahas di sini:
- status progres harian
- daftar task selesai
- rencana kerja sprint
- referensi visual Stitch per screen

## 2. Prinsip arsitektur
- `pages/*` hanya berisi UI dan state lokal.
- `pages/*` tidak melakukan query Supabase langsung.
- Semua akses data lewat `data/repositories/*`.
- `features/*` berisi logika pure Dart, tanpa import `package:flutter`.
- `core/*` berisi auth, router, theme, service, util, dan design system.
- Perubahan state yang menyentuh DB / auth / stok / transaksi harus dibuat hati-hati dan minimal.

## 3. Struktur folder inti
```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── auth/
│   ├── design_system/
│   ├── router/
│   ├── services/
│   ├── theme/
│   ├── ui/
│   └── utils/
├── data/
│   ├── models/
│   └── repositories/
├── features/
├── pages/
└── widgets/
```

## 4. Model data inti
### 4.1 Obat
Field inti:
- `id`
- `namaObat`
- `stok`
- `stokMinimum`
- `satuan`
- `hargaJual`
- `hargaBeli`
- `etalase`
- `etalaseLabel`
- `createdAt`
- `updatedAt`

Catatan:
- `etalaseLabel` adalah hasil join / turunan.
- `foto_key` adalah path utama untuk foto obat di storage.
- `foto_url` hanya fallback legacy bila memang masih ada.

### 4.2 Pasien
Field inti:
- `id`
- `namaPasien`
- `noTelp`
- `alamat`
- `tanggalLahir`
- `jenisKelamin`
- `catatan`
- `createdAt`

### 4.3 Transaksi
Field inti:
- `idTransaksi`
- `idPasien`
- `idAdmin`
- `jenisTransaksi`
- `total`
- `metodeBayar`
- `tanggal`
- `catatan`
- `createdAt`

Enum internal:
- `praktekCustom` → label `Praktek`
- `obatReadyStock` → label `Obat`

### 4.4 Transaksi item
Field inti:
- `id`
- `idTransaksi`
- `idObat`
- `jumlah`
- `hargaSatuan`
- `subtotal`
- `namaObat`

### 4.5 Print queue
Field inti:
- `id`
- `idTransaksi`
- `status`
- `notes`
- `queueAt`
- `processedAt`
- `completedAt`
- `metodeBayar`
- `idAdmin`
- `createdAt`

Status umum:
- `pending`
- `processing`
- `printed`
- `failed`

## 5. Repository layer
### 5.1 Pola umum
Semua repository membaca dan menulis lewat Supabase client, lalu memetakan result ke model.

### 5.2 TransaksiRepository
Method penting:
- `createTransaksi(...)`
- `getTransaksiById(int id)`
- `getTransaksiItems(int id)`
- `getAllTransaksi({limit})`
- `getRecentTransaksi({limit})`

### 5.3 ObatRepository
Method penting:
- `getObat()`
- `getObatById(int id)`
- `createObat(Map data)`
- `updateObat(int id, Map data)`
- `deleteObat(int id)`
- `insertObatMasuk(...)`
- `insertObatKeluar(...)`
- `updateStok(int id, int delta)`
- `updateFotoKey(...)`
- `getObatsByEtalase(...)`

### 5.4 PasienRepository
Method penting:
- `getPasien()`
- `getPasienById(int id)`
- `createPasien(...)`
- `updatePasien(...)`
- `searchPasien(String q)`

### 5.5 PrintQueueRepository
Method penting:
- `enqueue(int idTransaksi)`
- `getAll({statuses})`
- `getById(int id)`
- `updateStatus({id, status, notes})`

Aturan:
- `enqueue()` hanya dipanggil satu kali per transaksi dari form transaksi.
- `updateStatus()` harus best-effort dan tidak boleh memblokir alur cetak fisik.

## 6. Auth dan role
Gunakan `AdminSession` sebagai sumber role.

Aturan:
- jangan hardcode role
- jangan bypass guard
- jangan tampilkan nominal / laporan ke admin atau petugas
- fitur owner-only harus tetap terkunci di UI dan di logika halaman

Role-aware screens:
- Dashboard
- Hub Obat
- Riwayat Transaksi
- Laporan
- Print Queue
- Struk pembayaran
- Halaman stok tertentu

## 7. Routing
Route utama:
- `/login`
- `/dashboard`
- `/obat-hub`
- `/obat-form`
- `/obat-detail`
- `/stok-alert`
- `/pasien`
- `/pasien-form`
- `/pasien-detail`
- `/transaksi-form`
- `/riwayat-transaksi`
- `/laporan`
- `/print-queue`
- `/struk-pembayaran`

Prinsip:
- routing hanya mendefinisikan perpindahan halaman
- guard role tetap harus dicek di page / repository bila perlu
- page besar tetap lebih baik mempertahankan pola state yang sudah ada daripada migrasi besar-besaran

## 8. Lifecycle transaksi
### 8.1 Alur ringkas
1. User isi form transaksi
2. `createTransaksi()` menyimpan header dan item
3. `enqueue()` menambahkan baris print queue secara best-effort
4. App pindah ke halaman struk
5. Operator mencetak
6. Status print queue diperbarui bila sukses / gagal

### 8.2 Aturan penting
- `enqueue()` tidak boleh dipanggil dari halaman struk.
- Jika enqueue gagal, alur transaksi tetap lanjut.
- Bila transaksi tipe Obat, `id_pasien` harus null.
- Bila transaksi tipe Praktek, `id_pasien` wajib terisi.

## 9. Lifecycle stok
### 9.1 Stok masuk
- tercatat di `obat_masuk`
- stok agregat bertambah

### 9.2 Stok keluar
- tercatat di `obat_keluar`
- stok agregat berkurang
- bisa datang dari transaksi atau pengeluaran non-penjualan

### 9.3 Sinkronisasi stok
- untuk koreksi / audit stok fisik vs sistem
- tidak boleh mengubah logika stok secara sembarangan
- gunakan repository dan fungsi yang sudah ada

## 10. Fitur pasien
- list pasien
- form create/edit
- detail pasien
- ringkasan kunjungan
- entry transaksi dari halaman pasien bila diperlukan

## 11. Fitur laporan
- ringkasan
- harian / bulanan / tahunan atau variasi tab yang sudah ada di codebase
- export CSV / PDF bila tersedia
- halaman laporan bersifat owner-only

## 12. Riwayat transaksi
Halaman riwayat transaksi berisi gabungan data transaksi dan riwayat stok.
Perilaku UI:
- tab filter tetap sederhana
- filter harus sesuai role
- format tanggal dan nominal konsisten

## 13. Halaman owner-only
Contoh halaman / section yang harus dikunci:
- laporan nominal
- stok alert tertentu
- ringkasan owner tertentu
- print queue dan struk bila ada guard role

## 14. Desain visual teknis
Token dan helper visual ada di:
- `lib/core/design_system/`
- `lib/core/theme/`
- `lib/core/ui/`

Prinsip:
- gunakan token yang sudah ada
- jangan duplikasi token di banyak file
- jangan tulis lagi daftar referensi visual di sini bila sudah ada di `STITCH_SOURCE_OF_TRUTH.md`

## 15. Penanganan error
- tampilkan error yang jelas dan ringkas
- fallback aman untuk null / empty state
- best-effort pada fitur yang tidak boleh memblokir alur utama
- operasi sensitif tetap harus jelas kalau gagal

## 16. Catatan lintas fitur
- Hindari logika ganda antara form transaksi, struk, dan print queue.
- Hindari menulis aturan visual final di lebih dari satu dokumen.
- Kalau ada perubahan besar, update dokumentasi dengan skala minimal dan konsisten.

## 17. Rujukan
- Status kerja terbaru ada di `PROJECT_PROGRESS.md`
- Rujukan visual final ada di `STITCH_SOURCE_OF_TRUTH.md`
- Aturan kerja Claude ada di `CLAUDE.md`
