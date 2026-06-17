# F9 Print Queue — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Print queue — simpan job cetak ke DB, tampilkan list, update status setelah print berhasil.

**Architecture:** Setelah transaksi disimpan, insert record ke `print_queue` DB. Owner lihat list pending → klik → print → status updated ke 'printed'. Akses Owner-only seperti StrukPembayaranPage.

**Tech Stack:** Flutter, Supabase, existing ReceiptPrinterService

---

## File Structure

```
lib/data/models/print_queue_model.dart   — sudah ada (int id, 3 status)
lib/pages/print_queue_page.dart           — BELUM ADA (dibuat)
lib/data/repositories/print_queue_repository.dart — BELUM ADA (dibuat)
lib/pages/transaksi/struk_pembayaran_page.dart     — dimodifikasi (insert after print)
docs/superpowers/plans/2026-05-31-F9-Print-Queue.md — plan ini
```

---

## Task 1: SQL Table print_queue (DISPLAY ONLY — perlu user approval)

**SQL (DONT EXECUTE — tampilkan dulu):**

```sql
CREATE TABLE print_queue (
  id          BIGSERIAL PRIMARY KEY,
  id_transaksi INTEGER NOT NULL REFERENCES public.transaksi(id),
  created_by  INTEGER NOT NULL REFERENCES public.admin(id),
  created_at  TIMESTAMPTZ  DEFAULT NOW(),
  status      TEXT NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'printed', 'failed')),
  notes       TEXT
);
CREATE INDEX idx_print_queue_status     ON print_queue(status);
CREATE INDEX idx_print_queue_created_at ON print_queue(created_at DESC);
```

> **Catatan:** Schema pakai `INTEGER` agar konsisten dengan model (`print_queue_model.dart` pakai `int id`, `int idTransaksi`). Plan sebelumnya pakai UUID — di-tolak karena tidak cocok dengan existing pattern tabel lain di DB ini.

---

## Task 2: PrintQueueRepository

**File:** Create `lib/data/repositories/print_queue_repository.dart`

- [ ] **Step 1: Buat file repository**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/print_queue_model.dart';

class PrintQueueRepository {
  final _client = Supabase.instance.client;

  /// Insert print job after transaksi saved.
  Future<void> enqueue({
    required int idTransaksi,
    required int createdBy,
    String? notes,
  }) async {
    await _client.from('print_queue').insert({
      'id_transaksi': idTransaksi,
      'created_by': createdBy,
      'status': 'pending',
      if (notes != null) 'notes': notes,
    });
  }

  /// Fetch all print jobs, newest first.
  Future<List<PrintQueueModel>> getAll() async {
    final result = await _client
        .from('print_queue')
        .select('''
          id,
          id_transaksi,
          created_by,
          created_at,
          status,
          notes,
          transaksi(total_transaksi, tanggal, metode_bayar)
        ''')
        .order('created_at', ascending: false)
        .limit(50);

    return result.map((row) => _fromRow(row)).toList();
  }

  /// Update status after print attempt.
  Future<void> updateStatus({
    required int id,
    required String status,
    String? notes,
  }) async {
    await _client
        .from('print_queue')
        .update({
          'status': status,
          if (notes != null) 'notes': notes,
        })
        .eq('id', id);
  }

