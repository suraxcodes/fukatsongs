import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final killSwitchProvider = StateNotifierProvider<KillSwitchNotifier, bool>((ref) {
  return KillSwitchNotifier();
});

class KillSwitchNotifier extends StateNotifier<bool> {
  static const _deviceChannel = MethodChannel('com.fukatsongs.app/device');

  KillSwitchNotifier() : super(false) {
    _init();
  }

  void _init() {
    try {
      final authBox = Hive.box(HiveBoxes.auth);
      
      // ✅ Check local secure persistence first: if already banned, lock immediately (works offline!)
      final isBanned = authBox.get('is_banned', defaultValue: false);
      if (isBanned == true) {
        state = true;
      }

      // ✅ Fetch the unique hardware Android ID to check against global banned devices
      _deviceChannel.invokeMethod<String>('getAndroidId').then((androidId) {
        if (androidId != null) {
          debugPrint('Unique Hardware Device ID: $androidId');
          
          // Connect to the global banned devices registry
          final bannedDeviceRef = FirebaseDatabase.instance.ref('banned_devices/$androidId');
          bannedDeviceRef.onValue.listen((event) {
            final isBannedDevice = event.snapshot.value as bool?;
            if (isBannedDevice == true) {
              debugPrint('⚠️ Hardware Device is globally BANNED. Locking client!');
              authBox.put('is_banned', true);
              state = true;
            }
          }, onError: (e) {
            debugPrint('Banned device check failed (offline or permission denied): $e');
          });
        }
      }).catchError((e) {
        debugPrint('Failed to fetch Android ID: $e');
      });

      final isUnlocked = authBox.get('is_unlocked', defaultValue: false);
      if (!isUnlocked) return;

      // Silently sign in anonymously if not already signed in
      if (FirebaseAuth.instance.currentUser == null) {
        FirebaseAuth.instance.signInAnonymously().then((credential) {
          final user = credential.user;
          if (user != null) {
            _setupStatusListener(user.uid);
          }
        }).catchError((e) {
          debugPrint('Silent anonymous sign-in failed: $e');
        });
      } else {
        _setupStatusListener(FirebaseAuth.instance.currentUser!.uid);
      }
    } catch (e) {
      debugPrint('Firebase Kill Switch Initialization error: $e');
    }
  }

  void _setupStatusListener(String uid) {
    try {
      final databaseRef = FirebaseDatabase.instance.ref('users/$uid');

      // Update last_login timestamp and associate hardware device ID for admin visibility
      _deviceChannel.invokeMethod<String>('getAndroidId').then((androidId) {
        final Map<String, dynamic> updates = {
          'last_login': DateTime.now().toIso8601String(),
        };
        if (androidId != null) {
          updates['device_id'] = androidId;
        }
        databaseRef.update(updates).catchError((e) {
          debugPrint('Failed to update user node metadata: $e');
        });
      });

      // Listen to status changes
      databaseRef.child('status').onValue.listen((event) {
        final status = event.snapshot.value as String?;
        final authBox = Hive.box(HiveBoxes.auth);

        if (status == 'active') {
          // Explicitly active -> unlock
          authBox.put('is_banned', false);
          state = false;
        } else {
          // If status is 'banned', deleted (null), or any other value -> lock instantly!
          authBox.put('is_banned', true);
          state = true;

          // ✅ Auto-register this hardware ID globally to prevent reinstalls!
          _deviceChannel.invokeMethod<String>('getAndroidId').then((androidId) {
            if (androidId != null) {
              FirebaseDatabase.instance.ref('banned_devices/$androidId').set(true);
            }
          });
        }
      }, onError: (e) {
        debugPrint('Error listening to status (likely permissions revoked): $e');
        // Handle database permission revoked / locked nodes as instant bans
        if (e.toString().contains('Permission denied') || e.toString().contains('permission-denied')) {
          final authBox = Hive.box(HiveBoxes.auth);
          authBox.put('is_banned', true);
          state = true;
          
          // Auto-register device ID under global banned registry
          _deviceChannel.invokeMethod<String>('getAndroidId').then((androidId) {
            if (androidId != null) {
              FirebaseDatabase.instance.ref('banned_devices/$androidId').set(true);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Setup status listener failed: $e');
    }
  }

  Future<void> triggerStatusCheck() async {
    _init();
  }
}
