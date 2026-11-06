import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:hybrid_app/modules/native_dashboard/data/local_vault.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/codex_library.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_clips.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_deck.dart';

enum QuizRank { apprentice, scribe, highPriest }

class CodexLesson {
  CodexLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.minutes,
    required this.progress,
    required this.audioMinutes,
    required this.difficulty,
    required this.summary,
    required this.story,
    required this.fact,
    this.bookmarked = false,
  });

  final String id;
  final String title;
  final String category;
  final int minutes;
  final int audioMinutes;
  final String difficulty;
  final String summary;
  final String story;
  final String fact;
  double progress;
  bool bookmarked;
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class GlyphEntry {
  const GlyphEntry({
    required this.symbol,
    required this.name,
    required this.meaning,
    required this.lore,
    required this.reading,
  });

  final String symbol;
  final String name;
  final String meaning;
  final String lore;
  final String reading;
}

class CodexBadge {
  const CodexBadge({
    required this.title,
    required this.hint,
    required this.unlocked,
    required this.progress,
  });

  final String title;
  final String hint;
  final bool unlocked;
  final double progress;
}

class AncientCodexController extends ChangeNotifier {
  AncientCodexController({this.deck, this.vault}) {
    _restore();
  }

  final SoundDeck? deck;
  final LocalVault? vault;
  bool _persistGuard = false;
  static const categories = ['All', 'Myths', 'Script', 'Ritual'];

  final List<CodexLesson> lessons = [
    CodexLesson(
      id: 'scarab',
      title: 'Scarab and the sun',
      category: 'Myths',
      minutes: 8,
      progress: 0,
      audioMinutes: 3,
      difficulty: 'Medium',
      summary: 'Egyptians pictured the rising sun as a scarab beetle pushing a bright disk across the sky. The god of that first hour was Khepri, whose name is built from the word for "coming into being."',
      story: 'Carvers shaped the beetle in stone and glazed it blue-green, then drilled it so a cord could rest over the heart. On the flat underside a scribe might cut a short plea: let the heart stay silent when it is weighed, and let the owner pass into the day.',
      fact: 'Heart scarabs turn up in burials from the New Kingdom on, often in dark green stone. The one from Tutankhamun\'s chest is large enough to cover the breast and still carries a form of that heart spell.',
    ),
    CodexLesson(
      id: 'house',
      title: 'House sign',
      category: 'Script',
      minutes: 6,
      progress: 0,
      audioMinutes: 2,
      difficulty: 'Easy',
      summary: 'The house sign is a rectangle with a small opening, the picture of a building and the sound pr. It is one of the first shapes a student learned to draw.',
      story: 'The same outline stands in words for house, estate, palace, and temple. Scribes used it on limestone flakes, the scrap "paper" of the workshop, when they counted grain, labor, and the rooms those goods belonged to.',
      fact: 'The sign is already stable in Old Kingdom inscriptions. Later school texts keep it near the front of the list, because the outline is simple and the word for house appears constantly in accounts.',
    ),
    CodexLesson(
      id: 'incense',
      title: 'Incense at the threshold',
      category: 'Ritual',
      minutes: 10,
      progress: 0,
      audioMinutes: 4,
      difficulty: 'Hard',
      summary: 'At a temple door, incense was a greeting. Smoke marked the moment a priest crossed from the courtyard into the rooms reserved for the god.',
      story: 'Resin, often frankincense or myrrh brought from the south, fell onto charcoal in a long burner. Offering lists treat that scent as food, set beside bread, beer, and cool water, not as a perfume for the crowd.',
      fact: 'New Kingdom burners often end in a carved hand, as if the priest held the scent out toward the shrine. Some vessels still hold traces of aromatic gum, the closest we come to the smell of a morning rite.',
    ),
    CodexLesson(
      id: 'barque',
      title: 'Barque of Ra',
      category: 'Myths',
      minutes: 12,
      progress: 0,
      audioMinutes: 5,
      difficulty: 'Medium',
      summary: 'By day the sun sailed a boat across the sky. At dusk the same god changed vessels and entered the night river of the underworld.',
      story: 'Royal books such as the Amduat split that night into twelve hours. In each hour the crew holds off the serpent that tries to stop the sun. Dawn is the hour the night boat becomes the day boat again.',
      fact: 'Wooden boat models were placed in tombs long before those hour-by-hour books were painted on royal walls. A barque beside a coffin meant passage, a way through the dark, not a record of a hobby.',
    ),
    ...extraCodexLessons(),
  ];

