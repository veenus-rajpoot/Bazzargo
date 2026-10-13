import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/matching_service.dart';
import '../../../../core/services/payment_service.dart';

class SendParcelScreen extends StatefulWidget {
  const SendParcelScreen({super.key});

  @override
  State<SendParcelScreen> createState() => _SendParcelScreenState();
}

class _SendParcelScreenState extends State<SendParcelScreen> {
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _itemTypeController = TextEditingController();
  final _rewardController = TextEditingController(text: '10');

  bool _isLoading = false;
  String? _errorMessage;
  String _parcelOption = 'send'; // 'send', 'want', or 'ride'

  final PaymentService _paymentService = PaymentService();

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _itemTypeController.dispose();
    _rewardController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final pickupStr = _pickupController.text.trim();
    final dropStr = _dropController.text.trim();
    final itemType = _itemTypeController.text.trim();
    final rewardText = _rewardController.text.trim();

    if (pickupStr.isEmpty || dropStr.isEmpty || itemType.isEmpty || rewardText.isEmpty) {
      setState(() => _errorMessage = 'Please fill out all required fields');
      return;
    }

    final double? rewardAmount = double.tryParse(rewardText);
    if (rewardAmount == null || rewardAmount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid tip amount');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('You must be logged in to send a parcel');

      // 1. Process Payment
      final contact = user.phone ?? '9999999999';
      final email = user.email ?? 'test@bazzargo.com';
      
      final paymentSuccess = await _paymentService.initiatePayment(contact, email);
      
      if (!paymentSuccess) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Payment failed or was cancelled.";
          });
        }
        return; // Abort
      }

      // image_url is null as the photo option is disabled
      const String? imageUrl = null;

      final insertedRequest = await Supabase.instance.client.from('delivery_requests').insert({
        'sender_id': user.id,
        'pickup_location': pickupStr,
        'drop_location': dropStr,
        'item_type': '[${_parcelOption.toUpperCase()}] $itemType',
        'image_url': imageUrl,
        'reward_amount': rewardAmount,
        'status': 'pending',
      }).select().single();

      // Trigger matching logic
      MatchingService.performMatchingForRequest(insertedRequest);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('success'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('parcel_posted_success'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/home');
                },
                child: Text('ok'.tr()),
              ),
            ],
          ),
        );
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
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
              ),
            ),
            SizedBox(width: 0),
            Text(
              'BazzarGo',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19.sp,
                color: AppTheme.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_outlined, color: AppTheme.primaryColor, size: 28),
            onPressed: () {},
          ),
          SizedBox(width: 0),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Options at the Top
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _parcelOption = 'send'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _parcelOption == 'send' ? Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _parcelOption == 'send' ? AppTheme.primaryColor : Colors.grey.shade300,
                          width: _parcelOption == 'send' ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            color: _parcelOption == 'send' ? AppTheme.primaryColor : Color(0xFF64748B),
                            size: 26.sp,
                          ),
                          SizedBox(height: 0),
                          Text(
                            'send_item'.tr(),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: _parcelOption == 'send' ? AppTheme.primaryColor : Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 0),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _parcelOption = 'want'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _parcelOption == 'want' ? Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _parcelOption == 'want' ? AppTheme.primaryColor : Colors.grey.shade300,
                          width: _parcelOption == 'want' ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: _parcelOption == 'want' ? AppTheme.primaryColor : Color(0xFF64748B),
                            size: 26.sp,
                          ),
                          SizedBox(height: 0),
                          Text(
                            'want_item'.tr(),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: _parcelOption == 'want' ? AppTheme.primaryColor : Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _parcelOption = 'ride'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _parcelOption == 'ride' ? Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _parcelOption == 'ride' ? AppTheme.primaryColor : Colors.grey.shade300,
                          width: _parcelOption == 'ride' ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            color: _parcelOption == 'ride' ? AppTheme.primaryColor : Color(0xFF64748B),
                            size: 26.sp,
                          ),
                          SizedBox(height: 0),
                          Text(
                            'ride'.tr(),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: _parcelOption == 'ride' ? AppTheme.primaryColor : Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                    SizedBox(width: 0),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Color(0xFF991B1B), fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 0),
            ],

            // Card 1: Locations
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'pickup_location'.tr(),
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                  ),
                  SizedBox(height: 0),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _pickupController,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        hintText: 'pickup_hint'.tr(),
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp, fontWeight: FontWeight.w500),
                        prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  // Connecting line
                  Padding(
                    padding: const EdgeInsets.only(left: 26.0, top: 4, bottom: 4),
                    child: Container(
                      width: 2,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Text(
                    'drop_location'.tr(),
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                  ),
                  SizedBox(height: 0),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _dropController,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        hintText: 'drop_hint'.tr(),
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp, fontWeight: FontWeight.w500),
                        prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 0),

            // Card 2: What are you sending / What item do you want
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _parcelOption == 'want'
                        ? 'what_item_do_you_want'.tr()
                        : _parcelOption == 'ride'
                            ? 'ride_details'.tr()
                            : 'what_are_you_sending'.tr(),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: -0.3),
                  ),
                  SizedBox(height: 0),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 0),
                        Icon(
                          _parcelOption == 'want'
                              ? Icons.shopping_bag_outlined
                              : _parcelOption == 'ride'
                                  ? Icons.directions_car_outlined
                                  : Icons.inventory_2_outlined,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        SizedBox(width: 0),
                        Expanded(
                          child: TextField(
                            controller: _itemTypeController,
                            style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: _parcelOption == 'want'
                                  ? 'item_want_hint'.tr()
                                  : _parcelOption == 'ride'
                                      ? 'ride_hint'.tr()
                                      : 'item_type_hint'.tr(),
                              hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13.sp, fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 0),

            // Card 3: Traveler Tip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'traveler_tip'.tr(),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: -0.3),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF86EFAC),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          'flexible_tip'.tr(),
                          style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                        ),
                        SizedBox(width: 0),
                        Expanded(
                          child: TextField(
                            controller: _rewardController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                            onChanged: (val) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'enter_amount'.tr(),
                              hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 18.sp, fontWeight: FontWeight.w900),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0),
                  Row(
                    children: [
                      Expanded(
                        child: _RewardChip(
                          '₹ 10',
                          _rewardController.text == '10',
                          () => setState(() => _rewardController.text = '10'),
                        ),
                      ),
                      SizedBox(width: 0),
                      Expanded(
                        child: _RewardChip(
                          '₹ 20',
                          _rewardController.text == '20',
                          () => setState(() => _rewardController.text = '20'),
                        ),
                      ),
                      SizedBox(width: 0),
                      Expanded(
                        child: _RewardChip(
                          '₹ 50',
                          _rewardController.text == '50',
                          () => setState(() => _rewardController.text = '50'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 0),

            // Action Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE67E22), // Action Orange
                minimumSize: const Size(double.infinity, 56),
                elevation: 4,
                shadowColor: Color(0xFFE67E22).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'pay_amount'.tr(args: [_rewardController.text.isEmpty ? '0' : _rewardController.text]),
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                        SizedBox(width: 6.w),
                        Icon(Icons.payment, color: Colors.white, size: 22),
                      ],
                    ),
            ),
            SizedBox(height: 0),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RewardChip(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE2EAFF) : Color(0xFFF1F5F9),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 10.sp,
          ),
        ),
      ),
    );
  }
}


