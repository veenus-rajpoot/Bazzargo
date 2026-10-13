import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final List<dynamic> response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      // Mark all fetched notifications as read
      if (_notifications.isNotEmpty) {
        final unreadIds = _notifications
            .where((n) => !(n['is_read'] as bool? ?? false))
            .map((n) => n['id'])
            .toList();

        if (unreadIds.isNotEmpty) {
          await Supabase.instance.client
              .from('notifications')
              .update({'is_read': true})
              .inFilter('id', unreadIds);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;
                await Supabase.instance.client
                    .from('notifications')
                    .delete()
                    .eq('user_id', user.id);
                _loadNotifications();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                            SizedBox(height: 0),
                            Text(
                              'All caught up!',
                              style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 0),
                            Text(
                              'Matches and updates will appear here.',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final type = notification['type'] as String? ?? 'general';

                          if (type == 'match_found') {
                            return _MatchNotificationTile(
                              notification: notification,
                              onRefresh: _loadNotifications,
                            );
                          }

                          return _GeneralNotificationTile(notification: notification);
                        },
                      ),
      ),
    );
  }
}

class _GeneralNotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _GeneralNotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final isRead = notification['is_read'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
          ),
          SizedBox(width: 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppTheme.primaryColor),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 0),
                Text(
                  message,
                  style: TextStyle(fontSize: 12.sp, color: Colors.black87, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchNotificationTile extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onRefresh;

  const _MatchNotificationTile({
    required this.notification,
    required this.onRefresh,
  });

  @override
  State<_MatchNotificationTile> createState() => _MatchNotificationTileState();
}

class _MatchNotificationTileState extends State<_MatchNotificationTile> {
  bool _fetchingDetails = true;
  bool _processingAction = false;
  Map<String, dynamic>? _matchData;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('delivery_matches')
          .select('*, delivery_requests(*)')
          .eq('id', widget.notification['related_id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          _matchData = response;
          _fetchingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fetchingDetails = false;
        });
      }
    }
  }

  Future<void> _handleAccept() async {
    if (_matchData == null) return;
    setState(() => _processingAction = true);

    try {
      final client = Supabase.instance.client;
      final matchId = _matchData!['id'];
      final deliveryRequest = _matchData!['delivery_requests'];
      final deliveryRequestId = deliveryRequest['id'];
      final pickup = deliveryRequest['pickup_location'];
      final drop = deliveryRequest['drop_location'];
      final senderId = deliveryRequest['sender_id'];

      // Check if delivery request is already matched
      final checkRequest = await client
          .from('delivery_requests')
          .select()
          .eq('id', deliveryRequestId)
          .single();

      if (checkRequest['status'] != 'pending') {
        throw Exception('This package has already been matched with another traveler.');
      }

      // 1. Accept current match
      await client.from('delivery_matches').update({'status': 'accepted'}).eq('id', matchId);

      // 2. Accept delivery request
      await client.from('delivery_requests').update({'status': 'accepted'}).eq('id', deliveryRequestId);

      // 3. Reject other matches for the same request
      await client
          .from('delivery_matches')
          .update({'status': 'rejected'})
          .eq('delivery_request_id', deliveryRequestId)
          .neq('id', matchId);

      // 4. Create customer notification
      final user = client.auth.currentUser;
      final travelerName = user?.userMetadata?['full_name'] ?? 'A traveler';

      await client.from('notifications').insert({
        'user_id': senderId,
        'title': 'Traveler Found!',
        'message': '$travelerName has accepted to carry your parcel from $pickup to $drop.',
        'type': 'match_accepted',
        'related_id': deliveryRequestId,
      });

      // 5. Create traveler confirmation notification
      if (user != null) {
        await client.from('notifications').insert({
          'user_id': user.id,
          'title': 'Delivery Match Confirmed!',
          'message': 'You have accepted to carry the parcel from $pickup to $drop.',
          'type': 'general',
          'related_id': deliveryRequestId,
        });
      }

      // 6. Create chat room for traveler + customer
      Map<String, dynamic>? chatRoom;
      if (user != null) {
        try {
          final chatRepo = ChatRepository(client);
          chatRoom = await chatRepo.createOrGetChatRoom(
            deliveryRequestId: deliveryRequestId,
            matchId: matchId,
            customerId: senderId,
            travelerId: user.id,
          );
        } catch (e) {
          // Chat room creation is non-blocking — proceed even if it fails
        }
      }

      if (mounted) {
        final itemType = deliveryRequest['item_type'] as String? ?? 'Parcel';
        // Navigate directly to chat after accepting
        if (chatRoom != null && user != null) {
          Navigator.pop(context); // pop any dialogs
          widget.onRefresh();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                deliveryRequestId: deliveryRequestId,
                roomId: chatRoom!['id'] as String,
                otherUserId: senderId,
                otherUserName: 'Customer',
                itemType: itemType,
                pickup: pickup,
                drop: drop,
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF0A7E3E), size: 28),
                  SizedBox(width: 6.w),
                  Text('Match Accepted!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'You are live now! The customer has been notified.',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRefresh();
                  },
                  child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A7E3E))),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
        setState(() => _processingAction = false);
      }
    }
  }

  Future<void> _handleReject() async {
    if (_matchData == null) return;
    setState(() => _processingAction = true);

    try {
      final client = Supabase.instance.client;
      final matchId = _matchData!['id'];

      // 1. Reject current match
      await client.from('delivery_matches').update({'status': 'rejected'}).eq('id', matchId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match rejected.')),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _processingAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetchingDetails) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_matchData == null) {
      return const SizedBox.shrink();
    }

    final deliveryRequest = _matchData!['delivery_requests'];
    final pickup = deliveryRequest['pickup_location'] as String? ?? '';
    final drop = deliveryRequest['drop_location'] as String? ?? '';
    final itemType = deliveryRequest['item_type'] as String? ?? '';
    final reward = deliveryRequest['reward_amount'] as num? ?? 0.0;
    final matchStatus = _matchData!['status'] as String? ?? 'pending';

    final bool isStillPending = matchStatus == 'pending' && deliveryRequest['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isStillPending ? Colors.green.shade200 : Colors.grey.shade200, width: isStillPending ? 1.5 : 1),
        boxShadow: isStillPending
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isStillPending ? Color(0xFFDCFCE7) : Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch,
                  color: isStillPending ? Color(0xFF166534) : Color(0xFF475569),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStillPending ? 'Matching Request Found!' : 'Match Resolved',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isStillPending ? Color(0xFF166534) : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Delivery item: $itemType',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
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
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(left: 3, top: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 12,
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 0),
          // Tip/Reward
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Traveler Tip:',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              Text(
                '₹ $reward',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
              ),
            ],
          ),
          SizedBox(height: 0),
          // Action Buttons
          if (isStillPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processingAction ? null : _handleReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processingAction ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0A7E3E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _processingAction
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: matchStatus == 'accepted' 
                      ? Colors.green.shade50 
                      : (matchStatus == 'completed' ? Colors.blue.shade50 : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  matchStatus == 'accepted' 
                      ? 'Accepted' 
                      : (matchStatus == 'completed' ? 'Completed' : (matchStatus == 'cancelled' ? 'Cancelled' : 'Rejected')),
                  style: TextStyle(
                    color: matchStatus == 'accepted' 
                        ? Colors.green.shade700 
                        : (matchStatus == 'completed' ? Colors.blue.shade700 : Colors.red.shade700),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
