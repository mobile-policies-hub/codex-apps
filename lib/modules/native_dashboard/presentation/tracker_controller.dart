import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:hybrid_app/modules/native_dashboard/data/local_vault.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_clips.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_deck.dart';

class Habit {
  Habit({
    required this.id,
    required this.title,
    this.done = false,
    this.reminder = '08:00',
    this.category = 'Mind',
    this.personalStreak = 0,
  });

  final String id;
  final String title;
  String reminder;
  final String category;
  int personalStreak;
  bool done;
}

enum AmbientSound { rain, forest, noise, bowl }

class TrackerController extends ChangeNotifier {
  TrackerController({DateTime? today, this.deck, this.vault, this.alarms})
    : today = _dateOnly(today ?? DateTime.now()) {
    deck?.addListener(_syncDeck);
    _restore();
    if (notificationsEnabled) _syncAlarms();
  }

  final SoundDeck? deck;
  final LocalVault? vault;
  final HabitAlarmScheduler? alarms;
  bool _persistGuard = false;

  int glasses = 0;
  String journal = '';
  static const focusChoices = [15, 25, 45];

  final DateTime today;
  final Map<String, int> _scoresByDay = {};
  int scoreGoal = 100;
  int waterGoal = 8;
  bool remindersEnabled = true;
  bool notificationsEnabled = true;
  int completedSessions = 0;
  int focusedMinutes = 0;
  int focusChoice = 25;
  int focusRemaining = 25 * 60;
  bool focusRunning = false;
  Timer? _focusTimer;
  int? moodIndex;
  bool quietHours = false;
  AmbientSound? ambient;
  bool ambientPlaying = false;
  int _nextHabit = 0;

  final List<String> sessions = [];

  final List<Habit> habits = [
    Habit(
      id: 'morning',
      title: 'Morning page',
      reminder: '07:30',
      category: 'Mind',
      personalStreak: 0,
    ),
    Habit(
      id: 'midday',
      title: 'Glass before noon',
      reminder: '11:40',
      category: 'Health',
      personalStreak: 0,
    ),
    Habit(
      id: 'walk',
      title: 'Short walk',
      reminder: '18:10',
      category: 'Health',
      personalStreak: 0,
    ),
    Habit(
      id: 'evening',
      title: 'Evening review',
      reminder: '21:30',
      category: 'Work',
      personalStreak: 0,
    ),
    Habit(
      id: 'stretch',
      title: 'Shoulder stretch',
      reminder: '08:15',
      category: 'Health',
      personalStreak: 0,
    ),
    Habit(
      id: 'pages',
      title: 'Page before sleep',
      reminder: '22:40',
      category: 'Mind',
      personalStreak: 0,
    ),
  ];

  static const moods = ['Clear', 'Steady', 'Quiet', 'Heavy', 'Empty'];
  static const habitCategories = ['Health', 'Work', 'Mind'];

  /// Habits are 70 points, finished focus blocks are 10 points each, up to 3.
  int get habitPoints {
    if (habits.isEmpty) return 0;
    return (completedHabits * 70) ~/ habits.length;
  }

  int get sessionPoints {
    final capped = completedSessions > 3 ? 3 : completedSessions;
    return capped * 10;
  }

  int get focusScore {
    final total = habitPoints + sessionPoints;
    return total > 100 ? 100 : total;
  }

  int get pointsRemaining {
    final remaining = scoreGoal - focusScore;
    return remaining > 0 ? remaining : 0;
  }

  bool get scoreGoalReached => focusScore >= scoreGoal;

  double get scoreProgress {
    if (scoreGoal <= 0) return 0;
    return focusScore / scoreGoal;
  }

  int get scorePercent {
    final percent = (scoreProgress * 100).round();
    if (percent < 0) return 0;
    if (percent > 100) return 100;
    return percent;
  }

