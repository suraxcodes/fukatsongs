import 'package:fukatsongs/core/constants/route_paths.dart';
import 'package:fukatsongs/screens/widgets/global_footer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fukatsongs/screens/screen/common_views/add_to_playlist_screen.dart';
import 'package:fukatsongs/screens/screen/explore_screen.dart';
import 'package:fukatsongs/screens/screen/library_screen.dart';
import 'package:fukatsongs/screens/screen/library_views/import_media_view.dart';
import 'package:fukatsongs/screens/screen/library_views/import_process_screen.dart';
import 'package:fukatsongs/screens/screen/library_views/playlist_screen.dart';
import 'package:fukatsongs/screens/screen/offline_screen.dart';
import 'package:fukatsongs/screens/screen/local_music_screen.dart';
import 'package:fukatsongs/screens/screen/search_screen.dart';
import 'package:fukatsongs/screens/screen/chart/chart_view.dart';
import 'package:fukatsongs/screens/screen/gatekeeper_screen.dart';
import 'package:fukatsongs/services/db/dao/settings_dao.dart';
import 'package:fukatsongs/services/db/db_provider.dart';

/// Canonical app router configuration.
///
/// Use [AppRouter] in new code. The [GlobalRoutes] typedef at the bottom
/// provides backward-compatible access for existing callers.
class AppRouter {
  static final globalRouterKey = GlobalKey<NavigatorState>();

  static final globalRouter = GoRouter(
    initialLocation: '/Gatekeeper',
    navigatorKey: globalRouterKey,
    redirect: (context, state) async {
      final settingsDao = SettingsDAO(DBProvider.db);
      final isUnlocked = await settingsDao.getSettingBool('is_unlocked', defaultValue: false) ?? false;
      final isBanned = await settingsDao.getSettingBool('is_banned', defaultValue: false) ?? false;
      
      if (isBanned) {
        return '/Gatekeeper';
      }
      
      if (!isUnlocked && state.uri.path != '/Gatekeeper') {
        return '/Gatekeeper';
      }
      
      if (isUnlocked && state.uri.path == '/Gatekeeper') {
        return '/Explore';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/Gatekeeper',
        builder: (context, state) => const GatekeeperScreen(),
      ),
      GoRoute(
        path: '/AddToPlaylist',
        parentNavigatorKey: globalRouterKey,
        name: RoutePaths.addToPlaylistScreen,
        builder: (context, state) => const AddToPlaylistScreen(),
      ),
      StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              GlobalFooter(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  name: RoutePaths.exploreScreen,
                  path: '/Explore',
                  builder: (context, state) => const ExploreScreen(),
                  routes: [
                    GoRoute(
                        name: RoutePaths.chartScreen,
                        path: 'ChartScreen',
                        builder: (context, state) {
                          final qp = state.uri.queryParameters;
                          return ChartScreen(
                            pluginId: qp['pluginId'] ?? '',
                            chartId: qp['chartId'] ?? '',
                            chartTitle: qp['chartTitle'] ?? 'Chart',
                          );
                        }),
                  ])
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  name: RoutePaths.libraryScreen,
                  path: '/Library',
                  builder: (context, state) => const LibraryScreen(),
                  routes: [
                    GoRoute(
                      path: RoutePaths.importMediaFromPlatforms,
                      name: RoutePaths.importMediaFromPlatforms,
                      builder: (context, state) =>
                          const ImportMediaFromPlatformsView(),
                    ),
                    GoRoute(
                      path: RoutePaths.importProcess,
                      name: RoutePaths.importProcess,
                      builder: (context, state) {
                        final pluginId =
                            state.uri.queryParameters['pluginId'] ?? '';
                        return ImportProcessScreen(pluginId: pluginId);
                      },
                    ),
                    GoRoute(
                      name: RoutePaths.playlistView,
                      path: RoutePaths.playlistView,
                      builder: (context, state) {
                        final initialPlaylistName = state.extra as String?;
                        return PlaylistView(
                          initialPlaylistName: initialPlaylistName,
                        );
                      },
                    ),
                  ]),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                name: RoutePaths.searchScreen,
                path: '/Search',
                builder: (context, state) {
                  if (state.uri.queryParameters['query'] != null) {
                    return SearchScreen(
                      searchQuery:
                          state.uri.queryParameters['query']!.toString(),
                    );
                  } else {
                    return const SearchScreen();
                  }
                },
              ),
            ]),

            StatefulShellBranch(routes: [
              GoRoute(
                name: RoutePaths.offlineScreen,
                path: '/Offline',
                builder: (context, state) => const OfflineScreen(),
              ),
            ]),
          ])
    ],
  );
}

/// Backward-compat alias for [AppRouter].
/// Prefer importing from [routes/app_router.dart] and using [AppRouter] directly.
typedef GlobalRoutes = AppRouter;
