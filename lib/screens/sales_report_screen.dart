import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';

class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Header
          Container(
            color: kGreen,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Sales Report',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: currentUserId == null
                ? Center(
              child: Text(
                'You must be logged in to view your sales report.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : _SalesReportBody(wholesalerId: currentUserId),
          ),
        ],
      ),
    );
  }
}

class _SalesReportBody extends StatelessWidget {
  final String wholesalerId;

  const _SalesReportBody({required this.wholesalerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('wholesalerId', isEqualTo: wholesalerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kGreen),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bar_chart_outlined,
                    color: kGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No sales yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your sales summary will appear\nhere once orders come in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        // ── Compute summary stats ──────────────────────────────────────
        int pendingCount = 0;
        int confirmedCount = 0;
        int rejectedCount = 0;
        num confirmedRevenue = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'pending') as String;
          final num total = (data['totalPrice'] ?? 0) as num;

          switch (status) {
            case 'confirmed':
              confirmedCount++;
              confirmedRevenue += total;
              break;
            case 'rejected':
              rejectedCount++;
              break;
            case 'pending':
            default:
              pendingCount++;
              break;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Revenue highlight card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Revenue (Confirmed Orders)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${confirmedRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stat grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Pending',
                    value: '$pendingCount',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Confirmed',
                    value: '$confirmedCount',
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Rejected',
                    value: '$rejectedCount',
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEE2E2),
                    icon: Icons.cancel_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total Orders',
                    value: '${docs.length}',
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFDEECFF),
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ...docs.take(10).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _RecentOrderTile(data: data);
            }),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RecentOrderTile({required this.data});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending') as String;
    final productName = (data['productName'] ?? 'Unknown product') as String;
    final retailerName = (data['retailerName'] ?? '') as String;
    final num totalPrice = (data['totalPrice'] ?? 0) as num;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
                if (retailerName.isNotEmpty)
                  Text(
                    retailerName,
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Text(
            'KES ${totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}