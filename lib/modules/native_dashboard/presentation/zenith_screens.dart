import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/domain/tracker_format.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/breath_card.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/brand_card.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/premium_surface.dart';

class _DayNote extends StatefulWidget {
  const _DayNote();

  @override
  State<_DayNote> createState() => _DayNoteState();
}

class _DayNoteState extends State<_DayNote> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(
      text: context.read<TrackerController>().journal,
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('One line for today'),
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('What moved, what you are leaving for tomorrow.'),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('day-journal'),
            controller: _note,
            maxLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.tr('A sentence is enough'),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: context.read<TrackerController>().setJournal,
          ),
        ],
      ),
    );
  }
}

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerController>();
    final scheme = Theme.of(context).colorScheme;
    return BrandFeed(
      children: [
        Text(
          context.tr('Session'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('Short stretches without distractions'),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        BrandCard(
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.45),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: Text(
                  tracker.focusClock,
                  key: const Key('focus-clock'),
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(tracker.focusRunning ? 'Counting down' : 'Ready to start'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                children: [
                  for (final minutes in TrackerController.focusChoices)
                    ChoiceChip(
                      key: Key('focus-minutes-$minutes'),
                      label: Text('$minutes ${context.tr('min')}'),
                      selected: tracker.focusChoice == minutes,
                      onSelected: tracker.focusRunning
                          ? null
                          : (_) => tracker.selectFocusMinutes(minutes),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('focus-start'),
                onPressed: tracker.toggleFocus,
                icon: Icon(
                  tracker.focusRunning ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(context.tr(tracker.focusRunning ? 'Pause' : 'Start')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AmbientDeck(tracker: tracker),
        const SizedBox(height: 16),
        _SessionLog(tracker: tracker),
        const SizedBox(height: 16),
        const BreathCard(),
      ],
    );
  }
}

class _AmbientDeck extends StatelessWidget {
  const _AmbientDeck({required this.tracker});

  final TrackerController tracker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const sounds = [
      (AmbientSound.rain, 'Rain'),
      (AmbientSound.forest, 'Forest'),
      (AmbientSound.noise, 'White noise'),
      (AmbientSound.bowl, 'Singing bowl'),
    ];
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Background sounds'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sound in sounds)
                ChoiceChip(
                  label: Text(context.tr(sound.$2)),
                  selected: tracker.ambient == sound.$1,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    tracker.selectAmbient(sound.$1);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('ambient-toggle'),
            onPressed: tracker.ambient == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    tracker.toggleAmbient();
                  },
            icon: Icon(tracker.ambientPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(context.tr(tracker.ambientPlaying ? 'Stop' : 'Play')),
          ),
          if (tracker.ambient != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tracker.ambientPlaying
                    ? '${context.tr('Playing')}: ${context.tr(_ambientName(tracker.ambient!))}'
                    : '${context.tr('Selected')}: ${context.tr(_ambientName(tracker.ambient!))}',
                style: TextStyle(color: scheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

String _ambientName(AmbientSound sound) {
  return switch (sound) {
    AmbientSound.rain => 'Rain',
    AmbientSound.forest => 'Forest',
    AmbientSound.noise => 'White noise',
    AmbientSound.bowl => 'Singing bowl',
  };
}

class _SessionLog extends StatelessWidget {
  const _SessionLog({required this.tracker});

  final TrackerController tracker;

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("Today's session history"),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (tracker.sessions.isEmpty)
            Text(
              context.tr('No sessions yet today'),
              style: TextStyle(color: Colors.white60),
            )
          else
            for (final session in tracker.sessions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  sessionLine(context, session),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
        ],
      ),
    );
  }
}

String sessionLine(BuildContext context, String session) {
  final finished = RegExp(r'^Finished a (\d+) min block$').firstMatch(session);
  if (finished != null) {
    return context
        .tr('Finished a {n} min block')
        .replaceAll('{n}', finished.group(1)!);
  }
  final paused = RegExp(r'^A (\d+) min block was paused$').firstMatch(session);
  if (paused != null) {
    return context
        .tr('A {n} min block was paused')
        .replaceAll('{n}', paused.group(1)!);
  }
  return context.tr(session);
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerController>();
    final scheme = Theme.of(context).colorScheme;
    final fractions = _weekFractions(tracker);
    return BrandFeed(
      children: [
        BrandCard(
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.55),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(Icons.local_fire_department, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Streak'),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streakCaption(context, tracker.streakDays),
                      key: const Key('streak-value'),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _DayNote(),
        const SizedBox(height: 16),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Trend'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('This week only shows days you logged.'),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < fractions.length; index++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _FractionBar(
                            fraction: fractions[index],
                            label: context.tr(weekDayLabels[index]),
                            selected: index == tracker.today.weekday - 1,
                            accent: scheme.primary,
                          ),
                        ),
                      ),
                  ],
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
              Text(
                context.tr('Composure'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tracker.moodIndex == null
                    ? context.tr('Mood not marked yet')
                    : '${context.tr('Today')}: ${context.tr(TrackerController.moods[tracker.moodIndex!])}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 6),
              Text(
                context
                    .tr('{done} of {total} habits done')
                    .replaceAll('{done}', '${tracker.completedHabits}')
                    .replaceAll('{total}', '${tracker.habits.length}'),
                style: TextStyle(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<double> _weekFractions(TrackerController tracker) {
    final goal = tracker.scoreGoal <= 0 ? 1 : tracker.scoreGoal;
    return [
      for (final score in tracker.weekScores)
        (score / goal).clamp(0.0, 1.0).toDouble(),
    ];
  }
}

class _FractionBar extends StatelessWidget {
  const _FractionBar({
    required this.fraction,
    required this.label,
    required this.selected,
    required this.accent,
  });

  final double fraction;
  final String label;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction.clamp(0.08, 1),
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? accent : const Color(0xFF334155),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: selected ? accent : scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

String streakCaption(BuildContext context, int value) {
  final code = AppText.maybeOf(context)?.code ?? 'en';
  if (code == 'ru') {
    final count = value.abs();
    final mod10 = count % 10;
    final mod100 = count % 100;
    final word = mod10 == 1 && mod100 != 11
        ? 'день'
        : (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14))
        ? 'дня'
        : 'дней';
    return '$value $word';
  }
  return '$value ${context.tr(pluralize(value, 'day', 'days'))}';
}
