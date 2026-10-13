import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bazzargo/core/theme/app_theme.dart';
import 'package:bazzargo/features/auth/data/auth_repository.dart';
import 'package:bazzargo/features/sender/data/delivery_repository.dart';
import 'package:bazzargo/features/sender/presentation/providers/delivery_providers.dart';
import 'package:bazzargo/features/traveler/data/journey_repository.dart';
import 'package:bazzargo/features/traveler/presentation/providers/journey_providers.dart';
import 'package:bazzargo/features/chat/data/chat_repository.dart';
import 'package:bazzargo/features/chat/presentation/screens/chat_screen.dart';
import 'package:easy_localization/easy_localization.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _nearbyTravelers = [];
  String? _errorMessage;
  bool _isRatingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final client = Supabase.instance.client;

      // 1. Fetch unread notifications count
      final countRes = await client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      // 2. Fetch nearby travelers (live journeys posted by other users) (without profiles join)
      final List<dynamic> travelersRes = await client
          .from('journeys')
          .select()
          .eq('status', 'live')
          .neq('traveler_id', user.id)
          .limit(5);

      // 3. Fetch profiles for all relevant travelers to join in memory
      final List<String> profileIdsToFetch = [];
      for (final t in travelersRes) {
        if (t['traveler_id'] != null) {
          profileIdsToFetch.add(t['traveler_id'] as String);
        }
      }

      Map<String, Map<String, dynamic>> profilesMap = {};
      if (profileIdsToFetch.isNotEmpty) {
        final profilesRes = await client
            .from('profiles')
            .select()
            .inFilter('id', profileIdsToFetch.toSet().toList());

        for (final p in profilesRes) {
          profilesMap[p['id'] as String] = Map<String, dynamic>.from(p);
        }
      }

      final List<Map<String, dynamic>> finalTravelers = [];
      for (final t in travelersRes) {
        final Map<String, dynamic> travelerCopy = Map<String, dynamic>.from(t);
        final travelerId = t['traveler_id'] as String?;
        if (travelerId != null && profilesMap.containsKey(travelerId)) {
          travelerCopy['profiles'] = profilesMap[travelerId];
        }
        finalTravelers.add(travelerCopy);
      }

      if (mounted) {
        setState(() {
          _unreadCount = countRes.length;
          _nearbyTravelers = finalTravelers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelDeliveryRequest(String requestId) async {
    try {
      final repo = ref.read(deliveryRepositoryProvider);
      // Use repository — marks status 'cancelled' in Supabase
      await repo.cancelDeliveryRequest(requestId);
      // Invalidate provider so realtime + manual refresh both update
      ref.invalidate(activeDeliveriesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled successfully.'),
          backgroundColor: Color(0xFF0A7E3E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling request: $e')),
      );
    }
  }

  Future<void> _cancelJourney(String journeyId) async {
    try {
      final repo = ref.read(journeyRepositoryProvider);
      // Use repository — marks status 'cancelled' in Supabase
      await repo.cancelJourney(journeyId);
      // Invalidate provider so realtime + manual refresh both update
      ref.invalidate(ownLiveJourneysProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journey ended successfully.'),
          backgroundColor: Color(0xFF0A7E3E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending journey: $e')),
      );
    }
  }

  void _confirmCancelRequest(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        title: Text('Cancel Request?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this delivery request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('NO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelDeliveryRequest(requestId);
            },
            child: Text('YES, CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelJourney(String journeyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        title: Text('Cancel Journey?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel your live journey? Any matched customers will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('NO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelJourney(journeyId);
            },
            child: Text('YES, CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showVerifyDialog(Map<String, dynamic> match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VerifyDeliveryBottomSheet(
        match: match, 
        onComplete: () {
          _loadData();
          ref.invalidate(ownLiveJourneysProvider);
        },
      ),
    );
  }

  Set<String> _ratedMatchIds = {};

  void _showRatingDialog(String matchId, String travelerId, String travelerName) {
    int _selectedRating = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: Text('Delivery Completed!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How was your experience with $travelerName?', textAlign: TextAlign.center),
                  SizedBox(height: 20.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            _selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            index < _selectedRating ? Icons.star : Icons.star_border,
                            color: Color(0xFFEAB308),
                            size: 32.sp,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_selectedRating == 0) return;
                    _ratedMatchIds.add(matchId);
                    Navigator.pop(context);
                    try {
                      final repo = ref.read(deliveryRepositoryProvider);
                      await repo.rateTraveler(matchId, travelerId, _selectedRating);
                      ref.invalidate(unratedDeliveriesProvider);
                    } catch (_) {}
                    _isRatingDialogOpen = false;
                  },
                  child: Text('SUBMIT', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check active roles
    final activeDeliveries = ref.watch(activeDeliveriesProvider).value ?? [];
    final activeJourneys = ref.watch(ownLiveJourneysProvider).value ?? [];
    
    final isCustomerActive = activeDeliveries.isNotEmpty;
    final isTravelerActive = activeJourneys.isNotEmpty;

    // Check for unrated deliveries to show popup
    final unrated = ref.watch(unratedDeliveriesProvider).value ?? [];
    if (unrated.isNotEmpty && !_isRatingDialogOpen) {
      final delivery = unrated.first;
      final matches = delivery['delivery_matches'] as List<dynamic>? ?? [];
      if (matches.isNotEmpty) {
        final match = matches.first;
        final matchId = match['id'] as String;
        
        // Skip if we already rated this in the current session
        if (!_ratedMatchIds.contains(matchId)) {
          final journey = match['journeys'];
          final travelerId = journey?['traveler_id'];
          final travelerName = 'Traveler'; // Hide real names
          if (travelerId != null) {
            _isRatingDialogOpen = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showRatingDialog(matchId, travelerId, travelerName);
            });
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'BazzarGo',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24.sp,
            color: AppTheme.primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_outlined, color: AppTheme.primaryColor, size: 26.sp),
                onPressed: () => context.push('/notifications').then((_) => _loadData()),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error Banner ──
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: const Color(0xFF991B1B), fontSize: 12.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // ══════════════════════════════════════════════
              // ── ACTION CARDS (Customer / Traveler) ──
              // ══════════════════════════════════════════════
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── I'm Customer Card ──
                    Expanded(
                      child: _IllustrationActionCard(
                        title: 'im_customer'.tr(),
                        imagePath: 'assets/images/customer_banner.png',
                        bgColor: const Color(0xFFFDECD0),
                        isActive: isCustomerActive,
                        isBlurred: isTravelerActive && !isCustomerActive,
                        onTap: () => context.push('/send-parcel').then((_) => _loadData()),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // ── I'm Traveler Card ──
                    Expanded(
                      child: _IllustrationActionCard(
                        title: 'im_traveler'.tr(),
                        imagePath: 'assets/images/traveler_banner.png',
                        bgColor: const Color(0xFFCDF5D1),
                        isActive: isTravelerActive,
                        isBlurred: isCustomerActive && !isTravelerActive,
                        onTap: () => context.push('/post-journey').then((_) => _loadData()),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // ══════════════════════════════════════════════
              // ── NEARBY TRAVELERS ──
              // ══════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'nearby_travelers'.tr(),
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: -0.3),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text(
                      'VIEW ALL'.tr(),
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppTheme.actionGreen, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // ── Nearby Travelers List ──
              SizedBox(
                height: 180.h,
                child: _isLoading && _nearbyTravelers.isEmpty
                    ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : _nearbyTravelers.isEmpty
                        ? Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.explore_outlined, size: 36.sp, color: Colors.grey.shade300),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'no_active_travelers'.tr(),
                                    style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13.sp),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _nearbyTravelers.length,
                            clipBehavior: Clip.none,
                            itemBuilder: (context, index) {
                              final traveler = _nearbyTravelers[index];
                              final profile = traveler['profiles'];
                              final travelerName = 'Traveler';
                              final avatarUrl = profile != null ? profile['avatar_url'] as String? : null;
                              final initials = 'T';

                              final fromLoc = traveler['from_location'] as String? ?? '';
                              final toLoc = traveler['to_location'] as String? ?? '';
                              final vehicle = traveler['vehicle_type'] as String? ?? 'Train';

                              final ratingSum = profile != null ? (profile['rating_sum'] as int? ?? 0) : 0;
                              final ratingCount = profile != null ? (profile['rating_count'] as int? ?? 0) : 0;
                              final ratingDisplay = ratingCount > 0 ? (ratingSum / ratingCount).toStringAsFixed(1) : 'New';

                              return Container(
                                width: 180.w,
                                margin: EdgeInsets.only(right: 14.w),
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: Colors.grey.shade100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar + Name + Rating row
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20.r,
                                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                          backgroundColor: const Color(0xFFE8F8EE),
                                          child: avatarUrl == null
                                              ? Text(initials, style: TextStyle(color: AppTheme.actionGreen, fontWeight: FontWeight.bold, fontSize: 14.sp))
                                              : null,
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                travelerName,
                                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: AppTheme.primaryColor),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 2.h),
                                              Row(
                                                children: [
                                                  Icon(Icons.star_rounded, size: 14.sp, color: const Color(0xFFEAB308)),
                                                  SizedBox(width: 3.w),
                                                  Text(
                                                    ratingCount > 0 ? '$ratingDisplay ($ratingCount)' : 'New Traveler'.tr(),
                                                    style: TextStyle(fontSize: 11.sp, color: const Color(0xFFCA8A04), fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    // Route info container
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                vehicle == 'Train'
                                                    ? Icons.train_outlined
                                                    : vehicle == 'Bus'
                                                        ? Icons.directions_bus_outlined
                                                        : vehicle == 'Car'
                                                            ? Icons.directions_car_outlined
                                                            : Icons.two_wheeler_outlined,
                                                size: 14.sp,
                                                color: AppTheme.actionGreen,
                                              ),
                                              SizedBox(width: 6.w),
                                              Expanded(
                                                child: Text(
                                                  '$fromLoc → $toLoc',
                                                  style: TextStyle(color: const Color(0xFF1B4332), fontSize: 12.sp, fontWeight: FontWeight.w700),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'departs_at'.tr(args: [traveler['departure_time'].toString()]),
                                            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              SizedBox(height: 24.h),

              // ══════════════════════════════════════════════
              // ── MY ACTIVE ORDERS ──
              // ══════════════════════════════════════════════
              Text(
                'my_active_orders'.tr(),
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: -0.3),
              ),
              SizedBox(height: 10.h),

              ref.watch(activeDeliveriesProvider).when(
                loading: () => Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                data: (deliveries) => deliveries.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.inventory_2_outlined, size: 36.sp, color: AppTheme.actionGreen.withValues(alpha: 0.5)),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'no_active_deliveries'.tr(),
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'your_posted_parcel_requests_will_show_up_here'.tr(),
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: deliveries.map((delivery) {
                          final matches = delivery['delivery_matches'] as List<dynamic>? ?? [];
                          final acceptedMatch = matches.firstWhere(
                            (m) => m['status'] == 'accepted',
                            orElse: () => <String, dynamic>{},
                          );

                          final isMatched = acceptedMatch.isNotEmpty;
                          final itemType = delivery['item_type'] as String? ?? 'Parcel';
                          final pickup = delivery['pickup_location'] as String? ?? '';
                          final drop = delivery['drop_location'] as String? ?? '';
                          final status = delivery['status'] as String? ?? 'pending';

                          String travelerName = 'Finding Traveler...';
                          String? travelerAvatar;
                          String statusText = 'Pending Match';
                          Color statusBgColor = const Color(0xFFFEF3C7);
                          Color statusTextColor = const Color(0xFF92400E);
                          double progressValue = 0.2;

                          if (isMatched) {
                            final journey = acceptedMatch['journeys'];
                            final profile = journey != null ? journey['profiles'] : null;
                            travelerName = 'Traveler';
                            travelerAvatar = profile != null ? profile['avatar_url'] as String? : null;
                            statusText = isMatched ? 'Match Found' : (status == 'in_transit' ? 'In Transit' : 'Traveler Found');
                            statusBgColor = const Color(0xFFDCFCE7);
                            statusTextColor = const Color(0xFF166534);
                            progressValue = 0.75;
                          }

                          return Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: isMatched ? const Color(0xFFBBF7D0) : Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row: item icon + name + status badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Icon(Icons.widgets_outlined, color: AppTheme.actionGreen, size: 24.sp),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itemType,
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp, color: AppTheme.primaryColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'ID: BZG-${delivery['id'].toString().substring(0, 8).toUpperCase()}',
                                            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusTextColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Route row: Pickup → Drop
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8.w,
                                              height: 8.w,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.actionGreen,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Expanded(
                                              child: Text(
                                                pickup,
                                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                                        child: Icon(Icons.arrow_forward, size: 14.sp, color: Colors.grey.shade400),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8.w,
                                              height: 8.w,
                                              decoration: BoxDecoration(
                                                color: AppTheme.actionOrange,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Expanded(
                                              child: Text(
                                                drop,
                                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(isMatched ? AppTheme.actionGreen : AppTheme.actionOrange),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                // Traveler row + action buttons
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14.r,
                                      backgroundImage: travelerAvatar != null ? NetworkImage(travelerAvatar) : null,
                                      backgroundColor: const Color(0xFFE8F8EE),
                                      child: travelerAvatar == null
                                          ? Text(
                                              travelerName.substring(0, 1).toUpperCase(),
                                              style: TextStyle(color: AppTheme.actionGreen, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        isMatched ? 'Traveler: $travelerName' : travelerName,
                                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13.sp),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // ── Locked after match: show Chat button ──
                                    if (isMatched)
                                      GestureDetector(
                                        onTap: () async {
                                          final deliveryRequestId = delivery['id'] as String;
                                          final matchId = acceptedMatch['id'] as String? ?? '';
                                          final travelerId = (acceptedMatch['journeys']?['traveler_id'] as String?) ?? '';
                                          final currentUser = ref.read(currentUserProvider);
                                          final customerId = currentUser?.id ?? '';
                                          final journey = acceptedMatch['journeys'];
                                          final profile = journey?['profiles'];
                                          final tName = 'Traveler';
                                          final tAvatar = profile?['avatar_url'] as String?;
                                          try {
                                            final chatRepo = ref.read(chatRepositoryProvider);
                                            // createOrGetChatRoom creates room if not yet existing
                                            final room = await chatRepo.createOrGetChatRoom(
                                              deliveryRequestId: deliveryRequestId,
                                              matchId: matchId,
                                              customerId: customerId,
                                              travelerId: travelerId,
                                            );
                                            if (!context.mounted) return;
                                            Navigator.of(context).push(MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                deliveryRequestId: deliveryRequestId,
                                                roomId: room['id'] as String,
                                                otherUserId: travelerId,
                                                otherUserName: tName,
                                                otherUserAvatar: tAvatar,
                                                itemType: itemType,
                                                pickup: pickup,
                                                drop: drop,
                                              ),
                                            ));
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error opening chat: $e')),
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(10.r),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.chat_bubble_outline, size: 13.sp, color: Colors.white),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Chat',
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () => _confirmCancelRequest(delivery['id'] as String),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(10.r),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.cancel_outlined, size: 13.sp, color: Colors.red.shade600),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.red.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              // ══════════════════════════════════════════════
              // ── MY LIVE JOURNEYS ──
              // ══════════════════════════════════════════════
              ref.watch(ownLiveJourneysProvider).when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (ownJourneys) => ownJourneys.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Live Journeys',
                                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: -0.3),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Text(
                                  '${ownJourneys.length} Live',
                                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF166534)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Column(
                            children: ownJourneys.map((journey) {
                              final from = journey['from_location'] as String? ?? '';
                              final to = journey['to_location'] as String? ?? '';
                              final vehicle = journey['vehicle_type'] as String? ?? '';
                              final journeyId = journey['id'] as String;

                              // Check if this journey has an accepted delivery match
                              final journeyMatches = (journey['delivery_matches'] as List<dynamic>?) ?? [];
                              final acceptedJourneyMatch = journeyMatches.firstWhere(
                                (m) => m['status'] == 'accepted',
                                orElse: () => <String, dynamic>{},
                              );
                              final hasAcceptedMatch = acceptedJourneyMatch.isNotEmpty;
                              final matchedDeliveryRequestId = hasAcceptedMatch
                                  ? acceptedJourneyMatch['delivery_request_id'] as String? ?? ''
                                  : '';
                              final matchedCustomerId = hasAcceptedMatch
                                  ? (acceptedJourneyMatch['delivery_requests']?['sender_id'] as String?) ?? ''
                                  : '';

                              return Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: hasAcceptedMatch
                                        ? AppTheme.actionOrange
                                        : const Color(0xFFBBF7D0),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (hasAcceptedMatch ? AppTheme.actionOrange : AppTheme.actionGreen).withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10.w),
                                          decoration: BoxDecoration(
                                            color: hasAcceptedMatch ? const Color(0xFFFFF5EB) : const Color(0xFFDCFCE7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            vehicle == 'Train'
                                                ? Icons.train_outlined
                                                : vehicle == 'Bus'
                                                    ? Icons.directions_bus_outlined
                                                    : vehicle == 'Car'
                                                        ? Icons.directions_car_outlined
                                                        : Icons.two_wheeler_outlined,
                                            color: hasAcceptedMatch ? AppTheme.actionOrange : AppTheme.actionGreen,
                                            size: 18.sp,
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$from → $to',
                                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp, color: AppTheme.primaryColor),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8.w,
                                                    height: 8.w,
                                                    decoration: BoxDecoration(
                                                      color: hasAcceptedMatch
                                                          ? AppTheme.actionOrange
                                                          : AppTheme.actionGreen,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Text(
                                                    hasAcceptedMatch ? 'MATCH FOUND' : 'LIVE',
                                                    style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight: FontWeight.w900,
                                                      color: hasAcceptedMatch
                                                          ? AppTheme.actionOrange
                                                          : AppTheme.actionGreen,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // ── Chat or End Journey ──
                                        if (hasAcceptedMatch)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _showVerifyDialog(acceptedJourneyMatch),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.actionOrange,
                                                    borderRadius: BorderRadius.circular(10.r),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.verified_user_outlined, size: 14.sp, color: Colors.white),
                                                      SizedBox(width: 3.w),
                                                      Text(
                                                        'Verify',
                                                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 6.w),
                                              GestureDetector(
                                                onTap: () async {
                                                  final currentUser = ref.read(currentUserProvider);
                                                  final travelerId = currentUser?.id ?? '';
                                                  final matchId = acceptedJourneyMatch['id'] as String? ?? '';
                                                  final deliveryReq = acceptedJourneyMatch['delivery_requests'];
                                                  final itemTypej = (deliveryReq?['item_type'] as String?) ?? 'Parcel';
                                                  final pickupj = (deliveryReq?['pickup_location'] as String?) ?? '';
                                                  final dropj = (deliveryReq?['drop_location'] as String?) ?? '';
                                                  try {
                                                    final chatRepo = ref.read(chatRepositoryProvider);
                                                    // createOrGetChatRoom creates room if not yet existing
                                                    final room = await chatRepo.createOrGetChatRoom(
                                                      deliveryRequestId: matchedDeliveryRequestId,
                                                      matchId: matchId,
                                                      customerId: matchedCustomerId,
                                                      travelerId: travelerId,
                                                    );
                                                    if (!context.mounted) return;
                                                    Navigator.of(context).push(MaterialPageRoute(
                                                      builder: (_) => ChatScreen(
                                                        deliveryRequestId: matchedDeliveryRequestId,
                                                        roomId: room['id'] as String,
                                                        otherUserId: matchedCustomerId,
                                                        otherUserName: 'Customer',
                                                        itemType: itemTypej,
                                                        pickup: pickupj,
                                                        drop: dropj,
                                                      ),
                                                    ));
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Error opening chat: $e')),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    borderRadius: BorderRadius.circular(10.r),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.chat_bubble_outline, size: 14.sp, color: Colors.white),
                                                      SizedBox(width: 3.w),
                                                      Text(
                                                        'Chat',
                                                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          GestureDetector(
                                            onTap: () => _confirmCancelJourney(journeyId),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(10.r),
                                                border: Border.all(color: Colors.red.shade200),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.stop_circle_outlined, size: 14.sp, color: Colors.red.shade600),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    'End Journey',
                                                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.red.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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

class _IllustrationActionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isActive;
  final bool isBlurred;

  const _IllustrationActionCard({
    required this.title,
    required this.imagePath,
    required this.bgColor,
    required this.onTap,
    this.isActive = false,
    this.isBlurred = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isBlurred ? 0.5 : 1.0,
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isActive ? AppTheme.actionGreen.withValues(alpha: 0.4) : Colors.grey.shade200,
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: AppTheme.actionGreen.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illustration image
              Center(
                child: Image.asset(
                  imagePath,
                  height: 100.h,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_outlined,
                    size: 50.sp,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // Title + Arrow CTA row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.actionGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyDeliveryBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> match;
  final VoidCallback onComplete;

  const _VerifyDeliveryBottomSheet({required this.match, required this.onComplete});

  @override
  ConsumerState<_VerifyDeliveryBottomSheet> createState() => _VerifyDeliveryBottomSheetState();
}

class _VerifyDeliveryBottomSheetState extends ConsumerState<_VerifyDeliveryBottomSheet> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _pinSent = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final pin = widget.match['verification_pin'] as String?;
    if (pin != null && pin.isNotEmpty) {
      _pinSent = true;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _sendPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final customerId = widget.match['delivery_requests']?['sender_id'] as String?;
      if (customerId == null) throw Exception('Customer not found');
      
      await repo.sendVerificationPin(widget.match['id'], customerId);
      
      if (mounted) {
        setState(() {
          _pinSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 5) {
      setState(() => _errorMessage = 'Please enter a 5-digit PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final reqId = widget.match['delivery_request_id'];
      final journeyId = widget.match['journey_id'];
      
      await repo.verifyDelivery(widget.match['id'], reqId, journeyId, pin);
      
      if (mounted) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
        
        // Wait a moment for success animation then close
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
          widget.onComplete();
        }
      }
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
    if (_isSuccess) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: const Color(0xFF0A7E3E), size: 80.sp),
            SizedBox(height: 16.h),
            Text(
              'Journey Completed Successfully!',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Payment will be processed and added to your wallet shortly.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Complete Delivery',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            _pinSent 
              ? 'Ask the customer for the 5-digit verification code they received.'
              : 'When you are with the customer, send them a verification PIN to complete this delivery.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp),
              ),
            ),

          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 5,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w900, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '00000',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.actionOrange, width: 2),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.actionOrange,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: _isLoading && _pinController.text.trim().length == 5
                ? SizedBox(height: 20.h, width: 20.h, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Verify & Complete', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: _isLoading ? null : _sendPin,
            child: Text(_pinSent ? 'Resend OTP' : 'Send OTP', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }
}
