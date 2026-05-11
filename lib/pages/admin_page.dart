import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/app_localizations.dart';
import '../services/chips_export_service.dart';
import '../services/earbuds_repository.dart';
import '../theme/app_spacing.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? _selectedId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final list = EarbudsRepository.instance.records;
    if (list.isNotEmpty) _selectedId = list.first.id;
    EarbudsRepository.instance.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    EarbudsRepository.instance.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final list = EarbudsRepository.instance.records;
      if (_selectedId != null && !list.any((r) => r.id == _selectedId)) {
        _selectedId = list.isEmpty ? null : list.first.id;
      } else if (_selectedId == null && list.isNotEmpty) {
        _selectedId = list.first.id;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repo = EarbudsRepository.instance;
    final all = repo.records;
    final filtered = _query.trim().isEmpty
        ? all
        : all
            .where((r) =>
                r.id.toLowerCase().contains(_query.trim().toLowerCase()))
            .toList();

    final selected =
        _selectedId == null ? null : repo.recordById(_selectedId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminTitle),
        leading: IconButton(
          tooltip: t.adminBackHome,
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _exportJson(context),
            icon: const Icon(Icons.file_download_outlined),
            label: Text(t.adminExportJson),
          ),
          TextButton.icon(
            onPressed: () => _confirmResetAll(context),
            icon: const Icon(Icons.restore),
            label: Text(t.adminResetAll),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: _ChipListPanel(
              chips: filtered,
              total: all.length,
              query: _query,
              selectedId: _selectedId,
              onQueryChanged: (q) => setState(() => _query = q),
              onSelect: (id) => setState(() => _selectedId = id),
              onAdd: () {
                final c = repo.add();
                setState(() => _selectedId = c.id);
              },
              onDuplicate: (id) {
                final c = repo.duplicate(id);
                setState(() => _selectedId = c.id);
              },
              onDelete: (id) => _confirmDelete(context, id),
              onReorder: (oldIndex, newIndex) {
                repo.reorder(oldIndex, newIndex);
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected == null
                ? Center(child: Text(t.adminNoChipSelected))
                : _ChipEditor(
                    key: ValueKey('chip_${selected.id}'),
                    record: selected,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
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
      EarbudsRepository.instance.delete(id);
    }
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminResetConfirmTitle),
        content: Text(t.adminResetConfirmBody),
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
      await EarbudsRepository.instance.resetToSeed();
    }
  }

  Future<void> _exportJson(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final files = EarbudsRepository.instance.exportAsJsonFiles();
      final location = await saveChipsExportZip(files);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.adminExportSuccess(location)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.adminExportFailed('$e')),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _ChipListPanel extends StatelessWidget {
  final List<MutableEarbudsChip> chips;
  final int total;
  final String query;
  final String? selectedId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<String> onDuplicate;
  final ValueChanged<String> onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _ChipListPanel({
    required this.chips,
    required this.total,
    required this.query,
    required this.selectedId,
    required this.onQueryChanged,
    required this.onSelect,
    required this.onAdd,
    required this.onDuplicate,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final canReorder = query.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: t.adminSearchChip,
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(t.adminAddChip),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              t.adminTotalChips(total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (!canReorder)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x1),
              child: Text(
                t.adminReorderDisabledInSearch,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          const Divider(),
          Expanded(
            child: canReorder
                ? ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: chips.length,
                    onReorder: onReorder,
                    itemBuilder: (ctx, i) {
                      if (i < 0 || i >= chips.length) {
                        return SizedBox.shrink(
                          key: ValueKey('chip_tile_oob_$i'),
                        );
                      }
                      final c = chips[i];
                      return _buildChipTile(
                        context,
                        t,
                        c,
                        key: ValueKey('chip_tile_${c.id}'),
                        dragIndex: i,
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: chips.length,
                    itemBuilder: (ctx, i) {
                      if (i < 0 || i >= chips.length) {
                        return const SizedBox.shrink();
                      }
                      final c = chips[i];
                      return _buildChipTile(
                        context,
                        t,
                        c,
                        key: ValueKey('chip_tile_${c.id}'),
                        dragIndex: null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipTile(
    BuildContext context,
    AppLocalizations t,
    MutableEarbudsChip c, {
    required Key key,
    required int? dragIndex,
  }) {
    final isSel = c.id == selectedId;
    return Material(
      key: key,
      type: MaterialType.transparency,
      child: ListTile(
        dense: true,
        selected: isSel,
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
        title: Text(c.id),
        subtitle: Text(
          [
            if (c.process != null) c.process,
            if (c.massProduction) 'MP',
          ].whereType<String>().join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'duplicate') onDuplicate(c.id);
            if (v == 'delete') onDelete(c.id);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'duplicate',
              child: Text(t.adminDuplicate),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(t.adminDelete),
            ),
          ],
        ),
        onTap: () => onSelect(c.id),
      ),
    );
  }
}

class _ChipEditor extends StatefulWidget {
  final MutableEarbudsChip record;
  const _ChipEditor({super.key, required this.record});

  @override
  State<_ChipEditor> createState() => _ChipEditorState();
}

class _ChipEditorState extends State<_ChipEditor> {
  late MutableEarbudsChip _draft;
  String? _idError;

  @override
  void initState() {
    super.initState();
    _draft = MutableEarbudsChip.from(widget.record.toImmutable());
  }

  bool get _dirty {
    final orig = widget.record.toImmutable();
    final draft = _draft.toImmutable();
    return _chipSignature(orig) != _chipSignature(draft);
  }

  String _chipSignature(dynamic c) => c.toString();

  void _save() {
    final newId = _draft.id.trim();
    if (newId.isEmpty) {
      setState(() => _idError = AppLocalizations.of(context).adminInvalidId);
      return;
    }
    if (newId != widget.record.id &&
        EarbudsRepository.instance.recordById(newId) != null) {
      setState(() => _idError = AppLocalizations.of(context).adminInvalidId);
      return;
    }
    _idError = null;
    final r = widget.record;
    r.id = newId;
    r.process = _draft.process;
    r.core = _draft.core;
    r.fullRamKb = _draft.fullRamKb;
    r.massProduction = _draft.massProduction;
    r.sleep = _draft.sleep;
    r.mcuRun = _draft.mcuRun;
    r.scene = _draft.scene;
    r.bt = _draft.bt;
    r.txSweep = _draft.txSweep;
    r.rxVana = _draft.rxVana;
    r.rxVsys = _draft.rxVsys;
    r.pa = _draft.pa;
    EarbudsRepository.instance.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).adminSaved),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  void _revert() {
    setState(() {
      _draft = MutableEarbudsChip.from(widget.record.toImmutable());
      _idError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _draft.id,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_dirty)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.x2),
                  child: Text(
                    t.adminUnsavedChanges,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _dirty ? _revert : null,
                icon: const Icon(Icons.undo),
                label: Text(t.adminRevert),
              ),
              const SizedBox(width: AppSpacing.x2),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(t.adminSave),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(t.adminSectionBasic, [
                  _textField(
                    label: t.adminFieldId,
                    initial: _draft.id,
                    errorText: _idError,
                    onChanged: (v) => _draft.id = v,
                  ),
                  _textField(
                    label: t.adminFieldProcess,
                    initial: _draft.process ?? '',
                    onChanged: (v) =>
                        _draft.process = v.isEmpty ? null : v,
                  ),
                  _textField(
                    label: t.adminFieldCore,
                    initial: _draft.core ?? '',
                    onChanged: (v) => _draft.core = v.isEmpty ? null : v,
                  ),
                  _doubleField(
                    label: t.adminFieldFullRamKb,
                    initial: _draft.fullRamKb,
                    onChanged: (v) => _draft.fullRamKb = v,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.adminFieldMassProduction),
                    value: _draft.massProduction,
                    onChanged: (v) =>
                        setState(() => _draft.massProduction = v),
                  ),
                ]),
                _section(t.adminSectionScene, [
                  _doubleField(
                    label: 'hotelCal',
                    initial: _draft.scene.hotelCal,
                    onChanged: (v) => _draft.scene.hotelCal = v,
                  ),
                  _doubleField(
                    label: 'mute',
                    initial: _draft.scene.mute,
                    onChanged: (v) => _draft.scene.mute = v,
                  ),
                  _doubleField(
                    label: 'noisePink',
                    initial: _draft.scene.noisePink,
                    onChanged: (v) => _draft.scene.noisePink = v,
                  ),
                  _doubleField(
                    label: 'k1Hz',
                    initial: _draft.scene.k1Hz,
                    onChanged: (v) => _draft.scene.k1Hz = v,
                  ),
                  _doubleField(
                    label: 'call',
                    initial: _draft.scene.call,
                    onChanged: (v) => _draft.scene.call = v,
                  ),
                  _doubleField(
                    label: 'sniffPage',
                    initial: _draft.scene.sniffPage,
                    onChanged: (v) => _draft.scene.sniffPage = v,
                  ),
                  _doubleField(
                    label: 'powerOff',
                    initial: _draft.scene.powerOff,
                    onChanged: (v) => _draft.scene.powerOff = v,
                  ),
                ]),
                _section(t.adminSectionSceneAncOn, [
                  _doubleField(
                    label: 'hotelCalAncOn',
                    initial: _draft.scene.hotelCalAncOn,
                    onChanged: (v) => _draft.scene.hotelCalAncOn = v,
                  ),
                  _doubleField(
                    label: 'muteAncOn',
                    initial: _draft.scene.muteAncOn,
                    onChanged: (v) => _draft.scene.muteAncOn = v,
                  ),
                  _doubleField(
                    label: 'noisePinkAncOn',
                    initial: _draft.scene.noisePinkAncOn,
                    onChanged: (v) => _draft.scene.noisePinkAncOn = v,
                  ),
                  _doubleField(
                    label: 'k1HzAncOn',
                    initial: _draft.scene.k1HzAncOn,
                    onChanged: (v) => _draft.scene.k1HzAncOn = v,
                  ),
                  _doubleField(
                    label: 'callAncOn',
                    initial: _draft.scene.callAncOn,
                    onChanged: (v) => _draft.scene.callAncOn = v,
                  ),
                  _doubleField(
                    label: 'sniffPageAncOn',
                    initial: _draft.scene.sniffPageAncOn,
                    onChanged: (v) => _draft.scene.sniffPageAncOn = v,
                  ),
                  _doubleField(
                    label: 'powerOffAncOn',
                    initial: _draft.scene.powerOffAncOn,
                    onChanged: (v) => _draft.scene.powerOffAncOn = v,
                  ),
                ]),
                _section(t.adminSectionTestConfig, [
                  _textField(
                    label: 'testPhone',
                    initial: _draft.scene.testConfig.testPhone ?? '',
                    onChanged: (v) => _draft.scene.testConfig.testPhone =
                        v.isEmpty ? null : v,
                  ),
                  _textField(
                    label: 'testDate',
                    initial: _draft.scene.testConfig.testDate ?? '',
                    onChanged: (v) => _draft.scene.testConfig.testDate =
                        v.isEmpty ? null : v,
                  ),
                  _doubleField(
                    label: 'vbat',
                    initial: _draft.scene.testConfig.vbat,
                    onChanged: (v) => _draft.scene.testConfig.vbat = v,
                  ),
                  _textField(
                    label: 'audioEncoder',
                    initial: _draft.scene.testConfig.audioEncoder ?? '',
                    onChanged: (v) =>
                        _draft.scene.testConfig.audioEncoder =
                            v.isEmpty ? null : v,
                  ),
                  _textField(
                    label: 'outputLoad',
                    initial: _draft.scene.testConfig.outputLoad ?? '',
                    onChanged: (v) =>
                        _draft.scene.testConfig.outputLoad =
                            v.isEmpty ? null : v,
                  ),
                  _textField(
                    label: 'audioOutputPower',
                    initial:
                        _draft.scene.testConfig.audioOutputPower ?? '',
                    onChanged: (v) =>
                        _draft.scene.testConfig.audioOutputPower =
                            v.isEmpty ? null : v,
                  ),
                  _textField(
                    label: 'softwareVersion',
                    initial:
                        _draft.scene.testConfig.softwareVersion ?? '',
                    onChanged: (v) =>
                        _draft.scene.testConfig.softwareVersion =
                            v.isEmpty ? null : v,
                  ),
                  _textField(
                    label: 'moduleVoltageDetail',
                    initial:
                        _draft.scene.testConfig.moduleVoltageDetail ?? '',
                    onChanged: (v) =>
                        _draft.scene.testConfig.moduleVoltageDetail =
                            v.isEmpty ? null : v,
                  ),
                ]),
                _section(t.adminSectionBt, [
                  _doubleField(
                    label: 'btBase',
                    initial: _draft.bt.btBase,
                    onChanged: (v) => _draft.bt.btBase = v,
                  ),
                  _doubleField(
                    label: 'bleAdv500_9',
                    initial: _draft.bt.bleAdv500_9,
                    onChanged: (v) => _draft.bt.bleAdv500_9 = v,
                  ),
                  _doubleField(
                    label: 'bleConn200_0',
                    initial: _draft.bt.bleConn200_0,
                    onChanged: (v) => _draft.bt.bleConn200_0 = v,
                  ),
                  _doubleField(
                    label: 'bleConn500_0',
                    initial: _draft.bt.bleConn500_0,
                    onChanged: (v) => _draft.bt.bleConn500_0 = v,
                  ),
                  _doubleField(
                    label: 'btPagescan9',
                    initial: _draft.bt.btPagescan9,
                    onChanged: (v) => _draft.bt.btPagescan9 = v,
                  ),
                  _doubleField(
                    label: 'btSniff200_0',
                    initial: _draft.bt.btSniff200_0,
                    onChanged: (v) => _draft.bt.btSniff200_0 = v,
                  ),
                  _doubleField(
                    label: 'btSniff500_0',
                    initial: _draft.bt.btSniff500_0,
                    onChanged: (v) => _draft.bt.btSniff500_0 = v,
                  ),
                ]),
                _section(t.adminSectionSleep, [
                  _doubleField(
                    label: 'vcoreM (V)',
                    initial: _draft.sleep.vcoreM,
                    onChanged: (v) => _draft.sleep.vcoreM = v,
                  ),
                  _doubleField(
                    label: 'vcoreL (V)',
                    initial: _draft.sleep.vcoreL,
                    onChanged: (v) => _draft.sleep.vcoreL = v,
                  ),
                  _doubleField(
                    label: 'vana (V)',
                    initial: _draft.sleep.vana,
                    onChanged: (v) => _draft.sleep.vana = v,
                  ),
                  _doubleField(
                    label: 'vhppa (V)',
                    initial: _draft.sleep.vhppa,
                    onChanged: (v) => _draft.sleep.vhppa = v,
                  ),
                  _doubleField(
                    label: 'pdSleep256 (µA)',
                    initial: _draft.sleep.pdSleep256,
                    onChanged: (v) => _draft.sleep.pdSleep256 = v,
                  ),
                  _doubleField(
                    label: 'pdSleepFull (µA)',
                    initial: _draft.sleep.pdSleepFull,
                    onChanged: (v) => _draft.sleep.pdSleepFull = v,
                  ),
                  _doubleField(
                    label: 'deepSleep (µA)',
                    initial: _draft.sleep.deepSleep,
                    onChanged: (v) => _draft.sleep.deepSleep = v,
                  ),
                ]),
                _mcuRunSection(t),
                _section(t.adminSectionPa, [
                  _doubleField(
                    label: 'db0',
                    initial: _draft.pa.db0,
                    onChanged: (v) => _draft.pa.db0 = v,
                  ),
                  _doubleField(
                    label: 'dbNeg20',
                    initial: _draft.pa.dbNeg20,
                    onChanged: (v) => _draft.pa.dbNeg20 = v,
                  ),
                  _doubleField(
                    label: 'dbNegInf',
                    initial: _draft.pa.dbNegInf,
                    onChanged: (v) => _draft.pa.dbNegInf = v,
                  ),
                ]),
                _txSweepSection(t),
                _rxSweepSection(
                  title: t.adminSectionRxVana,
                  rx: _draft.rxVana,
                  showVana: true,
                ),
                _rxSweepSection(
                  title: t.adminSectionRxVsys,
                  rx: _draft.rxVsys,
                  showVana: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.x2),
            Wrap(
              spacing: AppSpacing.x3,
              runSpacing: AppSpacing.x2,
              children: children
                  .map((w) => SizedBox(width: 240, child: w))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        errorText: errorText,
      ),
      onChanged: onChanged,
    );
  }

  Widget _doubleField({
    required String label,
    required double? initial,
    required ValueChanged<double?> onChanged,
  }) {
    return TextFormField(
      initialValue: initial == null ? '' : initial.toString(),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) {
        final s = v.trim();
        if (s.isEmpty) {
          onChanged(null);
          return;
        }
        final d = double.tryParse(s);
        if (d != null) onChanged(d);
      },
    );
  }

  Widget _mcuRunSection(AppLocalizations t) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.adminSectionMcuRun,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _draft.mcuRun.add(MutableRunCurrent(label: 'new'));
                  }),
                  icon: const Icon(Icons.add),
                  label: Text(t.adminAddRow),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            for (int i = 0; i < _draft.mcuRun.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.x2,
                        runSpacing: AppSpacing.x2,
                        children: [
                          SizedBox(
                            width: 160,
                            child: _textField(
                              label: 'label',
                              initial: _draft.mcuRun[i].label,
                              onChanged: (v) => _draft.mcuRun[i].label = v,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: _doubleField(
                              label: 'wfi24M',
                              initial: _draft.mcuRun[i].wfi24M,
                              onChanged: (v) =>
                                  _draft.mcuRun[i].wfi24M = v,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: _doubleField(
                              label: 'cm24M',
                              initial: _draft.mcuRun[i].cm24M,
                              onChanged: (v) =>
                                  _draft.mcuRun[i].cm24M = v,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: _doubleField(
                              label: 'cm48M',
                              initial: _draft.mcuRun[i].cm48M,
                              onChanged: (v) =>
                                  _draft.mcuRun[i].cm48M = v,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: _doubleField(
                              label: 'cm96M',
                              initial: _draft.mcuRun[i].cm96M,
                              onChanged: (v) =>
                                  _draft.mcuRun[i].cm96M = v,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: _doubleField(
                              label: 'cm192M',
                              initial: _draft.mcuRun[i].cm192M,
                              onChanged: (v) =>
                                  _draft.mcuRun[i].cm192M = v,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: t.adminRemoveRow,
                      onPressed: () => setState(() {
                        _draft.mcuRun.removeAt(i);
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _txSweepSection(AppLocalizations t) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.adminSectionTxSweep,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _draft.txSweep.add(MutableTxSweepVariant(
                        label: 'new', values: <int, double>{}));
                  }),
                  icon: const Icon(Icons.add),
                  label: Text(t.adminAddRow),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            for (int i = 0; i < _draft.txSweep.length; i++)
              _txVariantBlock(t, i),
          ],
        ),
      ),
    );
  }

  Widget _txVariantBlock(AppLocalizations t, int idx) {
    final v = _draft.txSweep[idx];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x2),
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _textField(
                  label: 'label',
                  initial: v.label,
                  onChanged: (s) => v.label = s,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              IconButton(
                tooltip: t.adminRemoveRow,
                onPressed: () => setState(() {
                  _draft.txSweep.removeAt(idx);
                }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          _intDoubleMapEditor(
            t: t,
            keyLabel: 'dBm',
            valueLabel: 'mA',
            map: v.values,
          ),
        ],
      ),
    );
  }

  Widget _rxSweepSection({
    required String title,
    required MutableRxSweep rx,
    required bool showVana,
  }) {
    final t = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.x2),
            if (showVana)
              SizedBox(
                width: 240,
                child: _doubleField(
                  label: 'vana (V)',
                  initial: rx.vana,
                  onChanged: (v) => rx.vana = v,
                ),
              ),
            if (showVana) const SizedBox(height: AppSpacing.x2),
            _intDoubleMapEditor(
              t: t,
              keyLabel: 'gain',
              valueLabel: 'mA',
              map: rx.values,
            ),
          ],
        ),
      ),
    );
  }

  Widget _intDoubleMapEditor({
    required AppLocalizations t,
    required String keyLabel,
    required String valueLabel,
    required Map<int, double> map,
  }) {
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x1),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text('$keyLabel = ${e.key}'),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: e.value.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: valueLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (s) {
                      final d = double.tryParse(s.trim());
                      if (d != null) map[e.key] = d;
                    },
                  ),
                ),
                IconButton(
                  tooltip: t.adminRemoveRow,
                  onPressed: () => setState(() {
                    map.remove(e.key);
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showAddMapEntryDialog(map, keyLabel, valueLabel),
            icon: const Icon(Icons.add),
            label: Text(t.adminAddRow),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddMapEntryDialog(
      Map<int, double> map, String keyLabel, String valueLabel) async {
    final t = AppLocalizations.of(context);
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminAddRow),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(labelText: keyLabel),
            ),
            TextField(
              controller: valCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(labelText: valueLabel),
            ),
          ],
        ),
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
      final k = int.tryParse(keyCtrl.text.trim());
      final v = double.tryParse(valCtrl.text.trim());
      if (k != null && v != null) {
        setState(() => map[k] = v);
      }
    }
  }
}
