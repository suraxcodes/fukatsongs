import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/core/constants/app_secrets.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';
import 'package:fukat_songs/features/main/main_screen.dart';

class GatekeeperScreen extends StatefulWidget {
  const GatekeeperScreen({super.key});

  @override
  State<GatekeeperScreen> createState() => _GatekeeperScreenState();
}

class _GatekeeperScreenState extends State<GatekeeperScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  String? _errorText;

  Future<void> _checkPassword() async {
    if (_controller.text == AppSecrets.appPassword) {
      // ✅ Save the "unlocked" flag — never ask again on this install
      final authBox = Hive.box(HiveBoxes.auth);
      await authBox.put('is_unlocked', true);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      setState(() {
        _errorText = 'Incorrect password. Try again.';
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
                Image.asset(
                  'assets/images/logo.png',
                  height: 110,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.lock_person_rounded,
                    size: 100,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'FUKAT SONGS',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PRIVATE ACCESS ONLY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 48),

                // Password Input
                TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
                  textAlign: TextAlign.center,
                  autofocus: true,
                  onSubmitted: (_) => _checkPassword(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    hintText: '• • • •',
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8, fontSize: 22),
                    errorText: _errorText,
                    errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                const SizedBox(height: 28),

                // Unlock Button
                ElevatedButton.icon(
                  onPressed: _checkPassword,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text(
                    'UNLOCK',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
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
                const Text(
                  'You only need to enter this once.',
                  style: TextStyle(fontSize: 11, color: Colors.white24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