  final List<GlyphEntry> glyphs = const [
    GlyphEntry(
      symbol: '𓂀',
      name: 'Eye',
      meaning: 'Protection and wholeness',
      lore: 'The Eye of Horus was reassembled after the battle: each fragment restored sight.',
      reading: 'irt',
    ),
    GlyphEntry(
      symbol: '𓆣',
      name: 'Scarab',
      meaning: 'Rebirth of the sun',
      lore: "The beetle rolled a ball, and that gesture explained the sun's path across the sky.",
      reading: 'kheper',
    ),
    GlyphEntry(
      symbol: '𓇳',
      name: 'Ra',
      meaning: 'Daytime sun',
      lore: 'A dotted disk was set above royal names so the day began with their title.',
      reading: 'ra',
    ),
    GlyphEntry(
      symbol: '𓋹',
      name: 'Ankh',
      meaning: 'Life',
      lore: "The ankh loop was placed in a statue's hand: the gesture meant breath, not jewelry.",
      reading: 'ankh',
    ),
    GlyphEntry(
      symbol: '𓊹',
      name: 'Netjer',
      meaning: 'The divine',
      lore: "The staff mark tagged a god's name and set it apart from an ordinary word.",
      reading: 'netjer',
    ),
    GlyphEntry(
      symbol: '𓈖',
      name: 'Flow',
      meaning: 'Flow and the Nile',
      lore: 'The wave meant water and the sound n, so it appeared in names and flood maps.',
      reading: 'en',
    ),
    GlyphEntry(
      symbol: '𓃭',
      name: 'Lion',
      meaning: 'Strength of the pharaoh',
      lore: 'The lion stood at the temple door as a guard who does not sleep at noon.',
      reading: 'ru',
    ),
    GlyphEntry(
      symbol: '𓌻',
      name: 'Scepter',
      meaning: 'Power and stability',
      lore: 'The was-staff was held upright to show that power stands and does not run.',
      reading: 'was',
    ),
    GlyphEntry(
      symbol: '𓅓',
      name: 'Owl',
      meaning: 'Hearing the night',
      lore: 'The owl was read as the sound m and as a reminder that the temple hears the quiet.',
      reading: 'em',
    ),
    GlyphEntry(
      symbol: '𓂋',
      name: 'Mouth',
      meaning: 'Speech and command',
      lore: 'The mouth outline opened a formula: a word counted as an act once spoken aloud.',
      reading: 'er',
    ),
    GlyphEntry(
      symbol: '𓏏',
      name: 'Bread',
      meaning: 'Share and gift',
      lore:
          'The loaf was listed among offerings beside the names of ancestors.',
      reading: 'et',
    ),
    GlyphEntry(
      symbol: '𓊽',
      name: 'Djed',
      meaning: 'Support of the spine',
      lore: 'The djed pillar was raised at the festival so the year would stand straight.',
      reading: 'djed',
    ),
  ];

  String category = 'All';
  String query = '';
  int? soundedGlyph;
  final Set<int> learnedGlyphs = {};
  bool useMeters = true;
  QuizRank rank = QuizRank.apprentice;
  bool dailyDone = false;
  bool quizOpen = false;
  int quizIndex = 0;
  int score = 0;
  int? chosen;
  bool quizFinished = false;
  int quizzesFinished = 0;
  int bestScore = 0;
  int drillBest = 0;
  int? selectedGlyph;
  final List<String> activity = ['Codex opened'];

  List<CodexLesson> get visibleLessons => lessonsMatching((value) => value);

  List<CodexLesson> lessonsMatching(String Function(String english) translate) {
    final needle = query.trim().toLowerCase();
    return lessons.where((lesson) {
      final categoryMatches = category == 'All' || lesson.category == category;
      final haystack =
          '${lesson.title} ${translate(lesson.title)} ${translate(lesson.category)}'
              .toLowerCase();
      final queryMatches = needle.isEmpty || haystack.contains(needle);
      return categoryMatches && queryMatches;
    }).toList();
  }

