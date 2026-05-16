import 'package:flutter/material.dart';
import '../home/presentation/home_screen.dart';
import '../search/presentation/search_screen.dart';
import '../library/presentation/library_screen.dart';
import '../library/presentation/background_import_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../player/presentation/widgets/mini_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_screen_notifier.dart';

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

    return Scaffold(
      body: Stack(
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
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF0D0B1F),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => ref.read(mainScreenNotifierProvider.notifier).state = index,
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
    );
  }
}
