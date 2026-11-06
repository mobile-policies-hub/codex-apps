import 'package:hybrid_app/core/config/app_brand_config.dart';

enum LegalDocument { privacy, terms }

String legalDocumentTitle(LegalDocument document) {
  return switch (document) {
    LegalDocument.privacy => 'Privacy Policy',
    LegalDocument.terms => 'Terms of Service',
  };
}

/// GitHub Pages site that hosts one public privacy page per app.
const privacyPolicySite = 'https://mobile-policies-hub.github.io/codex-apps';

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
  final copy = _legalCopy(brand.id, language, document, name, email);
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

enum _Product { lessons, habits, calculator }

(String, String) _legalCopy(
  AppBrandId id,
  String language,
  LegalDocument document,
  String name,
  String email,
) {
  final product = switch (id) {
    AppBrandId.ancientCodex => _Product.lessons,
    AppBrandId.zenithHabits => _Product.habits,
    AppBrandId.apexCalc => _Product.calculator,
  };
  final code = switch (language) {
    'ru' || 'es' || 'de' || 'fr' => language,
    _ => 'en',
  };
  final titles = _titles[code]!;
  final body = document == LegalDocument.privacy
      ? _privacy(code, product, name, email)
      : _terms(code, product, name, email);
  final title = document == LegalDocument.privacy ? titles.$1 : titles.$2;
  return (title, body);
}

const _titles = <String, (String, String)>{
  'en': ('Privacy Policy', 'Terms of Service'),
  'ru': ('Политика конфиденциальности', 'Условия использования'),
  'es': ('Política de privacidad', 'Condiciones de uso'),
  'de': ('Datenschutz', 'Nutzungsbedingungen'),
  'fr': ('Politique de confidentialité', "Conditions d'utilisation"),
};

String _privacy(String code, _Product product, String name, String email) {
  final mail = _mail(email);
  return switch (code) {
    'ru' => _privacyRu(product, name, mail),
    'es' => _privacyEs(product, name, mail),
    'de' => _privacyDe(product, name, mail),
    'fr' => _privacyFr(product, name, mail),
    _ => _privacyEn(product, name, mail),
  };
}

String _terms(String code, _Product product, String name, String email) {
  final mail = _mail(email);
  return switch (code) {
    'ru' => _termsRu(product, name, mail),
    'es' => _termsEs(product, name, mail),
    'de' => _termsDe(product, name, mail),
    'fr' => _termsFr(product, name, mail),
    _ => _termsEn(product, name, mail),
  };
}

String _privacyEn(_Product product, String name, String mail) {
  final stored = switch (product) {
    _Product.lessons =>
      '$name stores lesson progress, quiz results, bookmarks, and your language choice on this device. That information is not sent to us.',
    _Product.habits =>
      '$name stores habit checkmarks, reminder times, the water count, journal notes, and your language choice on this device. That information is not sent to us.',
    _Product.calculator =>
      '$name stores the numbers you enter, saved notes, and your language choice on this device. That information is not sent to us.',
  };
  final extra = switch (product) {
    _Product.habits =>
      '<p>If you allow notifications, the app schedules them on this device at the clock times you choose. Turning notifications off cancels those alerts.</p>',
    _Product.calculator =>
      '<h2>Calculator figures</h2><p>Currency figures in the calculator are sample rates for reference only. They are not a live market quote and are not fetched from a market service.</p>',
    _Product.lessons => '',
  };
  return '''
<p>Effective date: 6 November 2026.</p>
<p>This policy explains what $name does with information. The same text is shown in the app under Settings, Privacy Policy.</p>
<h2>Who we are</h2>
<p>$name is a utility you install from the App Store. Support is $mail. The app does not ask you to create an account.</p>
<h2>Information stored on this device</h2>
<p>$stored</p>
$extra
<h2>Information we do not collect</h2>
<p>The app does not collect your name, contacts, photos, location, advertising identifier, or a usage profile. It does not use third-party analytics or advertising. On launch it does not request a remote configuration and does not open a remote page.</p>
<p>The app does not sell personal information and does not share it with data brokers.</p>
<h2>Children</h2>
<p>$name is not directed at children under 13, and we do not knowingly collect personal information from children.</p>
<h2>How long information stays</h2>
<p>On-device records stay until you delete them in the app or delete the app. Deleting the app removes its local storage from the device.</p>
<h2>Changes</h2>
<p>If this policy changes, the updated text will be shown in Settings. The effective date will change with it.</p>
<h2>Contact</h2>
<p>Questions: $mail</p>
''';
}

