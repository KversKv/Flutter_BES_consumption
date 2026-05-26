import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/chip_json_repository.dart';
import '../services/chips_export_service.dart';
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
        appBar: AppBar(
          title: Text(t.adminTitle),
          leading: IconButton(
            tooltip: t.adminBackHome,
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
          actions: [
            TextButton.icon(
              onPressed: _exportAll,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(t.adminExportAll),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _authed = false),
              icon: const Icon(Icons.logout),
              label: Text(t.adminLogout),
            ),
            const SizedBox(width: AppSpacing.x2),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: t.adminBleCase),
              Tab(text: t.adminBtCase),
              Tab(text: t.adminEarbuds),
              Tab(text: t.adminWifi),
              Tab(text: t.adminOps),
              Tab(text: t.adminHeat),
            ],
          ),
        ),
        body: TabBarView(
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
    );
  }

  Widget _loginView(AppLocalizations t) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminLoginTitle),
        leading: IconButton(
          tooltip: t.adminBackHome,
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.adminLoginTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    TextField(
                      controller: _secretCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: t.adminSecret,
                        border: const OutlineInputBorder(),
                        errorText: _loginError,
                      ),
                      onSubmitted: (_) => _tryLogin(t),
                    ),
                    const SizedBox(height: AppSpacing.x3),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: _RecordList(
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
            onMoveDown: (index) =>
                repo.reorder(widget.domain, index, index + 1),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? Center(child: Text(t.adminNoChipSelected))
              : _JsonRecordEditor(
                  key: ValueKey('${widget.domain.key}_${selected.id}'),
                  domain: widget.domain,
                  record: selected,
                ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: t.adminSearchChip,
              prefixIcon: const Icon(Icons.search, size: 18),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onSearch,
          ),
          const SizedBox(height: AppSpacing.x2),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(t.adminAddChip),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(t.adminTotalChips(total)),
          Text(
            t.adminSortHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!canReorder)
            Text(
              t.adminReorderDisabledInSearch,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const Divider(),
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
    );
  }

  Widget _tile(BuildContext context, ChipJsonRecord record, int? dragIndex) {
    final t = AppLocalizations.of(context);
    return Material(
      key: ValueKey(record.id),
      type: MaterialType.transparency,
      child: ListTile(
        dense: true,
        selected: record.id == selectedId,
        leading: dragIndex == null
            ? null
            : ReorderableDragStartListener(
                index: dragIndex,
                child: Semantics(
                  label: t.adminDragHandle,
                  button: true,
                  child: const Icon(Icons.drag_indicator, size: 18),
                ),
              ),
        title: Text(record.id),
        subtitle: Text(
          (record.data['name'] ?? record.data['description'] ?? '').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'up' && dragIndex != null) onMoveUp(dragIndex);
            if (value == 'down' && dragIndex != null) onMoveDown(dragIndex);
            if (value == 'duplicate') onDuplicate(record.id);
            if (value == 'delete') onDelete(record.id);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'up',
              enabled: dragIndex != null && dragIndex > 0,
              child: Text(t.adminMoveUp),
            ),
            PopupMenuItem(
              value: 'down',
              enabled: dragIndex != null && dragIndex < records.length - 1,
              child: Text(t.adminMoveDown),
            ),
            PopupMenuItem(value: 'duplicate', child: Text(t.adminDuplicate)),
            PopupMenuItem(value: 'delete', child: Text(t.adminDelete)),
          ],
        ),
        onTap: () => onSelect(record.id),
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

  _FieldDraft({
    required this.name,
    required this.value,
    required this.type,
    this.children = const [],
  });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x3,
              vertical: AppSpacing.x2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.record.id,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
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
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x2),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.x3),
            itemCount: _fields.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2),
            itemBuilder: (context, index) => _fieldRow(t, index, _fields),
          ),
        ),
      ],
    );
  }

  Widget _fieldRow(AppLocalizations t, int index, List<_FieldDraft> fields) {
    final field = fields[index];
    final isObject = field.type == _FieldType.json && field.children.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
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
                        border: const OutlineInputBorder(),
                        isDense: true,
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
                        border: const OutlineInputBorder(),
                        isDense: true,
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
                          if (value != _FieldType.json) field.children = [];
                          if (value == _FieldType.json &&
                              field.children.isEmpty &&
                              field.value.trim().isEmpty) {
                            field.value = '{}';
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: isObject
                        ? Text(t.adminNestedFields)
                        : TextFormField(
                            initialValue: field.value,
                            minLines: field.type == _FieldType.json ? 3 : 1,
                            maxLines: field.type == _FieldType.json ? 8 : 1,
                            decoration: InputDecoration(
                              labelText: t.adminFieldValue,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) => field.value = value,
                          ),
                  ),
                  IconButton(
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
            if (isObject) ...[
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
    final field = fields[index];
    final isObject = field.type == _FieldType.json && field.children.isNotEmpty;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    initialValue: field.name,
                    decoration: InputDecoration(
                      labelText: t.adminFieldName,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => field.name = value,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<_FieldType>(
                    initialValue: field.type,
                    decoration: InputDecoration(
                      labelText: t.adminFieldType,
                      border: const OutlineInputBorder(),
                      isDense: true,
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
                        if (value != _FieldType.json) field.children = [];
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: isObject
                      ? Text(t.adminNestedFields)
                      : TextFormField(
                          initialValue: field.value,
                          minLines: field.type == _FieldType.json ? 2 : 1,
                          maxLines: field.type == _FieldType.json ? 6 : 1,
                          decoration: InputDecoration(
                            labelText: t.adminFieldValue,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) => field.value = value,
                        ),
                ),
                IconButton(
                  tooltip: t.adminRemoveRow,
                  onPressed: () => setState(() => fields.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (isObject) ...[
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
    final children = value is Map
        ? value.entries
            .map((entry) => _fieldFromValue(entry.key.toString(), entry.value))
            .toList()
        : <_FieldDraft>[];
    return _FieldDraft(
      name: name,
      value: children.isEmpty ? _formatValue(value) : '',
      type: type,
      children: children,
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
