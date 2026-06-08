import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/admin_session_store.dart';
import '../services/chip_json_repository.dart';
import '../services/chips_export_service.dart';
import '../services/noisepink_sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AdminPage extends StatefulWidget {
  final String secretKey;

  const AdminPage({
    super.key,
    required this.secretKey,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _secretCtrl = TextEditingController();
  bool _authed = false;
  bool _sessionReady = false;
  bool _loginBusy = false;
  bool _secretVisible = false;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    _secretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (!_sessionReady) return const _AdminSessionLoadingView();
    if (!_authed) return _loginView(t);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _AdminTopBar(
                title: t.adminTitle,
                onBackHome: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
                onExportAll: _exportAll,
                onLogout: () => unawaited(_logout()),
              ),
              const _AdminTabStrip(),
              Expanded(
                child: _LazyAdminTabView(
                  children: [
                    _DomainAdminTab(domain: ChipJsonDomain.ble),
                    _DomainAdminTab(domain: ChipJsonDomain.bt),
                    _DomainAdminTab(domain: ChipJsonDomain.earbuds),
                    _DomainAdminTab(domain: ChipJsonDomain.wifi),
                    _InfoPanel(
                      icon: Icons.settings_outlined,
                      title: t.adminOps,
                      body: t.adminOpsHint,
                    ),
                    _InfoPanel(
                      icon: Icons.local_fire_department_outlined,
                      title: t.adminHeat,
                      body: t.adminHeatHint,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginView(AppLocalizations t) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.bgBase,
                      palette.bgElevated1,
                      palette.bgBase,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.x3,
              top: AppSpacing.x3,
              child: IconButton.filledTonal(
                tooltip: t.adminBackHome,
                icon: const Icon(Icons.home_outlined),
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x4,
                    vertical: AppSpacing.x6,
                  ),
                  child: _AdminPanel(
                    padding: const EdgeInsets.all(AppSpacing.x8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: palette.accentMuted,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                              border: Border.all(color: palette.borderStrong),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 30,
                              color: palette.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Align(
                          alignment: Alignment.center,
                          child: _LoginStatusPill(
                            icon: Icons.verified_user_outlined,
                            label: t.adminLoginBadge,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          t.adminLoginTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          t.adminLoginSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        TextField(
                          controller: _secretCtrl,
                          enabled: !_loginBusy,
                          obscureText: !_secretVisible,
                          decoration: InputDecoration(
                            labelText: t.adminSecret,
                            hintText: t.adminSecretHint,
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              tooltip: _secretVisible
                                  ? t.adminHideSecret
                                  : t.adminShowSecret,
                              onPressed: _loginBusy
                                  ? null
                                  : () => setState(
                                        () => _secretVisible = !_secretVisible,
                                      ),
                              icon: Icon(
                                _secretVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _tryLogin(t),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _loginError == null
                              ? const SizedBox(height: AppSpacing.x4)
                              : Padding(
                                  key: ValueKey(_loginError),
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.x3,
                                    bottom: AppSpacing.x1,
                                  ),
                                  child: _LoginErrorBanner(
                                    message: _loginError!,
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _loginBusy ? null : () => _tryLogin(t),
                            icon: _loginBusy
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: palette.accentOn,
                                    ),
                                  )
                                : const Icon(Icons.lock_open_outlined),
                            label: Text(
                              _loginBusy ? t.adminLoginChecking : t.adminLogin,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tryLogin(AppLocalizations t) async {
    if (_loginBusy) return;
    setState(() {
      _loginBusy = true;
      _loginError = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    final ok = _secretCtrl.text == widget.secretKey;
    if (ok) {
      await AdminSessionStore.instance.unlock();
    } else {
      await AdminSessionStore.instance.clear();
    }
    if (!mounted) return;
    setState(() {
      _authed = ok;
      _loginBusy = false;
      _loginError = ok ? null : t.adminInvalidSecret;
    });
  }

  Future<void> _restoreSession() async {
    final authed = await AdminSessionStore.instance.isUnlocked();
    if (!mounted) return;
    setState(() {
      _authed = authed;
      _sessionReady = true;
    });
  }

  Future<void> _logout() async {
    await AdminSessionStore.instance.clear();
    if (!mounted) return;
    setState(() {
      _authed = false;
      _secretCtrl.clear();
      _loginError = null;
      _secretVisible = false;
    });
  }

  Future<void> _exportAll() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final location =
          await saveChipsExportZip(ChipJsonRepository.instance.exportFiles());
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(t.adminExportSuccess(location))),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(t.adminExportFailed('$e'))),
      );
    }
  }
}

class _AdminSessionLoadingView extends StatelessWidget {
  const _AdminSessionLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _LoginStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LoginStatusPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bgElevated1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: palette.success),
            const SizedBox(width: AppSpacing.x2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  final String message;

  const _LoginErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: palette.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: palette.danger.withValues(alpha: palette.isDark ? 0.42 : 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x2,
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: palette.danger),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.danger,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LazyAdminTabView extends StatefulWidget {
  final List<Widget> children;

  const _LazyAdminTabView({required this.children});

  @override
  State<_LazyAdminTabView> createState() => _LazyAdminTabViewState();
}

class _LazyAdminTabViewState extends State<_LazyAdminTabView> {
  TabController? _controller;
  late List<bool> _visited;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _visited = List<bool>.filled(widget.children.length, false);
    if (_visited.isNotEmpty) _visited[0] = true;
  }

  @override
  void didUpdateWidget(covariant _LazyAdminTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _visited = List<bool>.generate(
        widget.children.length,
        (i) => i < _visited.length && _visited[i],
      );
      if (_index >= widget.children.length) _index = 0;
      if (_visited.isNotEmpty) _visited[_index] = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DefaultTabController.of(context);
    if (_controller == next) return;
    _controller?.removeListener(_onTabChanged);
    _controller = next;
    _index = next.index;
    if (_index >= 0 && _index < _visited.length) {
      _visited[_index] = true;
    }
    next.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    final controller = _controller;
    if (controller == null || controller.index == _index) return;
    setState(() {
      _index = controller.index;
      if (_index >= 0 && _index < _visited.length) {
        _visited[_index] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _index,
      children: List.generate(widget.children.length, (i) {
        return _visited[i] ? widget.children[i] : const SizedBox.shrink();
      }),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBackHome;
  final VoidCallback onExportAll;
  final VoidCallback onLogout;

  const _AdminTopBar({
    required this.title,
    required this.onBackHome,
    required this.onExportAll,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.bgElevated1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            return Row(
              children: [
                IconButton.filledTonal(
                  tooltip: t.adminBackHome,
                  onPressed: onBackHome,
                  icon: const Icon(Icons.home_outlined),
                ),
                const SizedBox(width: AppSpacing.x3),
                if (!compact) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.accentMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: palette.borderStrong),
                    ),
                    child: Icon(
                      Icons.memory_outlined,
                      size: 20,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                ],
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                if (compact) ...[
                  IconButton.filledTonal(
                    tooltip: t.adminExportAll,
                    onPressed: onExportAll,
                    icon: const Icon(Icons.file_download_outlined),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  IconButton(
                    tooltip: t.adminLogout,
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: onExportAll,
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(t.adminExportAll),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  TextButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: Text(t.adminLogout),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminTabStrip extends StatelessWidget {
  const _AdminTabStrip();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.bgElevated2,
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: palette.accent,
          unselectedLabelColor: palette.textSecondary,
          indicatorColor: palette.accent,
          indicatorWeight: 3,
          tabs: [
            Tab(icon: const Icon(Icons.bluetooth), text: t.adminBleCase),
            Tab(
              icon: const Icon(Icons.headphones_outlined),
              text: t.adminBtCase,
            ),
            Tab(icon: const Icon(Icons.earbuds_outlined), text: t.adminEarbuds),
            Tab(icon: const Icon(Icons.wifi), text: t.adminWifi),
            Tab(icon: const Icon(Icons.settings_outlined), text: t.adminOps),
            Tab(
              icon: const Icon(Icons.local_fire_department_outlined),
              text: t.adminHeat,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _AdminPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x3),
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bgElevated2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.borderSubtle),
        boxShadow: AppElevation.card,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DomainAdminTab extends StatefulWidget {
  final ChipJsonDomain domain;

  const _DomainAdminTab({required this.domain});

  @override
  State<_DomainAdminTab> createState() => _DomainAdminTabState();
}

class _DomainAdminTabState extends State<_DomainAdminTab> {
  String? _selectedId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _pickFirst();
    ChipJsonRepository.instance.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    ChipJsonRepository.instance.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    final changedDomain = ChipJsonRepository.instance.lastChangedDomain;
    if (changedDomain != null && changedDomain != widget.domain) return;
    setState(_pickFirst);
  }

  void _pickFirst() {
    final list = ChipJsonRepository.instance.records(widget.domain);
    if (_selectedId == null ||
        !list.any((record) => record.id == _selectedId)) {
      _selectedId = list.isEmpty ? null : list.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repo = ChipJsonRepository.instance;
    final all = repo.records(widget.domain);
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? all
        : all.where((r) => r.id.toLowerCase().contains(query)).toList();
    final selected = _selectedId == null
        ? null
        : repo.recordById(widget.domain, _selectedId!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        final list = _RecordList(
          records: filtered,
          total: all.length,
          selectedId: _selectedId,
          canReorder: query.isEmpty,
          onSearch: (value) => setState(() => _query = value),
          onSelect: (id) => setState(() => _selectedId = id),
          onAdd: () {
            final record = repo.add(widget.domain);
            setState(() => _selectedId = record.id);
          },
          onResetSeed: () => _confirmReset(),
          onSyncExcel: widget.domain == ChipJsonDomain.earbuds
              ? () => _syncExcel()
              : null,
          onDuplicate: (id) {
            final record = repo.duplicate(widget.domain, id);
            setState(() => _selectedId = record.id);
          },
          onDelete: (id) => _confirmDelete(id),
          onReorder: (oldIndex, newIndex) =>
              repo.reorder(widget.domain, oldIndex, newIndex),
          onMoveUp: (index) => repo.reorder(widget.domain, index, index - 1),
          onMoveDown: (index) => repo.reorder(widget.domain, index, index + 1),
        );
        final editor = selected == null
            ? Center(child: Text(t.adminNoChipSelected))
            : _JsonRecordEditor(
                key: ValueKey('${widget.domain.key}_${selected.id}'),
                domain: widget.domain,
                record: selected,
              );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 300, child: list),
              const Divider(height: 1),
              Expanded(child: editor),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
                width: constraints.maxWidth < 1120 ? 320 : 360, child: list),
            const VerticalDivider(width: 1),
            Expanded(child: editor),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(String id) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminDeleteConfirmTitle),
        content: Text(t.adminDeleteConfirmBody(id)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.adminConfirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      ChipJsonRepository.instance.delete(widget.domain, id);
    }
  }

  Future<void> _confirmReset() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminResetDomain),
        content: Text(t.adminResetDomainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.adminConfirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ChipJsonRepository.instance.resetToSeed(widget.domain);
    }
  }

  Future<void> _syncExcel() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'csv'],
        withData: true,
      );
    } catch (_) {
      picked = null;
    }

    final file = picked?.files.isNotEmpty == true ? picked!.files.first : null;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.adminSyncExcelPickFailed)),
      );
      return;
    }

    Map<String, Map<String, dynamic>> details;
    try {
      details = NoisePinkSyncService.parse(file.name, bytes);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.adminSyncExcelParseFailed)),
      );
      return;
    }

    if (details.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.adminSyncExcelEmpty)),
      );
      return;
    }

    final result =
        ChipJsonRepository.instance.syncEarbudsNoisePinkDetail(details);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminSyncExcelResultTitle),
        content: Text(
          t.adminSyncExcelResultBody(
            result.matched.length,
            result.skipped.length,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.adminConfirm),
          ),
        ],
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  final List<ChipJsonRecord> records;
  final int total;
  final String? selectedId;
  final bool canReorder;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onResetSeed;
  final VoidCallback? onSyncExcel;
  final ValueChanged<String> onDuplicate;
  final ValueChanged<String> onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;

  const _RecordList({
    required this.records,
    required this.total,
    required this.selectedId,
    required this.canReorder,
    required this.onSearch,
    required this.onSelect,
    required this.onAdd,
    required this.onResetSeed,
    this.onSyncExcel,
    required this.onDuplicate,
    required this.onDelete,
    required this.onReorder,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return ColoredBox(
      color: palette.bgElevated1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.adminJsonEditor,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _CountPill(text: t.adminTotalChips(total)),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            TextField(
              decoration: InputDecoration(
                hintText: t.adminSearchChip,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: records.isEmpty
                    ? null
                    : Icon(
                        Icons.filter_list_outlined,
                        size: 18,
                        color: palette.textMuted,
                      ),
              ),
              onChanged: onSearch,
            ),
            const SizedBox(height: AppSpacing.x2),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t.adminAddChip),
            ),
            const SizedBox(height: AppSpacing.x2),
            OutlinedButton.icon(
              onPressed: onResetSeed,
              icon: const Icon(Icons.restore),
              label: Text(t.adminResetDomain),
            ),
            if (onSyncExcel != null) ...[
              const SizedBox(height: AppSpacing.x2),
              OutlinedButton.icon(
                onPressed: onSyncExcel,
                icon: const Icon(Icons.sync),
                label: Text(t.adminSyncExcel),
              ),
            ],
            const SizedBox(height: AppSpacing.x3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x2),
              decoration: BoxDecoration(
                color: palette.bgElevated2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: palette.accent),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      canReorder
                          ? t.adminSortHint
                          : t.adminReorderDisabledInSearch,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Expanded(
              child: canReorder
                  ? ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: records.length,
                      onReorderItem: onReorder,
                      itemBuilder: (context, index) =>
                          _tile(context, records[index], index),
                    )
                  : ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) =>
                          _tile(context, records[index], null),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ChipJsonRecord record, int? dragIndex) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final selected = record.id == selectedId;
    return Material(
      key: ValueKey(record.id),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => onSelect(record.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2,
              vertical: AppSpacing.x2,
            ),
            decoration: BoxDecoration(
              color: selected ? palette.accentMuted : palette.bgElevated2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? palette.accent : palette.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                if (dragIndex != null) ...[
                  ReorderableDragStartListener(
                    index: dragIndex,
                    child: Semantics(
                      label: t.adminDragHandle,
                      button: true,
                      child: Icon(
                        Icons.drag_indicator,
                        size: 20,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                ],
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? palette.accent : palette.bgElevated3,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.memory_outlined,
                    size: 16,
                    color: selected ? palette.accentOn : palette.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        (record.data['name'] ??
                                record.data['description'] ??
                                '')
                            .toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (dragIndex != null) ...[
                  IconButton(
                    tooltip: t.adminMoveUp,
                    onPressed: dragIndex > 0 ? () => onMoveUp(dragIndex) : null,
                    icon: const Icon(Icons.keyboard_arrow_up),
                  ),
                  IconButton(
                    tooltip: t.adminMoveDown,
                    onPressed: dragIndex < records.length - 1
                        ? () => onMoveDown(dragIndex)
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'duplicate') onDuplicate(record.id);
                    if (value == 'delete') onDelete(record.id);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(t.adminDuplicate),
                    ),
                    PopupMenuItem(value: 'delete', child: Text(t.adminDelete)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String text;

  const _CountPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: palette.bgElevated3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.textSecondary,
            ),
      ),
    );
  }
}

enum _FieldType { string, number, boolean, json }

enum _FieldCategory { identity, timing, current, radio, hardware, other }

class _FieldDraft {
  String name;
  String value;
  _FieldType type;
  List<_FieldDraft> children;
  bool expanded;
  dynamic rawValue;

  _FieldDraft({
    required this.name,
    required this.value,
    required this.type,
    this.rawValue,
  })  : children = <_FieldDraft>[],
        expanded = false;

  int get childCount {
    if (children.isNotEmpty) return children.length;
    final raw = rawValue;
    if (raw is Map) return raw.length;
    return 0;
  }

  bool get hasObjectChildren => type == _FieldType.json && childCount > 0;
}

class _FieldSection {
  final _FieldCategory category;
  final List<int> indexes;

  const _FieldSection(this.category, this.indexes);
}

class _JsonRecordEditor extends StatefulWidget {
  final ChipJsonDomain domain;
  final ChipJsonRecord record;

  const _JsonRecordEditor({
    super.key,
    required this.domain,
    required this.record,
  });

  @override
  State<_JsonRecordEditor> createState() => _JsonRecordEditorState();
}

class _JsonRecordEditorState extends State<_JsonRecordEditor> {
  late List<_FieldDraft> _fields;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fields = widget.record.data.entries
        .map((entry) => _fieldFromValue(entry.key, entry.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final sections = _fieldSections();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: palette.bgElevated2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.borderSubtle)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x3,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 560;
                final title = Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.accentMuted,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: palette.borderStrong),
                      ),
                      child: Icon(
                        Icons.data_object_outlined,
                        size: 20,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.record.id,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            t.adminJsonEditor,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: palette.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: _addField,
                      icon: const Icon(Icons.add),
                      label: Text(t.adminAddField),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(t.adminSave),
                    ),
                  ],
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      const SizedBox(height: AppSpacing.x3),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: AppSpacing.x3),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x3,
              AppSpacing.x4,
              0,
            ),
            child: Material(
              color: palette.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x3),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: palette.danger),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: palette.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: ColoredBox(
            color: palette.bgBase,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.x4),
              itemCount: sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = sections[sectionIndex];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        sectionIndex == sections.length - 1 ? 0 : AppSpacing.x4,
                  ),
                  child: _FieldGroupPanel(
                    icon: _categoryIcon(section.category),
                    title: _categoryTitle(t, section.category),
                    count: section.indexes.length,
                    child: Column(
                      children: [
                        for (int i = 0; i < section.indexes.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: AppSpacing.x4,
                              color: palette.borderSubtle,
                            ),
                          _fieldRow(t, section.indexes[i], _fields),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<_FieldSection> _fieldSections() {
    final grouped = <_FieldCategory, List<int>>{
      for (final category in _FieldCategory.values) category: <int>[],
    };
    for (int i = 0; i < _fields.length; i++) {
      grouped[_categoryFor(_fields[i].name)]!.add(i);
    }
    return _FieldCategory.values
        .where((category) => grouped[category]!.isNotEmpty)
        .map((category) => _FieldSection(category, grouped[category]!))
        .toList();
  }

  _FieldCategory _categoryFor(String name) {
    final key = name.toLowerCase();
    if (_matchesAny(key, [
      'id',
      'name',
      'model',
      'description',
      'project',
      'software',
      'mass',
      'config',
    ])) {
      return _FieldCategory.identity;
    }
    if (_matchesAny(key, [
      'crystal',
      'clock',
      'osc',
      'pll',
      'process',
      'core',
      'ram',
      'vcore',
      'vana',
      'vsys',
      'vhppa',
    ])) {
      return _FieldCategory.hardware;
    }
    if (_matchesAny(key, [
      'current',
      'power',
      'voltage',
      'vbat',
      'ma',
      'ua',
      'sleep',
      'standby',
      'wfi',
    ])) {
      return _FieldCategory.current;
    }
    if (_matchesAny(key, [
      'window',
      'time',
      'length',
      'interval',
      'delay',
      'duration',
      'attemptwait',
      'gap',
      'period',
      'rmin',
    ])) {
      return _FieldCategory.timing;
    }
    if (_matchesAny(key, [
      'tx',
      'rx',
      'bt',
      'ble',
      'wifi',
      'phy',
      'dbm',
      'gain',
      'payload',
      'packet',
      'channel',
      'sniff',
      'page',
    ])) {
      return _FieldCategory.radio;
    }
    return _FieldCategory.other;
  }

  bool _matchesAny(String value, List<String> patterns) {
    return patterns.any(value.contains);
  }

  IconData _categoryIcon(_FieldCategory category) {
    switch (category) {
      case _FieldCategory.identity:
        return Icons.badge_outlined;
      case _FieldCategory.timing:
        return Icons.timer_outlined;
      case _FieldCategory.current:
        return Icons.bolt_outlined;
      case _FieldCategory.radio:
        return Icons.settings_input_antenna_outlined;
      case _FieldCategory.hardware:
        return Icons.memory_outlined;
      case _FieldCategory.other:
        return Icons.tune_outlined;
    }
  }

  String _categoryTitle(AppLocalizations t, _FieldCategory category) {
    switch (category) {
      case _FieldCategory.identity:
        return t.adminGroupIdentity;
      case _FieldCategory.timing:
        return t.adminGroupTiming;
      case _FieldCategory.current:
        return t.adminGroupCurrent;
      case _FieldCategory.radio:
        return t.adminGroupRadio;
      case _FieldCategory.hardware:
        return t.adminGroupHardware;
      case _FieldCategory.other:
        return t.adminGroupOther;
    }
  }

  List<DropdownMenuItem<_FieldType>> _fieldTypeItems(AppLocalizations t) {
    return [
      DropdownMenuItem(
        value: _FieldType.string,
        child: Text(t.adminTypeString),
      ),
      DropdownMenuItem(
        value: _FieldType.number,
        child: Text(t.adminTypeNumber),
      ),
      DropdownMenuItem(
        value: _FieldType.boolean,
        child: Text(t.adminTypeBool),
      ),
      DropdownMenuItem(
        value: _FieldType.json,
        child: Text(t.adminTypeJson),
      ),
    ];
  }

  Future<void> _confirmRemoveField(
    String fieldName,
    VoidCallback onConfirmed,
  ) async {
    final t = AppLocalizations.of(context);
    final label = fieldName.trim().isEmpty ? '-' : fieldName.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminRemoveFieldConfirmTitle),
        content: Text(t.adminRemoveFieldConfirmBody(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.adminConfirm),
          ),
        ],
      ),
    );
    if (ok == true) onConfirmed();
  }

  Widget _fieldRow(AppLocalizations t, int index, List<_FieldDraft> fields) {
    final palette = AppPalette.of(context);
    final field = fields[index];
    final isObject = field.hasObjectChildren;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final nameInput = _FieldInputFrame(
            child: TextFormField(
              initialValue: field.name,
              decoration: InputDecoration(
                hintText: t.adminFieldName,
                prefixIcon: const Icon(Icons.label_outline, size: 18),
              ),
              onChanged: (value) => field.name = value,
            ),
          );
          final typeInput = _FieldInputFrame(
            child: DropdownButtonFormField<_FieldType>(
              initialValue: field.type,
              decoration: InputDecoration(
                hintText: t.adminFieldType,
                prefixIcon: const Icon(Icons.tune_outlined, size: 18),
              ),
              items: _fieldTypeItems(t),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  field.type = value;
                  if (value != _FieldType.json) {
                    field.children = [];
                    field.rawValue = null;
                  }
                  if (value == _FieldType.json &&
                      field.children.isEmpty &&
                      field.rawValue == null &&
                      field.value.trim().isEmpty) {
                    field.value = '{}';
                  }
                });
              },
            ),
          );
          final valueInput = isObject
              ? _ObjectFieldButton(
                  label: t.adminNestedFields,
                  childCount: field.childCount,
                  onTap: () => _openObjectEditor(t, field),
                )
              : _FieldInputFrame(
                  child: TextFormField(
                    initialValue: field.value,
                    minLines: field.type == _FieldType.json ? 3 : 1,
                    maxLines: field.type == _FieldType.json ? 8 : 1,
                    decoration: InputDecoration(
                      hintText: t.adminFieldValue,
                      prefixIcon: const Icon(Icons.edit_note, size: 18),
                    ),
                    onChanged: (value) => field.value = value,
                  ),
                );
          final removeButton = Padding(
            padding: const EdgeInsets.only(left: AppSpacing.x2),
            child: IconButton.filledTonal(
              tooltip: t.adminRemoveRow,
              onPressed: () => _confirmRemoveField(
                field.name,
                () => setState(() => fields.removeAt(index)),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          );
          final grip = Padding(
            padding: EdgeInsets.only(
              right: narrow ? 0 : AppSpacing.x2,
              top: narrow ? 0 : AppSpacing.x3,
            ),
            child: Icon(
              Icons.drag_indicator,
              size: 18,
              color: palette.textMuted,
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    grip,
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(child: nameInput),
                    removeButton,
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                typeInput,
                const SizedBox(height: AppSpacing.x2),
                valueInput,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              grip,
              SizedBox(width: 220, child: nameInput),
              const SizedBox(width: AppSpacing.x2),
              SizedBox(width: 150, child: typeInput),
              const SizedBox(width: AppSpacing.x2),
              Expanded(child: valueInput),
              removeButton,
            ],
          );
        },
      ),
    );
  }

  Widget _nestedFieldRow(
    AppLocalizations t,
    List<_FieldDraft> fields,
    int index,
    void Function(VoidCallback fn) mutate,
  ) {
    final palette = AppPalette.of(context);
    final field = fields[index];
    final isObject = field.hasObjectChildren;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          final nameInput = _FieldInputFrame(
            child: TextFormField(
              initialValue: field.name,
              decoration: InputDecoration(
                hintText: t.adminFieldName,
                prefixIcon: const Icon(Icons.label_outline, size: 18),
              ),
              onChanged: (value) => field.name = value,
            ),
          );
          final typeInput = _FieldInputFrame(
            child: DropdownButtonFormField<_FieldType>(
              initialValue: field.type,
              decoration: InputDecoration(
                hintText: t.adminFieldType,
                prefixIcon: const Icon(Icons.tune_outlined, size: 18),
              ),
              items: _fieldTypeItems(t),
              onChanged: (value) {
                if (value == null) return;
                mutate(() {
                  field.type = value;
                  if (value != _FieldType.json) {
                    field.children = [];
                    field.rawValue = null;
                  }
                });
              },
            ),
          );
          final valueInput = isObject
              ? _ObjectFieldButton(
                  label: t.adminNestedFields,
                  childCount: field.childCount,
                  onTap: () => _openObjectEditor(t, field),
                )
              : _FieldInputFrame(
                  child: TextFormField(
                    initialValue: field.value,
                    minLines: field.type == _FieldType.json ? 2 : 1,
                    maxLines: field.type == _FieldType.json ? 6 : 1,
                    decoration: InputDecoration(
                      hintText: t.adminFieldValue,
                      prefixIcon: const Icon(Icons.edit_note, size: 18),
                    ),
                    onChanged: (value) => field.value = value,
                  ),
                );
          final removeButton = Padding(
            padding: const EdgeInsets.only(left: AppSpacing.x2),
            child: IconButton.filledTonal(
              tooltip: t.adminRemoveRow,
              onPressed: () => _confirmRemoveField(
                field.name,
                () => mutate(() => fields.removeAt(index)),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          );
          final grip = Padding(
            padding: EdgeInsets.only(
              right: narrow ? 0 : AppSpacing.x2,
              top: narrow ? 0 : AppSpacing.x3,
            ),
            child: Icon(
              Icons.drag_indicator,
              size: 18,
              color: palette.textMuted,
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    grip,
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(child: nameInput),
                    removeButton,
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                typeInput,
                const SizedBox(height: AppSpacing.x2),
                valueInput,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              grip,
              SizedBox(width: 220, child: nameInput),
              const SizedBox(width: AppSpacing.x2),
              SizedBox(width: 150, child: typeInput),
              const SizedBox(width: AppSpacing.x2),
              Expanded(child: valueInput),
              removeButton,
            ],
          );
        },
      ),
    );
  }

  Future<void> _openObjectEditor(
    AppLocalizations t,
    _FieldDraft field,
  ) async {
    setState(() => _ensureChildren(field));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void mutateDialog(VoidCallback fn) {
              setDialogState(fn);
              setState(() {});
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(AppSpacing.x4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 980,
                  maxHeight: 720,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ObjectEditorHeader(
                      title: field.name,
                      subtitle: t.adminObjectEditorSubtitle(field.childCount),
                      onClose: () => Navigator.of(dialogContext).pop(),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AppPalette.of(context).bgBase,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.x4),
                          itemCount: field.children.length,
                          separatorBuilder: (_, __) => Divider(
                            height: AppSpacing.x4,
                            color: AppPalette.of(context).borderSubtle,
                          ),
                          itemBuilder: (context, i) => _nestedFieldRow(
                            t,
                            field.children,
                            i,
                            mutateDialog,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.x3),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => mutateDialog(() {
                            field.children = [
                              ...field.children,
                              _FieldDraft(
                                name: 'customField',
                                value: '',
                                type: _FieldType.string,
                              ),
                            ];
                          }),
                          icon: const Icon(Icons.add),
                          label: Text(t.adminAddNestedField),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  void _addField() {
    setState(() {
      _fields.add(_FieldDraft(
        name: 'customField',
        value: '',
        type: _FieldType.string,
      ));
    });
  }

  static void _ensureChildren(_FieldDraft field) {
    if (field.children.isNotEmpty) return;
    final raw = field.rawValue;
    if (raw is! Map) return;
    field.children = raw.entries
        .map((entry) => _fieldFromValue(entry.key.toString(), entry.value))
        .toList();
    field.rawValue = null;
    field.value = '';
  }

  void _save() {
    final t = AppLocalizations.of(context);
    final data = <String, dynamic>{};
    for (final field in _fields) {
      final name = field.name.trim();
      if (name.isEmpty) continue;
      try {
        data[name] = _valueFromField(field);
      } catch (_) {
        setState(() => _error = t.adminBadJson);
        return;
      }
    }
    if ((data['id'] ?? '').toString().trim().isEmpty) {
      setState(() => _error = t.adminInvalidId);
      return;
    }
    final ok = ChipJsonRepository.instance.update(
      widget.domain,
      widget.record.id,
      data,
    );
    if (!ok) {
      setState(() => _error = t.adminInvalidId);
      return;
    }
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.adminSavedLocal)),
    );
  }

  static _FieldType _typeOf(dynamic value) {
    if (value is num) return _FieldType.number;
    if (value is bool) return _FieldType.boolean;
    if (value is Map || value is List) return _FieldType.json;
    return _FieldType.string;
  }

  static _FieldDraft _fieldFromValue(String name, dynamic value) {
    final type = _typeOf(value);
    if (value is Map) {
      return _FieldDraft(
        name: name,
        value: '',
        type: type,
        rawValue: Map<String, dynamic>.from(value),
      );
    }
    return _FieldDraft(
      name: name,
      value: _formatValue(value),
      type: type,
    );
  }

  static String _formatValue(dynamic value) {
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value?.toString() ?? '';
  }

  static dynamic _parseValue(_FieldDraft field) {
    switch (field.type) {
      case _FieldType.string:
        return field.value;
      case _FieldType.number:
        return num.tryParse(field.value.trim()) ?? field.value;
      case _FieldType.boolean:
        return field.value.trim().toLowerCase() == 'true';
      case _FieldType.json:
        return jsonDecode(field.value);
    }
  }

  static dynamic _valueFromField(_FieldDraft field) {
    if (field.type == _FieldType.json && field.rawValue is Map) {
      return Map<String, dynamic>.from(field.rawValue as Map);
    }
    if (field.type == _FieldType.json && field.children.isNotEmpty) {
      final map = <String, dynamic>{};
      for (final child in field.children) {
        final name = child.name.trim();
        if (name.isEmpty) continue;
        map[name] = _valueFromField(child);
      }
      return map;
    }
    return _parseValue(field);
  }
}

class _FieldGroupPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Widget child;

  const _FieldGroupPanel({
    required this.icon,
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bgElevated2.withValues(alpha: palette.isDark ? 0.7 : 1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: palette.accent),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _CountPill(text: '$count'),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldInputFrame extends StatelessWidget {
  final Widget child;

  const _FieldInputFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: palette.isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                fillColor: palette.bgElevated2,
              ),
        ),
        child: child,
      ),
    );
  }
}

class _ObjectFieldButton extends StatelessWidget {
  final String label;
  final int childCount;
  final VoidCallback onTap;

  const _ObjectFieldButton({
    required this.label,
    required this.childCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return _FieldInputFrame(
      child: Material(
        color: palette.bgElevated2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 18,
                  color: palette.accent,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    '$label · $childCount',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ),
                Icon(
                  Icons.open_in_new_outlined,
                  size: 18,
                  color: palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ObjectEditorHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _ObjectEditorHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.bgElevated2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                Icons.account_tree_outlined,
                size: 20,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 44),
                  const SizedBox(height: AppSpacing.x2),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
