# Restore original Home background

Change only `lib/screens/screen/explore_screen.dart`.

Complete replacement file and patch are supplied for the `9b61edb` version. If newer Home changes exist, apply only the two edits in the patch instead of replacing the whole file.

1. Remove the `Positioned.fill` containing `Image.asset('assets/images/home_background.png')` from the Home Stack. Leave the RefreshIndicator and all its content unchanged.
2. In CustomDiscoverBar, restore SliverAppBar properties:

```dart
surfaceTintColor: Default_Theme.themeColor,
backgroundColor: Default_Theme.themeColor,
```

Remove the added `shadowColor: Colors.transparent`, `elevation: 0` and `scrolledUnderElevation: 0` overrides.

The Scaffold already uses `Default_Theme.themeColor`. The remaining single-child Stack is harmless and avoids reformatting/replacing the Home content.

Do not change cards, carousel, Recently Played, voice controls, navigation, playlist sorting or import code. Leave pubspec.yaml and the unused PNG alone; deleting them is not necessary to restore the appearance.

Validation: exact-match checks for both edits passed. Flutter build and device appearance have not been tested. Run `flutter analyze` and `flutter build apk --debug`, then check Home on the device.
