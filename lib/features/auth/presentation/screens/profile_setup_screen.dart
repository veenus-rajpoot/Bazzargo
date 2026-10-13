import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.userMetadata?['full_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateProfile(fullName: name);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 16.sp),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16.h),

              // Profile Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 56.r,
                    backgroundColor: Color(0xFFE2E8F0),
                    backgroundImage:
                        user?.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user!.userMetadata!['avatar_url'])
                            : null,
                    child: user?.userMetadata?['avatar_url'] == null
                        ? Icon(Icons.person_outline,
                            size: 48.sp, color: Color(0xFF64748B))
                        : null,
                  ),
                  Container(
                    padding: EdgeInsets.all(7.w),
                    decoration: BoxDecoration(
                      color: AppTheme.actionOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt,
                        color: Colors.white, size: 18.sp),
                  ),
                ],
              ),
              SizedBox(height: 28.h),

              Text(
                'What should we call you?',
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter your full name so travelers know who they are delivering for.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 28.h),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(14.w),
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline,
                          color: Color(0xFFDC2626), size: 18.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),

              // Name Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor),
                  decoration: InputDecoration(
                    hintText: 'Enter Full Name',
                    hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp),
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppTheme.primaryColor, size: 20.sp),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // Save Button
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppTheme.actionOrange)
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.actionOrange,
                        minimumSize: Size(double.infinity, 52.h),
                        elevation: 4,
                        shadowColor:
                            AppTheme.actionOrange.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: Text(
                        'Save & Continue',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
