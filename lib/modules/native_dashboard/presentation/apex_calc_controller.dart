import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:hybrid_app/modules/native_dashboard/data/local_vault.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_clips.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_deck.dart';

class CalcNote {
  CalcNote({required this.id, required this.title, required this.note});

  final int id;
  final String title;
  String note;
}

enum MeasureKind { money, length, mass, share }

class YearSlice {
  const YearSlice({required this.year, required this.interest});

  final int year;
  final int interest;
}

class ApexCalcController extends ChangeNotifier {
  ApexCalcController({this.deck, this.vault}) {
    _restore();
  }

  final SoundDeck? deck;
  final LocalVault? vault;
  bool _persistGuard = false;
  static const currencies = ['USD', 'EUR', 'GBP', 'JPY', 'RUB'];
  static const lengthUnits = ['m', 'km', 'ft', 'in'];
  static const massUnits = ['kg', 'g', 'lb', 'oz'];
  static const _perDollar = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.78,
    'JPY': 149.0,
    'RUB': 92.0,
  };
  static const _meters = {'m': 1.0, 'km': 1000.0, 'ft': 0.3048, 'in': 0.0254};
  static const _kilograms = {
    'kg': 1.0,
    'g': 0.001,
    'lb': 0.45359237,
    'oz': 0.0283495,
  };

  double amount = 10000;
  double rate = 12;
  double years = 3;
  double inflation = 4;
  double convertAmount = 100;
  String fromCurrency = 'USD';
  String toCurrency = 'EUR';
  String fromLength = 'm';
  String toLength = 'ft';
  String fromMass = 'kg';
  String toMass = 'lb';
  String preferredCurrency = 'USD';
  MeasureKind measure = MeasureKind.money;
  double sharePercent = 12;
  String? activePreset;
  final List<CalcNote> history = [];
  int _nextNoteId = 0;

  double get compounded => amount * math.pow(1 + rate / 100, years).toDouble();

  double get afterInflation =>
      compounded / math.pow(1 + inflation / 100, years).toDouble();

  int get interestEarned => (compounded - amount).round();

  double get monthlyPayment {
    final months = (years * 12).round().clamp(1, 360);
    final monthlyRate = rate / 100 / 12;
    if (monthlyRate == 0) return amount / months;
    final growth = math.pow(1 + monthlyRate, months);
    return amount * monthlyRate * growth / (growth - 1);
  }

  int get loanInterest {
    final months = (years * 12).round().clamp(1, 360);
    return (monthlyPayment * months - amount).round();
  }

  int get monthlySetAside {
    final months = (years * 12).round().clamp(1, 360);
    return (amount / months).round();
  }

  double get converted {
    final dollars = convertAmount / _perDollar[fromCurrency]!;
    return dollars * _perDollar[toCurrency]!;
  }

  String get readout {
    final value = switch (measure) {
      MeasureKind.money => converted,
      MeasureKind.length => _span(convertAmount, fromLength, toLength, _meters),
      MeasureKind.mass => _span(convertAmount, fromMass, toMass, _kilograms),
      MeasureKind.share => convertAmount * sharePercent / 100,
    };
    return value.toStringAsFixed(2);
  }

  String get resultUnit {
    return switch (measure) {
      MeasureKind.money => toCurrency,
      MeasureKind.length => toLength,
      MeasureKind.mass => toMass,
      MeasureKind.share => 'of the amount',
    };
  }

  String get sourceUnit {
    return switch (measure) {
      MeasureKind.money => fromCurrency,
      MeasureKind.length => fromLength,
      MeasureKind.mass => fromMass,
      MeasureKind.share => 'amount',
    };
  }

  String get conversionCaption {
    return switch (measure) {
      MeasureKind.money =>
        '1 $fromCurrency = ${_fx(1, fromCurrency, toCurrency).toStringAsFixed(2)} $toCurrency',
      MeasureKind.length =>
        '1 $fromLength = ${_span(1, fromLength, toLength, _meters).toStringAsFixed(2)} $toLength',
      MeasureKind.mass =>
        '1 $fromMass = ${_span(1, fromMass, toMass, _kilograms).toStringAsFixed(2)} $toMass',
      MeasureKind.share =>
        '${sharePercent.round()}% of ${convertAmount.round()}',
    };
  }

  List<YearSlice> get slices {
    final count = years.round().clamp(1, 6);
    var balance = amount;
    return [
      for (var year = 1; year <= count; year++)
        () {
          final next = balance * (1 + rate / 100);
          final interest = (next - balance).round();
          balance = next;
          return YearSlice(year: year, interest: interest);
        }(),
    ];
  }

  int get plusOnePoint {
    final bumped = amount * math.pow(1 + (rate + 1) / 100, years).toDouble();
    return bumped.round();
  }

  void setAmount(double value) {
    amount = value.clamp(1000, 100000).toDouble();
    activePreset = null;
    notifyListeners();
  }

  void setRate(double value) {
    rate = value.clamp(0, 30).toDouble();
    activePreset = null;
    notifyListeners();
  }

  void setYears(double value) {
    years = value.clamp(1, 30).toDouble();
    activePreset = null;
    notifyListeners();
  }

  void setInflation(double value) {
    inflation = value.clamp(0, 20).toDouble();
    activePreset = null;
    notifyListeners();
  }

  void setConvertAmount(double value) {
    convertAmount = value.clamp(1, 1000000).toDouble();
    notifyListeners();
  }

  void setFromCurrency(String value) {
    if (!currencies.contains(value) || value == fromCurrency) return;
    fromCurrency = value;
    notifyListeners();
  }

  void setToCurrency(String value) {
    if (!currencies.contains(value) || value == toCurrency) return;
    toCurrency = value;
    notifyListeners();
  }

  void setMeasure(MeasureKind value) {
    if (value == measure) return;
    measure = value;
    notifyListeners();
  }

  void setFromLength(String value) {
    if (!_meters.containsKey(value) || value == fromLength) return;
    fromLength = value;
    notifyListeners();
  }

  void setToLength(String value) {
    if (!_meters.containsKey(value) || value == toLength) return;
    toLength = value;
    notifyListeners();
  }

  void setFromMass(String value) {
    if (!_kilograms.containsKey(value) || value == fromMass) return;
    fromMass = value;
    notifyListeners();
  }

  void setToMass(String value) {
    if (!_kilograms.containsKey(value) || value == toMass) return;
    toMass = value;
    notifyListeners();
  }

  void setSharePercent(double value) {
    sharePercent = value.clamp(1, 100).toDouble();
    notifyListeners();
  }

  void swapCurrencies() {
    switch (measure) {
      case MeasureKind.money:
        final next = fromCurrency;
        fromCurrency = toCurrency;
        toCurrency = next;
      case MeasureKind.length:
        final next = fromLength;
        fromLength = toLength;
        toLength = next;
      case MeasureKind.mass:
        final next = fromMass;
        fromMass = toMass;
        toMass = next;
      case MeasureKind.share:
        sharePercent = (100 - sharePercent).clamp(1, 99).toDouble();
    }
    notifyListeners();
  }

  void applyPreset(String id) {
    switch (id) {
      case 'mortgage':
        amount = 80000;
        rate = 8;
        years = 20;
        inflation = 4;
      case 'deposit':
        amount = 10000;
        rate = 12;
        years = 3;
        inflation = 4;
      case 'stake':
        amount = 5000;
        rate = 18;
        years = 2;
        inflation = 6;
      case 'car':
        amount = 25000;
        rate = 10;
        years = 4;
        inflation = 5;
      default:
        return;
    }
    activePreset = id;
    deck?.playOnce('preset-$id', SoundClips.preset(id));
    notifyListeners();
  }

  double _fx(double amount, String from, String to) {
    final dollars = amount / _perDollar[from]!;
    return dollars * _perDollar[to]!;
  }

  double _span(
    double amount,
    String from,
    String to,
    Map<String, double> towardBase,
  ) {
    return amount * towardBase[from]! / towardBase[to]!;
  }

  void saveSnapshot() {
    saveNote('Snapshot at ${rate.round()} pp over ${years.round()} years');
  }

  void setPreferredCurrency(String value) {
    if (!currencies.contains(value) || value == preferredCurrency) return;
    preferredCurrency = value;
    notifyListeners();
  }

  void saveNote(String note) {
    final trimmed = note.trim();
    if (trimmed.isEmpty) return;
    history.insert(
      0,
      CalcNote(
        id: _nextNoteId++,
        title: 'Interest · ${compounded.round()}',
        note: trimmed,
      ),
    );
    notifyListeners();
  }

  void deleteNote(int id) {
    final before = history.length;
    history.removeWhere((note) => note.id == id);
    if (history.length == before) return;
    notifyListeners();
  }

  void updateNote(int index, String note) {
    if (index < 0 || index >= history.length) return;
    history[index].note = note;
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
    final raw = vault?.read('apex.progress.v3');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final notes = decoded['history'];
      if (notes is List) {
        history.clear();
        for (final item in notes) {
          if (item is! Map) continue;
          final id = item['id'];
          final title = item['title'];
          final note = item['note'];
          if (id is! int || title is! String || note is! String) continue;
          history.add(CalcNote(id: id, title: title, note: note));
        }
        final next = decoded['nextId'];
        _nextNoteId = next is int
            ? next
            : history.fold<int>(0, (maxId, note) {
                return note.id >= maxId ? note.id + 1 : maxId;
              });
      }
      final from = decoded['fromCurrency'];
      if (from is String && currencies.contains(from)) fromCurrency = from;
      final to = decoded['toCurrency'];
      if (to is String && currencies.contains(to)) toCurrency = to;
      final amountValue = decoded['convertAmount'];
      if (amountValue is num) {
        convertAmount = amountValue.toDouble().clamp(1, 1000000);
      }
      final principal = decoded['amount'];
      if (principal is num) amount = principal.toDouble().clamp(1000, 100000);
      final savedRate = decoded['rate'];
      if (savedRate is num) rate = savedRate.toDouble().clamp(0, 30);
      final savedYears = decoded['years'];
      if (savedYears is num) years = savedYears.toDouble().clamp(1, 30);
      final savedInflation = decoded['inflation'];
      if (savedInflation is num) {
        inflation = savedInflation.toDouble().clamp(0, 20);
      }
      final ledger = decoded['preferredCurrency'];
      if (ledger is String && currencies.contains(ledger)) {
        preferredCurrency = ledger;
      }
    } catch (_) {}
  }

  void _save() {
    final store = vault;
    if (store == null) return;
    store.write(
      'apex.progress.v3',
      jsonEncode({
        'history': [
          for (final note in history)
            {'id': note.id, 'title': note.title, 'note': note.note},
        ],
        'nextId': _nextNoteId,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'convertAmount': convertAmount,
        'amount': amount,
        'rate': rate,
        'years': years,
        'inflation': inflation,
        'preferredCurrency': preferredCurrency,
      }),
    );
  }
}