String _termsEn(_Product product, String name, String mail) {
  final body = switch (product) {
    _Product.lessons => '''
<p>$name is a local lesson app. Lesson progress stays on this device.</p>
<p>Lesson material is educational. It is not a certified course and does not grant an academic credential.</p>
<p>The app is provided as is. If something looks wrong, write to $mail.</p>
''',
    _Product.habits => '''
<p>$name is a local habit tracker. Habit records, journal notes, and reminder times stay on this device.</p>
<p>It is a personal checklist. It is not medical advice.</p>
<p>The app is provided as is. If something looks wrong, write to $mail.</p>
''',
    _Product.calculator => '''
<p>$name is a local calculator. The numbers you enter and your notes stay on this device.</p>
<p>Calculator results are illustrations. They are not financial, tax, or investment advice.</p>
<p>The app is provided as is, without a promise that every calculation will meet a particular purpose. If something looks wrong, write to $mail.</p>
''',
  };
  return '''
<p>Effective date: 6 November 2026.</p>
$body
<p>You may stop using the app at any time by deleting it. Local records are removed with the app.</p>
''';
}

String _privacyRu(_Product product, String name, String mail) {
  final stored = switch (product) {
    _Product.lessons =>
      '$name хранит на этом устройстве прогресс уроков, результаты квиза, закладки и выбранный язык. Эти сведения нам не отправляются.',
    _Product.habits =>
      '$name хранит на этом устройстве отметки привычек, время напоминаний, счёт воды, заметки дневника и выбранный язык. Эти сведения нам не отправляются.',
    _Product.calculator =>
      '$name хранит на этом устройстве введённые числа, сохранённые заметки и выбранный язык. Эти сведения нам не отправляются.',
  };
  final extra = switch (product) {
    _Product.habits =>
      '<p>Если разрешить уведомления, приложение ставит их на этом устройстве на выбранное время. Выключение уведомлений отменяет эти сигналы.</p>',
    _Product.calculator =>
      '<h2>Цифры калькулятора</h2><p>Курсы в калькуляторе — образцы для ориентира. Это не живая рыночная котировка, и они не загружаются с рыночного сервиса.</p>',
    _Product.lessons => '',
  };
  return '''
<p>Дата: 6 ноября 2026.</p>
<p>Здесь написано, что $name делает с информацией. Тот же текст открывается в приложении: Настройки, Политика конфиденциальности.</p>
<h2>Кто мы</h2>
<p>$name — утилита из App Store. Поддержка: $mail. Учётную запись создавать не нужно.</p>
<h2>Что хранится на этом устройстве</h2>
<p>$stored</p>
$extra
<h2>Что мы не собираем</h2>
<p>Приложение не собирает имя, контакты, фото, геолокацию, рекламный идентификатор и профиль использования. Нет сторонней аналитики и рекламы. При запуске оно не запрашивает удалённую конфигурацию и не открывает удалённую страницу.</p>
<p>Приложение не продаёт личные сведения и не передаёт их брокерам данных.</p>
<h2>Дети</h2>
<p>$name не предназначено для детей младше 13 лет, и мы сознательно не собираем личные сведения детей.</p>
<h2>Как долго хранятся сведения</h2>
<p>Записи на устройстве остаются, пока вы не удалите их в приложении или не удалите само приложение. Удаление приложения стирает его локальное хранилище.</p>
<h2>Изменения</h2>
<p>Если политика изменится, новый текст будет показан в Настройках. Дата обновится вместе с ним.</p>
<h2>Контакт</h2>
<p>Вопросы: $mail</p>
''';
}

