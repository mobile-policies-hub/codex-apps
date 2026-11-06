import 'package:hybrid_app/core/config/app_brand_config.dart';

enum LegalDocument { privacy, terms }

String legalDocumentTitle(LegalDocument document) {
  return switch (document) {
    LegalDocument.privacy => 'Privacy Policy',
    LegalDocument.terms => 'Terms of Service',
  };
}

/// GitHub Pages site that hosts one public privacy page per app.
const privacyPolicySite = 'https://denischern.github.io/codex-apps';

/// Public HTTPS address for the App Store privacy field.
///
/// The same text is shown inside the app.
String privacyPolicyUrl(AppBrandConfig brand) {
  final slug = switch (brand.id) {
    AppBrandId.ancientCodex => 'ancient-codex',
    AppBrandId.zenithHabits => 'zenith-habits',
    AppBrandId.apexCalc => 'apex-calc',
  };
  return '$privacyPolicySite/$slug/privacy.html';
}

String termsOfServiceUrl(AppBrandConfig brand) {
  return privacyPolicyUrl(brand).replaceFirst('privacy.html', 'terms.html');
}

/// Local policy page for [brand], shown by the in-app web view.
String legalDocumentHtml(
  AppBrandConfig brand,
  LegalDocument document, {
  String language = 'en',
}) {
  final name = _escape(brand.appName);
  final email = _escape(brand.supportEmail);
  final copy = _legalCopy(language, document, name, email);
  final title = _escape(copy.$1);
  final publicLine = document == LegalDocument.privacy
      ? _publicPageLine(language, privacyPolicyUrl(brand))
      : '';
  return '''
<!DOCTYPE html>
<html lang="${_escape(language)}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <style>
    body { font-family: -apple-system, sans-serif; margin: 24px; line-height: 1.45; color: #1b2420; }
    h1 { font-size: 22px; }
  </style>
</head>
<body>
  <h1>$title</h1>
  <p><strong>$name</strong></p>
  ${copy.$2}
  $publicLine
</body>
</html>
''';
}

(String, String) _legalCopy(
  String language,
  LegalDocument document,
  String name,
  String email,
) {
  final pack = _legalPacks[language] ?? _legalPacks['en']!;
  return document == LegalDocument.privacy
      ? (pack.privacyTitle, pack.privacy(name, email))
      : (pack.termsTitle, pack.terms(name, email));
}

class _LegalPack {
  const _LegalPack({
    required this.privacyTitle,
    required this.termsTitle,
    required this.privacy,
    required this.terms,
  });

  final String privacyTitle;
  final String termsTitle;
  final String Function(String name, String email) privacy;
  final String Function(String name, String email) terms;
}

String _mail(String email) => '<a href="mailto:$email">$email</a>';

