import 'package:flutter/material.dart';

import '../core/auth/admin_session.dart';
import '../core/theme/app_theme.dart';
import '../data/models/print_queue_model.dart';
import '../data/repositories/print_queue_repository.dart';

/// Halaman riwayat antrean cetak — Owner only.
class PrintQueuePage extends StatefulWidget {
  const PrintQueuePage({super.key});

  static const routeName = '/print-queue';

  @override
  State<PrintQueuePage> createState() => _PrintQueuePageState();
}

class _PrintQueuePageState extends State<PrintQueuePage> {
  final _repository = PrintQueueRepository();

  bool _loading = true;
  String? _error;
  List<PrintQueueModel> _queue = [];

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final isOwner = await AdminSession.isOwner();
    if (!isOwner) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Akses ditolak. Halaman ini hanya untuk owner.';
        });
      }
      return;
    }

    await _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queue = await _repository.getAll();
      if (mounted) {
        setState(() {
          _queue = queue;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat riwayat cetak: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Riwayat Cetak',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: cteal(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(context);
    }

    if (_queue.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      onRefresh: _loadQueue,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _queue.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _QueueCard(item: _queue[index]),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: cdanger(context)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cdanger(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkAccessAndLoad,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.print_disabled,
            size: 72,
            color: ctextMuted(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat cetak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ctextSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Struk yang berhasil dicetak akan muncul di sini',
            style: TextStyle(
              fontSize: 13,
              color: ctextMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Card untuk satu item antrean cetak.
class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item});

  final PrintQueueModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: ccardBg(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: total + badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.formattedTotal,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ctextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transaksi #${item.idTransaksi}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ctextMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: item.status),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom row: timestamp + metode bayar
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: ctextMuted(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.formattedQueueAt,
                    style: TextStyle(
                      fontSize: 12,
                      color: ctextMuted(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (item.metodeBayarLabel != null) ...[
                    Icon(
                      Icons.payment,
                      size: 14,
                      color: ctextMuted(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.metodeBayarLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: ctextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: ctextMuted(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: ctextMuted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge chip.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PrintQueueStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      PrintQueueStatus.pending => (cwarning(context), cwarning(context).withValues(alpha: 0.12)),
      PrintQueueStatus.printed => (csuccess(context), csuccess(context).withValues(alpha: 0.12)),
      PrintQueueStatus.failed => (cdanger(context), cdanger(context).withValues(alpha: 0.12)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