String _termsRu(_Product product, String name, String mail) {
  final body = switch (product) {
    _Product.lessons => '''
<p>$name — локальное приложение с уроками. Прогресс уроков остаётся на этом устройстве.</p>
<p>Материал уроков учебный. Это не сертифицированный курс и не даёт учёной степени.</p>
<p>Приложение даётся как есть. Если что-то выглядит неверно, напишите на $mail.</p>
''',
    _Product.habits => '''
<p>$name — локальный трекер привычек. Отметки, заметки дневника и время напоминаний остаются на этом устройстве.</p>
<p>Это личный список дел. Это не медицинская рекомендация.</p>
<p>Приложение даётся как есть. Если что-то выглядит неверно, напишите на $mail.</p>
''',
    _Product.calculator => '''
<p>$name — локальный калькулятор. Введённые числа и заметки остаются на этом устройстве.</p>
<p>Результаты калькулятора — иллюстрации. Это не финансовая, налоговая или инвестиционная рекомендация.</p>
<p>Приложение даётся как есть, без обещания, что каждый расчёт подойдёт для конкретной цели. Если что-то выглядит неверно, напишите на $mail.</p>
''',
  };
  return '''
<p>Дата: 6 ноября 2026.</p>
$body
<p>Приложение можно перестать использовать в любой момент, удалив его. Локальные записи удаляются вместе с ним.</p>
''';
}

String _privacyEs(_Product product, String name, String mail) {
  final stored = switch (product) {
    _Product.lessons =>
      '$name guarda en este dispositivo el progreso de las lecciones, los resultados del cuestionario, los marcadores y el idioma elegido. Esa información no se nos envía.',
    _Product.habits =>
      '$name guarda en este dispositivo las marcas de hábitos, las horas de los recordatorios, el recuento de agua, las notas del diario y el idioma elegido. Esa información no se nos envía.',
    _Product.calculator =>
      '$name guarda en este dispositivo los números que escribes, las notas guardadas y el idioma elegido. Esa información no se nos envía.',
  };
  final extra = switch (product) {
    _Product.habits =>
      '<p>Si permites avisos, la app los programa en este dispositivo a las horas que elijas. Apagar los avisos cancela esas alertas.</p>',
    _Product.calculator =>
      '<h2>Cifras de la calculadora</h2><p>Las cifras de moneda de la calculadora son tasas de muestra, solo de referencia. No son una cotización de mercado en vivo y no se descargan de un servicio de mercado.</p>',
    _Product.lessons => '',
  };
  return '''
<p>Fecha: 6 de noviembre de 2026.</p>
<p>Esta política explica qué hace $name con la información. El mismo texto se abre en la app: Ajustes, Política de privacidad.</p>
<h2>Quiénes somos</h2>
<p>$name es una utilidad de la App Store. El soporte es $mail. La app no pide crear una cuenta.</p>
<h2>Información en este dispositivo</h2>
<p>$stored</p>
$extra
<h2>Lo que no recogemos</h2>
<p>La app no recoge tu nombre, contactos, fotos, ubicación, identificador publicitario ni un perfil de uso. No usa analítica ni publicidad de terceros. Al abrirse no pide una configuración remota ni abre una página remota.</p>
<p>La app no vende información personal ni la comparte con intermediarios de datos.</p>
<h2>Niños</h2>
<p>$name no está dirigida a menores de 13 años, y no recogemos a sabiendas información personal de niños.</p>
<h2>Cuánto tiempo permanece</h2>
<p>Los registros del dispositivo siguen hasta que los borres en la app o borres la app. Borrar la app quita su almacenamiento local.</p>
<h2>Cambios</h2>
<p>Si esta política cambia, el texto nuevo se mostrará en Ajustes. La fecha cambiará con él.</p>
<h2>Contacto</h2>
<p>Preguntas: $mail</p>
''';
}

String _termsEs(_Product product, String name, String mail) {
  final body = switch (product) {
    _Product.lessons => '''
<p>$name es una app local de lecciones. El progreso de las lecciones se queda en este dispositivo.</p>
<p>El material de las lecciones es educativo. No es un curso certificado y no otorga un título.</p>
<p>La app se ofrece tal cual. Si algo parece mal, escribe a $mail.</p>
''',
    _Product.habits => '''
<p>$name es un registro local de hábitos. Las marcas, las notas del diario y las horas de los recordatorios se quedan en este dispositivo.</p>
<p>Es una lista personal. No es consejo médico.</p>
<p>La app se ofrece tal cual. Si algo parece mal, escribe a $mail.</p>
''',
    _Product.calculator => '''
<p>$name es una calculadora local. Los números que escribes y tus notas se quedan en este dispositivo.</p>
<p>Los resultados de la calculadora son ilustraciones. No son asesoramiento financiero, fiscal ni de inversión.</p>
<p>La app se ofrece tal cual, sin prometer que cada cálculo sirva para un fin concreto. Si algo parece mal, escribe a $mail.</p>
''',
  };
  return '''
<p>Fecha: 6 de noviembre de 2026.</p>
$body
<p>Puedes dejar de usarla en cualquier momento borrándola. Los registros locales se van con la app.</p>
''';
}

