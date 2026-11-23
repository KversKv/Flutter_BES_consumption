import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/chip_backend_client.dart';
import '../../services/chip_json_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AdminChangeLogTab extends StatefulWidget {
  const AdminChangeLogTab({super.key});

  @override
  State<AdminChangeLogTab> createState() => _AdminChangeLogTabState();
}

class _AdminChangeLogTabState extends State<AdminChangeLogTab> {
  static const int _pageSize = 30;

  ChipJsonDomain? _domain;
  List<ChipHistoryEntry> _entries = const [];
  List<String> _uncommitted = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _unavailable = false;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = false;
      _unavailable = false;
      _error = null;
    });
    try {
      final page = await ChipBackendClient.instance.fetchHistory(
        domain: _domain?.key,
        limit: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _entries = page.entries;
        _uncommitted = page.uncommitted;
        _hasMore = page.entries.length == _pageSize;
        _loading = false;
      });
    } on ChipHistoryUnavailable {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _entries = const [];
        _uncommitted = const [];
        _unavailable = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final requestId = _requestId;
    final skip = _entries.length;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final page = await ChipBackendClient.instance.fetchHistory(
        domain: _domain?.key,
        limit: _pageSize,
        skip: skip,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _entries = [..._entries, ...page.entries];
        _uncommitted = page.uncommitted;
        _hasMore = page.entries.length == _pageSize;
        _loadingMore = false;
      });
    } on ChipHistoryUnavailable {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _unavailable = true;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = '$e';
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return ColoredBox(
      color: palette.bgBase,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ChipJsonDomain?>(
                    initialValue: _domain,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: t.adminHistoryDomain,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem<ChipJsonDomain?>(
                        value: null,
                        child: Text(t.adminHistoryAllDomains),
                      ),
                      for (final domain in ChipJsonDomain.values)
                        DropdownMenuItem<ChipJsonDomain?>(
                          value: domain,
                          child: Text(domain.label),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _domain = value);
                      _reload();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                IconButton(
                  tooltip: t.adminHistoryRefresh,
                  onPressed: _loading ? null : _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_uncommitted.isNotEmpty &&
                !_loading &&
                !_unavailable &&
                _error == null) ...[
              const SizedBox(height: AppSpacing.x3),
              _UncommittedPanel(paths: _uncommitted),
            ],
            const SizedBox(height: AppSpacing.x3),
            Expanded(child: _buildBody(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_unavailable) {
      return _HistoryMessage(
        icon: Icons.source_outlined,
        message: t.adminHistoryUnavailable,
      );
    }
    if (_error != null) {
      return _HistoryMessage(
        icon: Icons.error_outline,
        message: t.adminHistoryLoadFailed(_error!),
      );
    }
    if (_entries.isEmpty) {
      return _HistoryMessage(
        icon: Icons.history_toggle_off,
        message: t.adminHistoryEmpty,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showDiff(entry),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.x3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.subject.isEmpty
                                    ? entry.shortSha
                                    : entry.subject,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x2),
                            Text(
                              entry.shortSha,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppPalette.of(context).accent,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          '${_formatTime(entry.time)} · ${entry.author}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppPalette.of(context).textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_hasMore) ...[
          const SizedBox(height: AppSpacing.x3),
          OutlinedButton.icon(
            onPressed: _loadingMore ? null : _loadMore,
            icon: _loadingMore
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more),
            label: Text(t.adminHistoryLoadMore),
          ),
        ],
      ],
    );
  }

  Future<void> _showDiff(ChipHistoryEntry entry) async {
    final t = AppLocalizations.of(context);
    final diffFuture = ChipBackendClient.instance.fetchHistoryDiff(entry.sha);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${entry.shortSha} · ${entry.subject}'),
        content: SizedBox(
          width: 900,
          height: MediaQuery.of(dialogContext).size.height * 0.65,
          child: FutureBuilder<String>(
            future: diffFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final error = snapshot.error;
                return _HistoryMessage(
                  icon: Icons.error_outline,
                  message: error is ChipHistoryUnavailable
                      ? t.adminHistoryUnavailable
                      : t.adminHistoryDiffFailed('$error'),
                );
              }
              final diff = snapshot.data ?? '';
              if (diff.trim().isEmpty) {
                return _HistoryMessage(
                  icon: Icons.difference_outlined,
                  message: t.adminHistoryNoDiff,
                );
              }
              return _DiffText(diff: diff);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.adminHistoryClose),
          ),
        ],
      ),
    );
  }

  String _formatTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _UncommittedPanel extends StatelessWidget {
  final List<String> paths;

  const _UncommittedPanel({required this.paths});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, size: 20, color: palette.warning),
              const SizedBox(width: AppSpacing.x2),
              Text(
                t.adminHistoryUncommitted,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.warning,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final path in paths)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x1),
                      child: Text(
                        path,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _HistoryMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: palette.textMuted),
            const SizedBox(height: AppSpacing.x3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffText extends StatelessWidget {
  final String diff;

  const _DiffText({required this.diff});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final lines = diff.split(RegExp(r'\r?\n'));
    final spans = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      Color? color;
      if (line.startsWith('+') && !line.startsWith('+++')) {
        color = palette.success;
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        color = palette.danger;
      }
      spans.add(TextSpan(
        text: i == lines.length - 1 ? line : '$line\n',
        style: TextStyle(color: color),
      ));
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText.rich(
          TextSpan(children: spans),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
        ),
      ),
    );
  }
}
