// rrt_grant_location_screen_no_overflow.dart
//
// ✅ FULL ONE-SHOT FILE (REPLACE EXISTING SCREEN FILE COMPLETELY)
// ✅ Standing instruction followed: full screen code output so no existing code is missed
//
// Screen: Rapid Response Team - Grant Location
// Source: Your Stitch HTML
//
// ✅ PRODUCTION SAFE (NO OVERFLOW):
// - Works on small devices without RenderFlex overflow
// - Scroll fallback only when needed
//
// ✅ Functional:
// - GET STARTED requests location permission
// - If granted -> navigates to next screen placeholder (replace with your READY screen)
//
// NOTE: Add dependency in pubspec.yaml:
//   geolocator: ^12.0.0
//
// AndroidManifest.xml:
//   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
//
// iOS Info.plist:
//   NSLocationWhenInUseUsageDescription = "We use your location to alert volunteers in your district."

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const RRTApp());
}

class RRTApp extends StatelessWidget {
  const RRTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RRTGrantLocationScreen(),
    );
  }
}

class RRTGrantLocationScreen extends StatefulWidget {
  const RRTGrantLocationScreen({super.key});

  @override
  State<RRTGrantLocationScreen> createState() => _RRTGrantLocationScreenState();
}

class _RRTGrantLocationScreenState extends State<RRTGrantLocationScreen> {
  bool isLoading = false;

  Future<void> _onGetStarted() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final ok = await _requestLocationPermission();
      if (!mounted) return;

      if (ok) {
        // ✅ Replace _ReadyStatePlaceholderScreen() with your actual READY screen:
        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RRTReadyScreen()));
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _ReadyStatePlaceholderScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission is required to continue."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<bool> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) return false;
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420), // max-w-md
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ✅ PRODUCTION SAFE "NO OVERFLOW" LAYOUT:
                // - Normal devices => no scroll needed visually
                // - Small devices => scroll activates automatically, no crash
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // TOP CONTENT (px-8 pt-16)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32)
                                .copyWith(top: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon box (w-12 h-12 border border-black p-2)
                                Container(
                                  width: 48,
                                  height: 48,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black, width: 1),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.pets,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32), // mb-8

                                // Titles (mb-10)
                                const Text(
                                  "Rapid",
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 36, // text-4xl
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  "Response Team",
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: Colors.grey.shade400,
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 40), // mb-10

                                // Text block (max-w-[280px])
                                const ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 280),
                                  child: Text(
                                    "Grant location access to see alerts in your district and ensure help reaches you quickly.",
                                    style: TextStyle(
                                      fontFamily: "Inter",
                                      fontSize: 18, // text-lg
                                      fontWeight: FontWeight.w500,
                                      height: 1.5, // leading-relaxed
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PUSH BOTTOM CONTENT DOWN (mt-auto)
                          const Spacer(),

                          // BOTTOM (px-8 pb-4 space-y-6)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32)
                                .copyWith(bottom: 16),
                            child: Column(
                              children: [
                                // GET STARTED Button (w-full bg-black h-16)
                                SizedBox(
                                  height: 64,
                                  width: double.infinity,
                                  child: Material(
                                    color: Colors.black,
                                    child: InkWell(
                                      onTap: _onGetStarted,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: isLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<Color>(
                                                          Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  : const Text(
                                                      "GET STARTED",
                                                      style: TextStyle(
                                                        fontFamily: "Inter",
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                        letterSpacing: 3.2, // 0.2em
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: double.infinity,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                          const SizedBox(
                                            width: 64,
                                            height: 64,
                                            child: Center(
                                              child: Icon(
                                                Icons.arrow_forward,
                                                size: 24,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24), // space-y-6

                                // Footer trust line (pb-8)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "SECURE ACCESS",
                                        style: TextStyle(
                                          fontFamily: "JetBrainsMono",
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 1.5, // 0.15em
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "•",
                                        style: TextStyle(
                                          fontFamily: "JetBrainsMono",
                                          fontSize: 10,
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "PRIVACY ENSURED",
                                        style: TextStyle(
                                          fontFamily: "JetBrainsMono",
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 1.5,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Placeholder screen used only so this file runs end-to-end.
// Replace this with your real READY screen later.
class _ReadyStatePlaceholderScreen extends StatelessWidget {
  const _ReadyStatePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Location granted ✅",
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Next: show READY state screen here.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.black, width: 1),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  "BACK",
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