  PrintQueueModel _fromRow(Map<String, dynamic> row) {
    final transaksi = row['transaksi'] as Map<String, dynamic>?;
    return PrintQueueModel(
      id: row['id'] as int,
      idTransaksi: row['id_transaksi'] as int,
      queueAt: DateTime.parse(row['created_at'] as String),
      status: PrintQueueStatus.fromString(row['status'] as String),
      notes: row['notes'] as String?,
      totalTransaksi: transaksi?['total_transaksi'] != null
          ? (transaksi!['total_transaksi'] as num).toDouble()
          : null,
      tanggalTransaksi: transaksi?['tanggal'] != null
          ? DateTime.parse(transaksi!['tanggal'] as String)
          : null,
      metodeBayarLabel: transaksi?['metode_bayar'] as String?,
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

```bash
cd D:/flutter_klinik_starter && flutter analyze 2>&1 | grep -E "(error|warning|No issues)" | head -20
```

Expected: No issues

---

## Task 3: PrintQueuePage

**File:** Create `lib/pages/print_queue_page.dart`

Akses: **Owner only** (sama seperti StrukPembayaranPage).

- [ ] **Step 1: Buat PrintQueuePage**

```dart
import 'package:flutter/material.dart';
import '../../core/auth/admin_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/print_queue_model.dart';
import '../../data/repositories/print_queue_repository.dart';

class PrintQueuePage extends StatefulWidget {
  const PrintQueuePage({super.key});
  static const routeName = '/print-queue';

  @override
  State<PrintQueuePage> createState() => _PrintQueuePageState();
}

class _PrintQueuePageState extends State<PrintQueuePage> {
  final _repo = PrintQueueRepository();
  List<PrintQueueModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isOwner = await AdminSession.isOwner();
    if (!isOwner) {
      setState(() { _error = 'Akses ditolak.'; _loading = false; });
      return;
    }
    try {
      final items = await _repo.getAll();
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Queue', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cteal(context),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: cdanger(context))))
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.print_disabled, size: 64, color: ctextMuted(context)),
                          const SizedBox(height: 12),
                          Text('Tidak ada job print', style: TextStyle(color: ctextMuted(context))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _QueueCard(item: item, onPrinted: _load);
                        },
                      ),
                    ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item, required this.onPrinted});
  final PrintQueueModel item;
  final VoidCallback onPrinted;

  Color _statusColor(BuildContext context) {
    switch (item.status) {
      case PrintQueueStatus.pending: return corange(context);
      case PrintQueueStatus.printed:  return csuccess(context);
      case PrintQueueStatus.failed:    return cdanger(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.formattedTotal,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.formattedQueueAt, style: TextStyle(fontSize: 12, color: ctextSecondary(context))),
            if (item.metodeBayarLabel != null) ...[
              const SizedBox(height: 4),
              Text('Metode: ${item.metodeBayarLabel}', style: TextStyle(fontSize: 12, color: ctextSecondary(context))),
            ],
            if (item.notes != null) ...[
              const SizedBox(height: 4),
              Text(item.notes!, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: ctextMuted(context))),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Expected: No issues

---

## Task 4: Wire print queue ke StrukPembayaranPage

**File:** Modify `lib/pages/transaksi/struk_pembayaran_page.dart`

Logika: setelah print berhasil → insert ke `print_queue` dengan status `'printed'` langsung (karena print langsung sukses).

> **Catatan penting:** Karena print dilakukan langsung (bukan queue deferred), status langsung `'printed'`. Print queue di sini berfungsi sebagai log/history semua struk yang pernah dicetak.

- [ ] **Step 1: Tambah import**

Tambah di baris import:

```dart
import '../../data/repositories/print_queue_repository.dart';
```

- [ ] **Step 2: Tambah field repository**

Di `_StrukPembayaranPageState`, tambah:

```dart
final _repository = TransaksiRepository();
final _printerService = ReceiptPrinterService();
final _printQueueRepo = PrintQueueRepository(); // <-- tambah ini
```

- [ ] **Step 3: Insert print queue setelah print berhasil**

Di method `_printReceipt`, cari block `if (mounted) { ScaffoldMessenger... 'Struk berhasil dikirim ke printer' }` — tambahkan insert setelahnya:

```dart
// Insert print log
try {
  await _printQueueRepo.enqueue(
    idTransaksi: transaksi.idTransaksi,
    createdBy: int.parse(AdminSession.current.adminId!),
  );
} catch (_) {
  // Gagal log tidak boleh block flow
}
```

Tambah import:
```dart
import '../../core/auth/admin_session.dart';
```

- [ ] **Step 4: Run flutter analyze**

```bash
cd D:/flutter_klinik_starter && flutter analyze 2>&1 | grep -E "(error|warning|No issues)" | head -20
```

Expected: No issues

---

## Task 5: Add route untuk PrintQueuePage

**File:** Modify `lib/core/routing/app_router.dart` (atau file routing yang sesuai)

- [ ] **Step 1: Cek existing routing setup**

```bash
grep -n "StrukPembayaranPage\|GoRoute\|routeName" lib/core/routing/app_router.dart | head -20
```

- [ ] **Step 2: Tambah route PrintQueuePage**

GoRoute(
  path: PrintQueuePage.routeName, // '/print-queue'
  name: 'print-queue',
  builder: (_, __) => const PrintQueuePage(),
),

- [ ] **Step 3: Run flutter analyze**

Expected: No issues

---

## Task 6: Update PROJECT_PROGRESS.md

**File:** `docs/PROJECT_PROGRESS.md`

- [ ] **Step 1: Update F9 section**

Ubah dari:
```
### ✅ FASE 9 — Print Queue (DB + UI) — DALAM PROGRESS
- [x] `print_queue_model.dart` — model created (file exists, 54 lines)
- [ ] `print_queue_page.dart` — BELUM ADA (model exists, page not created)
- [ ] SQL table `print_queue` — BELUM ADA di DB (pending user approval)
- [ ] Wire print queue into TransaksiFormPage (pending — page not created)
```

Menjadi:
```
### ✅ FASE 9 — Print Queue (DB + UI) — SELESAI
- [x] `print_queue_model.dart` — model created
- [x] `print_queue_repository.dart` — repository created
- [x] `print_queue_page.dart` — page created
- [x] Wire ke StrukPembayaranPage — insert log after print
- [x] SQL table `print_queue` — created
- [x] Route `/print-queue` — added
```

---

## Self-Review Checklist

1. **Spec coverage:** Semua requirement F9 tercakup — model, repository, page, wiring, SQL, route
2. **Placeholder scan:** Tidak ada TBD/TODO — semua code lengkap
3. **Type consistency:** PrintQueueModel dari existing file — `id:int`, `idTransaksi:int` konsisten dipakai di repository dan page
4. **SQL schema:** Pakai `INTEGER` (bukan UUID) agar konsisten dengan PrintQueueModel dan existing tabel lain di DB ini
