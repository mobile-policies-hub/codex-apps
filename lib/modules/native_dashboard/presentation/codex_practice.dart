import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/ancient_codex_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/brand_card.dart';

const kingdomPeriods = <(String, String, String)>[
  (
    'c. 3100 BCE',
    'Unification',
    'Upper and Lower Egypt become one court. The palette and the crown are the story of that join.',
  ),
  (
    'c. 2686 BCE',
    'Old Kingdom',
    'Pyramid age. School lists put the house sign near the front because the outline is simple.',
  ),
  (
    'c. 2055 BCE',
    'Middle Kingdom',
    'Literature takes the stage. Tales and loyalist teachings are copied as practice, not only as prayer.',
  ),
  (
    'c. 1550 BCE',
    'New Kingdom',
    'Temple walls carry the night boat, hour by hour. Heart scarabs sit on the chest.',
  ),
  (
    'c. 664 BCE',
    'Late Period',
    'Scribes look back on purpose. Older signs are copied carefully, as a craft worth keeping.',
  ),
];

class KingdomStrip extends StatelessWidget {
  const KingdomStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('The long arc'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kingdomPeriods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final period = kingdomPeriods[index];
              return SizedBox(
                width: 220,
                child: BrandCard(
                  gold: index == 3,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(period.$1),
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr(period.$2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          context.tr(period.$3),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.3,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScribeDrill extends StatefulWidget {
  const ScribeDrill({super.key});

  @override
  State<ScribeDrill> createState() => _ScribeDrillState();
}

class _Round {
  _Round({required this.glyph, required this.options});

  final GlyphEntry glyph;
  final List<String> options;
}

class _ScribeDrillState extends State<ScribeDrill> {
  late List<_Round> _rounds;
  int _step = 0;
  int _score = 0;
  int? _picked;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _rounds = _buildRounds();
  }

  List<_Round> _buildRounds() {
    final glyphs = context.read<AncientCodexController>().glyphs;
    final random = math.Random(glyphs.length * 17);
    final order = List<GlyphEntry>.of(glyphs)..shuffle(random);
    return [
      for (final glyph in order.take(6))
        _Round(
          glyph: glyph,
          options: _options(glyph, glyphs, random),
        ),
    ];
  }

  List<String> _options(
    GlyphEntry glyph,
    List<GlyphEntry> glyphs,
    math.Random random,
  ) {
    final wrong = glyphs
        .where((item) => item.reading != glyph.reading)
        .map((item) => item.reading)
        .toSet()
        .toList()
      ..shuffle(random);
    final options = [glyph.reading, ...wrong.take(3)]..shuffle(random);
    return options;
  }

  void _pick(String reading) {
    if (_picked != null || _done) return;
    final round = _rounds[_step];
    final index = round.options.indexOf(reading);
    final correct = reading == round.glyph.reading;
    HapticFeedback.selectionClick();
    setState(() {
      _picked = index;
      if (correct) _score += 1;
    });
  }

  void _next() {
    if (_step + 1 >= _rounds.length) {
      context.read<AncientCodexController>().recordDrill(_score);
      setState(() => _done = true);
      return;
    }
    setState(() {
      _step += 1;
      _picked = null;
    });
  }

  void _again() {
    setState(() {
      _rounds = _buildRounds();
      _step = 0;
      _score = 0;
      _picked = null;
      _done = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final best = context.watch<AncientCodexController>().drillBest;
    if (_rounds.isEmpty) return const SizedBox.shrink();
    final round = _rounds[_step];
    return BrandCard(
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Scribe drill'),
            style: TextStyle(
              color: scheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.tr('Best drill')} $best',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          if (_done)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_score / ${_rounds.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('A short recall. The signs you miss come back next round.'),
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('drill-again'),
                  onPressed: _again,
                  child: Text(context.tr('Again')),
                ),
              ],
            )
          else ...[
            Text(
              '${_step + 1} / ${_rounds.length}',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 8),
            Text(
              round.glyph.symbol,
              style: const TextStyle(fontSize: 48, color: Colors.white),
            ),
            Text(
              context.tr(round.glyph.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < round.options.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Option(
                  label: round.options[index],
                  picked: _picked == index,
                  reveal: _picked != null,
                  correct: round.options[index] == round.glyph.reading,
                  onTap: () => _pick(round.options[index]),
                ),
              ),
            if (_picked != null) ...[
              Text(
                context.tr(round.glyph.lore),
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 10),
              FilledButton(
                key: const Key('drill-next'),
                onPressed: _next,
                child: Text(
                  _step + 1 >= _rounds.length
                      ? context.tr('Finish')
                      : context.tr('Next'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.picked,
    required this.reveal,
    required this.correct,
    required this.onTap,
  });

  final String label;
  final bool picked;
  final bool reveal;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !reveal
        ? scheme.onSurface
        : correct
        ? const Color(0xFF8FE3B0)
        : picked
        ? const Color(0xFFFFB4A8)
        : scheme.onSurfaceVariant;
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: reveal ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
