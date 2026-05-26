import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/chip_json_repository.dart';
import '../services/chips_export_service.dart';
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
  String? _loginError;

  @override
  void dispose() {
    _secretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                onLogout: () => setState(() => _authed = false),
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
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  child: _AdminPanel(
                    padding: const EdgeInsets.all(AppSpacing.x6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 40,
                          color: palette.accent,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          t.adminLoginTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        TextField(
                          controller: _secretCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: t.adminSecret,
                            prefixIcon: const Icon(Icons.key_outlined),
                            errorText: _loginError,
                          ),
                          onSubmitted: (_) => _tryLogin(t),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        FilledButton.icon(
                          onPressed: () => _tryLogin(t),
                          icon: const Icon(Icons.lock_open_outlined),
                          label: Text(t.adminLogin),
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

  void _tryLogin(AppLocalizations t) {
    final ok = _secretCtrl.text == widget.secretKey;
    setState(() {
      _authed = ok;
      _loginError = ok ? null : t.adminInvalidSecret;
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
}

class _RecordList extends StatelessWidget {
  final List<ChipJsonRecord> records;
  final int total;
  final String? selectedId;
  final bool canReorder;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
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
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x4),
              itemCount: _fields.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x3),
              itemBuilder: (context, index) => _fieldRow(t, index, _fields),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldRow(AppLocalizations t, int index, List<_FieldDraft> fields) {
    final palette = AppPalette.of(context);
    final field = fields[index];
    final isObject = field.hasObjectChildren;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bgElevated2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 720;
                final controls = [
                  SizedBox(
                    width: narrow ? double.infinity : 220,
                    child: TextFormField(
                      initialValue: field.name,
                      decoration: InputDecoration(
                        labelText: t.adminFieldName,
                        prefixIcon: const Icon(Icons.label_outline, size: 18),
                      ),
                      onChanged: (value) => field.name = value,
                    ),
                  ),
                  SizedBox(
                    width: narrow ? double.infinity : 150,
                    child: DropdownButtonFormField<_FieldType>(
                      initialValue: field.type,
                      decoration: InputDecoration(
                        labelText: t.adminFieldType,
                        prefixIcon: const Icon(Icons.tune_outlined, size: 18),
                      ),
                      items: [
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
                      ],
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
                  ),
                  Expanded(
                    child: isObject
                        ? _NestedFieldsBadge(
                            label: t.adminNestedFields,
                            childCount: field.childCount,
                            expanded: field.expanded,
                            onToggle: () => _toggleExpanded(field),
                          )
                        : TextFormField(
                            initialValue: field.value,
                            minLines: field.type == _FieldType.json ? 3 : 1,
                            maxLines: field.type == _FieldType.json ? 8 : 1,
                            decoration: InputDecoration(
                              labelText: t.adminFieldValue,
                              prefixIcon: const Icon(Icons.edit_note, size: 18),
                            ),
                            onChanged: (value) => field.value = value,
                          ),
                  ),
                  IconButton.filledTonal(
                    tooltip: t.adminRemoveRow,
                    onPressed: () => setState(() => fields.removeAt(index)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ];
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: controls
                        .map((child) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.x2),
                              child: child,
                            ))
                        .toList(),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    controls[0],
                    const SizedBox(width: AppSpacing.x2),
                    controls[1],
                    const SizedBox(width: AppSpacing.x2),
                    controls[2],
                    controls[3],
                  ],
                );
              },
            ),
            if (isObject && field.expanded) ...[
              const SizedBox(height: AppSpacing.x2),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.x2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < field.children.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                        child: _nestedFieldRow(t, field.children, i),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _ensureChildren(field);
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nestedFieldRow(
    AppLocalizations t,
    List<_FieldDraft> fields,
    int index,
  ) {
    final palette = AppPalette.of(context);
    final field = fields[index];
    final isObject = field.hasObjectChildren;
    return Material(
      color: palette.bgElevated1,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 680;
                final controls = [
                  SizedBox(
                    width: narrow ? double.infinity : 220,
                    child: TextFormField(
                      initialValue: field.name,
                      decoration: InputDecoration(
                        labelText: t.adminFieldName,
                        prefixIcon: const Icon(Icons.label_outline, size: 18),
                      ),
                      onChanged: (value) => field.name = value,
                    ),
                  ),
                  SizedBox(
                    width: narrow ? double.infinity : 150,
                    child: DropdownButtonFormField<_FieldType>(
                      initialValue: field.type,
                      decoration: InputDecoration(
                        labelText: t.adminFieldType,
                        prefixIcon: const Icon(Icons.tune_outlined, size: 18),
                      ),
                      items: [
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
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          field.type = value;
                          if (value != _FieldType.json) {
                            field.children = [];
                            field.rawValue = null;
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: isObject
                        ? _NestedFieldsBadge(
                            label: t.adminNestedFields,
                            childCount: field.childCount,
                            expanded: field.expanded,
                            onToggle: () => _toggleExpanded(field),
                          )
                        : TextFormField(
                            initialValue: field.value,
                            minLines: field.type == _FieldType.json ? 2 : 1,
                            maxLines: field.type == _FieldType.json ? 6 : 1,
                            decoration: InputDecoration(
                              labelText: t.adminFieldValue,
                              prefixIcon: const Icon(Icons.edit_note, size: 18),
                            ),
                            onChanged: (value) => field.value = value,
                          ),
                  ),
                  IconButton.filledTonal(
                    tooltip: t.adminRemoveRow,
                    onPressed: () => setState(() => fields.removeAt(index)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ];

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: controls
                        .map((child) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.x2),
                              child: child,
                            ))
                        .toList(),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    controls[0],
                    const SizedBox(width: AppSpacing.x2),
                    controls[1],
                    const SizedBox(width: AppSpacing.x2),
                    controls[2],
                    controls[3],
                  ],
                );
              },
            ),
            if (isObject && field.expanded) ...[
              const SizedBox(height: AppSpacing.x2),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.x2),
                child: Column(
                  children: [
                    for (int i = 0; i < field.children.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x1),
                        child: _nestedFieldRow(t, field.children, i),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _ensureChildren(field);
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  void _toggleExpanded(_FieldDraft field) {
    setState(() {
      _ensureChildren(field);
      field.expanded = !field.expanded;
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

class _NestedFieldsBadge extends StatelessWidget {
  final String label;
  final int childCount;
  final bool expanded;
  final VoidCallback onToggle;

  const _NestedFieldsBadge({
    required this.label,
    required this.childCount,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.bgElevated1,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onToggle,
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
                expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 20,
                color: palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.x1),
              Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: palette.accent,
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  '$label · $childCount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
              ),
            ],
          ),
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
