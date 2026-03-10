import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'admin/admin_shell.dart';
import 'parent/parent_shell.dart';
import 'consent_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── State ──
  bool _isAdmin = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // ── Secret Admin Login ──
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  // ── Animations ──
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Colors ──
  static const _accent = Color(0xFF6C5CE7);
  static const _accentLight = Color(0xFFEDE9FE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textTertiary = Color(0xFF9CA3AF);
  static const _border = Color(0xFFE5E7EB);
  static const _fieldBg = Color(0xFFF9FAFB);
  static const _cardBg = Colors.white;
  static const _bgColor = Color(0xFFF8F9FC);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  //  LOGIN LOGIC  (unchanged functionality)
  // ═══════════════════════════════════════════════
  void _switchMode(bool admin) {
    if (_isAdmin == admin) return;
    _usernameController.clear();
    _passwordController.clear();
    _totpController.clear();
    _slideController.reset();
    _slideController.forward();
    setState(() {
      _isAdmin = admin;
    });

    if (admin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin mode unlocked', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
            backgroundColor: _accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    
    // Reset counter if more than 1 second passed since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 1) {
      _logoTapCount = 0;
    }
    
    _lastTapTime = now;
    _logoTapCount++;

    if (_logoTapCount >= 5 && !_isAdmin) {
      HapticFeedback.heavyImpact();
      _switchMode(true);
      _logoTapCount = 0;
    } else if (_logoTapCount > 0 && _logoTapCount < 5 && !_isAdmin) {
      // Light feedback for counting taps
      HapticFeedback.lightImpact();
    }
  }

  void _login() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final api = ApiService();

      if (_isAdmin) {
        final user = _usernameController.text.trim();
        final pass = _passwordController.text.trim();
        if (user.isEmpty || pass.isEmpty) {
          _snack('Please enter username and password');
          setState(() => _isLoading = false);
          return;
        }
        final res = await api.adminLogin(user, pass, totpCode: _totpController.text.trim());
        if (res['success'] == true && mounted) {
          final role = res['role'] ?? 'super_admin';
          final name = res['name'] ?? 'Admin';
          _navigateTo(AdminShell(role: role, staffName: name));
        }
      } else {
        final user = _usernameController.text.trim();
        final pass = _passwordController.text.trim();
        if (user.isEmpty || pass.isEmpty) {
          _snack('Please enter credentials');
          setState(() => _isLoading = false);
          return;
        }
        final res = await api.parentLogin(user, pass);
        if (res['success'] == true && mounted) {
          final studentId = res['studentId'] ?? '';
          final consentRequired = res['consentRequired'] == true;

          if (consentRequired) {
            // Show consent screen first (DPDP Act)
            _navigateTo(ConsentScreen(
              studentId: studentId,
              onConsentAccepted: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ParentShell(studentId: studentId)),
                );
              },
            ));
          } else {
            _navigateTo(ParentShell(studentId: studentId));
          }
        }
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateTo(Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        backgroundColor: _textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  UI — Clean White Professional
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenH * 0.04),

                    // ── Logo ──
                    _buildLogo(),
                    const SizedBox(height: 20),

                    // ── Brand ──
                    Text(
                      'PCC',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: 4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coaching Management',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textTertiary,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Card ──
                    SlideTransition(
                      position: _slideAnim,
                      child: _buildCard(),
                    ),

                    const SizedBox(height: 32),

                    // ── Footer ──
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'SECURE  •  ENCRYPTED  •  PRIVATE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _textTertiary,
                                  letterSpacing: 2.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse('https://padashettycoaching.in/privacy-policy.html');
                            try {
                              // Try in-app first, then external
                              await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                            } catch (_) {
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } catch (e) {
                                if (mounted) _snack('Could not open Privacy Policy');
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.privacy_tip_outlined, size: 14, color: _accent),
                                const SizedBox(width: 8),
                                Text(
                                  'Click here to read our Privacy Policy',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenH * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──
  Widget _buildLogo() {
    return GestureDetector(
      onTap: _handleLogoTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _cardBg,
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.10),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Image.asset(
            'assets/pcc.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                'P',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Main card ──
  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _cardBg,
        border: Border.all(color: _border.withValues(alpha: 0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Sign in',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isAdmin
                  ? 'Manage your coaching centre'
                  : 'Track your child\'s progress',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // ── Form ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                      begin: const Offset(0, .03), end: Offset.zero)
                      .animate(a),
                  child: child,
                ),
              ),
              child: _formFields(),
            ),

            const SizedBox(height: 28),

            // ── Sign In Button ──
            _buildSignInButton(),
            
            // ── Return to Parent Mode (Admin Only) ──
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: TextButton(
                    onPressed: () => _switchMode(false),
                    style: TextButton.styleFrom(
                      foregroundColor: _textTertiary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Return to Parent Login',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Toggle pill (Removed) ──

  // ── Sign In button ──
  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _isLoading ? _accent.withValues(alpha: 0.7) : _accent,
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isLoading ? null : _login,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              size: 15, color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form fields ──
  Widget _formFields() {
    if (_isAdmin) {
      return Column(
        key: const ValueKey('admin'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Username'),
          const SizedBox(height: 8),
          _cleanField(controller: _usernameController, hint: 'admin', icon: Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _label('Password'),
          const SizedBox(height: 8),
          _cleanField(
            controller: _passwordController,
            hint: 'Enter password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            isObscured: _obscurePassword,
          ),
          const SizedBox(height: 16),
          _label('Authenticator Code (optional)'),
          const SizedBox(height: 8),
          _cleanField(
            controller: _totpController,
            hint: '6-digit code from Google Authenticator',
            icon: Icons.security_rounded,
            keyboard: TextInputType.number,
          ),
        ],
      );
    }
    // Parent
    return Column(
      key: const ValueKey('parent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Username'),
        const SizedBox(height: 8),
        _cleanField(controller: _usernameController, hint: 'Student ID or username', icon: Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _label('Password'),
        const SizedBox(height: 8),
        _cleanField(
          controller: _passwordController,
          hint: 'Enter password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
          isObscured: _obscurePassword,
        ),
      ],
    );
  }

  // ── Label ──
  Widget _label(String t) {
    return Text(t,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
          letterSpacing: 0.2,
        ));
  }

  // ── Clean text field ──
  Widget _cleanField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    VoidCallback? toggleObscure,
    bool isObscured = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: _textPrimary,
        fontWeight: FontWeight.w400,
      ),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: _textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 20, color: _textTertiary),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _textTertiary,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: _fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      ),
    );
  }

}