  List<CodexBadge> get badges {
    final opened = selectedGlyph == null ? 0.0 : 1.0;
    return [
      CodexBadge(
        title: 'First scroll',
        hint: 'At least one lesson',
        unlocked: finishedLessons >= 1,
        progress: (finishedLessons / lessons.length).clamp(0, 1).toDouble(),
      ),
      CodexBadge(
        title: 'Scribe',
        hint: 'Three finished lessons',
        unlocked: finishedLessons >= 3,
        progress: (finishedLessons / 3).clamp(0, 1).toDouble(),
      ),
      CodexBadge(
        title: 'Challenger',
        hint: 'A finished quiz',
        unlocked: quizzesFinished >= 1,
        progress: quizzesFinished >= 1 ? 1 : 0,
      ),
      CodexBadge(
        title: 'Priest',
        hint: 'A high score',
        unlocked: bestScore >= 90,
        progress: (bestScore / 90).clamp(0, 1).toDouble(),
      ),
      CodexBadge(
        title: 'Sign keeper',
        hint: 'An opened card',
        unlocked: selectedGlyph != null,
        progress: opened,
      ),
      CodexBadge(
        title: 'Daily guardian',
        hint: "The day's challenge",
        unlocked: dailyDone,
        progress: dailyDone ? 1 : 0,
      ),
    ];
  }

  double get studyProgress {
    if (lessons.isEmpty) return 0;
    final total = lessons.fold<double>(
      0,
      (sum, lesson) => sum + lesson.progress,
    );
    return total / lessons.length;
  }

  int get finishedLessons =>
      lessons.where((lesson) => lesson.progress >= 1).length;

  List<QuizQuestion> get questions {
    final bank = [
      QuizQuestion(
        prompt: 'What was the sun god called?',
        options: ['Ra', 'Set', 'Anubis', 'Thoth'],
        correctIndex: 0,
      ),
      QuizQuestion(
        prompt: 'What does the ankh open?',
        options: ['Life', 'War', 'Desert', 'Nile'],
        correctIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Where were pharaohs buried?',
        options: ['Valley of the Kings', 'Karnak', 'Memphis', 'Siwa'],
        correctIndex: 0,
      ),
      ...extraQuizQuestions(),
    ];
    final width = switch (rank) {
      QuizRank.apprentice => 2,
      QuizRank.scribe => 3,
      QuizRank.highPriest => 4,
    };
    return [
      for (final question in bank)
        QuizQuestion(
          prompt: question.prompt,
          options: question.options.take(width).toList(),
          correctIndex: question.correctIndex,
        ),
    ];
  }

  int get rankPoints => switch (rank) {
    QuizRank.apprentice => 10,
    QuizRank.scribe => 20,
    QuizRank.highPriest => 30,
  };

  void setQuery(String value) {
    if (value == query) return;
    query = value;
    notifyListeners();
  }

  void toggleBookmark(String id) {
    final lesson = lessons.where((item) => item.id == id).firstOrNull;
    if (lesson == null) return;
    lesson.bookmarked = !lesson.bookmarked;
    notifyListeners();
  }

  void setCategory(String value) {
    if (value == category || !categories.contains(value)) return;
    category = value;
    notifyListeners();
  }

  void readLesson(String id) {
    final lesson = lessons.where((item) => item.id == id).firstOrNull;
    if (lesson == null || lesson.progress >= 1) return;
    lesson.progress = (lesson.progress + 0.25).clamp(0, 1).toDouble();
    activity.insert(0, 'Lesson read: ${lesson.title}');
    notifyListeners();
  }

  /// Marks a lesson finished from the reader and records it in history.
  void completeLesson(String id) {
    final lesson = lessons.where((item) => item.id == id).firstOrNull;
    if (lesson == null || lesson.progress >= 1) return;
    lesson.progress = 1;
    activity.insert(0, 'Lesson read: ${lesson.title}');
    notifyListeners();
  }

  void setRank(QuizRank value) {
    if (quizOpen || value == rank) return;
    rank = value;
    notifyListeners();
  }

  void completeDaily() {
    if (dailyDone) return;
    dailyDone = true;
    activity.insert(0, 'Daily challenge closed');
    notifyListeners();
  }

  void setUseMeters(bool value) {
    if (value == useMeters) return;
    useMeters = value;
    notifyListeners();
  }

  void startQuiz() {
    quizOpen = true;
    quizFinished = false;
    quizIndex = 0;
    score = 0;
    chosen = null;
    notifyListeners();
  }

  void chooseAnswer(int index) {
    if (!quizOpen || quizFinished || chosen != null) return;
    chosen = index;
    final question = questions[quizIndex];
    if (index == question.correctIndex) score += rankPoints;
    notifyListeners();
  }

