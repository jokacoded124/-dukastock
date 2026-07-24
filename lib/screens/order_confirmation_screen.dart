import 'package:flutter/material.dart';
import '../constants.dart';
import 'orders_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId; // orderGroupId from checkout batch
  final int itemCount; // number of distinct products
  final int totalUnits; // total quantity across all items
  final num totalPrice;
  final String paymentMethod;
  final String summaryLine; // e.g. "Omo 1kg + 2 more items"

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.itemCount,
    required this.totalUnits,
    required this.totalPrice,
    required this.paymentMethod,
    required this.summaryLine,
  });

  String get _shortOrderId =>
      orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: kGreen,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Order Placed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order has been sent to the wholesaler\nfor confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 28),

              // Receipt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _row('Order ID', '#$_shortOrderId'),
                    _row('Items', summaryLine),
                    _row('Products',
                        '$itemCount product${itemCount == 1 ? '' : 's'}'),
                    _row('Total Units', '$totalUnits units'),
                    _row('Payment Method', paymentMethod),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid',
                            style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(
                          'KES ${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View My Orders',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kGreen),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue Shopping',
                      style: TextStyle(color: kGreen, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
