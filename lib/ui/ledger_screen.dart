import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../logic/dates.dart';
import '../logic/ledger.dart';
import '../logic/money.dart';
import '../providers.dart';
import 'format.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  /// Null means all time.
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(ledgerProvider).value ?? const <LedgerEntry>[];
    final entries = filterByMonth(all, _month);
    final totals = ledgerTotals(entries);

    // Months that have entries, newest first, plus the current month.
    final now = DateTime.now();
    final months = <DateTime>{DateTime(now.year, now.month)};
    for (final e in all) {
      months.add(DateTime(e.date.year, e.date.month));
    }
    final monthList = months.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          DropdownButton<DateTime?>(
            value: _month,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All time')),
              for (final m in monthList)
                DropdownMenuItem(value: m, child: Text(monthFormat.format(m))),
            ],
            onChanged: (v) => setState(() => _month = v),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => openLedgerEditor(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _TotalCard('Personal', totals.personal),
                _TotalCard('Business', totals.business),
                _TotalCard('All', totals.all),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No entries'))
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _EntryTile(entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard(this.label, this.pence);
  final String label;
  final int pence;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(label, style: t.labelMedium),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  formatPence(pence),
                  style: t.titleMedium?.copyWith(
                    color: pence < 0
                        ? Colors.red
                        : (pence > 0 ? Colors.green : null),
                    fontWeight: FontWeight.bold,
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

class _EntryTile extends StatelessWidget {
  const _EntryTile(this.e);
  final LedgerEntry e;

  @override
  Widget build(BuildContext context) {
    final isIn = e.direction == Direction.moneyIn;
    return ListTile(
      onTap: () => openLedgerEditor(context, existing: e),
      title: Text(e.note.isEmpty ? (isIn ? 'In' : 'Out') : e.note),
      subtitle: Row(
        children: [
          Text(dayFormat.format(e.date)),
          const SizedBox(width: 8),
          _CategoryTag(e.category),
        ],
      ),
      trailing: Text(
        '${isIn ? '+' : '−'}${formatPence(e.amountPence)}',
        style: TextStyle(
          color: isIn ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag(this.c);
  final LedgerCategory c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final personal = c == LedgerCategory.personal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: personal ? scheme.secondaryContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        personal ? 'Personal' : 'Business',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

Future<void> openLedgerEditor(BuildContext context, {LedgerEntry? existing}) =>
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LedgerEditor(existing: existing)));

class LedgerEditor extends ConsumerStatefulWidget {
  const LedgerEditor({super.key, this.existing});
  final LedgerEntry? existing;

  @override
  ConsumerState<LedgerEditor> createState() => _LedgerEditorState();
}

class _LedgerEditorState extends ConsumerState<LedgerEditor> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  late Direction _direction;
  late LedgerCategory _category;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = TextEditingController(
      text: e == null ? '' : penceToInput(e.amountPence),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? dateOnly(DateTime.now());
    _direction = e?.direction ?? Direction.moneyOut;
    _category = e?.category ?? LedgerCategory.personal;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pence = parsePence(_amount.text);
    if (pence == null || pence == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount, e.g. 12.50')),
      );
      return;
    }
    final db = ref.read(dbProvider);
    final e = widget.existing;
    if (e == null) {
      await db.insertLedgerEntry(
        LedgerEntriesCompanion.insert(
          date: _date,
          amountPence: pence,
          direction: _direction,
          category: _category,
          note: Value(_note.text.trim()),
        ),
      );
    } else {
      await db.updateLedgerEntry(
        e.copyWith(
          date: _date,
          amountPence: pence,
          direction: _direction,
          category: _category,
          note: _note.text.trim(),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(dbProvider).deleteLedgerEntry(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New entry' : 'Edit entry'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<Direction>(
            segments: const [
              ButtonSegment(value: Direction.moneyIn, label: Text('In')),
              ButtonSegment(value: Direction.moneyOut, label: Text('Out')),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() => _direction = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: widget.existing == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '£',
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<LedgerCategory>(
            segments: const [
              ButtonSegment(
                value: LedgerCategory.personal,
                label: Text('Personal'),
              ),
              ButtonSegment(
                value: LedgerCategory.business,
                label: Text('Business'),
              ),
            ],
            selected: {_category},
            onSelectionChanged: (s) => setState(() => _category = s.first),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(dayFormat.format(_date)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _date = dateOnly(d));
            },
          ),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
        ],
      ),
    );
  }
}
