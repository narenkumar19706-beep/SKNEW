// rrt_profile_setup_screen_prod.dart
//
// ✅ FULL ONE-SHOT FILE (REPLACE EXISTING SCREEN FILE COMPLETELY)
// ✅ Standing instruction followed: full updated file, no partial snippets
//
// ✅ PRODUCTION-GRADE Profile Setup Screen
// - Matches Stitch HTML UI (sharp corners, minimalist, high contrast)
// - No overflow (scroll fallback only when needed)
// - Robust validation + normalization
// - Persists profile locally (SharedPreferences)
// - Auto-loads saved profile on open
// - Safe button state + loading state + error UX
// - Consistent across Android + iOS (no adaptive widgets)
//
// ----------------------------
// REQUIRED DEPENDENCIES
// pubspec.yaml:
//
// dependencies:
//   flutter:
//     sdk: flutter
//   shared_preferences: ^2.2.3
//
// ----------------------------
// OPTIONAL (recommended) FONTS
// Add fonts "Inter" and "JetBrainsMono" to pubspec.yaml + assets
// If fonts not added, the app will still run, but typography differs per OS.
//
// ----------------------------
// WHAT THIS SCREEN DOES
// - User enters Name + Mobile
// - Mobile: Indian format support (+91 / spaces allowed)
// - On Save: persists locally + shows success + navigates to next screen placeholder
//
// Replace `_NextScreenPlaceholder()` with your real next screen (Grant Location / Ready).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RRTApp());
}

class RRTApp extends StatelessWidget {
  const RRTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RRTProfileSetupScreen(),
    );
  }
}

class RRTProfileSetupScreen extends StatefulWidget {
  const RRTProfileSetupScreen({super.key});

  @override
  State<RRTProfileSetupScreen> createState() => _RRTProfileSetupScreenState();
}

class _RRTProfileSetupScreenState extends State<RRTProfileSetupScreen> {
  // Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  // Focus
  final FocusNode nameFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();

  // UI State
  bool isBootLoading = true; // loading saved values
  bool isSaving = false;

  // Errors
  String? nameError;
  String? phoneError;

  // Storage Keys
  static const String _kNameKey = "rrt_profile_name";
  static const String _kPhoneE164Key = "rrt_profile_phone_e164"; // ex: +919876543210

  @override
  void initState() {
    super.initState();
    nameCtrl.addListener(_onChange);
    phoneCtrl.addListener(_onChange);
    _bootstrap();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    nameFocus.dispose();
    phoneFocus.dispose();
    super.dispose();
  }

