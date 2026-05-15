import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'search_notifier.dart';
import 'widgets/song_card.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);
    final notifier = ref.read(searchNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context, notifier),
            Expanded(
              child: searchState.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildResults(songs);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildErrorState(notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, SearchNotifier notifier) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        onChanged: (val) => notifier.search(val),
        decoration: InputDecoration(
          hintText: 'Search songs, artists...',
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20.w),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildResults(List songs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Results',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return SongCard(
                song: songs[index],
                onTap: () {
                  // TODO: Play song
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No songs found',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildErrorState(SearchNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Something went wrong', style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: () => notifier.search(''),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
