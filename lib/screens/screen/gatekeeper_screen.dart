import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fukatsongs/core/constants/app_secrets.dart';
import 'package:fukatsongs/blocs/kill_switch/kill_switch_cubit.dart';
import 'package:fukatsongs/services/db/dao/settings_dao.dart';
import 'package:fukatsongs/services/db/db_provider.dart';
import 'package:go_router/go_router.dart';

class GatekeeperScreen extends StatefulWidget {
  final bool isUpgradeFlow;
  const GatekeeperScreen({super.key, this.isUpgradeFlow = false});

  @override
  State<GatekeeperScreen> createState() => _GatekeeperScreenState();
}

class _GatekeeperScreenState extends State<GatekeeperScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _obscure = true;
  String? _passwordError;
  String? _nicknameError;
  bool _isLoading = false;
  late SettingsDAO _settingsDao;

  @override
  void initState() {
    super.initState();
    _settingsDao = SettingsDAO(DBProvider.db);
  }

  Future<void> _checkPassword() async {
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    setState(() {
      _passwordError = null;
      _nicknameError = null;
    });

    bool hasError = false;
    if (!widget.isUpgradeFlow && password != AppSecrets.appPassword) {
      setState(() {
        _passwordError = 'Incorrect password. Try again.';
      });
      hasError = true;
    }

    if (nickname.isEmpty) {
      setState(() {
        _nicknameError = 'Please enter a device name.';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ 1. Check global ban registry BEFORE letting them register or unlock
      final killSwitchCubit = context.read<KillSwitchCubit>();
      final hardwareId = await killSwitchCubit.getHardwareId();

      if (hardwareId != null) {
        try {
          // Check static banned_devices node first
          final banSnapshot = await FirebaseDatabase.instance
              .ref('banned_devices/$hardwareId')
              .get();

          if (banSnapshot.exists && banSnapshot.value != null) {
            setState(() {
              _isLoading = false;
              _passwordError = 'This device app is banned by developer. Thank you.';
            });
            await _settingsDao.putSettingBool('is_banned', true);
            return;
          }

          // ✅ CHECK 2: Query historical user nodes to see if this physical hardware ID is linked to any banned/deleted accounts
          final usersSnapshot = await FirebaseDatabase.instance
              .ref('users')
              .orderByChild('device_id')
              .equalTo(hardwareId)
              .get();

          if (usersSnapshot.exists && usersSnapshot.value != null) {
            final dynamic rawData = usersSnapshot.value;
            String? existingNickname;
            bool isGloballyBanned = false;

            if (rawData is Map) {
              for (final entry in rawData.values) {
                if (entry is Map) {
                  final status = entry['status'] as String?;
                  final nick = entry['nickname'] as String?;
                  if (status != null && status != 'active') {
                    isGloballyBanned = true;
                    existingNickname = nick;
                    break;
                  } else if (status == 'active') {
                    existingNickname = nick;
                  }
                }
              }
            }

            if (isGloballyBanned) {
              setState(() {
                _isLoading = false;
                _passwordError = 'This device app is banned by developer. Thank you.';
              });
              await _settingsDao.putSettingBool('is_banned', true);

              // Auto-register this hardware ID globally so future checks are instant!
              FirebaseDatabase.instance.ref('banned_devices/$hardwareId').set(existingNickname ?? nickname);
              return;
            }

            // B: If already registered and active, log them into their existing node path
            if (existingNickname != null) {
              await _settingsDao.putSettingBool('is_unlocked', true);
              await _settingsDao.putSettingStr('device_nickname', existingNickname);

              // Trigger status check to start the real-time kill switch listener
              killSwitchCubit.triggerStatusCheck();

              if (!mounted) return;
              context.go('/Explore');
              return;
            }
          }
        } catch (banErr) {
          debugPrint('Gatekeeper pre-check global ban lookup error/bypassed: $banErr');
        }
      }

      // 2. Silently try Firebase Registration
      try {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        final user = credential.user;
        if (user != null) {
          final databaseRef = FirebaseDatabase.instance.ref('users/${nickname}_$hardwareId');
          await databaseRef.set({
            'nickname': nickname,
            'status': 'active',
            'registered_at': DateTime.now().toIso8601String(),
            'last_login': DateTime.now().toIso8601String(),
            'device_id': hardwareId,
          });
          debugPrint('Device registered with Firebase uid: ${user.uid}');
        }
      } catch (fbErr) {
        // Safe bypass if Firebase is not configured or offline
        debugPrint('Firebase silent registration bypassed/failed: $fbErr');
      }

      // ✅ Save the "unlocked" flag and nickname
      await _settingsDao.putSettingBool('is_unlocked', true);
      await _settingsDao.putSettingStr('device_nickname', nickname);

      // Trigger status check to start the real-time kill switch listener immediately!
      context.read<KillSwitchCubit>().triggerStatusCheck();

      if (!mounted) return;
      context.go('/Explore');
    } catch (e) {
      debugPrint('Gatekeeper submit error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1040),
              const Color(0xFF0D0B1F),
              const Color(0xFF0D0B1F),
              Colors.deepPurple.withOpacity(0.12),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                const Icon(
                  Icons.music_note_rounded,
                  size: 100,
                  color: Colors.deepPurpleAccent,
                ),
                const SizedBox(height: 32),

                Text(
                  widget.isUpgradeFlow ? 'FUKAT UPDATE' : 'FUKAT SONGS',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isUpgradeFlow ? 'DEVICE NICKNAME SETUP' : 'PRIVATE ACCESS ONLY',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 48),

                // Device Nickname Input
                TextField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    hintText: "Your Nickname (e.g. Rahul )",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                    errorText: _nicknameError,
                    errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),
                if (!widget.isUpgradeFlow) ...[
                  const SizedBox(height: 20),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 6),
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _checkPassword(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      hintText: 'Master Password',
                      hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 0, fontSize: 16),
                      errorText: _passwordError,
                      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      prefixIcon: const Icon(Icons.vpn_key_rounded, color: Colors.white38),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Unlock Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkPassword,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(widget.isUpgradeFlow ? Icons.check_circle_outline_rounded : Icons.lock_open_rounded),
                  label: Text(
                    _isLoading
                        ? 'REGISTERING...'
                        : (widget.isUpgradeFlow ? 'REGISTER DEVICE' : 'UNLOCK'),
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 12,
                    shadowColor: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  widget.isUpgradeFlow
                      ? 'Please enter a nickname to identify this device.'
                      : 'You only need to enter this once.',
                  style: const TextStyle(fontSize: 11, color: Colors.white24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
