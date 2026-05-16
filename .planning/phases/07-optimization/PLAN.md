# Phase 07: Optimization & Polish - Plan

## Objectives
1. Implement a persistent caching layer in `MusicRepository`.
2. Add network resilience with Dio interceptors.
3. Build a "Glassmorphic" UI system for premium visual feel.
4. Implement adaptive offline search.

## Wave 1: Caching & Resilience
- [ ] Implement `CacheManager` with Hive (TTL logic).
- [ ] Integrate cache into `MusicRepository.search`.
- [ ] Configure `Dio` interceptors for timeouts and retry.
- [ ] Verify `cached_network_image` TTL settings.

## Wave 2: Adaptive Offline UI
- [ ] Implement `ConnectivityService` to monitor network state.
- [ ] Update `SearchScreen` to automatically toggle between Global and Library search.
- [ ] Add "Offline Mode" banner/indicator.

## Wave 3: Visual Polish (Glassmorphism)
- [ ] Implement `GlassContainer` widget with blur and gradients.
- [ ] Create `ShimmerSkeleton` using the glassmorphic style.
- [ ] Apply skeletons to `SearchScreen` and `LibraryScreen` loading states.
- [ ] Add smooth page transitions.

## Verification
- [ ] Verify search results are instant on second query.
- [ ] Toggle Airplane mode and check if search switches to Library.
- [ ] Check UI on different screen sizes for shimmer scaling.
