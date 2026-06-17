# F10 — Transaksi Etalase Filter

## Ringkasan
Filter obat yang ditampilkan di form transaksi berdasarkan tab yang aktif:
- Tab **Obat** (index 0) → hanya tampilkan obat dari Etalase 1 & Etalase 2
- Tab **Praktek** (index 1) → hanya tampilkan obat dari Etalase 3

## Desain

### Prinsip
Filter di level **data**, bukan UI. Saat tab berubah → reload daftar obat dengan filter etalase yang sesuai.

### File yang Diubah

#### 1. `lib/pages/transaksi_form_page.dart`
- Method `_loadAvailableObats()` — tambahkan parameter `List<Etalase>? allowedEtalases`
- Saat tab index 0 (Obat): load dengan `allowedEtalases = [Etalase.etalase1, Etalase.etalase2]`
- Saat tab index 1 (Praktek): load dengan `allowedEtalases = [Etalase.etalase3]`
- Saat filter aktif, tampilkan subtitle/chip kecil yang menunjukkan etalase yang aktif, misal: "Etalase 1 & 2"

#### 2. `lib/data/repositories/obat_repository.dart`
- Tambah method: `Future<List<ObatModel>> getObatsByEtalase(List<Etalase> etalases)`
- Filter dari query existing dengan `.in_('etalase', etalases.map((e) => e.value).toList())`

#### 3. `lib/data/models/obat_etalase.dart`
- Pastikan `Etalase` enum sudah ada dengan values: `etalase1`, `etalase2`, `etalase3`
- Sudah ada — tidak perlu diubah

### Validasi
- Tidak perlu validasi tambahan di save — filter sudah di-level loading
- Edge case: jika user punya obat tersisa di cart saat switch tab → clear cart dengan dialog konfirmasi

### Edge Case
- Tab switch dengan item di cart → tanyakan: "Pindah tab akan mengosongkan daftar obat yang dipilih. Lanjutkan?"
- Jika user pilih "Batal" → tidak switch tab

## Scope
- Hanya `transaksi_form_page.dart`
- Tidak mengubah `TransaksiRepository` — filter dilakukan di `ObatRepository`
- Tidak mengubah schema DB
- Tidak mengubah `transaksi_item` atau logika save