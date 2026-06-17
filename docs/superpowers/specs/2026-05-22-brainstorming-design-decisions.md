# Brainstorming Session — 22 Mei 2026

## Project: Klinik Sin She Jaya Abadi Flutter App

---

## ✅ Decisions that were APPROVED by both Owner and Developer

### Transaksi & Pasien
- Semua transaksi WAJIB pilih pasien (`id_pasien` tidak boleh NULL) — tidak ada walk-in umum
- Quick-add pasien via bottom sheet di halaman transaksi (tanpa navigasi terpisah)
- Patient master: Nama, Alamat, Usia (eksak), Gender (L/P), Tanggal daftar — TIDAK ada no. telp
- Patient Profile: Tab Riwayat (obat+resep) + Tab Info. Tab Jadwal TIDAK muncul di patient profile
- Pasien beli obat tanpa transaksi Praktek tetap dicatat data dirinya
- Owner bisa lihat riwayat pasien kapan saja

### Resep & Racikan
- Resep disimpan di aplikasi (bukan cetak) — cukup untuk referensi sinshe/admin saat pasien datang lagi
- Etalase 3: Admin bisa lihat NAMA OBAT individual tapi TIDAK bisa tahu formula/kombinasi racikan
- Hanya Owner/Sinshe yang tahu formula lengkap Racikan #001 dst
- Etalase 3 diinput MANUAL oleh Sinshe (beda dari Etalase 1 & 2 yang diinput developer)

### Kehadiran & Jadwal
- Mekanisme hadir/tidak hadir saja — tanpa keterangan tambahan
- Tidak ada reminder/notifikasi ke pasien — murni keputusan pasien mau datang atau tidak
- Tab Jadwal tidak muncul di Patient Profile — cukup di halaman Jadwal Praktek utama

### Biaya & Kas
- Transaksi Praktek: 1 harga all-in (tidak di-breakdown per komponen konsultasi + obat + racikan)
- App tahu total penjualan Tunai/hari (dari Laporan/Akuntansi). Admin catat di buku fisik
- Tidak ada mekanisme setor/tarik cash di aplikasi
- Prive owner tidak masuk sistem (privasi owner dihormati)

### QRIS Flow (V3.1)
- Klik menu QRIS → langsung tampil "QRIS berhasil" → selesai
- Tidak ada QR code visual, tidak ada langkah-langkah scan, tidak ada checkbox konfirmasi

### Auth & UI
- 1 halaman login (sama untuk owner & admin)
  - Owner: ketik "owner" atau "owner@gmail.com" → password "owner"
  - Admin: username "admin" → password "admin"
- Session persistent (daily use — 1x login seterusnya, tidak perlu login ulang)
- Dark Mode + Logout posisinya di halaman Akun (untuk kedua role, BUKAN di Dashboard)
- Multi-account admin: next phase (saat ini 3 admin sharing 1 akun, nanti diupgrade ke 3 akun terpisah)
- Login page: Logo Klinik + 2 field + tombol Masuk + small link "Hubungi Developer" (direct ke WhatsApp developer)
- Bahasa: 100% Bahasa Indonesia

### Edit/Hapus & Lainnya
- Edit/Hapus transaksi tanpa batas waktu — bisa dilakukan kapan saja
- Serah terima obat dilakukan di luar sistem (fisik di lokasi klinik)

### Workflow Tambahan
- Owner bisa cek data pasien + lihat riwayat obat kapan saja (bukan hanya saat transaksi)
- Jika pasien lupa nama obat/resep saat datang lagi → sinshe bisa lihat dari riwayat di app
- Form Pasien Baru: Bottom sheet tidak perlu keluar dari halaman transaksi

---

## ❌ Things that were DECIDED AGAINST
- Reminder/notifikasi ke pasien — tidak ada
- Breakdown biaya per komponen di transaksi Praktek — all-in 1 harga
- Tab Jadwal di patient profile — tidak perlu
- Print/resep fisik — cukup simpan di app
- Remember me checkbox — tidak perlu
- Forgot password — hubungi developer via WhatsApp link
- Kategori usia (Balita/Lansia dll) — angka eksak saja
- Multi-language — Indonesia only
- Prive recording di app — tidak masuk sistem

---

## 📁 Related Files
- `docs/PROJECT_PROGRESS.md` — master tracker (updated with this session)
- `docs/mockup/mockup_v3.html` — revisi V3 (revisi 1-6 + 2 screen baru)
- `docs/mockup/mockup_v3.1.html` — QRIS scan simplified flow
- Next: `docs/mockup/mockup_v4.html` — Full app (Owner + Admin perspective, semua halaman)