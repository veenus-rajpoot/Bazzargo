import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 0),
                Text(
                  '₹42,850.00',
                  style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 0),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.actionGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Withdraw Funds'),
                ),
              ],
            ),
          ),
          SizedBox(height: 0),
          Text('Recent Transactions', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 0),
          // Placeholder for transactions
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
            title: Text('Delivery Payout'),
            subtitle: Text('Today, 12:30 PM'),
            trailing: Text('+ ₹450', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
