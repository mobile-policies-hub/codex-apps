import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/domain/tracker_format.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_palette.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/brand_card.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/goal_ring.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/metric_card.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/premium_surface.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/progress_ring.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/week_bar_chart.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerController>();
    final accent = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    final chart = WeekBarChart(
      values: tracker.weekScores,
      selectedIndex: tracker.today.weekday - 1,
      accent: accent,
      barHeight: 108,
      subtitle: context.tr('Score by day'),
      semanticsLabel: 'Focus scores for the week',
    );
    final hero = _HeroCard(tracker: tracker, accent: accent, ringSize: 84);

    return BrandFeed(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          formatLongDate(tracker.today),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _MoodRow(tracker: tracker, accent: accent),
        const SizedBox(height: 12),
        _HabitCard(tracker: tracker, accent: accent),
        const SizedBox(height: 12),
        hero,
        if (tracker.remindersEnabled &&
            !tracker.scoreGoalReached &&
            !tracker.quietHours) ...[
          const SizedBox(height: 8),
          _ReminderBanner(text: reminderText(context, tracker)),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MetricCard(
                key: const Key('metric-steps'),
                icon: Icons.bolt,
                label: context.tr('Daily Score'),
                value: '${tracker.focusScore}',
                hint: 'of ${tracker.scoreGoal}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                key: const Key('metric-focus'),
                icon: Icons.timer_outlined,
                label: context.tr('Focus time'),
                value: '${tracker.focusedMinutes}',
                hint: pluralize(tracker.focusedMinutes, 'minute', 'minutes'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                key: const Key('metric-water'),
                icon: Icons.water_drop_outlined,
                label: context.tr('Hydration'),
                value: '${tracker.glasses}',
                hint: 'of ${tracker.waterGoal}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _GlassRow(tracker: tracker, accent: accent),
        const SizedBox(height: 16),
        chart,
        const SizedBox(height: 16),
        _Heatmap(tracker: tracker, accent: accent),
        const SizedBox(height: 12),
        _QuietCard(tracker: tracker),
      ],
    );
  }
}

class _GlassRow extends StatelessWidget {
  const _GlassRow({required this.tracker, required this.accent});