String _privacyDe(_Product product, String name, String mail) {
  final stored = switch (product) {
    _Product.lessons =>
      '$name speichert auf diesem Gerät den Lernstand, Quizergebnisse, Merker und die gewählte Sprache. Das wird nicht an uns geschickt.',
    _Product.habits =>
      '$name speichert auf diesem Gerät Häkchen bei Gewohnheiten, Erinnerungszeiten, den Wasserzähler, Tagebuchzeilen und die gewählte Sprache. Das wird nicht an uns geschickt.',
    _Product.calculator =>
      '$name speichert auf diesem Gerät die eingegebenen Zahlen, gespeicherte Notizen und die gewählte Sprache. Das wird nicht an uns geschickt.',
  };
  final extra = switch (product) {
    _Product.habits =>
      '<p>Wenn du Hinweise erlaubst, legt die App sie auf diesem Gerät zu den Uhrzeiten an, die du wählst. Hinweise auszuschalten löscht diese Alarme.</p>',
    _Product.calculator =>
      '<h2>Zahlen im Rechner</h2><p>Währungskurse im Rechner sind Muster und nur zur Orientierung. Sie sind kein live Marktpreis und werden nicht von einem Marktdienst geladen.</p>',
    _Product.lessons => '',
  };
  return '''
<p>Stand: 6. November 2026.</p>
<p>Hier steht, was $name mit Informationen macht. Derselbe Text steht in der App unter Einstellungen, Datenschutz.</p>
<h2>Wer wir sind</h2>
<p>$name ist ein Werkzeug aus dem App Store. Support: $mail. Ein Konto ist nicht nötig.</p>
<h2>Was auf diesem Gerät liegt</h2>
<p>$stored</p>
$extra
<h2>Was wir nicht sammeln</h2>
<p>Die App sammelt nicht deinen Namen, Kontakte, Fotos, Standort, Werbekennung oder ein Nutzungsprofil. Keine Analyse durch Dritte, keine Werbung. Beim Start fordert sie keine entfernte Konfiguration an und öffnet keine entfernte Seite.</p>
<p>Die App verkauft keine personenbezogenen Angaben und gibt sie nicht an Datenhändler weiter.</p>
<h2>Kinder</h2>
<p>$name richtet sich nicht an Kinder unter 13, und wir sammeln wissentlich keine Angaben von Kindern.</p>
<h2>Wie lange Angaben bleiben</h2>
<p>Einträge auf dem Gerät bleiben, bis du sie in der App löschst oder die App löschst. Das Löschen der App entfernt ihren lokalen Speicher.</p>
<h2>Änderungen</h2>
<p>Wenn sich diese Erklärung ändert, steht der neue Text in den Einstellungen. Das Datum ändert sich mit.</p>
<h2>Kontakt</h2>
<p>Fragen: $mail</p>
''';
}

String _termsDe(_Product product, String name, String mail) {
  final body = switch (product) {
    _Product.lessons => '''
<p>$name ist eine lokale Lektions-App. Der Lernstand bleibt auf diesem Gerät.</p>
<p>Der Lektionsstoff ist zur Bildung. Er ist kein zertifizierter Kurs und gibt keinen Abschluss.</p>
<p>Die App wird so bereitgestellt, wie sie ist. Wenn etwas falsch wirkt, schreib an $mail.</p>
''',
    _Product.habits => '''
<p>$name ist ein lokaler Gewohnheitstracker. Häkchen, Tagebuchzeilen und Erinnerungszeiten bleiben auf diesem Gerät.</p>
<p>Es ist eine persönliche Liste. Es ist kein medizinischer Rat.</p>
<p>Die App wird so bereitgestellt, wie sie ist. Wenn etwas falsch wirkt, schreib an $mail.</p>
''',
    _Product.calculator => '''
<p>$name ist ein lokaler Rechner. Eingegebene Zahlen und Notizen bleiben auf diesem Gerät.</p>
<p>Ergebnisse des Rechners sind Beispiele. Sie sind keine Finanz-, Steuer- oder Anlageberatung.</p>
<p>Die App wird so bereitgestellt, wie sie ist, ohne Zusage, dass jede Rechnung einem bestimmten Zweck genügt. Wenn etwas falsch wirkt, schreib an $mail.</p>
''',
  };
  return '''
<p>Stand: 6. November 2026.</p>
$body
<p>Du kannst die App jederzeit löschen und damit aufhören. Lokale Einträge gehen mit der App.</p>
''';
}