  void advanceQuiz() {
    if (chosen == null) return;
    if (quizIndex + 1 >= questions.length) {
      quizFinished = true;
      quizOpen = false;
      quizzesFinished += 1;
      if (score > bestScore) bestScore = score;
      activity.insert(0, 'Trial: $score points');
    } else {
      quizIndex += 1;
      chosen = null;
    }
    notifyListeners();
  }

  void playGlyph(int index) {
    if (index < 0 || index >= glyphs.length) return;
    soundedGlyph = index;
    final id = 'glyph-$index';
    if (deck?.nowPlaying == id) {
      deck?.stop();
    } else {
      deck?.playOnce(id, SoundClips.glyph(glyphs[index].reading));
    }
    notifyListeners();
  }

  void toggleLesson(String id) {
    final key = 'lesson-$id';
    if (deck?.nowPlaying == key) {
      deck?.stop();
      return;
    }
    deck?.playLoop(key, SoundClips.lesson(id));
  }

  bool glyphLearned(int index) => learnedGlyphs.contains(index);

  void recordDrill(int score) {
    if (score <= drillBest) return;
    drillBest = score;
    final line = 'Scribe drill $score';
    if (activity.isEmpty || activity.first != line) activity.insert(0, line);
    notifyListeners();
  }

  void toggleLearnedGlyph(int index) {
    if (!learnedGlyphs.add(index)) learnedGlyphs.remove(index);
    final glyph = glyphs[index];
    final line = learnedGlyphs.contains(index)
        ? 'Learned sign ${glyph.name}'
        : 'Sign ${glyph.name} back in practice';
    if (activity.first != line) activity.insert(0, line);
    notifyListeners();
  }

  void selectGlyph(int index) {
    selectedGlyph = index;
    final glyph = glyphs[index];
    final line = 'Opened sign ${glyph.name}';
    if (activity.first != line) activity.insert(0, line);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_persistGuard) {
      _persistGuard = true;
      _save();
      _persistGuard = false;
    }
    super.notifyListeners();
  }

  void _restore() {
    final raw = vault?.read('codex.progress.v2');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final savedLessons = decoded['lessons'];
      if (savedLessons is Map) {
        for (final lesson in lessons) {
          final item = savedLessons[lesson.id];
          if (item is! Map) continue;
          final progress = item['progress'];
          if (progress is num) lesson.progress = progress.toDouble();
          final bookmarked = item['bookmarked'];
          if (bookmarked is bool) lesson.bookmarked = bookmarked;
        }
      }
      final glyph = decoded['selectedGlyph'];
      if (glyph is int && glyph >= 0 && glyph < glyphs.length) {
        selectedGlyph = glyph;
      }
      final best = decoded['bestScore'];
      if (best is int) bestScore = best;
      final drill = decoded['drillBest'];
      if (drill is int && drill >= 0) drillBest = drill;
      final finished = decoded['quizzesFinished'];
      if (finished is int) quizzesFinished = finished;
      final daily = decoded['dailyDone'];
      if (daily is bool) dailyDone = daily;
      final meters = decoded['useMeters'];
      if (meters is bool) useMeters = meters;
      final learned = decoded['learnedGlyphs'];
      if (learned is List) {
        learnedGlyphs
          ..clear()
          ..addAll(
            learned.whereType<int>().where(
              (index) => index >= 0 && index < glyphs.length,
            ),
          );
      }
      final lines = decoded['activity'];
      if (lines is List) {
        activity
          ..clear()
          ..addAll(lines.whereType<String>().take(40));
        if (activity.isEmpty) activity.add('Codex opened');
      }
    } catch (_) {}
  }

  void _save() {
    final store = vault;
    if (store == null) return;
    store.write(
      'codex.progress.v2',
      jsonEncode({
        'lessons': {
          for (final lesson in lessons)
            lesson.id: {
              'progress': lesson.progress,
              'bookmarked': lesson.bookmarked,
            },
        },
        'selectedGlyph': selectedGlyph,
        'bestScore': bestScore,
        'drillBest': drillBest,
        'quizzesFinished': quizzesFinished,
        'dailyDone': dailyDone,
        'learnedGlyphs': learnedGlyphs.toList(),
        'useMeters': useMeters,
        'activity': activity.take(40).toList(),
      }),
    );
  }
}