  void _onChange() {
    // Clear errors as user edits
    if (nameError != null || phoneError != null) {
      setState(() {
        nameError = null;
        phoneError = null;
      });
    } else {
      // still rebuild to update button state
      setState(() {});
    }
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedName = prefs.getString(_kNameKey);
      final savedE164 = prefs.getString(_kPhoneE164Key);

      if (savedName != null && savedName.trim().isNotEmpty) {
        nameCtrl.text = savedName.trim();
      }

      // If saved as +91XXXXXXXXXX, show in pretty format
      if (savedE164 != null && savedE164.startsWith("+91") && savedE164.length == 13) {
        final ten = savedE164.substring(3); // 10 digits
        phoneCtrl.text = _prettyIndianMobile(ten);
      }
    } catch (_) {
      // ignore bootstrap failures; allow manual input
    } finally {
      if (!mounted) return;
      setState(() => isBootLoading = false);
    }
  }

  // -----------------------
  // VALIDATION + NORMALIZE
  // -----------------------

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  // This returns 10 digit Indian mobile number OR null if invalid.
  // Accepts input:
  // - "9876543210"
  // - "+91 98765 43210"
  // - "91 9876543210"
  String? _normalizeIndianMobileTo10Digits(String input) {
    final digits = _onlyDigits(input);

    if (digits.length == 10) {
      return digits;
    }

    if (digits.length == 12 && digits.startsWith("91")) {
      return digits.substring(2);
    }

    return null;
  }

  // Final canonical format to store/send: +91XXXXXXXXXX
  String? _normalizeToE164India(String input) {
    final ten = _normalizeIndianMobileTo10Digits(input);
    if (ten == null) return null;
    return "+91$ten";
  }

  bool _isValidName(String s) {
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v.length < 2) return false;

    // minimal sanity: allow alphabets, spaces, dot, hyphen
    final ok = RegExp(r"^[a-zA-Z][a-zA-Z\s\.\-']+$").hasMatch(v);
    return ok;
  }

  bool _isValidPhone(String s) {
    return _normalizeIndianMobileTo10Digits(s) != null;
  }

  String _prettyIndianMobile(String tenDigits) {
    // 98765 43210
    if (tenDigits.length != 10) return tenDigits;
    return "${tenDigits.substring(0, 5)} ${tenDigits.substring(5)}";
  }

  bool get _canSubmit {
    if (isBootLoading) return false;
    if (isSaving) return false;
    return _isValidName(nameCtrl.text) && _isValidPhone(phoneCtrl.text);
  }

  // -----------------------
  // SAVE
  // -----------------------
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final name = nameCtrl.text.trim();
    final phoneRaw = phoneCtrl.text.trim();

    // Validate
    String? newNameError;
    String? newPhoneError;

    if (!_isValidName(name)) {
      newNameError = "Enter a valid name";
    }

    final e164 = _normalizeToE164India(phoneRaw);
    if (e164 == null) {
      newPhoneError = "Enter a valid Indian mobile number";
    }

    setState(() {
      nameError = newNameError;
      phoneError = newPhoneError;
    });

    if (newNameError != null) {
      nameFocus.requestFocus();
      return;
    }

    if (newPhoneError != null) {
      phoneFocus.requestFocus();
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNameKey, name);
      await prefs.setString(_kPhoneE164Key, e164!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile saved ✅"),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate next
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _NextScreenPlaceholder()),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not save profile. Try again."),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => isSaving = false);
    }
  }

  // -----------------------
  // UI
  // -----------------------

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);

    final gray400 = Colors.grey.shade400;
    final gray200 = Colors.grey.shade200;
    final dividerWhite20 = Colors.white.withOpacity(0.20);
    final errorRed = Colors.red.shade700;

    final showLoading = isSaving;
    final isDisabled = !showLoading && !_canSubmit;
    final buttonColor = isDisabled ? Colors.grey.shade200 : black;
    final buttonTextColor = isDisabled ? Colors.grey.shade500 : Colors.white;
    final buttonDividerColor =
        isDisabled ? Colors.grey.shade400.withOpacity(0.6) : dividerWhite20;

    final nameDecoration = InputDecoration(
      hintText: "Enter Name",
      hintStyle: TextStyle(
        fontFamily: "Inter",
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: gray400,
      ),
      errorText: nameError,
      errorStyle: TextStyle(
        fontFamily: "Inter",
        fontSize: 12,
        color: errorRed,
      ),
      errorMaxLines: 2,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: black, width: 1),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: black, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: black, width: 1),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorRed, width: 1),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );

    final phoneDecoration = InputDecoration(
      hintText: "+91 00000 00000",
      hintStyle: TextStyle(
        fontFamily: "Inter",
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: gray400,
      ),
      errorText: phoneError,
      errorStyle: TextStyle(
        fontFamily: "Inter",
        fontSize: 12,
        color: errorRed,
      ),
      errorMaxLines: 2,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: black, width: 1),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: black, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: black, width: 1),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorRed, width: 1),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      counterText: "",
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420), // max-w-md
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ✅ PRODUCTION SAFE: no overflow across devices
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // TOP CONTENT (px-8 pt-16)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32).copyWith(top: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // App icon box
                                Container(
                                  width: 48,
                                  height: 48,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: black, width: 1),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.pets, size: 24, color: black),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Rapid / Response Team
                                const Text(
                                  "Rapid",
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: black,
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
                                    color: gray400,
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Your Profile
                                const Text(
                                  "Your Profile",
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: black,
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 48),

                                const Text(
                                  "NAME",
                                  style: TextStyle(
                                    fontFamily: "JetBrainsMono",
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: nameCtrl,
                                  focusNode: nameFocus,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) => phoneFocus.requestFocus(),
                                  enabled: !isSaving,
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: black,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  inputFormatters: const [
                                    LengthLimitingTextInputFormatter(60),
                                  ],
                                  decoration: nameDecoration,
                                ),

                                const SizedBox(height: 28),

                                const Text(
                                  "MOBILE NUMBER",
                                  style: TextStyle(
                                    fontFamily: "JetBrainsMono",
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: phoneCtrl,
                                  focusNode: phoneFocus,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (_canSubmit) {
                                      _submit();
                                    }
                                  },
                                  enabled: !isSaving,
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: black,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                                    LengthLimitingTextInputFormatter(16),
                                  ],
                                  decoration: phoneDecoration,
                                  maxLength: 16,
                                ),

                                const SizedBox(height: 20),

                                Text(
                                  "MANDATORY FOR ALERTS.",
                                  style: TextStyle(
                                    fontFamily: "JetBrainsMono",
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: gray400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "YOUR PHONE NUMBER IS EXPOSED ONLY WHEN AN SOS ALERT IS ACTIVE. PRIVACY BY DESIGN.",
                                  style: TextStyle(
                                    fontFamily: "JetBrainsMono",
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    height: 1.5,
                                    letterSpacing: 1.1,
                                    color: gray400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PUSH BOTTOM CONTENT DOWN
                          const Spacer(),

                          // BOTTOM CONTENT
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32).copyWith(bottom: 16),
                            child: Column(
                              children: [
                                // SAVE & PROCEED Button
                                SizedBox(
                                  height: 64,
                                  width: double.infinity,
                                  child: Material(
                                    color: buttonColor,
                                    child: InkWell(
                                      onTap: _canSubmit ? _submit : null,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: showLoading
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
                                                  : Text(
                                                      "SAVE & PROCEED",
                                                      style: TextStyle(
                                                        fontFamily: "Inter",
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: buttonTextColor,
                                                        letterSpacing: 3.0,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: double.infinity,
                                            color: buttonDividerColor,
                                          ),
                                          SizedBox(
                                            width: 64,
                                            height: 64,
                                            child: Center(
                                              child: Icon(
                                                Icons.arrow_forward,
                                                size: 24,
                                                color: buttonTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

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
                                          letterSpacing: 1.5,
                                          color: gray400,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "•",
                                        style: TextStyle(
                                          fontFamily: "JetBrainsMono",
                                          fontSize: 10,
                                          color: gray200,
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
                                          color: gray400,
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
// Replace this with your real next screen later.
class _NextScreenPlaceholder extends StatelessWidget {
  const _NextScreenPlaceholder();

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
                              "Profile saved ✅",
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Next: show your Grant Location or READY screen here.",
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
