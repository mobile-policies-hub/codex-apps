import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/domain/tracker_format.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_calc_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_report.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_clips.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_deck.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/brand_card.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/premium_surface.dart';

class _GrowthBars extends StatelessWidget {
  const _GrowthBars({required this.slices, required this.color});

  final List<YearSlice> slices;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const SizedBox.shrink();
    final peak = slices
        .map((slice) => slice.interest)
        .reduce((best, value) => value > best ? value : best);
    final scale = peak <= 0 ? 1 : peak;
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final slice in slices)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: 16 + 56 * (slice.interest / scale),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        color.withValues(alpha: 0.35),
                        color,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ApexCalcScreen extends StatelessWidget {
  const ApexCalcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<ApexCalcController>();
    final scheme = Theme.of(context).colorScheme;
    return BrandFeed(
      children: [
        Text(
          context.tr('Interest and inflation'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${context.tr('Ledger currency')}: ${calc.preferredCurrency}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(context.tr('Mortgage')),
              selected: calc.activePreset == 'mortgage',
              onSelected: (_) {
                HapticFeedback.selectionClick();
                calc.applyPreset('mortgage');
              },
            ),
            ChoiceChip(
              label: Text(context.tr('Deposit 12%')),
              selected: calc.activePreset == 'deposit',
              onSelected: (_) => calc.applyPreset('deposit'),
            ),
            ChoiceChip(
              label: Text(context.tr('Savings plan')),
              selected: calc.activePreset == 'stake',
              onSelected: (_) => calc.applyPreset('stake'),
            ),
            ChoiceChip(
              label: Text(context.tr('Car savings')),
              selected: calc.activePreset == 'car',
              onSelected: (_) => calc.applyPreset('car'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BrandCard(
          child: Column(
            children: [
              _SliderRow(
                label: context.tr('Amount'),
                value: formatCount(calc.amount.round()),
                child: Slider(
                  key: const Key('apex-amount-slider'),
                  min: 1000,
                  max: 100000,
                  divisions: 99,
                  value: calc.amount,
                  onChanged: calc.setAmount,
                ),
              ),
              _SliderRow(
                label: context.tr('Rate'),
                value: '${calc.rate.round()}%',
                child: Slider(
                  key: const Key('apex-rate-slider'),
                  min: 0,
                  max: 30,
                  divisions: 30,
                  value: calc.rate,
                  onChanged: calc.setRate,
                ),
              ),
              _SliderRow(
                label: context.tr('Term'),
                value: '${calc.years.round()} ${context.tr('yr')}',
                child: Slider(
                  key: const Key('apex-years-slider'),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  value: calc.years,
                  onChanged: calc.setYears,
                ),
              ),
              _SliderRow(
                label: context.tr('Inflation'),
                value: '${calc.inflation.round()}%',
                child: Slider(
                  key: const Key('apex-inflation-slider'),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  value: calc.inflation,
                  onChanged: calc.setInflation,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('Balance'), style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    formatCount(calc.compounded.round()),
                    key: const Key('apex-result'),
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('After inflation'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                formatCount(calc.afterInflation.round()),
                key: const Key('apex-real'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr('Interest earned')}  ${formatCount(calc.interestEarned)}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('Set aside each month')}  ${formatCount(calc.monthlySetAside)}',
                key: const Key('apex-monthly'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'One extra point of interest pulls the balance away from the base case.',
                ),
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<SoundDeck>().playOnce(
                    'apex-result',
                    SoundClips.chime(),
                  );
                },
                icon: const Icon(Icons.volume_up),
                label: Text(context.tr('Play the result')),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('Each year'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final slice in calc.slices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${context.tr('Year')} ${slice.year}  +${formatCount(slice.interest)}',
                    key: Key('apex-year-${slice.year}'),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 12),
              _GrowthBars(slices: calc.slices, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                context.tr('If this were a loan'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('Monthly payment')}  ${formatCount(calc.monthlyPayment.round())}',
                key: const Key('apex-payment'),
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('Interest over the term')}  ${formatCount(calc.loanInterest)}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Yearly breakdown'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final slice in calc.slices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${context.tr('Year')} ${slice.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        '${context.tr('interest')} ${formatCount(slice.interest)}',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: calc.saveSnapshot,
          child: Text(context.tr('Save calculation to history')),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('apex-export'),
          onPressed: () => unawaited(_exportApexReport(context, calc)),
          child: Text(context.tr('Export PDF')),
        ),
      ],
    );
  }
}

Future<void> _exportApexReport(
  BuildContext context,
  ApexCalcController calc,
) async {
  final bytes = await buildApexReportPdf(calc);
  if (!context.mounted) return;
  try {
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'apex-calc-report.pdf',
      subject: 'Apex Calc report',
    );
  } catch (_) {
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.tr('Export PDF')),
        content: Text(
          'Balance ${calc.compounded.round()} after ${calc.years.round()} years at ${calc.rate.round()}%. Rates are for reference only.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('Done')),
          ),
        ],
      ),
    );
  }
}

