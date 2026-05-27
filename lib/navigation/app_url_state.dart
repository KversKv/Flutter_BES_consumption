import 'package:flutter/services.dart';

import '../models/profile_params.dart';
import '../state/app_state.dart';
import '../state/bt_state.dart';
import '../state/earbuds_state.dart';
import '../state/wifi_state.dart';

class AppUrlState {
  AppUrlState._();

  static const pagePaths = ['/ble', '/bt', '/earbuds', '/wifi'];

  static int pageIndexFromPath(String path) {
    return switch (path) {
      '/' || '/ble' => 0,
      '/bt' => 1,
      '/earbuds' => 2,
      '/wifi' => 3,
      _ => 0,
    };
  }

  static String pathForPage(int index) {
    if (index < 0 || index >= pagePaths.length) return pagePaths.first;
    return pagePaths[index];
  }

  static Uri uriForPage(int index) => Uri(path: pathForPage(index));

  static Uri uriForBle(AppState state) {
    return Uri(
      path: '/ble',
      queryParameters: {
        'chip': state.selectedChipId,
        'mode': state.params.mode.name,
      },
    );
  }

  static Uri uriForBt(BTState state) {
    return Uri(
      path: '/bt',
      queryParameters: {
        'case': state.caseType.name,
        'chip': state.selectedChipId,
      },
    );
  }

  static Uri uriForEarbuds(EarbudsState state) {
    final query = <String, String>{
      'tab': _earbudsTabSlug(state.tabIndex),
    };
    if (state.selectedIds.isNotEmpty) {
      query['chips'] = state.selectedIds.join(',');
    }
    final focus = state.focusedChipId;
    if (focus != null) {
      query['focus'] = focus;
    }
    return Uri(path: '/earbuds', queryParameters: query);
  }

  static Uri uriForWifi(WIFIState state) {
    return Uri(
      path: '/wifi',
      queryParameters: {
        'case': state.caseType.name,
        'chip': state.selectedChipId,
        'band': state.band,
      },
    );
  }

  static void applyBle(AppState state, Uri uri) {
    final chip = uri.queryParameters['chip'];
    if (chip != null && state.chips.any((c) => c.id == chip)) {
      state.setChip(chip);
    }

    final mode = _enumByName(Mode.values, uri.queryParameters['mode']);
    if (mode != null) {
      state.setMode(mode);
    }
  }

  static void applyBt(BTState state, Uri uri) {
    final caseType = _enumByName(BTCase.values, uri.queryParameters['case']);
    if (caseType != null) {
      state.setCase(caseType);
    }

    final chip = uri.queryParameters['chip'];
    if (chip != null &&
        (state.btChips.any((c) => c.id == chip) ||
            state.bleChips.any((c) => c.id == chip))) {
      state.setChip(chip);
    }
  }

  static void applyEarbuds(EarbudsState state, Uri uri) {
    final tab = _earbudsTabIndex(uri.queryParameters['tab']);
    if (tab != null) {
      state.setTabIndex(tab);
    }

    final chips = uri.queryParameters['chips']
        ?.split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (chips != null) {
      final validIds = state.allChips.map((c) => c.id).toSet();
      state.clearSelection();
      for (final id in chips) {
        if (validIds.contains(id)) {
          state.toggleSelected(id);
        }
      }
    }

    final focus = uri.queryParameters['focus'];
    if (focus != null && state.allChips.any((c) => c.id == focus)) {
      state.setFocusedChip(focus);
    }
  }

  static void applyWifi(WIFIState state, Uri uri) {
    final caseType = _enumByName(SniffCase.values, uri.queryParameters['case']);
    if (caseType != null) {
      state.setCase(caseType);
    }

    final chip = uri.queryParameters['chip'];
    if (chip != null && state.wifiChips.any((c) => c.id == chip)) {
      state.setChip(chip);
    }

    final band = uri.queryParameters['band'];
    if (band == '2.4G' || band == '5G') {
      state.setBand(band!);
    }
  }

  static void replaceBrowserUrl(Uri uri) {
    SystemNavigator.routeInformationUpdated(uri: uri, replace: true);
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static String _earbudsTabSlug(int index) {
    return switch (index) {
      0 => 'scene',
      1 => 'bt',
      2 => 'cpu',
      3 => 'tx',
      4 => 'rx',
      5 => 'pa',
      _ => 'scene',
    };
  }

  static int? _earbudsTabIndex(String? slug) {
    return switch (slug) {
      'scene' => 0,
      'bt' => 1,
      'cpu' => 2,
      'tx' => 3,
      'rx' => 4,
      'pa' => 5,
      _ => null,
    };
  }
}
