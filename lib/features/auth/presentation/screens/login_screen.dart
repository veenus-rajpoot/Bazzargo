import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/auth_repository.dart';

const String kGoogleWebClientId =
    '1013832705151-u9qii7a179suta269r3bn3rjfg9mmrk7.apps.googleusercontent.com';
const String kPrivacyPolicyUrl =
    'https://sites.google.com/view/bazzargo?usp=sharing';
const String kTermsConditionsUrl =
    'https://sites.google.com/view/bazaargo-terms-conditions?usp=sharing';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    if (kGoogleWebClientId.contains('YOUR_GOOGLE')) {
      setState(() {
        _errorMessage =
            'Please configure your Google Web Client ID in login_screen.dart or Supabase dashboard.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle(webClientId: kGoogleWebClientId);
      if (mounted) context.go('/profile-setup');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F5F4),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Illustration and Branding Section
                      Expanded(
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Background artwork / decorative elements
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _TopBackgroundPainter(),
                              ),
                            ),

                            // Branding Content
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 20.h),
                                  // Circular Logo Container with soft glow
                                  Container(
                                    width: 104.w,
                                    height: 104.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00A896).withValues(alpha: 0.18),
                                          blurRadius: 20,
                                          spreadRadius: 4,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(4.w),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // App Name: Bazzar (Navy) + Go (Teal)
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Bazzar',
                                          style: TextStyle(
                                            fontSize: 32.sp,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF1E2B48),
                                            letterSpacing: -0.5,
                                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Go',
                                          style: TextStyle(
                                            fontSize: 32.sp,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF00A896),
                                            letterSpacing: -0.5,
                                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8.h),

                                  // Tagline
                                  Text(
                                    'login_subtitle'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      color: const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),

                                  // Delivery Scooter Visual
                                  _DeliveryRiderIllustration(),
                                  SizedBox(height: 12.h),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom White Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(28.w, 28.h, 28.w, 24.h + MediaQuery.of(context).padding.bottom),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Welcome Header
                            Text(
                              'welcome_to_bazzargo'.tr(),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E2B48),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // Teal Accent Indicator Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32.w,
                                  height: 3.5.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A896),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Container(
                                  width: 4.w,
                                  height: 4.w,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00A896),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),

                            // Subtitle
                            Text(
                              'explore_subtitle'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Error message if any
                            if (_errorMessage != null)
                              Container(
                                padding: EdgeInsets.all(12.w),
                                margin: EdgeInsets.only(bottom: 16.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: const Color(0xFFDC2626),
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: const Color(0xFF991B1B),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Continue with Google Button
                            _isLoading
                                ? Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: const CircularProgressIndicator(
                                      color: Color(0xFF00A896),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _handleGoogleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1E2B48),
                                      elevation: 0,
                                      minimumSize: Size(double.infinity, 52.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14.r),
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const _GoogleGLogo(),
                                        SizedBox(width: 12.w),
                                        Text(
                                          'continue_with_google'.tr(),
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E2B48),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            SizedBox(height: 24.h),

                            // Terms of Service & Privacy Policy Footer
                            Text(
                              'by_continuing_agree'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _openUrl(kTermsConditionsUrl),
                                  child: Text(
                                    'terms_of_service'.tr(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF00A896),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Text(
                                  '  ${'and'.tr()}  ',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _openUrl(kPrivacyPolicyUrl),
                                  child: Text(
                                    'privacy_policy'.tr(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF00A896),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }
}

/// Official 4-Color Google "G" Icon Painter
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(20.w, 20.w),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w / 2;

    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;

    final Rect rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final double innerRadius = radius * 0.55;

    // Draw Google G geometry with accurate 4-color arcs & crossbar
    final Path bluePath = Path();
    bluePath.moveTo(cx, cy - innerRadius);
    bluePath.lineTo(w, cy);
    bluePath.lineTo(w, cy + radius * 0.1);
    bluePath.lineTo(cx, cy + radius * 0.1);
    bluePath.close();

    // Red arc (top)
    final Path redArc = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -3.14159 * 0.75, 3.14159 * 0.5, false)
      ..close();

    // Yellow arc (left)
    final Path yellowArc = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -3.14159 * 1.25, 3.14159 * 0.5, false)
      ..close();

    // Green arc (bottom)
    final Path greenArc = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, 3.14159 * 0.25, 3.14159 * 0.5, false)
      ..close();

    // Blue arc (right + bar)
    final Path blueArc = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -3.14159 * 0.25, 3.14159 * 0.5, false)
      ..close();

    canvas.drawPath(redArc, redPaint);
    canvas.drawPath(yellowArc, yellowPaint);
    canvas.drawPath(greenArc, greenPaint);
    canvas.drawPath(blueArc, bluePaint);

    // Inner cutout to make it a ring
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), innerRadius, whitePaint);

    // Right cut & horizontal bar
    final Path barPath = Path();
    barPath.addRect(Rect.fromLTRB(cx - 1, cy - innerRadius * 0.45, w, cy + innerRadius * 0.45));
    canvas.drawPath(barPath, bluePaint);

    // Top-right cutout angle
    final Path cutPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(w, cy - innerRadius)
      ..lineTo(w, cy)
      ..close();
    canvas.drawPath(cutPath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Delivery rider visual with scooter and package
class _DeliveryRiderIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.w,
      height: 72.h,
      decoration: BoxDecoration(
        color: const Color(0xFFD4EFEF).withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.two_wheeler,
            size: 48.sp,
            color: const Color(0xFF00A896),
          ),
          Positioned(
            right: 28.w,
            top: 14.h,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(
                Icons.inventory_2,
                size: 14.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter for the soft city silhouette, route curve, and location pin accents
class _TopBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pathPaint = Paint()
      ..color = const Color(0xFFB8E4E2).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Dotted / dashed curve representing travel journey
    final Path journeyPath = Path();
    journeyPath.moveTo(size.width * 0.15, size.height * 0.35);
    journeyPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.28,
      size.width * 0.5,
      size.height * 0.32,
    );
    journeyPath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.38,
      size.width * 0.85,
      size.height * 0.32,
    );

    // Draw route line
    canvas.drawPath(journeyPath, pathPaint);

    // Draw Location Pin Accents
    _drawPin(canvas, Offset(size.width * 0.18, size.height * 0.34), const Color(0xFF00A896), 10);
    _drawPin(canvas, Offset(size.width * 0.83, size.height * 0.33), const Color(0xFF6366F1), 11);
    _drawPin(canvas, Offset(size.width * 0.12, size.height * 0.65), const Color(0xFF00A896), 12);
  }

  void _drawPin(Canvas canvas, Offset center, Color color, double radius) {
    final Paint pinPaint = Paint()..color = color;
    final Paint centerDotPaint = Paint()..color = Colors.white;

    // Pin head
    canvas.drawCircle(center, radius, pinPaint);
    canvas.drawCircle(center, radius * 0.45, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
