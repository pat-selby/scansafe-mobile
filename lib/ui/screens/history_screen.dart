import 'package:flutter/material.dart';

import '../../core/scan_result.dart';
import '../../data/scan_history_store.dart';
import '../theme.dart';
import '../widgets/verdict_badge.dart';
import 'result_screen.dart';

/// Layer 6 — local scan history.
///
/// Everything on this screen lives on the device. The empty state says so
/// explicitly, because the privacy claim is only useful if the user knows
/// about it.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.store});

  final ScanHistoryStore store;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult>? _history;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await widget.store.load();
    if (mounted) setState(() => _history = history);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear scan history?'),
        content: const Text(
          'This deletes every saved scan on this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.store.clear();
    if (mounted) setState(() => _history = []);
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan history'),
        actions: [
          if (history != null && history.isNotEmpty)
            IconButton(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all scans',
            ),
        ],
      ),
      body: history == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : history.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) =>
                      _HistoryRow(result: history[index], onDelete: () async {
                        final updated = await widget.store.removeAt(index);
                        if (mounted) setState(() => _history = updated);
                      }),
                ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.result, required this.onDelete});

  final ScanResult result;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${result.scannedAt.toIso8601String()}|${result.url}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.errorContainer,
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.monoUrl.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: VerdictPill(level: result.level, score: result.score),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No scans yet', style: AppType.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Scans you run are saved here on this device only. They are never '
              'uploaded anywhere.',
              textAlign: TextAlign.center,
              style: AppType.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
