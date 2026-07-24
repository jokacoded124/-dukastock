import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/storage_service.dart';
import '../widgets/product_image_widget.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _role;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await StorageService.getRole();
    if (!mounted) return;
    setState(() {
      _role = role;
      _loadingRole = false;
    });
  }

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
                Text(
                  _role == 'wholesaler' ? 'Incoming Orders' : 'My Orders',
                  style: const TextStyle(
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
            child: _loadingRole || currentUserId == null
                ? const Center(
                child: CircularProgressIndicator(color: kGreen))
                : _OrdersList(role: _role!, currentUserId: currentUserId),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String role;
  final String currentUserId;

  const _OrdersList({required this.role, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isWholesaler = role == 'wholesaler';

    final query = FirebaseFirestore.instance
        .collection('orders')
        .where(
      isWholesaler ? 'wholesalerId' : 'retailerId',
      isEqualTo: currentUserId,
    )
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
          return _EmptyState(isWholesaler: isWholesaler);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _OrderCard(
              orderId: doc.id,
              data: data,
              isWholesaler: isWholesaler,
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final bool isWholesaler;

  const _OrderCard({
    required this.orderId,
    required this.data,
    required this.isWholesaler,
  });

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

  Color _statusBgColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFFDCFCE7);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'pending':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'confirmed' ? 'Order confirmed' : 'Order rejected',
            ),
            backgroundColor: kGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = (data['status'] ?? 'pending') as String;
    final String productName = (data['productName'] ?? 'Unknown product') as String;
    final num quantity = (data['quantity'] ?? 0) as num;
    final num pricePerUnit = (data['pricePerUnit'] ?? 0) as num;
    final num totalPrice = (data['totalPrice'] ?? (quantity * pricePerUnit)) as num;
    final String retailerName = (data['retailerName'] ?? '') as String;
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    final String? imageUrl = data['productImage'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantity units × KES ${pricePerUnit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isWholesaler && retailerName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'From: $retailerName',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(createdAt.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBgColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isWholesaler && status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(String? imageUrl) {
    return ProductImage(image: imageUrl, size: 56, borderRadius: 10);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final bool isWholesaler;
  const _EmptyState({required this.isWholesaler});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFFEA580C),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isWholesaler ? 'No incoming orders yet' : 'No orders yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWholesaler
                ? 'Orders from retailers will\nappear here.'
                : 'Your orders will appear here\nonce you start shopping.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (!isWholesaler)
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                'Browse Products',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
