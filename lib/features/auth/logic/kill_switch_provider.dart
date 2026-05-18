import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

  String _generateRandomId(String prefix) {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    final hex = values.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${prefix}_$hex';
  }

  Future<String?> getHardwareId() async {
    final authBox = Hive.box(HiveBoxes.auth);
    final savedId = authBox.get('unique_device_id') as String?;
    if (savedId != null) {
      return savedId;
    }

    String? hardwareId;
    if (kIsWeb) {
      hardwareId = _generateRandomId('web');
    } else if (Platform.isWindows) {
      try {
        final result = await Process.run('powershell', [
          '-Command',
          '(Get-CimInstance Win32_ComputerSystemProduct).UUID'
        ]);
        if (result.exitCode == 0) {
          final uuid = result.stdout.toString().trim();
          if (uuid.isNotEmpty) {
            hardwareId = 'windows_$uuid';
          }
        }
      } catch (e) {
        debugPrint('Failed to get Windows motherboard UUID: $e');
      }
      hardwareId ??= _generateRandomId('desktop');
    } else if (!Platform.isAndroid) {
      hardwareId = _generateRandomId('desktop');
    } else {
      try {
        hardwareId = await _deviceChannel.invokeMethod<String>('getAndroidId');
      } catch (e) {
        debugPrint('Failed to fetch Android ID: $e');
        hardwareId = _generateRandomId('android_fallback');
      }
    }

    if (hardwareId != null) {
      await authBox.put('unique_device_id', hardwareId);
    }
    return hardwareId;
  }

  void _init() {
    try {
      final authBox = Hive.box(HiveBoxes.auth);
      
      // ✅ Check local secure persistence first: if already banned, lock immediately (works offline!)
      final isBanned = authBox.get('is_banned', defaultValue: false);
      if (isBanned == true) {
        state = true;
      }

      final isUnlocked = authBox.get('is_unlocked', defaultValue: false);
      if (!isUnlocked) {
        // If not registered/unlocked yet, let them go to the GatekeeperScreen!
        // The GatekeeperScreen's own check will block them if they are indeed banned when they click Unlock.
        return;
      }

      // ✅ Fetch the unique hardware ID to check against global banned devices
      getHardwareId().then((androidId) {
        if (androidId != null) {
          debugPrint('Unique Hardware Device ID: $androidId');
          
          // Connect to the global banned devices registry
          final bannedDeviceRef = FirebaseDatabase.instance.ref('banned_devices/$androidId');
          bannedDeviceRef.onValue.listen((event) {
            final banValue = event.snapshot.value;
            if (banValue != null) {
              // ✅ Self-Healing Sync Check: Verify if the user node status is actually 'active' now!
              FirebaseDatabase.instance
                  .ref('users')
                  .orderByChild('device_id')
                  .equalTo(androidId)
                  .get()
                  .then((usersSnapshot) {
                if (usersSnapshot.exists && usersSnapshot.value != null) {
                  final dynamic rawData = usersSnapshot.value;
                  bool isStillBanned = true;

                  if (rawData is Map) {
                    for (final entry in rawData.values) {
                      if (entry is Map) {
                        final status = entry['status'] as String?;
                        if (status == 'active') {
                          isStillBanned = false;
                          break;
                        }
                      }
                    }
                  }

                  if (!isStillBanned) {
                    // Auto-heal: The developer set the status to active, so unban globally!
                    debugPrint('--- Kill Switch: Reactivated by developer. Auto-healing ban! ---');
                    authBox.put('is_banned', false);
                    state = false;
                    bannedDeviceRef.remove();
                    return;
                  }
                }

                // If indeed banned
                debugPrint('⚠️ Hardware Device is globally BANNED. Locking client!');
                authBox.put('is_banned', true);
                state = true;
              }).catchError((err) {
                debugPrint('Self-healing lookup failed, fallback to ban: $err');
                debugPrint('⚠️ Hardware Device is globally BANNED. Locking client!');
                authBox.put('is_banned', true);
                state = true;
              });
            } else {
              // ✅ Developer deleted the device ID from the banned_devices folder!
              // Auto-heal: Unban the client and set their user node back to active!
              if (authBox.get('is_banned', defaultValue: false) == true) {
                debugPrint('--- Kill Switch: Removed from banned_devices folder. Reactivating! ---');
                authBox.put('is_banned', false);
                state = false;

                // Sync: Also update the user's status to active under users folder
                final nickname = authBox.get('device_nickname') as String?;
                if (nickname != null) {
                  FirebaseDatabase.instance.ref('users/${nickname}_$androidId/status').set('active');
                }
              }
            }
          }, onError: (e) {
            debugPrint('Banned device check failed (offline or permission denied): $e');
          });
        }
      });

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
      final authBox = Hive.box(HiveBoxes.auth);
      final nickname = authBox.get('device_nickname', defaultValue: 'unknown_device') as String;
      
      getHardwareId().then((androidId) {
        if (androidId != null) {
          final databaseRef = FirebaseDatabase.instance.ref('users/${nickname}_$androidId');
          
          databaseRef.get().then((snapshot) {
            final Map<String, dynamic> updates = {
              'last_login': DateTime.now().toIso8601String(),
              'device_id': androidId,
              'nickname': nickname,
            };

            // Safely default to 'active' on new registrations or if status is missing
            final existingData = snapshot.value as Map?;
            if (!snapshot.exists || existingData == null || existingData['status'] == null) {
              updates['status'] = 'active';
            }

            databaseRef.update(updates).then((_) {
              // Start listening to status changes only after initial write is complete
              databaseRef.child('status').onValue.listen((event) {
                final status = event.snapshot.value as String?;
                final authBox = Hive.box(HiveBoxes.auth);

                if (status == 'active') {
                  // Explicitly active -> unlock
                  authBox.put('is_banned', false);
                  state = false;
                  
                  // Keep banned_devices cleaned up and in sync
                  FirebaseDatabase.instance.ref('banned_devices/$androidId').remove();
                } else {
                  // If status is 'banned', deleted (null), or any other value -> lock instantly!
                  authBox.put('is_banned', true);
                  state = true;

                  // Auto-register this hardware ID globally to prevent reinstalls with the nickname as the identifier!
                  FirebaseDatabase.instance.ref('banned_devices/$androidId').set(nickname);
                }
              }, onError: (e) {
                debugPrint('Error listening to status: $e');
                if (e.toString().contains('Permission denied') || e.toString().contains('permission-denied')) {
                  authBox.put('is_banned', true);
                  state = true;
                  FirebaseDatabase.instance.ref('banned_devices/$androidId').set(nickname);
                }
              });
            }).catchError((e) {
              debugPrint('Failed to update user node metadata: $e');
            });
          }).catchError((e) {
            debugPrint('Failed to fetch initial user node: $e');
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
