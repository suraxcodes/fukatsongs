import 'dart:async';
import 'dart:developer';

import 'package:fukatsongs/core/constants/setting_keys.dart';
import 'package:fukatsongs/core/di/service_locator.dart';
import 'package:fukatsongs/services/db/dao/settings_dao.dart';
import 'package:fukatsongs/services/local_music_service.dart';
import 'package:fukatsongs/services/plugin_bootstrap_service.dart';
import 'package:fukatsongs/services/onboarding_service.dart';
import 'package:fukatsongs/src/rust/frb_generated.dart';
import 'package:fukatsongs/services/db/db_provider.dart';
import 'package:path_provider/path_provider.dart';

/// Application bootstrap — run once before [runApp].
///
/// Responsibilities:
/// - Initialize platform path constants.
/// - Open the Isar database via [DBProvider].
/// - Schedule periodic DB maintenance tasks.
/// - Wire the [ServiceLocator] and initialize the plugin system.
Future<void> bootstrapApp() async {
  // Initialize flutter_rust_bridge before any Rust API call.
  try {
    await RustLib.init();
  } catch (e, stack) {
    log('Failed to initialize RustLib (Rust backend missing)', error: e, stackTrace: stack, name: 'Bootstrap');
  }

  final String appDocPath = (await getApplicationDocumentsDirectory()).path;
  final String appSuppPath = (await getApplicationSupportDirectory()).path;

  // Open DB and schedule maintenance.
  await DBProvider.init(
      appSupportPath: appSuppPath, appDocumentsPath: appDocPath);
  DBProvider.scheduleMaintenance();

  // DI wiring (registers singletons).
  await ServiceLocator.setup();

  // Ensure hosted repositories are persisted in settings (idempotent).
  // Missing URLs are added, existing ones are left untouched.
  unawaited(
    PluginBootstrapService.ensureHostedRepositoriesPresent(
      repositoryService: ServiceLocator.pluginRepositoryService,
    ).catchError((e) {
      log('Hosted repository reconciliation skipped',
          error: e, name: 'Bootstrap');
    })
  );

  // Initialize plugin system:
  //   Creates Rust PluginManager → connects event bus →
  //   preloads storage from Isar → starts storage event handler.
  try {
    unawaited(
      ServiceLocator.initializePluginSystem().then((_) {
        log('Plugin system initialized successfully', name: 'Bootstrap');
      }).catchError((e, stack) {
        log('Plugin system initialization failed (non-fatal)',
            error: e, stackTrace: stack, name: 'Bootstrap');
      })
    );
  } catch (e, stack) {
    log('Failed to schedule plugin initialization', error: e, name: 'Bootstrap');
  }

  // Auto-scan local music folders if enabled (fire-and-forget).
  try {
    final settingsDao = SettingsDAO(DBProvider.db);
    final autoScan =
        await settingsDao.getSettingBool(SettingKeys.localMusicAutoScan) ??
            true;
    if (autoScan) {
      unawaited(LocalMusicService.create().scanAndPersist());
    }
  } catch (e) {
    log('Local music auto-scan skipped', error: e, name: 'Bootstrap');
  }

  // Pre-load the plugin-bootstrap done-flag so that _MyAppState can check
  // it synchronously in initState() without an async call.
  try {
    final settingsDao = SettingsDAO(DBProvider.db);
    await OnboardingService.checkAndCacheDone(settingsDao);
    await PluginBootstrapService.checkAndCacheDone(settingsDao);
  } catch (e) {
    log('Could not load bootstrap flag (will re-run bootstrap)',
        error: e, name: 'Bootstrap');
  }
}
