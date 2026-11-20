// 安全级别对比：同一份 Lua 公式按 O1/O2/O3 绑定后，调用结果和性能有何不同
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'formula_lab.dart';
import 'formulas.dart';
import 'game_scripts.dart';

class SafetyLevelsPage extends StatefulWidget {
  const SafetyLevelsPage({super.key});

  @override
  State<SafetyLevelsPage> createState() => _SafetyLevelsPageState();
}

class _SafetyLevelsPageState extends State<SafetyLevelsPage> {
  static const _iterationChoices = [1000, 5000, 20000];

  bool _faulty = false;
  Map<FormulaBackend, List<CallOutcome>>? _outcomes;
  String? _error;

  int _iterations = 5000;
  bool _benchmarking = false;
  List<BenchmarkRow>? _rows;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<GameSources> _sources({required bool faulty}) => GameSources.load(
    rootBundle,
    formulas: faulty ? 'formulas_faulty.lua' : 'formulas.lua',
  );

  /// 用所选脚本新建一个运行时，每档每个方法调用一次
  Future<void> _probe() async {
    final faulty = _faulty;
    try {
      final scripts = GameScripts.create(await _sources(faulty: faulty));
      try {
        final outcomes = probeLevels(scripts);
        if (!mounted || faulty != _faulty) return;
        setState(() {
          _outcomes = outcomes;
          _error = null;
        });
      } finally {
        scripts.close();
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _benchmark() async {
    setState(() => _benchmarking = true);
    try {
      final rows = await benchmarkInBackground(
        await _sources(faulty: false),
        iterations: _iterations,
      );
      if (mounted) setState(() => _rows = rows);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _benchmarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyLevels)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildScriptCard(l10n),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          for (final backend in [
            FormulaBackend.o1,
            FormulaBackend.o2,
            FormulaBackend.o3,
          ])
            _buildLevelCard(backend),
          const SizedBox(height: 16),
          _buildBenchmarkCard(l10n),
        ],
      ),
    );
  }

  Widget _buildScriptCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.scriptLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.correctScript)),
                ButtonSegment(value: true, label: Text(l10n.faultyScript)),
              ],
              selected: {_faulty},
              onSelectionChanged: (selection) {
                setState(() {
                  _faulty = selection.single;
                  _outcomes = null;
                });
                _probe();
              },
            ),
            if (_faulty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.faultyScriptHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(l10n.callResults),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(FormulaBackend backend) {
    final outcomes = _outcomes?[backend];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(backend.label)),
                const SizedBox(width: 8),
                Expanded(child: Text(backend.description)),
              ],
            ),
            if (outcomes == null)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              )
            else
              for (final call in outcomes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    call.ok ? Icons.check_circle : Icons.error,
                    color: call.ok ? Colors.green : Colors.red,
                  ),
                  title: Text(call.method),
                  subtitle: SelectableText(
                    call.text,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkCard(AppLocalizations l10n) {
    final rows = _rows;
    String us(double value) => value.toStringAsFixed(2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.benchmark, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.benchmarkHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<int>(
                  segments: [
                    for (final n in _iterationChoices)
                      ButtonSegment(value: n, label: Text('×$n')),
                  ],
                  selected: {_iterations},
                  onSelectionChanged: _benchmarking
                      ? null
                      : (selection) =>
                            setState(() => _iterations = selection.single),
                ),
                FilledButton.icon(
                  onPressed: _benchmarking ? null : _benchmark,
                  icon: _benchmarking
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _benchmarking ? l10n.benchmarkRunning : l10n.runBenchmark,
                  ),
                ),
              ],
            ),
            if (rows != null) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('')),
                    const DataColumn(
                      label: Text('physicalDamage'),
                      numeric: true,
                    ),
                    const DataColumn(label: Text('actionOrder'), numeric: true),
                    const DataColumn(label: Text('heal'), numeric: true),
                    DataColumn(label: Text(l10n.perBattle), numeric: true),
                  ],
                  rows: [
                    for (final row in rows)
                      DataRow(
                        cells: [
                          DataCell(Text(row.backend.label)),
                          DataCell(Text(us(row.physicalDamage))),
                          DataCell(Text(us(row.actionOrder))),
                          DataCell(Text(us(row.heal))),
                          DataCell(
                            Text((row.battle / 1000).toStringAsFixed(2)),
                          ),
                        ],
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
}