final _legalPacks = <String, _LegalPack>{
  'en': _LegalPack(
    privacyTitle: 'Privacy Policy',
    termsTitle: 'Terms of Service',
    privacy: (name, email) => '''
<p>Effective date: 6 November 2026.</p>
<p>This policy explains what $name does with information. The same text is shown in the app under Settings, Privacy Policy.</p>
<h2>Who we are</h2>
<p>$name is a utility you install from the App Store. Support is ${_mail(email)}. The app does not ask you to create an account.</p>
<h2>Information stored on this device</h2>
<p>$name stores lesson progress, habit checkmarks, reminders, journal notes, language choice, and calculation notes on this device. That information is not sent to us.</p>
<p>If you allow notifications, the app schedules them on this device at the clock times you choose. Turning notifications off cancels those alerts.</p>
<h2>Information we do not collect</h2>
<p>The app does not collect your name, contacts, photos, location, advertising identifier, or a usage profile. It does not use third-party analytics or advertising. On launch it does not request a remote configuration and does not open a remote page.</p>
<p>The app does not sell personal information and does not share it with data brokers.</p>
<h2>Calculator figures</h2>
<p>Currency figures in the calculator are sample rates for reference only. They are not a live market quote and are not fetched from a market service.</p>
<h2>Children</h2>
<p>$name is not directed at children under 13, and we do not knowingly collect personal information from children.</p>
<h2>How long information stays</h2>
<p>On-device records stay until you delete them in the app or delete the app. Deleting the app removes its local storage from the device.</p>
<h2>Changes</h2>
<p>If this policy changes, the updated text will be shown in Settings. The effective date will change with it.</p>
<h2>Contact</h2>
<p>Questions: ${_mail(email)}</p>
''',
    terms: (name, email) => '''
<p>Effective date: 6 November 2026.</p>
<p>$name is a local utility. Habit records, lesson progress, and calculator notes stay on this device.</p>
<p>Calculator results are illustrations. They are not financial, tax, or investment advice.</p>
<p>Lesson material is educational. It is not a certified course and does not grant an academic credential.</p>
<p>The app is provided as is, without a promise that every calculation or reminder will meet a particular purpose. If something looks wrong, write to ${_mail(email)}.</p>
<p>You may stop using the app at any time by deleting it. Local records are removed with the app.</p>
''',
  ),
  'ru': _LegalPack(
    privacyTitle: 'Политика конфиденциальности',
    termsTitle: 'Условия использования',
    privacy: (name, email) => '''
<p>Дата: 6 ноября 2026.</p>
<p>Здесь написано, что $name делает с информацией. Тот же текст открывается в приложении: Настройки, Политика конфиденциальности.</p>
<h2>Кто мы</h2>
<p>$name — утилита из App Store. Поддержка: ${_mail(email)}. Учётную запись создавать не нужно.</p>
<h2>Что хранится на этом устройстве</h2>
<p>$name хранит прогресс уроков, отметки привычек, напоминания, заметки дневника, выбранный язык и заметки к расчётам на этом устройстве. Эти сведения нам не отправляются.</p>
<p>Если разрешить уведомления, приложение ставит их на этом устройстве на выбранное время. Выключение уведомлений отменяет эти сигналы.</p>
<h2>Что мы не собираем</h2>
<p>Приложение не собирает имя, контакты, фото, геолокацию, рекламный идентификатор и профиль использования. Нет сторонней аналитики и рекламы. При запуске оно не запрашивает удалённую конфигурацию и не открывает удалённую страницу.</p>
<p>Приложение не продаёт личные сведения и не передаёт их брокерам данных.</p>
<h2>Цифры калькулятора</h2>
<p>Курсы в калькуляторе — образцы для ориентира. Это не живая рыночная котировка, и они не загружаются с рыночного сервиса.</p>
<h2>Дети</h2>
<p>$name не предназначено для детей младше 13 лет, и мы сознательно не собираем личные сведения детей.</p>
<h2>Как долго хранятся сведения</h2>
<p>Записи на устройстве остаются, пока вы не удалите их в приложении или не удалите само приложение. Удаление приложения стирает его локальное хранилище.</p>
<h2>Изменения</h2>
<p>Если политика изменится, новый текст будет показан в Настройках. Дата обновится вместе с ним.</p>
<h2>Контакт</h2>
<p>Вопросы: ${_mail(email)}</p>
''',
    terms: (name, email) => '''
<p>Дата: 6 ноября 2026.</p>
<p>$name — локальная утилита. Записи привычек, прогресс уроков и заметки калькулятора остаются на этом устройстве.</p>
<p>Результаты калькулятора — иллюстрации. Это не финансовая, налоговая или инвестиционная рекомендация.</p>
<p>Материал уроков учебный. Это не сертифицированный курс и не даёт учёной степени.</p>
<p>Приложение даётся как есть, без обещания, что каждый расчёт или каждый сигнал подойдёт для конкретной цели. Если что-то выглядит неверно, напишите на ${_mail(email)}.</p>
<p>Приложение можно перестать использовать в любой момент, удалив его. Локальные записи удаляются вместе с ним.</p>
''',
  ),
  'es': _LegalPack(
    privacyTitle: 'Política de privacidad',
    termsTitle: 'Condiciones de uso',
    privacy: (name, email) => '''
<p>Fecha: 6 de noviembre de 2026.</p>
<p>Esta política explica qué hace $name con la información. El mismo texto se abre en la app: Ajustes, Política de privacidad.</p>
<h2>Quiénes somos</h2>
<p>$name es una utilidad de la App Store. El soporte es ${_mail(email)}. La app no pide crear una cuenta.</p>
<h2>Información en este dispositivo</h2>
<p>$name guarda en este dispositivo el progreso de las lecciones, las marcas de hábitos, los recordatorios, las notas del diario, el idioma elegido y las notas de cálculo. Esa información no se nos envía.</p>
<p>Si permites avisos, la app los programa en este dispositivo a las horas que elijas. Apagar los avisos cancela esas alertas.</p>
<h2>Lo que no recogemos</h2>
<p>La app no recoge tu nombre, contactos, fotos, ubicación, identificador publicitario ni un perfil de uso. No usa analítica ni publicidad de terceros. Al abrirse no pide una configuración remota ni abre una página remota.</p>
<p>La app no vende información personal ni la comparte con intermediarios de datos.</p>
<h2>Cifras de la calculadora</h2>
<p>Los cambios de la calculadora son tasas de muestra, solo de referencia. No son una cotización de mercado en vivo y no se descargan de un servicio de mercado.</p>
<h2>Niños</h2>
<p>$name no está dirigida a menores de 13 años, y no recogemos a sabiendas información personal de niños.</p>
<h2>Cuánto tiempo permanece</h2>
<p>Los registros del dispositivo siguen hasta que los borres en la app o borres la app. Borrar la app quita su almacenamiento local.</p>
<h2>Cambios</h2>
<p>Si esta política cambia, el texto nuevo se mostrará en Ajustes. La fecha cambiará con él.</p>
<h2>Contacto</h2>
<p>Preguntas: ${_mail(email)}</p>
''',
    terms: (name, email) => '''
<p>Fecha: 6 de noviembre de 2026.</p>
<p>$name es una utilidad local. Los hábitos, el progreso de las lecciones y las notas de la calculadora se quedan en este dispositivo.</p>
<p>Los resultados de la calculadora son ilustraciones. No son asesoramiento financiero, fiscal ni de inversión.</p>
<p>El material de las lecciones es educativo. No es un curso certificado y no otorga un título.</p>
<p>La app se ofrece tal cual, sin prometer que cada cálculo o cada aviso sirva para un fin concreto. Si algo parece mal, escribe a ${_mail(email)}.</p>
<p>Puedes dejar de usarla en cualquier momento borrándola. Los registros locales se van con la app.</p>
''',
  ),
  'de': _LegalPack(
    privacyTitle: 'Datenschutz',
    termsTitle: 'Nutzungsbedingungen',
    privacy: (name, email) => '''
<p>Stand: 6. November 2026.</p>
<p>Hier steht, was $name mit Informationen macht. Derselbe Text steht in der App unter Einstellungen, Datenschutz.</p>
<h2>Wer wir sind</h2>
<p>$name ist ein Werkzeug aus dem App Store. Support: ${_mail(email)}. Ein Konto ist nicht nötig.</p>
<h2>Was auf diesem Gerät liegt</h2>
<p>$name speichert Lernstand, Häkchen bei Gewohnheiten, Erinnerungen, Tagebuchzeilen, die gewählte Sprache und Notizen zu Rechnungen auf diesem Gerät. Das wird nicht an uns geschickt.</p>
<p>Wenn du Hinweise erlaubst, legt die App sie auf diesem Gerät zu den Uhrzeiten an, die du wählst. Hinweise auszuschalten löscht diese Alarme.</p>
<h2>Was wir nicht sammeln</h2>
<p>Die App sammelt nicht deinen Namen, Kontakte, Fotos, Standort, Werbekennung oder ein Nutzungsprofil. Keine Analyse durch Dritte, keine Werbung. Beim Start fordert sie keine entfernte Konfiguration an und öffnet keine entfernte Seite.</p>
<p>Die App verkauft keine personenbezogenen Angaben und gibt sie nicht an Datenhändler weiter.</p>
<h2>Zahlen im Rechner</h2>
<p>Währungskurse im Rechner sind Muster und nur zur Orientierung. Sie sind kein live Marktpreis und werden nicht von einem Marktdienst geladen.</p>
<h2>Kinder</h2>
<p>$name richtet sich nicht an Kinder unter 13, und wir sammeln wissentlich keine Angaben von Kindern.</p>
<h2>Wie lange Angaben bleiben</h2>
<p>Einträge auf dem Gerät bleiben, bis du sie in der App löschst oder die App löschst. Das Löschen der App entfernt ihren lokalen Speicher.</p>
<h2>Änderungen</h2>
<p>Wenn sich diese Erklärung ändert, steht der neue Text in den Einstellungen. Das Datum ändert sich mit.</p>
<h2>Kontakt</h2>
<p>Fragen: ${_mail(email)}</p>
''',
    terms: (name, email) => '''
<p>Stand: 6. November 2026.</p>
<p>$name ist ein lokales Werkzeug. Gewohnheiten, Lernstand und Rechennotizen bleiben auf diesem Gerät.</p>
<p>Ergebnisse des Rechners sind Beispiele. Sie sind keine Finanz-, Steuer- oder Anlageberatung.</p>
<p>Der Lektionsstoff ist zur Bildung. Er ist kein zertifizierter Kurs und gibt keinen Abschluss.</p>
<p>Die App wird so bereitgestellt, wie sie ist, ohne Zusage, dass jede Rechnung oder jeder Hinweis einem bestimmten Zweck genügt. Wenn etwas falsch wirkt, schreib an ${_mail(email)}.</p>
<p>Du kannst die App jederzeit löschen und damit aufhören. Lokale Einträge gehen mit der App.</p>
''',
  ),
  'fr': _LegalPack(
    privacyTitle: 'Politique de confidentialité',
    termsTitle: "Conditions d'utilisation",
    privacy: (name, email) => '''
<p>Date : 6 novembre 2026.</p>
<p>Ce texte explique ce que $name fait des informations. Le même texte s'ouvre dans l'app : Réglages, Politique de confidentialité.</p>
<h2>Qui nous sommes</h2>
<p>$name est un utilitaire de l'App Store. L'assistance : ${_mail(email)}. L'app ne demande pas de compte.</p>
<h2>Ce qui reste sur cet appareil</h2>
<p>$name garde sur cet appareil la progression des leçons, les coches d'habitudes, les rappels, les notes du journal, la langue choisie et les notes de calcul. Ces informations ne nous sont pas envoyées.</p>
<p>Si tu autorises les alertes, l'app les programme sur cet appareil aux heures que tu choisis. Les couper annule ces alertes.</p>
<h2>Ce que nous ne collectons pas</h2>
<p>L'app ne collecte pas ton nom, tes contacts, tes photos, ta position, un identifiant publicitaire ni un profil d'usage. Pas d'analyse tierce, pas de publicité. Au lancement elle ne demande pas de configuration distante et n'ouvre pas de page distante.</p>
<p>L'app ne vend pas les informations personnelles et ne les partage pas avec des courtiers de données.</p>
<h2>Chiffres du calcul</h2>
<p>Les taux du calculateur sont des exemples, à titre indicatif. Ce n'est pas un cours de marché en direct et ils ne sont pas chargés depuis un service de marché.</p>
<h2>Enfants</h2>
<p>$name ne s'adresse pas aux enfants de moins de 13 ans, et nous ne collectons pas sciemment d'informations personnelles d'enfants.</p>
<h2>Durée</h2>
<p>Les enregistrements de l'appareil restent jusqu'à ce que tu les effaces dans l'app ou que tu supprimes l'app. Supprimer l'app retire son stockage local.</p>
<h2>Changements</h2>
<p>Si cette politique change, le nouveau texte sera affiché dans Réglages. La date changera avec lui.</p>
<h2>Contact</h2>
<p>Questions : ${_mail(email)}</p>
''',
    terms: (name, email) => '''
<p>Date : 6 novembre 2026.</p>
<p>$name est un utilitaire local. Habitudes, progression des leçons et notes de calcul restent sur cet appareil.</p>
<p>Les résultats du calculateur sont des illustrations. Ce n'est pas un conseil financier, fiscal ou d'investissement.</p>
<p>Le contenu des leçons est éducatif. Ce n'est pas un cours certifié et cela ne donne pas de diplôme.</p>
<p>L'app est fournie telle quelle, sans promesse que chaque calcul ou chaque rappel convienne à un but précis. Si quelque chose semble faux, écris à ${_mail(email)}.</p>
<p>Tu peux cesser de l'utiliser à tout moment en la supprimant. Les enregistrements locaux partent avec l'app.</p>
''',
  ),
};

String _publicPageLine(String language, String url) {
  final safe = _escape(url);
  final label = switch (language) {
    'ru' => 'Публичная страница',
    'es' => 'Página pública',
    'de' => 'Öffentliche Seite',
    'fr' => 'Page publique',
    _ => 'Public page',
  };
  return '<p>$label: <a href="$safe">$safe</a></p>';
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
