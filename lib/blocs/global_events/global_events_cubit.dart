import 'dart:developer';

import 'package:fukatsongs/core/constants/setting_keys.dart';
import 'package:fukatsongs/services/bloomee_updater_tools.dart';
import 'package:fukatsongs/services/db/dao/settings_dao.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'global_events_state.dart';

class GlobalEventsCubit extends Cubit<GlobalEventsState> {
  final SettingsDAO _settingsDao;

  GlobalEventsCubit({required SettingsDAO settingsDao})
      : _settingsDao = settingsDao,
        super(GlobalEventsInitial()) {
    checkForUpdates();
  }

  void checkForUpdates() async {
    final Map<String, dynamic> updates = await getAppUpdates();
    log("Checking for updates...", name: 'GlobalEventsCubit');

    if (updates['changelogs'] != null) {
      emit(WhatIsNewState(changeLogs: updates['changelogs']));
    }

    if (await _settingsDao.getSettingBool(SettingKeys.autoUpdateNotify) ??
        true) {
      if (updates["results"]) {
        emit(UpdateAvailable(
          newVersion: updates["newVer"],
          newBuild: updates["newBuild"],
          downloadUrl: "https://FukatMusic.sourceforge.io/",
        ));
      }
    }
  }

  void showAlertDialog(String title, String content) {
    emit(AlertDialogState(title: title, content: content));
  }
}