class ApexConvertScreen extends StatelessWidget {
  const ApexConvertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<ApexCalcController>();
    final scheme = Theme.of(context).colorScheme;
    return BrandFeed(
      children: [
        Text(
          context.tr(_measureTitle(calc.measure)),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(_measureHint(calc.measure)),
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in MeasureKind.values)
              ChoiceChip(
                label: Text(context.tr(_measureLabel(kind))),
                selected: calc.measure == kind,
                onSelected: (_) => calc.setMeasure(kind),
              ),
          ],
        ),
        const SizedBox(height: 16),
        BrandCard(
          child: Column(
            children: [
              if (calc.measure == MeasureKind.money)
                Row(
                  children: [
                    Expanded(
                      child: _UnitMenu(
                        menuKey: const Key('apex-from'),
                        value: calc.fromCurrency,
                        items: ApexCalcController.currencies,
                        onChanged: calc.setFromCurrency,
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('Swap'),
                      onPressed: calc.swapCurrencies,
                      icon: Icon(Icons.swap_horiz, color: scheme.primary),
                    ),
                    Expanded(
                      child: _UnitMenu(
                        menuKey: const Key('apex-to'),
                        value: calc.toCurrency,
                        items: ApexCalcController.currencies,
                        onChanged: calc.setToCurrency,
                      ),
                    ),
                  ],
                )
              else if (calc.measure == MeasureKind.length)
                _PairMenus(
                  from: calc.fromLength,
                  to: calc.toLength,
                  items: ApexCalcController.lengthUnits,
                  onFrom: calc.setFromLength,
                  onTo: calc.setToLength,
                  onSwap: calc.swapCurrencies,
                  accent: scheme.primary,
                )
              else if (calc.measure == MeasureKind.mass)
                _PairMenus(
                  from: calc.fromMass,
                  to: calc.toMass,
                  items: ApexCalcController.massUnits,
                  onFrom: calc.setFromMass,
                  onTo: calc.setToMass,
                  onSwap: calc.swapCurrencies,
                  accent: scheme.primary,
                )
              else
                _SliderRow(
                  label: context.tr('Percent'),
                  value: '${calc.sharePercent.round()}%',
                  child: Slider(
                    min: 1,
                    max: 100,
                    divisions: 99,
                    value: calc.sharePercent,
                    onChanged: calc.setSharePercent,
                  ),
                ),
              _SliderRow(
                label: calc.measure == MeasureKind.share
                    ? context.tr('Of the number')
                    : '${context.tr('Amount')}, ${context.tr(calc.sourceUnit)}',
                value: formatCount(calc.convertAmount.round()),
                child: Slider(
                  key: const Key('apex-convert-slider'),
                  min: 1,
                  max: 1000,
                  divisions: 999,
                  value: calc.convertAmount,
                  onChanged: calc.setConvertAmount,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      calc.readout,
                      key: const Key('apex-converted'),
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${context.tr(calc.resultUnit)} · ${_conversionCaption(context, calc)}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
              if (calc.measure == MeasureKind.money) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('Rates are for reference only'),
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ApexHistoryScreen extends StatefulWidget {
  const ApexHistoryScreen({super.key});

  @override
  State<ApexHistoryScreen> createState() => _ApexHistoryScreenState();
}

class _ApexHistoryScreenState extends State<ApexHistoryScreen> {
  final TextEditingController _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<ApexCalcController>();
    final scheme = Theme.of(context).colorScheme;
    return BrandFeed(
      children: [
        Text(
          context.tr('Notes on calculations'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('apex-note'),
                controller: _draft,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: context.tr('Note'),
                  labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('apex-save'),
                onPressed: () {
                  calc.saveNote(_draft.text);
                  _draft.clear();
                },
                child: Text(context.tr('Save')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (calc.history.isEmpty)
          Text(
            context.tr('Nothing here yet'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        for (final note in calc.history) ...[
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _NoteEditor(
                  key: ValueKey(note.id),
                  fieldKey: Key('apex-note-${note.id}'),
                  initial: note.note,
                  onChanged: (value) =>
                      calc.updateNote(calc.history.indexOf(note), value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    super.key,
    required this.fieldKey,
    required this.initial,
    required this.onChanged,
  });

  final Key fieldKey;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      style: TextStyle(color: scheme.onSurface),
      decoration: const InputDecoration(isDense: true),
      onChanged: widget.onChanged,
    );
  }
}

String _conversionCaption(BuildContext context, ApexCalcController calc) {
  if (calc.measure == MeasureKind.share) {
    return context
        .tr('{percent}% of {amount}')
        .replaceAll('{percent}', '${calc.sharePercent.round()}')
        .replaceAll('{amount}', '${calc.convertAmount.round()}');
  }
  return calc.conversionCaption;
}

String _measureLabel(MeasureKind kind) {
  return switch (kind) {
    MeasureKind.money => 'Currencies',
    MeasureKind.length => 'Length',
    MeasureKind.mass => 'Weight',
    MeasureKind.share => 'Percent',
  };
}

String _measureTitle(MeasureKind kind) {
  return switch (kind) {
    MeasureKind.money => 'Currency exchange',
    MeasureKind.length => 'Length conversion',
    MeasureKind.mass => 'Weight conversion',
    MeasureKind.share => 'Share of a number',
  };
}

String _measureHint(MeasureKind kind) {
  return switch (kind) {
    MeasureKind.money => 'USD, EUR, GBP, JPY, and RUB',
    MeasureKind.length => 'Meters, kilometers, feet, and inches',
    MeasureKind.mass => 'Kilograms, grams, pounds, and ounces',
    MeasureKind.share => 'What share a percent is of a number',
  };
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}

class _PairMenus extends StatelessWidget {
  const _PairMenus({
    required this.from,
    required this.to,
    required this.items,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
    required this.accent,
  });

  final String from;
  final String to;
  final List<String> items;
  final ValueChanged<String> onFrom;
  final ValueChanged<String> onTo;
  final VoidCallback onSwap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _UnitMenu(value: from, items: items, onChanged: onFrom),
        ),
        IconButton(
          tooltip: context.tr('Swap'),
          onPressed: onSwap,
          icon: Icon(Icons.swap_horiz, color: accent),
        ),
        Expanded(
          child: _UnitMenu(value: to, items: items, onChanged: onTo),
        ),
      ],
    );
  }
}

class _UnitMenu extends StatelessWidget {
  const _UnitMenu({
    required this.value,
    required this.items,
    required this.onChanged,
    this.menuKey,
  });

  final Key? menuKey;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButton<String>(
      key: menuKey,
      isExpanded: true,
      value: value,
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: TextStyle(color: scheme.onSurface, fontSize: 16),
      items: [
        for (final code in items)
          DropdownMenuItem(value: code, child: Text(code)),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
