import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isWholesaler = role == 'wholesaler';

    final retailerItems = [
      _MenuItem(Icons.search, 'Browse Products',
          const Color(0xFFDEECFF), const Color(0xFF2563EB)),
      _MenuItem(Icons.shopping_cart_outlined, 'My Orders',
          const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
      _MenuItem(Icons.store_outlined, 'Wholesalers',
          const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
      _MenuItem(Icons.favorite_border, 'Favourites',
          const Color(0xFFFFE4E6), const Color(0xFFE11D48)),
    ];

    final wholesalerItems = [
      _MenuItem(Icons.inventory_2_outlined, 'Manage Stock',
          const Color(0xFFDEECFF), const Color(0xFF2563EB)),
      _MenuItem(Icons.receipt_long_outlined, 'Orders',
          const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
      _MenuItem(Icons.people_outline, 'Retailers',
          const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
      _MenuItem(Icons.bar_chart, 'Sales Report',
          const Color(0xFFCCFBF1), const Color(0xFF0D9488)),
    ];

    final items = isWholesaler ? wholesalerItems : retailerItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Header
          Container(
            color: kGreen,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white),
                    const Text(
                      'DukaStock',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Welcome banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kGreenLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWholesaler
                            ? 'Welcome, Wholesaler!'
                            : 'Welcome, Retailer!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWholesaler
                            ? 'Manage your stock and orders'
                            : 'Browse products and place orders',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Menu grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWholesaler ? 'Wholesaler Menu' : 'Retailer Menu',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: items.map((item) => _menuCard(item)).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(_MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: item.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  const _MenuItem(this.icon, this.label, this.bgColor, this.iconColor);
}