  List<int> get weekScores {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List<int>.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      if (day == today) return focusScore;
      return _scoresByDay[_dayKey(day)] ?? 0;
    });
  }

  int get completedHabits => habits.where((habit) => habit.done).length;

  int get streakDays =>
      habits.map((habit) => habit.personalStreak).fold(0, (best, streak) => streak > best ? streak : best);

  List<int> get monthMarks {
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    return List<int>.generate(daysInMonth, (index) {
      final day = DateTime(today.year, today.month, index + 1);
      final score = day == today
          ? focusScore
          : (_scoresByDay[_dayKey(day)] ?? 0);
      if (score <= 0) return 0;
      return (1 + (score / 100 * 7)).round().clamp(1, 8);
    });
  }

  String get focusClock {
    final minutes = focusRemaining ~/ 60;
    final seconds = focusRemaining % 60;
    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');
    return '$minuteText:$secondText';
  }

  void setScoreGoal(int value) {
    final next = value.clamp(40, 100).toInt();
    if (next == scoreGoal) return;
    scoreGoal = next;
    notifyListeners();
  }

  void setJournal(String value) {
    final next = value.length > 280 ? value.substring(0, 280) : value;
    if (next == journal) return;
    journal = next;
    notifyListeners();
  }

  void drinkGlass() {
    if (glasses >= waterGoal) return;
    glasses += 1;
    notifyListeners();
  }

  void undoGlass() {
    if (glasses <= 0) return;
    glasses -= 1;
    notifyListeners();
  }

  void setWaterGoal(int value) {
    final next = value.clamp(1, 16).toInt();
    if (next == waterGoal) return;
    waterGoal = next;
    if (glasses > waterGoal) glasses = waterGoal;
    notifyListeners();
  }

  void setRemindersEnabled(bool value) {
    if (value == remindersEnabled) return;
    remindersEnabled = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    if (value == notificationsEnabled) return;
    notificationsEnabled = value;
    notifyListeners();
    _syncAlarms();
  }

  void toggleHabit(String id) {
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit == null) return;
    habit.done = !habit.done;
    if (habit.done) {
      habit.personalStreak += 1;
    } else if (habit.personalStreak > 0) {
      habit.personalStreak -= 1;
    }
    notifyListeners();
  }

  void setMood(int index) {
    if (index < 0 || index >= moods.length) return;
    moodIndex = moodIndex == index ? null : index;
    notifyListeners();
  }

  void setQuietHours(bool value) {
    if (value == quietHours) return;
    quietHours = value;
    notifyListeners();
  }

  void addHabit(String title, String category) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || !habitCategories.contains(category)) return;
    habits.add(
      Habit(
        id: 'custom-${_nextHabit++}',
        title: trimmed,
        category: category,
        reminder: '09:00',
        personalStreak: 0,
      ),
    );
    notifyListeners();
    if (notificationsEnabled) _syncAlarms();
  }

  void setHabitReminder(String id, String reminder) {
    final habit = habits.where((item) => item.id == id).firstOrNull;
    final parts = reminder.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (habit == null || hour == null || minute == null) return;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return;
    final text =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    if (habit.reminder == text) return;
    habit.reminder = text;
    notifyListeners();
    if (notificationsEnabled) _syncAlarms();
  }

  void selectAmbient(AmbientSound sound) {
    final changed = ambient != sound;
    ambient = sound;
    if (changed && ambientPlaying) {
      deck?.playLoop(_ambientId(sound), SoundClips.ambient(sound.name));
    }
    notifyListeners();
  }

  void toggleAmbient() {
    if (ambient == null) return;
    final sound = ambient!;
    if (ambientPlaying) {
      stopAmbient();
      return;
    }
    deck?.playLoop(_ambientId(sound), SoundClips.ambient(sound.name));
    ambientPlaying = true;
    notifyListeners();
  }

  /// Silences the bed. Safe to call when nothing is playing.
  void stopAmbient() {
    final playing =
        ambientPlaying || deck?.nowPlaying?.startsWith('ambient-') == true;
    if (!playing) return;
    deck?.stop();
    ambientPlaying = false;
    notifyListeners();
  }

  void _syncDeck() {
    final sound = ambient;
    final playing =
        sound != null &&
        deck?.looping == true &&
        deck?.nowPlaying == _ambientId(sound);
    if (playing == ambientPlaying) return;
    ambientPlaying = playing;
    notifyListeners();
  }

  void selectFocusMinutes(int minutes) {
    if (focusRunning || !focusChoices.contains(minutes)) return;
    focusChoice = minutes;
    focusRemaining = minutes * 60;
    notifyListeners();
  }

  /// Counts one finished focus block toward today's score.
  void recordFinishedFocusBlock() {
    focusRemaining = 0;
    focusRunning = false;
    _focusTimer?.cancel();
    completedSessions += 1;
    focusedMinutes += focusChoice;
    sessions.insert(0, 'Finished a $focusChoice min block');
    if (!quietHours) {
      deck?.playOnce('focus-done', SoundClips.focusDone());
    }
    notifyListeners();
  }

  void toggleFocus() {
    if (focusRunning) {
      _focusTimer?.cancel();
      focusRunning = false;
      sessions.insert(0, 'A $focusChoice min block was paused');
      notifyListeners();
      return;
    }
    if (focusRemaining == 0) {
      focusRemaining = focusChoice * 60;
    }
    focusRunning = true;
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (focusRemaining <= 1) {
        recordFinishedFocusBlock();
      } else {
        focusRemaining -= 1;
        notifyListeners();
      }
    });
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

  void _syncAlarms() {
    final scheduler = alarms;
    if (scheduler == null) return;
    if (notificationsEnabled) {
      unawaited(scheduler.sync(List<Habit>.from(habits)));
    } else {
      unawaited(scheduler.cancelAll());
    }
  }

  void _restore() {
    final raw = vault?.read('zenith.progress.v2');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final savedHabits = decoded['habits'];
      if (savedHabits is List) {
        for (final item in savedHabits) {
          if (item is! Map) continue;
          final id = item['id'];
          if (id is! String) continue;
          final existing = habits.where((habit) => habit.id == id).firstOrNull;
          if (existing != null) {
            final done = item['done'];
            if (done is bool) existing.done = done;
            final streak = item['streak'];
            if (streak is int) existing.personalStreak = streak;
            final clock = item['reminder'];
            if (clock is String && clock.contains(':')) {
              existing.reminder = clock;
            }
          } else {
            final title = item['title'];
            if (title is! String || title.trim().isEmpty) continue;
            habits.add(
              Habit(
                id: id,
                title: title,
                done: item['done'] == true,
                reminder: item['reminder'] is String
                    ? item['reminder'] as String
                    : '09:00',
                category: item['category'] is String
                    ? item['category'] as String
                    : 'Mind',
                personalStreak: item['streak'] is int
                    ? item['streak'] as int
                    : 0,
              ),
            );
          }
        }
      }
      if (decoded.containsKey('mood')) {
        final mood = decoded['mood'];
        moodIndex = mood is int && mood >= 0 && mood < moods.length
            ? mood
            : null;
      }
      final notifications = decoded['notificationsEnabled'];
      if (notifications is bool) notificationsEnabled = notifications;
      final reminders = decoded['remindersEnabled'];
      if (reminders is bool) remindersEnabled = reminders;
      final quiet = decoded['quietHours'];
      if (quiet is bool) quietHours = quiet;
      final water = decoded['waterGoal'];
      if (water is int) waterGoal = water.clamp(1, 16);
      var nextCustom = 0;
      for (final habit in habits) {
        if (!habit.id.startsWith('custom-')) continue;
        final number = int.tryParse(habit.id.substring('custom-'.length));
        if (number != null && number >= nextCustom) nextCustom = number + 1;
      }
      _nextHabit = nextCustom;
      final sessionsDone = decoded['completedSessions'];
      if (sessionsDone is int && sessionsDone >= 0) {
        completedSessions = sessionsDone;
      }
      final minutes = decoded['focusedMinutes'];
      if (minutes is int && minutes >= 0) focusedMinutes = minutes;
      final note = decoded['journal'];
      if (note is String) journal = note;
      final drunk = decoded['glasses'];
      if (drunk is int && drunk >= 0) glasses = drunk;
      final goal = decoded['scoreGoal'];
      if (goal is int) scoreGoal = goal.clamp(40, 100);
      final savedScores = decoded['scoresByDay'];
      if (savedScores is Map) {
        _scoresByDay
          ..clear()
          ..addAll({
            for (final entry in savedScores.entries)
              if (entry.key is String && entry.value is int)
                entry.key as String: entry.value as int,
          });
      }
    } catch (_) {}
  }

  void _save() {
    final store = vault;
    if (store == null) return;
    _scoresByDay[_dayKey(today)] = focusScore;
    store.write(
      'zenith.progress.v2',
      jsonEncode({
        'habits': [
          for (final habit in habits)
            {
              'id': habit.id,
              'title': habit.title,
              'done': habit.done,
              'reminder': habit.reminder,
              'category': habit.category,
              'streak': habit.personalStreak,
            },
        ],
        'mood': moodIndex,
        'notificationsEnabled': notificationsEnabled,
        'remindersEnabled': remindersEnabled,
        'quietHours': quietHours,
        'waterGoal': waterGoal,
        'completedSessions': completedSessions,
        'focusedMinutes': focusedMinutes,
        'scoreGoal': scoreGoal,
        'glasses': glasses,
        'journal': journal,
        'scoresByDay': _scoresByDay,
      }),
    );
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    deck?.removeListener(_syncDeck);
    if (deck?.nowPlaying?.startsWith('ambient-') == true) {
      deck?.stop();
    }
    super.dispose();
  }
}

/// Daily local reminders for habit clock times.
abstract class HabitAlarmScheduler {
  Future<void> sync(List<Habit> habits);

  Future<void> cancelAll();
}

class NoopHabitAlarms implements HabitAlarmScheduler {
  const NoopHabitAlarms();

  @override
  Future<void> sync(List<Habit> habits) async {}

  @override
  Future<void> cancelAll() async {}
}

String _ambientId(AmbientSound sound) => 'ambient-${sound.name}';

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _dayKey(DateTime day) {
  final date = _dateOnly(day);
  final month = date.month.toString().padLeft(2, '0');
  final dayOfMonth = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$dayOfMonth';
}
