import 'package:fukatsongs/blocs/player_overlay/player_overlay_cubit.dart';
import 'package:fukatsongs/screens/widgets/player_overlay_wrapper.dart';
import 'package:fukatsongs/screens/widgets/mini_player_widget.dart';
import 'package:fukatsongs/core/theme/app_theme.dart';
import 'package:fukatsongs/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GlobalFooter extends StatefulWidget {
  const GlobalFooter({
    super.key,
    required this.navigationShell,
    required this.branchNavigatorKeys,
  });

  final StatefulNavigationShell navigationShell;
  final List<GlobalKey<NavigatorState>> branchNavigatorKeys;

  @override
  State<GlobalFooter> createState() => _GlobalFooterState();
}

class _GlobalFooterState extends State<GlobalFooter> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  /// Three taps on the same tab, with at most 450 ms between adjacent taps.
  static const _maxTapGap = Duration(milliseconds: 450);

  final Stopwatch _tapClock = Stopwatch()..start();

  Duration? _lastTabTap;
  int? _lastTappedTab;
  int _consecutiveTabTaps = 0;

  void _onTabSelected(int index) {
    final now = _tapClock.elapsed;
    final last = _lastTabTap;

    final continuesSequence = _lastTappedTab == index &&
        last != null &&
        now - last <= _maxTapGap;

    _consecutiveTabTaps =
        continuesSequence ? _consecutiveTabTaps + 1 : 1;
    _lastTappedTab = index;
    _lastTabTap = now;

    if (_consecutiveTabTaps < 3) {
      // Normal taps restore the tab's remembered navigation stack.
      navigationShell.goBranch(index);
      return;
    }

    // The third tap resets the sequence.
    _consecutiveTabTaps = 0;
    _lastTappedTab = null;
    _lastTabTap = null;

    // Clear imperative routes such as Settings → nested Settings pages.
    // Only the selected tab's stack is affected.
    widget.branchNavigatorKeys[index].currentState?.popUntil(
      (route) => route.isFirst,
    );

    // Reset the selected branch's declarative route to its initial page.
    navigationShell.goBranch(index, initialLocation: true);
  }

  @override
  void dispose() {
    _tapClock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PlayerOverlayCubit>();
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return PlayerOverlayWrapper(
      child: BackButtonListener(
        // Preserve the existing hardware-back priority:
        // 1. Navigator routes
        // 2. UpNext panel
        // 3. Player overlay
        // 4. Shell tab navigation
        // 5. System exit
        onBackButtonPressed: () async {
          final overlayC = context.read<PlayerOverlayCubit>();
          final router = GoRouter.of(context);

          if (router.canPop()) {
            router.pop();
            return true;
          }

          if (overlayC.state && overlayC.collapseUpNextPanel()) {
            return true;
          }

          if (overlayC.state) {
            overlayC.hidePlayer();
            return true;
          }

          // Let PopScope handle tab/exit navigation below.
          return false;
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleHardwareBackPress(context);
          },
          child: Scaffold(
            backgroundColor: Default_Theme.themeColor,
            drawerScrimColor: Default_Theme.themeColor,
            body: isMobile
                ? _AnimatedPageView(navigationShell: navigationShell)
                : Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: VerticalNavBar(
                          navigationShell: navigationShell,
                          onTabSelected: _onTabSelected,
                        ),
                      ),
                      Expanded(
                        child: _AnimatedPageView(
                          navigationShell: navigationShell,
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayerWidget(),
                  if (isMobile)
                    Container(
                      color: Colors.transparent,
                      margin: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      child: HorizontalNavBar(
                        navigationShell: navigationShell,
                        onTabSelected: _onTabSelected,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles PopScope back presses using the existing priority order.
  Future<void> _handleHardwareBackPress(BuildContext context) async {
    final overlayC = context.read<PlayerOverlayCubit>();
    final router = GoRouter.of(context);

    // 1. Navigator routes first.
    if (router.canPop()) {
      router.pop();
      return;
    }

    // 2. Collapse UpNext panel.
    if (overlayC.state && overlayC.collapseUpNextPanel()) return;

    // 3. Hide player.
    if (overlayC.state) {
      overlayC.hidePlayer();
      return;
    }

    // 4. Navigate to Home.
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return;
    }

    // 5. Exit app.
    if (context.mounted) {
      await SystemNavigator.pop();
    }
  }
}

class _AnimatedPageView extends StatefulWidget {
  const _AnimatedPageView({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<_AnimatedPageView> createState() => _AnimatedPageViewState();
}

class _AnimatedPageViewState extends State<_AnimatedPageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();

    _previousIndex = widget.navigationShell.currentIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(_AnimatedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.navigationShell.currentIndex != _previousIndex) {
      _previousIndex = widget.navigationShell.currentIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.navigationShell,
      ),
    );
  }
}

class VerticalNavBar extends StatelessWidget {
  const VerticalNavBar({
    super.key,
    required this.navigationShell,
    required this.onTabSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationRail(
      backgroundColor: Default_Theme.themeColor.withValues(alpha: 0.3),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(MingCute.home_4_fill),
          label: Text(l10n.navHome),
        ),
        NavigationRailDestination(
          icon: const Icon(MingCute.book_5_fill),
          label: Text(l10n.navLibrary),
        ),
        NavigationRailDestination(
          icon: const Icon(MingCute.search_2_fill),
          label: Text(l10n.navSearch),
        ),
        NavigationRailDestination(
          icon: const Icon(MingCute.folder_download_fill),
          label: Text(l10n.navOffline),
        ),
      ],
      selectedIndex: navigationShell.currentIndex,
      minWidth: 70,
      onDestinationSelected: onTabSelected,
      groupAlignment: 0.0,
      unselectedIconTheme: const IconThemeData(
        color: Default_Theme.primaryColor2,
      ),
      indicatorColor: Default_Theme.accentColor2,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
    );
  }
}

class HorizontalNavBar extends StatelessWidget {
  const HorizontalNavBar({
    super.key,
    required this.navigationShell,
    required this.onTabSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTabSelected;

  @override
  @override
  Widget build(BuildContext context) {
    return GNav(

      // google_nav_bar ignores taps during its animation duration.
      // Disable that lockout so rapid triple taps reach our handler.
      // The page fade/scale animation above is unchanged.
      duration: Duration.zero,
      gap: 7.0,
      tabBackgroundColor:
          Default_Theme.accentColor2.withValues(alpha: 0.22),
      color: Default_Theme.primaryColor2,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      activeColor: Default_Theme.accentColor2,
      textStyle: Default_Theme.secondoryTextStyleMedium.merge(
        const TextStyle(
          color: Default_Theme.accentColor2,
          fontSize: 18,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      backgroundColor: Default_Theme.themeColor.withValues(alpha: 0.3),
      tabs: const [
        GButton(icon: MingCute.home_4_fill),
        GButton(icon: MingCute.book_5_fill),
        GButton(icon: MingCute.search_2_fill),
        GButton(icon: MingCute.folder_download_fill),
      ],
      selectedIndex: navigationShell.currentIndex,
      onTabChange: onTabSelected,
    );
  }
}