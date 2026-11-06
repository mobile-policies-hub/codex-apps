import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/modules/native_dashboard/presentation/legal_document.dart';
import 'package:hybrid_app/modules/web_container/presentation/external_url_launcher.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_container_screen.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_notification_service.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_soft_prompt.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/ancient_codex_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_calc_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/premium_surface.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerController>();
    final brand = AppBrand.of(context);
    final scheme = Theme.of(context).colorScheme;
    return BrandBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(context.tr('Settings')),
          leading: IconButton(
            key: const Key('close-settings'),
            tooltip: context.tr('Back'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _LanguageSettings(),
                const SizedBox(height: 22),
                if (brand.id == AppBrandId.zenithHabits) ...[
                  const _SectionLabel('Goals'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('Daily score goal'),
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${tracker.scoreGoal}',
                              key: const Key('step-goal-value'),
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          key: const Key('step-goal-slider'),
                          min: 40,
                          max: 100,
                          divisions: 12,
                          value: tracker.scoreGoal.toDouble(),
                          label: '${tracker.scoreGoal}',
                          onChanged: (value) =>
                              tracker.setScoreGoal(value.round()),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('Glasses of water'),
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('water-goal-decrease'),
                              tooltip: context.tr('Less'),
                              onPressed: tracker.waterGoal > 1
                                  ? () => tracker.setWaterGoal(
                                      tracker.waterGoal - 1,
                                    )
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text(
                              '${tracker.waterGoal}',
                              key: const Key('water-goal-value'),
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              key: const Key('water-goal-increase'),
                              tooltip: context.tr('More'),
                              onPressed: tracker.waterGoal < 16
                                  ? () => tracker.setWaterGoal(
                                      tracker.waterGoal + 1,
                                    )
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (brand.id != AppBrandId.zenithHabits) ...[
                  const _SectionLabel('Units'),
                  const SizedBox(height: 8),
                  if (brand.id == AppBrandId.ancientCodex)
                    _SettingsCard(child: const _AncientUnits()),
                  if (brand.id == AppBrandId.apexCalc)
                    _SettingsCard(child: const _ApexUnits()),
                  const SizedBox(height: 22),
                ],
                if (brand.id == AppBrandId.zenithHabits) ...[
                  const _SectionLabel('Reminders'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: SwitchListTile(
                      key: const Key('reminders-switch'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('Home hint')),
                      subtitle: Text(
                        context.tr('How much is left toward the daily goal'),
                      ),
                      value: tracker.remindersEnabled,
                      onChanged: tracker.setRemindersEnabled,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (brand.id == AppBrandId.zenithHabits) ...[
                  const _SectionLabel('Notifications'),
                  const SizedBox(height: 8),
                  _SettingsCard(child: _NotificationSettings(tracker: tracker)),
                  const SizedBox(height: 22),
                ],
                const _SectionLabel('About'),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.appName,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('Version 1.0.0'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('Data stays on this device'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('privacy-policy'),
                          onPressed: () => _openLegalDocument(
                            context,
                            LegalDocument.privacy,
                          ),
                          child: Text(context.tr('Privacy Policy')),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('terms-of-service'),
                          onPressed: () =>
                              _openLegalDocument(context, LegalDocument.terms),
                          child: Text(context.tr('Terms of Service')),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('support-email'),
                          onPressed: () {
                            unawaited(
                              launchExternalApplication(
                                Uri(
                                  scheme: 'mailto',
                                  path: brand.supportEmail,
                                  queryParameters: {
                                    'subject': '${brand.appName} support',
                                  },
                                ),
                              ),
                            );
                          },
                          child: Text(
                            '${context.tr('Support Email')} · ${brand.supportEmail}',
                          ),
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
    );
  }
}

void _openLegalDocument(BuildContext context, LegalDocument document) {
  final brand = AppBrand.of(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => WebContainerScreen(
        targetUrl: Uri.parse('about:blank'),
        documentHtml: legalDocumentHtml(
          brand,
          document,
          language: AppText.maybeOf(context)?.code ?? 'en',
        ),
        title: context.tr(legalDocumentTitle(document)),
      ),
    ),
  );
}

class _NotificationSettings extends StatelessWidget {
  const _NotificationSettings({required this.tracker});

  final TrackerController tracker;

  @override
  Widget build(BuildContext context) {
    final push = PushNotificationService.maybeOf(context);
    return Column(
      children: [
        SwitchListTile(
          key: const Key('notifications-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('Notifications')),
          subtitle: Text(context.tr('Daily alerts at each habit time')),
          value: tracker.notificationsEnabled,
          onChanged: (value) {
            if (!value || push == null) {
              tracker.setNotificationsEnabled(value);
              return;
            }
            unawaited(_enableNotifications(context, tracker, push));
          },
        ),
        if (push != null && !kReleaseMode)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('send-test-notification'),
              onPressed: push.showTestNotification,
              child: Text(context.tr('Send a test alert')),
            ),
          ),
      ],
    );
  }
}

Future<void> _enableNotifications(
  BuildContext context,
  TrackerController tracker,
  PushNotificationService push,
) async {
  if (push.permission != PushPermission.granted) {
    final agreed = await showNotificationSoftPrompt(context);
    if (!context.mounted || !agreed) return;
    final granted = await push.requestPermission();
    if (!context.mounted) return;
    tracker.setNotificationsEnabled(granted);
    return;
  }
  tracker.setNotificationsEnabled(true);
}

class _AncientUnits extends StatelessWidget {
  const _AncientUnits();

  @override
  Widget build(BuildContext context) {
    final codex = context.watch<AncientCodexController>();
    final brand = AppBrand.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Length units'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          key: const Key('unit-selector'),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: brand.primaryColor,
            selectedForegroundColor: brand.backgroundColor,
          ),
          segments: [
            ButtonSegment(value: true, label: Text(context.tr('Meters'))),
            ButtonSegment(value: false, label: Text(context.tr('Cubits'))),
          ],
          selected: {codex.useMeters},
          onSelectionChanged: (value) => codex.setUseMeters(value.first),
        ),
      ],
    );
  }
}

class _ApexUnits extends StatelessWidget {
  const _ApexUnits();

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<ApexCalcController>();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ledger currency',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        DropdownButton<String>(
          key: const Key('apex-unit'),
          isExpanded: true,
          value: calc.preferredCurrency,
          dropdownColor: scheme.surface,
          style: TextStyle(color: scheme.onSurface, fontSize: 16),
          items: [
            for (final code in ApexCalcController.currencies)
              DropdownMenuItem(value: code, child: Text(code)),
          ],
          onChanged: (value) {
            if (value != null) calc.setPreferredCurrency(value);
          },
        ),
      ],
    );
  }
}

class _LanguageSettings extends StatelessWidget {
  const _LanguageSettings();

  @override
  Widget build(BuildContext context) {
    final text = AppText.maybeOf(context);
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Language'),
        const SizedBox(height: 8),
        _SettingsCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in AppText.options)
                ChoiceChip(
                  key: Key('language-${option.$1}'),
                  label: Text(option.$2),
                  selected: text.code == option.$1,
                  selectedColor: scheme.primary.withValues(alpha: 0.22),
                  onSelected: (_) => text.select(option.$1),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(text),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    return Material(
      color: brand.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x14FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: child,
      ),
    );
  }
}
