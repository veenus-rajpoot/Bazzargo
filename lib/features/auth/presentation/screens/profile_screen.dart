import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final fullName = user?.userMetadata?['full_name'] ?? 'Traveler';
    final emailOrPhone = user?.email ?? user?.phone ?? 'Google Account';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(
          'my_profile'.tr(),
          style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 17.sp),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        children: [
          Center(
            child: CircleAvatar(
              radius: 52.r,
              backgroundColor: Color(0xFFE2E8F0),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, size: 48.sp, color: Color(0xFF64748B))
                  : null,
            ),
          ),
          SizedBox(height: 14.h),

          // Name + edit row
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    fullName,
                    style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 6.w),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18.sp, color: AppTheme.actionOrange),
                  onPressed: () => context.push('/profile-setup'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Center(
            child: Text(
              emailOrPhone,
              style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 28.h),

          // Rating score card
          FutureBuilder<Map<String, dynamic>?>(
            future: Supabase.instance.client
                .from('profiles')
                .select('rating_sum, rating_count')
                .eq('id', user?.id ?? '')
                .maybeSingle(),
            builder: (context, snapshot) {
              final data = snapshot.data;
              final rSum = data?['rating_sum'] as int? ?? 0;
              final rCount = data?['rating_count'] as int? ?? 0;
              final rDisplay = rCount > 0 ? (rSum / rCount).toStringAsFixed(1) : 'traveler_rating_new'.tr().split(':').last.trim();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
                  leading: Container(
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                        color: Color(0xFFFEF08A).withValues(alpha: 0.3),
                        shape: BoxShape.circle),
                    child: Icon(Icons.star,
                        color: Color(0xFFCA8A04), size: 20.sp),
                  ),
                  title: Text(
                    rCount > 0 ? 'traveler_rating'.tr(args: [rDisplay]) : 'traveler_rating_new'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        fontSize: 14.sp),
                  ),
                  subtitle: Text(
                    rCount > 0 ? 'based_on_deliveries'.tr(args: [rCount.toString()]) : 'no_ratings_yet'.tr(),
                    style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20.h),

          // Options card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit_note,
                      color: AppTheme.primaryColor, size: 22.sp),
                  title: Text('edit_name_and_profile'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.sp)),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20.sp),
                  onTap: () => context.push('/profile-setup'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.settings_outlined,
                      color: AppTheme.primaryColor, size: 22.sp),
                  title: Text('settings'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.sp)),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20.sp),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language,
                      color: AppTheme.primaryColor, size: 22.sp),
                  title: Text('language_selection_title'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.sp)),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20.sp),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('language_selection_title'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              SizedBox(height: 20.h),
                              ListTile(
                                leading: const Icon(Icons.language),
                                title: Text('english'.tr()),
                                trailing: context.locale.languageCode == 'en' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                                onTap: () {
                                  context.setLocale(const Locale('en'));
                                  Navigator.pop(ctx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.language),
                                title: Text('hindi'.tr()),
                                trailing: context.locale.languageCode == 'hi' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                                onTap: () {
                                  context.setLocale(const Locale('hi'));
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout,
                      color: Colors.redAccent, size: 22.sp),
                  title: Text('logout'.tr(),
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp)),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/language');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever,
                      color: Colors.red.shade900, size: 22.sp),
                  title: Text('delete_account'.tr(),
                      style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext ctx) {
                        return AlertDialog(
                          title: Text('delete_account_question'.tr()),
                          content: Text('delete_account_warning'.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text('cancel'.tr()),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                try {
                                  await ref.read(authRepositoryProvider).deleteAccount();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Account deleted successfully')),
                                    );
                                    context.go('/language');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              },
                              child: Text('confirm'.tr(), style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
