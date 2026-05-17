import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/presentation/home_screen.dart';
import '../search/presentation/search_screen.dart';
import '../library/presentation/library_screen.dart';
import '../library/presentation/background_import_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../player/presentation/widgets/mini_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_screen_notifier.dart';
import '../player/presentation/player_notifier.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainScreenNotifierProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () {
          final focusNode = FocusManager.instance.primaryFocus;
          if (focusNode != null && focusNode.context != null) {
            final isTextField = focusNode.context!.findAncestorWidgetOfExactType<EditableText>() != null || 
                                focusNode.context!.widget is EditableText;
            if (isTextField) return;
          }
          ref.read(playerNotifierProvider.notifier).togglePlayPause();
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          final focusNode = FocusManager.instance.primaryFocus;
          if (focusNode != null && focusNode.context != null) {
            final isTextField = focusNode.context!.findAncestorWidgetOfExactType<EditableText>() != null || 
                                focusNode.context!.widget is EditableText;
            if (isTextField) return;
          }
          final currentPos = ref.read(playerNotifierProvider).position;
          final newPos = currentPos - const Duration(seconds: 10);
          ref.read(playerNotifierProvider.notifier).seek(newPos < Duration.zero ? Duration.zero : newPos);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          final focusNode = FocusManager.instance.primaryFocus;
          if (focusNode != null && focusNode.context != null) {
            final isTextField = focusNode.context!.findAncestorWidgetOfExactType<EditableText>() != null || 
                                focusNode.context!.widget is EditableText;
            if (isTextField) return;
          }
          final currentPos = ref.read(playerNotifierProvider).position;
          final totalPos = ref.read(playerNotifierProvider).totalDuration;
          final newPos = currentPos + const Duration(seconds: 10);
          ref.read(playerNotifierProvider.notifier).seek(newPos > totalPos ? totalPos : newPos);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              
              final contentStack = Stack(
                children: [
                  IndexedStack(
                    index: currentIndex,
                    children: _screens,
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: MiniPlayer(),
                  ),
                ],
              );

              if (isDesktop) {
                return Row(
                  children: [
                    NavigationRail(
                      backgroundColor: const Color(0xFF0D0B1F),
                      selectedIndex: currentIndex,
                      onDestinationSelected: (index) =>
                          ref.read(mainScreenNotifierProvider.notifier).state = index,
                      selectedIconTheme: const IconThemeData(color: Color(0xFFBB86FC)),
                      unselectedIconTheme: const IconThemeData(color: Colors.white54),
                      selectedLabelTextStyle: const TextStyle(color: Color(0xFFBB86FC)),
                      unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home_max_rounded),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.search_rounded),
                          label: Text('Search'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.library_music_rounded),
                          label: Text('Library'),
                        ),
                      ],
                    ),
                    Expanded(child: contentStack),
                  ],
                );
              } else {
                return contentStack;
              }
            },
          ),
          bottomNavigationBar: MediaQuery.of(context).size.width > 800
              ? null
              : Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: const Color(0xFF0D0B1F),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: currentIndex,
                    onTap: (index) =>
                        ref.read(mainScreenNotifierProvider.notifier).state = index,
                    backgroundColor: const Color(0xFF0D0B1F),
                    selectedItemColor: const Color(0xFFBB86FC),
                    unselectedItemColor: Colors.white54,
                    showUnselectedLabels: true,
                    type: BottomNavigationBarType.fixed,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_max_rounded),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search_rounded),
                        label: 'Search',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.library_music_rounded),
                        label: 'Library',
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
