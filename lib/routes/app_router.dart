import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fukatsongs/core/constants/route_paths.dart';
import 'package:fukatsongs/screens/widgets/global_footer.dart';
import 'package:fukatsongs/screens/screen/common_views/add_to_playlist_screen.dart';
import 'package:fukatsongs/screens/screen/explore_screen.dart';
import 'package:fukatsongs/screens/screen/library_screen.dart';
import 'package:fukatsongs/screens/screen/library_views/import_media_view.dart';
import 'package:fukatsongs/screens/screen/library_views/import_process_screen.dart';
import 'package:fukatsongs/screens/screen/library_views/playlist_screen.dart';
import 'package:fukatsongs/screens/screen/offline_screen.dart';
import 'package:fukatsongs/screens/screen/search_screen.dart';
import 'package:fukatsongs/screens/screen/chart/chart_view.dart';
import 'package:fukatsongs/screens/screen/gatekeeper_screen.dart';
import 'package:fukatsongs/services/connectivity_service.dart';

/// Refreshes router redirects when connectivity changes.
class ConnectivityRefreshNotifier extends ChangeNotifier {
  ConnectivityRefreshNotifier() {
    _sub = ConnectivityService.instance.onStatusChanged.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<bool> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Canonical app router configuration.
class AppRouter {
  static final globalRouterKey = GlobalKey<NavigatorState>();

  /// Stable keys, ordered to match the bottom-navigation tabs:
  /// Home, Library, Search, Offline.
  static final branchNavigatorKeys = <GlobalKey<NavigatorState>>[
    GlobalKey<NavigatorState>(debugLabel: 'homeBranch'),
    GlobalKey<NavigatorState>(debugLabel: 'libraryBranch'),
    GlobalKey<NavigatorState>(debugLabel: 'searchBranch'),
    GlobalKey<NavigatorState>(debugLabel: 'offlineBranch'),
  ];

  static final globalRouter = GoRouter(
    initialLocation: '/Gatekeeper',
    navigatorKey: globalRouterKey,
    refreshListenable: ConnectivityRefreshNotifier(),
    redirect: (context, state) async {
      // Preserve the existing development gate behaviour.
      const isUnlocked = true;
      const isBanned = false;

      if (isBanned) {
        return '/Gatekeeper';
      }

      if (!isUnlocked && state.uri.path != '/Gatekeeper') {
        return '/Gatekeeper';
      }

      if (isUnlocked && state.uri.path == '/Gatekeeper') {
        final hasInternet =
            await ConnectivityService.instance.ensureChecked();

        return hasInternet ? '/Explore' : '/Offline';
      }

      // Offline is a user-selectable page, not only a connection fallback.
      // Do not redirect away when internet is available or reconnects.
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
        builder: (context, state, navigationShell) => GlobalFooter(
          navigationShell: navigationShell,
          branchNavigatorKeys: branchNavigatorKeys,
        ),
        branches: [
          // Home
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[0],
            routes: [
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
                    },
                  ),
                ],
              ),
            ],
          ),

          // Library
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[1],
            routes: [
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
                ],
              ),
            ],
          ),

          // Search
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[2],
            routes: [
              GoRoute(
                name: RoutePaths.searchScreen,
                path: '/Search',
                builder: (context, state) {
                  final query = state.uri.queryParameters['query'];

                  if (query != null) {
                    return SearchScreen(searchQuery: query);
                  }

                  return const SearchScreen();
                },
              ),
            ],
          ),

          // Offline
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[3],
            routes: [
              GoRoute(
                name: RoutePaths.offlineScreen,
                path: '/Offline',
                builder: (context, state) => const OfflineScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Backward-compatible alias.
typedef GlobalRoutes = AppRouter;