String _privacyFr(_Product product, String name, String mail) {
  final stored = switch (product) {
    _Product.lessons =>
      "$name garde sur cet appareil la progression des leçons, les résultats du quiz, les signets et la langue choisie. Ces informations ne nous sont pas envoyées.",
    _Product.habits =>
      "$name garde sur cet appareil les coches d'habitudes, les heures des rappels, le compte d'eau, les notes du journal et la langue choisie. Ces informations ne nous sont pas envoyées.",
    _Product.calculator =>
      "$name garde sur cet appareil les nombres saisis, les notes enregistrées et la langue choisie. Ces informations ne nous sont pas envoyées.",
  };
  final extra = switch (product) {
    _Product.habits =>
      "<p>Si tu autorises les alertes, l'app les programme sur cet appareil aux heures que tu choisis. Les couper annule ces alertes.</p>",
    _Product.calculator =>
      "<h2>Chiffres du calcul</h2><p>Les taux du calculateur sont des exemples, à titre indicatif. Ce n'est pas un cours de marché en direct et ils ne sont pas chargés depuis un service de marché.</p>",
    _Product.lessons => '',
  };
  return '''
<p>Date : 6 novembre 2026.</p>
<p>Ce texte explique ce que $name fait des informations. Le même texte s'ouvre dans l'app : Réglages, Politique de confidentialité.</p>
<h2>Qui nous sommes</h2>
<p>$name est un utilitaire de l'App Store. L'assistance : $mail. L'app ne demande pas de compte.</p>
<h2>Ce qui reste sur cet appareil</h2>
<p>$stored</p>
$extra
<h2>Ce que nous ne collectons pas</h2>
<p>L'app ne collecte pas ton nom, tes contacts, tes photos, ta position, un identifiant publicitaire ni un profil d'usage. Pas d'analyse tierce, pas de publicité. Au lancement elle ne demande pas de configuration distante et n'ouvre pas de page distante.</p>
<p>L'app ne vend pas les informations personnelles et ne les partage pas avec des courtiers de données.</p>
<h2>Enfants</h2>
<p>$name ne s'adresse pas aux enfants de moins de 13 ans, et nous ne collectons pas sciemment d'informations personnelles d'enfants.</p>
<h2>Durée</h2>
<p>Les enregistrements de l'appareil restent jusqu'à ce que tu les effaces dans l'app ou que tu supprimes l'app. Supprimer l'app retire son stockage local.</p>
<h2>Changements</h2>
<p>Si cette politique change, le nouveau texte sera affiché dans Réglages. La date changera avec lui.</p>
<h2>Contact</h2>
<p>Questions : $mail</p>
''';
}

String _termsFr(_Product product, String name, String mail) {
  final body = switch (product) {
    _Product.lessons => '''
<p>$name est une app locale de leçons. La progression des leçons reste sur cet appareil.</p>
<p>Le contenu des leçons est éducatif. Ce n'est pas un cours certifié et cela ne donne pas de diplôme.</p>
<p>L'app est fournie telle quelle. Si quelque chose semble faux, écris à $mail.</p>
''',
    _Product.habits => '''
<p>$name est un suivi local d'habitudes. Les coches, les notes du journal et les heures des rappels restent sur cet appareil.</p>
<p>C'est une liste personnelle. Ce n'est pas un avis médical.</p>
<p>L'app est fournie telle quelle. Si quelque chose semble faux, écris à $mail.</p>
''',
    _Product.calculator => '''
<p>$name est un calculateur local. Les nombres saisis et tes notes restent sur cet appareil.</p>
<p>Les résultats du calculateur sont des illustrations. Ce n'est pas un conseil financier, fiscal ou d'investissement.</p>
<p>L'app est fournie telle quelle, sans promesse que chaque calcul convienne à un but précis. Si quelque chose semble faux, écris à $mail.</p>
''',
  };
  return '''
<p>Date : 6 novembre 2026.</p>
$body
<p>Tu peux cesser de l'utiliser à tout moment en la supprimant. Les enregistrements locaux partent avec l'app.</p>
''';
}

String _mail(String email) => '<a href="mailto:$email">$email</a>';

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
