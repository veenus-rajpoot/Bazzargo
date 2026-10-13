import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bazzargo/core/theme/app_theme.dart';
import 'package:bazzargo/features/auth/data/auth_repository.dart';
import 'package:bazzargo/features/sender/data/delivery_repository.dart';
import 'package:bazzargo/features/sender/presentation/providers/delivery_providers.dart';
import 'package:bazzargo/features/chat/data/chat_repository.dart';
import 'package:bazzargo/features/chat/presentation/screens/chat_screen.dart';

class ActiveDeliveriesScreen extends ConsumerStatefulWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  ConsumerState<ActiveDeliveriesScreen> createState() => _ActiveDeliveriesScreenState();
}

class _ActiveDeliveriesScreenState extends ConsumerState<ActiveDeliveriesScreen> {

  Future<void> _cancelDelivery(BuildContext context, WidgetRef ref, String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        title: Text('Cancel Request?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this delivery request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('NO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('YES, CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(deliveryRepositoryProvider);
      await repo.cancelDeliveryRequest(requestId);
      ref.invalidate(activeDeliveriesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled successfully.'),
          backgroundColor: Color(0xFF0A7E3E),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(activeDeliveriesProvider);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'My Deliveries',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () => ref.invalidate(activeDeliveriesProvider),
          ),
        ],
      ),
      body: deliveriesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: Colors.redAccent))),
        data: (deliveries) => deliveries.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                  SizedBox(height: 0),
                  Center(
                    child: Text(
                      'No deliveries posted yet',
                      style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 0),
                  Center(
                    child: Text(
                      'Tap the "+" button on Home page to send a parcel.',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(activeDeliveriesProvider),
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    final matches = delivery['delivery_matches'] as List<dynamic>? ?? [];
                    final acceptedMatch = matches.firstWhere(
                      (m) => m['status'] == 'accepted',
                      orElse: () => <String, dynamic>{},
                    );

                    final isMatched = acceptedMatch.isNotEmpty;
                    final itemType = delivery['item_type'] as String? ?? 'Parcel';
                    final pickup = delivery['pickup_location'] as String? ?? '';
                    final drop = delivery['drop_location'] as String? ?? '';



                    String travelerName = 'Finding Traveler...';
                    String? travelerAvatar;
                    String statusText = 'Pending Match';
                    Color statusBgColor = Color(0xFFFEF3C7);
                    Color statusTextColor = Color(0xFF92400E);
                    double progressValue = 0.2;

                    if (isMatched) {
                      final journey = acceptedMatch['journeys'];
                      final profile = journey != null ? journey['profiles'] : null;
                      travelerName = 'Traveler';
                      travelerAvatar = profile != null ? profile['avatar_url'] as String? : null;
                      statusText = 'Match Found';
                      statusBgColor = Color(0xFFBBF7D0);
                      statusTextColor = Color(0xFF166534);
                      progressValue = 0.75;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 10,
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMatched ? Color(0xFFEFF6FF) : Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: isMatched ? Colors.blueAccent : Colors.orangeAccent,
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemType,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppTheme.primaryColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: BZG-${delivery['id'].toString().substring(0, 8).toUpperCase()}',
                                      style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 0),
                          // Route Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Colors.green),
                                    SizedBox(width: 0),
                                    Expanded(
                                      child: Text(
                                        'Pickup: $pickup',
                                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 3, top: 4, bottom: 4),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      height: 10,
                                      width: 1.5,
                                      child: VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 10, color: Colors.red),
                                    SizedBox(width: 0),
                                    Expanded(
                                      child: Text(
                                        'Drop: $drop',
                                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(isMatched ? Color(0xFF0A7E3E) : Colors.orange),
                            ),
                          ),
                          SizedBox(height: 0),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10.r,
                                backgroundImage: travelerAvatar != null ? NetworkImage(travelerAvatar) : null,
                                backgroundColor: AppTheme.primaryLight,
                                child: travelerAvatar == null
                                    ? Text(
                                        travelerName.substring(0, 1).toUpperCase(),
                                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 0),
                              Expanded(
                                child: Text(
                                  isMatched ? 'Traveler: $travelerName' : travelerName,
                                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // ── Chat button when matched, Cancel when pending ──
                              if (isMatched)
                                GestureDetector(
                                  onTap: () async {
                                    final deliveryRequestId = delivery['id'] as String;
                                    final matchId = acceptedMatch['id'] as String? ?? '';
                                    final travelerId = (acceptedMatch['journeys']?['traveler_id'] as String?) ?? '';
                                    final currentUser = ref.read(currentUserProvider);
                                    final customerId = currentUser?.id ?? '';
                                    final tName = travelerName;
                                    final tAvatar = travelerAvatar;
                                    try {
                                      final chatRepo = ref.read(chatRepositoryProvider);
                                      // createOrGetChatRoom: creates the room if it doesn't exist yet
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_bubble_outline, size: 12.sp, color: Colors.white),
                                        SizedBox(width: 3.w),
                                        Text(
                                          'Chat',
                                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () => _cancelDelivery(context, ref, delivery['id'] as String),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.cancel_outlined, size: 12.sp, color: Colors.red.shade600),
                                        SizedBox(width: 0),
                                        Text(
                                          'Cancel',
                                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.red.shade600),
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
                  },
                ),
              ),
      ),
    );
  }
}
