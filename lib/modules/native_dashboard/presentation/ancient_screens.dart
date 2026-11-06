import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/ancient_codex_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/codex_practice.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_deck.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/brand_card.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/premium_surface.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/progress_ring.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final codex = context.watch<AncientCodexController>();
    final scheme = Theme.of(context).colorScheme;
    final lessons = codex.lessonsMatching(context.tr);
    return BrandFeed(
      children: [
        const _FactBanner(),
        const SizedBox(height: 10),
        Text(
          context.tr('Codex lessons'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            codex.useMeters ? 'Lengths in meters' : 'Lengths in cubits',
          ),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: codex.setQuery,
          style: TextStyle(color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: context.tr('Find a lesson'),
            hintStyle: const TextStyle(color: Colors.white60),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            isDense: true,
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
          runSpacing: 8,
          children: [
            for (final category in AncientCodexController.categories)
              ChoiceChip(
                key: Key('codex-filter-$category'),
                label: Text(context.tr(category)),
                selected: codex.category == category,
                onSelected: (_) => codex.setCategory(category),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (lessons.isEmpty)
          Text(
            context.tr('No lessons match this search'),
            style: const TextStyle(color: Colors.white60),
          ),
        for (final lesson in lessons) ...[
          _LessonCard(
            lesson: lesson,
            verticalInset: _lessonSpacing(codex, lessons).inset,
          ),
          SizedBox(height: _lessonSpacing(codex, lessons).gap),
        ],
        const SizedBox(height: 8),
        const KingdomStrip(),
      ],
    );
  }
}

({double inset, double gap}) _lessonSpacing(
  AncientCodexController codex,
  List<CodexLesson> lessons,
) {
  final filtered = codex.category != 'All' || codex.query.trim().isNotEmpty;
  if (!filtered || lessons.isEmpty || lessons.length > 2) {
    return (inset: 0, gap: 10);
  }
  if (lessons.length == 1) return (inset: 36, gap: 10);
  return (inset: 16, gap: 28);
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, this.verticalInset = 0});

  final CodexLesson lesson;
  final double verticalInset;

  @override
  Widget build(BuildContext context) {
    final codex = context.read<AncientCodexController>();
    final playing =
        context.watch<SoundDeck>().nowPlaying == 'lesson-${lesson.id}';
    final percent = (lesson.progress * 100).round();
    final done = lesson.progress >= 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openLesson(context, lesson.id),
      child: BrandCard(
        gold: true,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: lesson.progress <= 0
                              ? 0.02
                              : lesson.progress.clamp(0, 1).toDouble(),
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          color: const Color(0xFFE0A93B),
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                        Text(
                          '$percent%',
                          key: Key('lesson-progress-${lesson.id}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(lesson.title),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            SoftTag(
                              label: context.tr(lesson.category),
                              color: const Color(0xFFE0A93B),
                            ),
                            SoftTag(
                              label: '${lesson.minutes} ${context.tr('min')}',
                            ),
                            if (done)
                              SoftTag(
                                label: context.tr('Top'),
                                color: const Color(0xFFE0A93B),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: Key('read-${lesson.id}'),
                    onPressed: () => _openLesson(context, lesson.id),
                    child: Text(context.tr(done ? 'Done' : 'Read')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: lesson.progress <= 0
                            ? 0.04
                            : lesson.progress.clamp(0, 1).toDouble(),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(gradient: goldGradient),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SoftTag(
                    label: '${lesson.audioMinutes} ${context.tr('min audio')}',
                  ),
                  SoftTag(
                    label: '⭐ ${context.tr(lesson.difficulty)}',
                    color: const Color(0xFFE0A93B),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: context.tr(
                      playing ? 'Pause lesson' : 'Play lesson',
                    ),
                    onPressed: () => codex.toggleLesson(lesson.id),
                    icon: Icon(
                      playing ? Icons.pause_circle : Icons.play_circle,
                      color: const Color(0xFFE0A93B),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: context.tr(
                      lesson.bookmarked ? 'Bookmarked' : 'Bookmark',
                    ),
                    onPressed: () => codex.toggleBookmark(lesson.id),
                    icon: Icon(
                      lesson.bookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: const Color(0xFFE0A93B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openLesson(BuildContext context, String id) {
  final codex = context.read<AncientCodexController>();
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      useSafeArea: true,
      backgroundColor: const Color(0xFF140806),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.9;
        return ChangeNotifierProvider<AncientCodexController>.value(
          value: codex,
          child: SizedBox(
            height: height,
            child: LessonReaderSheet(lessonId: id),
          ),
        );
      },
    ),
  );
}

class LessonReaderSheet extends StatelessWidget {
  const LessonReaderSheet({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final codex = context.watch<AncientCodexController>();
    final lesson = codex.lessons
        .where((item) => item.id == lessonId)
        .firstOrNull;
    if (lesson == null) return const SizedBox.shrink();
    final done = lesson.progress >= 1;
    return Column(
      children: [
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const SizedBox(width: 42, height: 4),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(lesson.category).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFE0A93B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(lesson.title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${lesson.minutes} ${context.tr('min read')}',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 22),
                Text(
                  context.tr(lesson.summary),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(lesson.story),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1408),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE0A93B).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Historical fact'),
                          style: TextStyle(
                            color: Color(0xFFE0A93B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(lesson.fact),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('complete-lesson'),
                onPressed: done
                    ? null
                    : () {
                        codex.completeLesson(lesson.id);
                        Navigator.of(context).pop();
                      },
                child: Text(
                  context.tr(done ? 'Completed' : 'Complete Lesson'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FactBanner extends StatelessWidget {
  const _FactBanner();

  static const quotes = [
    'The scarab rolled the sun as a promise of a new day, not as a burden.',
    'A house sign is both a building and the sound pr. The sentence decides which.',
    'Incense at a temple door was a greeting, set beside bread and beer.',
    'The night boat of Ra has twelve hours. Dawn is the hour it becomes the day boat.',
  ];

  @override
  Widget build(BuildContext context) {
    final quote = quotes[DateTime.now().day % quotes.length];
    return BrandCard(
      gold: true,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftTag(
                  label: context.tr('Fact of the day'),
                  color: const Color(0xFFE0A93B),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(quote),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('Quote ready to share'))),
              );
            },
            icon: const Icon(
              Icons.ios_share,
              color: Color(0xFFE0A93B),
              size: 18,
            ),
            label: Text(context.tr('Share')),
          ),
        ],
      ),
    );
  }
}

class TrialsScreen extends StatelessWidget {
  const TrialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final codex = context.watch<AncientCodexController>();
    final scheme = Theme.of(context).colorScheme;
    return BrandFeed(
      children: [
        Text(
          context.tr('Trial rank'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final rank in QuizRank.values)
              ChoiceChip(
                key: Key('rank-${rank.name}'),
                label: Text(context.tr(_rankLabel(rank))),
                selected: codex.rank == rank,
                onSelected: codex.quizOpen ? null : (_) => codex.setRank(rank),
              ),
          ],
        ),
        const SizedBox(height: 16),
        BrandCard(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Daily challenge'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('Name three titles of Ra'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('daily-challenge'),
                onPressed: codex.dailyDone ? null : codex.completeDaily,
                child: Text(context.tr(codex.dailyDone ? 'Closed' : 'Mark')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!codex.quizOpen && !codex.quizFinished)
          FilledButton(
            key: const Key('start-quiz'),
            onPressed: codex.startQuiz,
            child: Text(context.tr('Start quiz')),
          ),
        if (codex.quizOpen) const _QuizCard(),
        if (codex.quizFinished) ...[
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: ${codex.score}',
                  key: const Key('quiz-score'),
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.tr('Best score')}: ${codex.bestScore}',
                  style: TextStyle(color: scheme.onSurface),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('start-quiz'),
                  onPressed: codex.startQuiz,
                  child: Text(context.tr('Try again')),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          context.tr('Achievements'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: codex.badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final badge = codex.badges[index];
            return BrandCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    badge.unlocked
                        ? Icons.workspace_premium
                        : Icons.lock_outline,
                    color: badge.unlocked
                        ? const Color(0xFFE0A93B)
                        : Colors.white60,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(badge.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.tr(badge.unlocked ? 'Unlocked' : 'Locked'),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      minHeight: 4,
                      color: const Color(0xFFE0A93B),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard();

  @override
  Widget build(BuildContext context) {
    final codex = context.watch<AncientCodexController>();
    final scheme = Theme.of(context).colorScheme;
    final question = codex.questions[codex.quizIndex];
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.tr('Question')} ${codex.quizIndex + 1} ${context.tr('of')} ${codex.questions.length}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(question.prompt),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < question.options.length; index++) ...[
            _AnswerCard(
              optionKey: Key('quiz-option-$index'),
              label: context.tr(question.options[index]),
              selected: codex.chosen == index,
              enabled: codex.chosen == null,
              onTap: () {
                HapticFeedback.selectionClick();
                codex.chooseAnswer(index);
              },
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text(
            '${context.tr('Score')}: ${codex.score}',
            style: TextStyle(color: scheme.onSurface),
          ),
          if (codex.chosen != null) ...[
            const SizedBox(height: 8),
            Text(
              codex.chosen == question.correctIndex
                  ? context.tr('Review: this answer holds the line of the myth.')
                  : context
                        .tr('Review: the right path is {answer}.')
                        .replaceAll(
                          '{answer}',
                          context.tr(question.options[question.correctIndex]),
                        ),
              style: const TextStyle(color: Colors.white60, height: 1.3),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('quiz-next'),
            onPressed: codex.chosen == null ? null : codex.advanceQuiz,
            child: Text(
              context.tr(
                codex.quizIndex + 1 >= codex.questions.length
                    ? 'Finish'
                    : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.optionKey,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: optionKey,
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE0A93B).withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE0A93B)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? const Color(0xFFE0A93B) : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
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

class WorkshopScreen extends StatelessWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final codex = context.watch<AncientCodexController>();
    final deck = context.watch<SoundDeck>();
    final scheme = Theme.of(context).colorScheme;
    final selected = codex.selectedGlyph == null
        ? null
        : codex.glyphs[codex.selectedGlyph!];
    return BrandFeed(
      children: [
        Text(
          context.tr('Symbols'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${context.tr('Tap a sign to read its meaning')} · ${context.tr('Learned signs')}: ${codex.learnedGlyphs.length}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: codex.glyphs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final glyph = codex.glyphs[index];
            final active = codex.selectedGlyph == index;
            return Material(
              color: active
                  ? scheme.primary.withValues(alpha: 0.2)
                  : AppBrand.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: active
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.24),
                ),
              ),
              child: InkWell(
                key: Key('glyph-$index'),
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  codex.selectGlyph(index);
                },
                child: Center(
                  child: Text(
                    glyph.symbol,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (selected != null)
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(selected.name),
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(selected.meaning),
                  key: const Key('glyph-meaning'),
                  style: TextStyle(color: scheme.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(selected.lore),
                  style: const TextStyle(color: Colors.white60, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.tr('Reading')}: ${selected.reading}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => codex.playGlyph(codex.selectedGlyph!),
                  icon: Icon(
                    deck.nowPlaying == 'glyph-${codex.selectedGlyph}'
                        ? Icons.stop
                        : Icons.volume_up,
                  ),
                  label: Text(
                    context.tr(
                      deck.nowPlaying == 'glyph-${codex.selectedGlyph}'
                          ? 'Stop the sound'
                          : 'Play the sound',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('learn-glyph'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    codex.toggleLearnedGlyph(codex.selectedGlyph!);
                  },
                  icon: Icon(
                    codex.glyphLearned(codex.selectedGlyph!)
                        ? Icons.check
                        : Icons.school_outlined,
                  ),
                  label: Text(
                    context.tr(
                      codex.glyphLearned(codex.selectedGlyph!)
                          ? 'Learned'
                          : 'Mark as learned',
                    ),
                  ),
                ),
                if (codex.soundedGlyph == codex.selectedGlyph)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context
                          .tr(
                            'A short tone built from the syllable "{reading}"',
                          )
                          .replaceAll('{reading}', selected.reading),
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const ScribeDrill(),
      ],
    );
  }
}

class CodexProgressScreen extends StatelessWidget {
  const CodexProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final codex = context.watch<AncientCodexController>();
    final scheme = Theme.of(context).colorScheme;
    final percent = (codex.studyProgress * 100).round();
    return BrandFeed(
      children: [
        BrandCard(
          child: Row(
            children: [
              ProgressRing(
                progress: codex.studyProgress,
                color: scheme.primary,
                label: '$percent%',
                size: 88,
                labelColor: scheme.onSurface,
                glow: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Studied'),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${context.tr('Lessons')}: ${codex.finishedLessons}',
                      key: const Key('codex-finished'),
                      style: TextStyle(color: scheme.onSurface),
                    ),
                    Text(
                      '${context.tr('Trials')}: ${codex.quizzesFinished}',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                    Text(
                      codex.quizzesFinished == 0
                          ? '${context.tr('Best score')}: —'
                          : '${context.tr('Best score')}: ${codex.bestScore}',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('History'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (!_hasJourneyHistory(codex))
          BrandCard(
            child: Text(
              context.tr(
                'Your journey begins! Complete lessons and trials to populate your history.',
              ),
              style: TextStyle(color: scheme.onSurface, height: 1.4),
            ),
          ),
        if (_hasJourneyHistory(codex))
          for (final line in codex.activity) ...[
            BrandCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                _activityLine(context, line),
                style: TextStyle(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

bool _hasJourneyHistory(AncientCodexController codex) {
  return codex.activity.any((line) => line != 'Codex opened');
}

String _activityLine(BuildContext context, String line) {
  if (line.startsWith('Lesson read: ')) {
    final title = line.substring('Lesson read: '.length);
    return '${context.tr('Lesson read')}: ${context.tr(title)}';
  }
  if (line.startsWith('Trial: ') && line.endsWith(' points')) {
    final score = line.substring('Trial: '.length, line.length - ' points'.length);
    return '${context.tr('Trial')}: $score ${context.tr('points')}';
  }
  if (line.startsWith('Learned sign ')) {
    final name = line.substring('Learned sign '.length);
    return '${context.tr('Learned sign')} ${context.tr(name)}';
  }
  if (line.startsWith('Opened sign ')) {
    final name = line.substring('Opened sign '.length);
    return '${context.tr('Opened sign')} ${context.tr(name)}';
  }
  const practice = ' back in practice';
  if (line.startsWith('Sign ') && line.endsWith(practice)) {
    final name = line.substring('Sign '.length, line.length - practice.length);
    return '${context.tr('Sign')} ${context.tr(name)} ${context.tr('back in practice')}';
  }
  return context.tr(line);
}

String _rankLabel(QuizRank rank) {
  return switch (rank) {
    QuizRank.apprentice => 'Apprentice',
    QuizRank.scribe => 'Scribe',
    QuizRank.highPriest => 'High Priest',
  };
}
