import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/matching_service.dart';

class PostJourneyScreen extends StatefulWidget {
  const PostJourneyScreen({super.key});

  @override
  State<PostJourneyScreen> createState() => _PostJourneyScreenState();
}

class _PostJourneyScreenState extends State<PostJourneyScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  DateTime _travelDate = DateTime.now();
  TimeOfDay _departureTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 16, minute: 30);

  String _selectedVehicle = 'Train';
  double _capacity = 5.0;
  String _journeyDirection = 'forward'; // 'forward' (one-way A to B) or 'both' (round-trip)

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _submitJourney() async {
    final fromStr = _fromController.text.trim();
    final toStr = _toController.text.trim();

    if (fromStr.isEmpty || toStr.isEmpty) {
      setState(() => _errorMessage = 'Please fill out both pickup and drop locations');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('You must be logged in to post a journey');

      // Convert travel date to YYYY-MM-DD
      final dateStr = '${_travelDate.year}-${_travelDate.month.toString().padLeft(2, '0')}-${_travelDate.day.toString().padLeft(2, '0')}';

      final insertedJourney = await Supabase.instance.client.from('journeys').insert({
        'traveler_id': user.id,
        'from_location': fromStr,
        'to_location': toStr,
        'journey_direction': _journeyDirection,
        'travel_date': dateStr,
        'departure_time': _formatTimeOfDay(_departureTime),
        'arrival_time': _formatTimeOfDay(_arrivalTime),
        'vehicle_type': _selectedVehicle,
        'carrying_capacity': _capacity,
        'status': 'live',
      }).select().single();

      // Trigger matching logic
      MatchingService.performMatchingForJourney(insertedJourney);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF1B8A44), size: 28),
                SizedBox(width: 8.w),
                Text('success'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'you_are_live_now'.tr(),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/home');
                },
                child: Text('ok'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Color(0xFF1B8A44))),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 0),
            Text(
              'BazzarGo',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19.sp, color: AppTheme.primaryColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
          SizedBox(width: 0),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'post_your_journey'.tr(),
              style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 0),
            Text(
              'post_journey_subtitle'.tr(),
              style: TextStyle(color: Colors.black87, fontSize: 14.sp, height: 1.4),
            ),
            SizedBox(height: 0),
            
            // From / To Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top circular node: O
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Color(0xFF1B8A44), width: 2),
                        ),
                      ),
                      SizedBox(height: 0),
                      // Dotted connecting line with arrow
                      _buildDottedArrowConnector(
                        height: 52,
                        doubleHeaded: _journeyDirection == 'both',
                      ),
                      SizedBox(height: 0),
                      // Bottom circular node: O
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Color(0xFF1B8A44), width: 2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 0),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: TextField(
                            controller: _fromController,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'from_location_hint'.tr(),
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
                              prefixIcon: Icon(Icons.my_location_outlined, color: Colors.grey.shade400, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        SizedBox(height: 0),
                        // Separator line with overlapping circular toggle button
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Divider(height: 1, color: Colors.grey.shade300),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _journeyDirection = (_journeyDirection == 'forward') ? 'both' : 'forward';
                                });
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE8F5E9), // Active green background
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(0xFF1B8A44), // Active green border
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _journeyDirection == 'both' ? Icons.swap_vert : Icons.arrow_downward,
                                  color: Color(0xFF1B8A44), // Highlighted green icon
                                  size: 19.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: TextField(
                            controller: _toController,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'to_location_hint'.tr(),
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
                              prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
            
            // Date & Time
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _travelDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        setState(() {
                          _travelDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('travel_date'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          SizedBox(height: 0),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 0),
                              Expanded(
                                child: Text(
                                  _formatDate(_travelDate),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 0),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _departureTime,
                      );
                      if (picked != null) {
                        setState(() {
                          _departureTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('departure'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          SizedBox(height: 0),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 0),
                              Expanded(
                                child: Text(
                                  _formatTimeOfDay(_departureTime),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 0),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _arrivalTime,
                      );
                      if (picked != null) {
                        setState(() {
                          _arrivalTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('arrival'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          SizedBox(height: 0),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 0),
                              Expanded(
                                child: Text(
                                  _formatTimeOfDay(_arrivalTime),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0),
            
            // Vehicle Type
            Row(
              children: [
                Icon(Icons.directions_train, size: 20),
                SizedBox(width: 6.w),
                Text('vehicle_type'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 0),
            Row(
              children: [
                Expanded(child: _VehicleChip('train'.tr(), Icons.train, _selectedVehicle == 'Train', () => setState(() => _selectedVehicle = 'Train'))),
                SizedBox(width: 0),
                Expanded(child: _VehicleChip('bus'.tr(), Icons.directions_bus, _selectedVehicle == 'Bus', () => setState(() => _selectedVehicle = 'Bus'))),
                SizedBox(width: 0),
                Expanded(child: _VehicleChip('car'.tr(), Icons.directions_car, _selectedVehicle == 'Car', () => setState(() => _selectedVehicle = 'Car'))),
                SizedBox(width: 0),
                Expanded(child: _VehicleChip('bike'.tr(), Icons.two_wheeler, _selectedVehicle == 'Bike', () => setState(() => _selectedVehicle = 'Bike'))),
              ],
            ),
            SizedBox(height: 0),
            
            // Carrying Capacity
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.work_outline, size: 24),
                          SizedBox(width: 6.w),
                          Text('carrying_capacity'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          '${_capacity.toInt()} kg',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                    ),
                    child: Slider(
                      value: _capacity,
                      min: 1,
                      max: 50,
                      activeColor: AppTheme.primaryColor,
                      inactiveColor: Colors.grey.shade400,
                      onChanged: (val) => setState(() => _capacity = val),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 kg', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                        Text('25 kg', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                        Text('50 kg', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 0),
            
            // Allowed Items
            Row(
              children: [
                Icon(Icons.category_outlined, size: 24),
                SizedBox(width: 6.w),
                Text('allowed_items'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 100), // Padding for the floating button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitJourney,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.actionGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.white),
                      SizedBox(width: 6.w),
                      Text(
                        'go_live'.tr(),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDottedArrowConnector({required double height, required bool doubleHeaded}) {
    const activeColor = Color(0xFF1B8A44);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (doubleHeaded)
          Icon(Icons.keyboard_arrow_up, size: 10, color: activeColor)
        else
          SizedBox(height: 0),
        const SizedBox(height: 2),
        ...List.generate(
          4,
          (index) => Container(
            width: 1.5,
            height: 3,
            color: activeColor.withValues(alpha: 0.5),
            margin: const EdgeInsets.symmetric(vertical: 2),
          ),
        ),
        const SizedBox(height: 2),
        Icon(Icons.keyboard_arrow_down, size: 10, color: activeColor),
      ],
    );
  }


}

class _VehicleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleChip(this.label, this.icon, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 28),
            SizedBox(height: 0),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
