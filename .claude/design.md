# DESIGN.md

## PURPOSE

Dokumen ini menjelaskan arsitektur teknis tingkat tinggi proyek Flutter Klinik Sin She Jaya Abadi.

Dokumen ini BUKAN:

* progress tracker
* debugging log
* investigasi error
* temporary notes
* task planning

Dokumen tersebut harus ditempatkan di:

```text
docs/investigations/
docs/notes/
PROJECT_PROGRESS.md
```

---

# SOURCE OF TRUTH HIERARCHY

Urutan referensi proyek:

1. CLAUDE.md

   * agent instructions
   * workflow
   * coding rules

2. PROJECT_PROGRESS.md

   * current implementation status
   * active phase
   * next action

3. STITCH_SOURCE_OF_TRUTH.md

   * visual reference
   * screen selection
   * design validation

4. DESIGN.md

   * architecture
   * domain model
   * feature boundaries

---

# ARCHITECTURE PRINCIPLES

## Layer Separation

Presentation
↓
Repository
↓
Data Source
↓
Supabase

UI tidak boleh mengakses Supabase secara langsung.

---

## Repository Pattern

Semua akses data dilakukan melalui repository.

Contoh:

* PasienRepository
* TransaksiRepository
* InventarisRepository
* PrintQueueRepository

---

## Feature Domains

### Dashboard

Owner analytics
Operational summary

### Inventaris

Master obat
Stok
Sinkronisasi stok

### Pasien

CRM pasien
Riwayat kunjungan

### Transaksi

POS
Pembayaran
Struk

### Operasional

Print queue
Laporan
Monitoring

---

## Print Queue Rules

1 transaksi hanya boleh menghasilkan 1 record queue aktif.

Print queue adalah audit trail operasional.

Implementasi detail mengikuti repository dan model aktual.

---

## Database Rules

Model dan schema database adalah source of truth.

Jika dokumentasi berbeda dengan implementasi aktual:

Implementasi database menang.

---

## Design System Rules

Visual source of truth:

STITCH_SOURCE_OF_TRUTH.md

Design token source:

klinik_sin_she_jaya_abadi_design_system

Dokumen ini tidak menyimpan daftar screen.

---

## Change Policy

Jangan menambahkan:

* debugging notes
* hook investigations
* temporary findings
* one-off experiments

ke dalam file ini.

Tempatkan ke:

```text
docs/investigations/
```

agar Claude Code tidak menganggapnya sebagai desain permanen proyek.