  final TrackerController tracker;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BrandCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('water-minus'),
            tooltip: context.tr('Less'),
            onPressed: tracker.glasses > 0
                ? () {
                    HapticFeedback.selectionClick();
                    tracker.undoGlass();
                  }
                : null,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Glasses today'),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${tracker.glasses} / ${tracker.waterGoal}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('water-plus'),
            tooltip: context.tr('More'),
            onPressed: tracker.glasses < tracker.waterGoal
                ? () {
                    HapticFeedback.lightImpact();
                    tracker.drinkGlass();
                  }
                : null,
            icon: Icon(Icons.water_drop, color: accent),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.tracker,
    required this.accent,
    required this.ringSize,
  });

  final TrackerController tracker;
  final Color accent;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final value = 'Daily Score ${tracker.focusScore}';
    final deep =
        Theme.of(context).extension<BrandSurfaces>()?.deep ??
        brandDeep(AppBrandConfig.current.primaryColor);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep, Color.lerp(deep, accent, 0.35)!, deep],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 24),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _LabeledRing(
                    caption: context.tr('Score'),
                    child: GoalRing(
                      progress: tracker.scoreProgress,
                      label: '${tracker.scorePercent}%',
                      color: accent,
                      glow: true,
                      size: ringSize,
                    ),
                  ),
                ),
                Expanded(
                  child: _LabeledRing(
                    caption: context.tr('Focus'),
                    child: ProgressRing(
                      size: ringSize,
                      progress: tracker.focusedMinutes / 120,
                      label: '${tracker.focusedMinutes}m',
                      color: accent,
                      glow: true,
                    ),
                  ),
                ),
                Expanded(
                  child: _LabeledRing(
                    caption: context.tr('Water'),
                    child: ProgressRing(
                      size: ringSize,
                      progress:
                          tracker.glasses / tracker.waterGoal,
                      label: '${tracker.glasses}/${tracker.waterGoal}',
                      color: accent,
                      glow: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              goalCaption(context, tracker),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE7C36A),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledRing extends StatelessWidget {
  const _LabeledRing({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const SizedBox(height: 4),
        Text(
          caption,
          style: const TextStyle(
            color: Color(0xFFD5E4DE),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.tracker, required this.accent});

  final TrackerController tracker;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Habits'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  '🔥 ${tracker.streakDays}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${tracker.completedHabits} ${context.tr('of')} ${tracker.habits.length}',
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _openHabitSheet(context, tracker),
            icon: const Icon(Icons.add),
            label: Text(context.tr('+ New habit')),
          ),
        ),
        const SizedBox(height: 10),
        for (final habit in tracker.habits) ...[
          Material(
            color: brand.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0x14FFFFFF)),
            ),
            child: InkWell(
              key: Key('habit-${habit.id}'),
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.selectionClick();
                tracker.toggleHabit(habit.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: habit.done
                      ? accent.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        habit.done ? Icons.check_circle : Icons.circle_outlined,
                        key: ValueKey(habit.done),
                        color: habit.done ? accent : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(habit.title),
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                              decoration: habit.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: TextButton(
                                    key: Key('habit-time-${habit.id}'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: Colors.white60,
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () => _pickHabitTime(
                                      context,
                                      tracker,
                                      habit,
                                    ),
                                    child: Text(habit.reminder),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' · ${context.tr(habit.category)} · 🔥 ${habit.personalStreak}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const Key('reminder-banner'),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.notifications_none, color: scheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String goalCaption(BuildContext context, TrackerController tracker) {
  if (tracker.scoreGoalReached) {
    return context.tr("Today's goal is complete");
  }
  final remaining = tracker.pointsRemaining;
  final unit = pluralize(remaining, 'point', 'points');
  return '$remaining ${context.tr(unit)} ${context.tr('to go')}';
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({required this.tracker, required this.accent});

  static const glyphs = ['☀️', '🙂', '😌', '😣', '🫥'];

  final TrackerController tracker;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Mood'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (
                var index = 0;
                index < TrackerController.moods.length;
                index++
              )
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _MoodChip(
                      label: TrackerController.moods[index],
                      glyph: glyphs[index],
                      selected: tracker.moodIndex == index,
                      accent: accent,
                      onTap: () => tracker.setMood(index),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.2) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? accent : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                glyph,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.tracker, required this.accent});

  final TrackerController tracker;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final marks = tracker.monthMarks;
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('30 days'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('Score this month'),
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              const columns = 10;
              final cell =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < marks.length; index++)
                    SizedBox(
                      width: cell,
                      height: cell,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: 0.18 + marks[index] / 8 * 0.7,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuietCard extends StatelessWidget {
  const _QuietCard({required this.tracker});

  final TrackerController tracker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BrandCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Quiet hours'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    tracker.quietHours
                        ? 'Evening cues are muted'
                        : 'Evening cues play as usual',
                  ),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: tracker.quietHours,
            activeThumbColor: scheme.primary,
            onChanged: tracker.setQuietHours,
          ),
        ],
      ),
    );
  }
}

void _openHabitSheet(BuildContext context, TrackerController tracker) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _HabitSheet(tracker: tracker),
  );
}

class _HabitSheet extends StatefulWidget {
  const _HabitSheet({required this.tracker});

  final TrackerController tracker;

  @override
  State<_HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<_HabitSheet> {
  final TextEditingController _name = TextEditingController();
  String _category = TrackerController.habitCategories.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('New habit'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: context.tr('Name'),
              hintStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final category in TrackerController.habitCategories)
                ChoiceChip(
                  label: Text(context.tr(category)),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              widget.tracker.addHabit(_name.text, _category);
              Navigator.of(context).pop();
            },
            child: Text(context.tr('Add')),
          ),
        ],
      ),
    );
  }
}

Future<void> _pickHabitTime(
  BuildContext context,
  TrackerController tracker,
  Habit habit,
) async {
  final parts = habit.reminder.split(':');
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    ),
  );
  if (picked == null) return;
  tracker.setHabitReminder(
    habit.id,
    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
  );
}

String reminderText(BuildContext context, TrackerController tracker) {
  final remaining = tracker.pointsRemaining;
  final unit = pluralize(remaining, 'point', 'points');
  return '$remaining ${context.tr(unit)} ${context.tr('still to go')}';
}
