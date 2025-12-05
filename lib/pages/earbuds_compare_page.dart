import 'package:flutter/material.dart';
import '../models/earbuds.dart';
import '../l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';

/// 耳机场景功耗对比页
class EarbudsComparePage extends StatefulWidget {
  const EarbudsComparePage({super.key});

  @override
  State<EarbudsComparePage> createState() => _EarbudsComparePageState();
}

class _EarbudsComparePageState extends State<EarbudsComparePage> {
  final List<Earbuds> allChips = demoEarbudsList;
  final List<Earbuds> selectedChips = [];

  void _toggleChip(Earbuds e) {
    setState(() {
      if (selectedChips.contains(e)) {
        selectedChips.remove(e);
      } else if (selectedChips.length < 3) {
        selectedChips.add(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).navEarbuds),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTableView(),
            const SizedBox(height: 20),
            _buildChipSelector(),
            const SizedBox(height: 20),
            Expanded(child: _buildCompareChart()),
          ],
        ),
      ),
    );
  }

  /// 顶部：所有芯片的功耗表格
  Widget _buildTableView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: Colors.grey.shade300),
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
        columns: [
          DataColumn(label: Text(AppLocalizations.of(context).chipId)),
          DataColumn(label: Text(AppLocalizations.of(context).massProdConfig)),
          DataColumn(label: Text('${AppLocalizations.of(context).mute} (mA)')),
          DataColumn(label: Text('${AppLocalizations.of(context).noisePink} AAC \n 8/15 (mA)')),
          DataColumn(label: Text('${AppLocalizations.of(context).oneKhz} -6dB \n 15/15 (mA)')),
          DataColumn(label: Text('${AppLocalizations.of(context).call} (mA)')),
          DataColumn(label: Text('${AppLocalizations.of(context).idle} (mA)')),
          DataColumn(label: Text('${AppLocalizations.of(context).powerOff} (mA)')),
        ],
        rows: allChips.map((e) {
          return DataRow(
            selected: selectedChips.contains(e),
            onSelectChanged: (_) => _toggleChip(e),
            cells: [
              DataCell(Text(e.chipId)),
              DataCell(Text(e.isMassProduction ? 'Y' : 'N')),
              DataCell(Text(e.currentMute.toStringAsFixed(2))),
              DataCell(Text(e.currentNoisePink.toStringAsFixed(2))),
              DataCell(Text(e.current1kHz.toStringAsFixed(2))),
              DataCell(Text(e.currentCall.toStringAsFixed(2))),
              DataCell(Text(e.currentIdle.toStringAsFixed(3))),
              DataCell(Text(e.currentPowerOff.toStringAsFixed(3))),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 对比芯片选择器
  Widget _buildChipSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: allChips.map((e) {
        final selected = selectedChips.contains(e);
        return FilterChip(
          selected: selected,
          label: Text(e.chipId),
          onSelected: (_) => _toggleChip(e),
          selectedColor: Colors.blue.shade100,
        );
      }).toList(),
    );
  }

  /// 底部：功耗对比图（柱状）
  Widget _buildCompareChart() {
    if (selectedChips.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).select2to3Chips),
      );
    }

    final categories = [
      'Mute',
      'NoisePink',
      '1kHz',
      'Call',
      'Idle',
      'PowerOff'
    ];

    final double groupSpace = 25;
    final double barWidth = 10;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calcMaxY(selectedChips) * 1.2,
          gridData: FlGridData(show: true, horizontalInterval: 5),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 5),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  int i = val.toInt();
                  if (i >= 0 && i < categories.length) {
                    return Text(categories[i],
                        style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: List.generate(categories.length, (i) {
            return BarChartGroupData(
              x: i,
              barsSpace: groupSpace,
              barRods: List.generate(selectedChips.length, (j) {
                final e = selectedChips[j];
                final color = Colors.primaries[j % Colors.primaries.length];
                final value = _getValue(e, i);
                return BarChartRodData(
                  toY: value,
                  color: color,
                  width: barWidth,
                  borderRadius: BorderRadius.circular(2),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  double _getValue(Earbuds e, int i) {
    switch (i) {
      case 0:
        return e.currentMute;
      case 1:
        return e.currentNoisePink;
      case 2:
        return e.current1kHz;
      case 3:
        return e.currentCall;
      case 4:
        return e.currentIdle;
      case 5:
        return e.currentPowerOff * 1000; // 放大可视
      default:
        return 0;
    }
  }

  double _calcMaxY(List<Earbuds> chips) {
    return chips
        .map((e) => [
              e.currentMute,
              e.currentNoisePink,
              e.current1kHz,
              e.currentCall,
              e.currentIdle
            ].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
  }
}
