import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../models/cart_item.dart';
import '../services/storage_service.dart';
import '../services/cart_service.dart';
import 'order_confirmation_screen.dart';

enum PaymentMethod { mpesa, cash, bank }

/// Checkout screen for a cart of one or more items, all belonging to the
/// same wholesaler (enforced by CartService before items ever land here).
///
/// Writes one `orders` doc per cart line, all sharing a common
/// `orderGroupId` so they can be displayed together later if needed, while
/// keeping the existing single-item order schema that Sales Report /
/// Incoming Orders / My Orders already query against.
class PaymentScreen extends StatefulWidget {
  final List<CartItem> items;

  const PaymentScreen({super.key, required this.items});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  num get _total => widget.items.fold(0, (sum, i) => sum + i.total);

  String get _wholesalerId => widget.items.first.wholesalerId;

  String _methodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.cash:
        return 'Cash on Delivery';
      case PaymentMethod.bank:
        return 'Bank Transfer';
    }
  }

  Future<void> _payNow() async {
    if (_selectedMethod == PaymentMethod.mpesa &&
        _phoneController.text.trim().length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid M-Pesa phone number')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to pay')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // ── Simulated payment processing ──────────────────────────────────
    // NOTE: This is a MOCK payment flow for demo purposes only. No real
    // money moves and no external payment gateway is called.
    await Future.delayed(const Duration(seconds: 2));

    try {
      final retailerName = await StorageService.getName() ?? 'Unknown Retailer';
      final paymentStatus =
      _selectedMethod == PaymentMethod.cash ? 'unpaid' : 'paid';
      final paymentMethodLabel = _methodLabel(_selectedMethod);

      // Group id shared across every order doc created in this checkout,
      // so a future "order history" view could reassemble the cart if
      // needed, without changing how existing per-order screens query.
      final orderGroupId =
          FirebaseFirestore.instance.collection('orders').doc().id;

      final batch = FirebaseFirestore.instance.batch();
      final ordersRef = FirebaseFirestore.instance.collection('orders');

      for (final item in widget.items) {
        final docRef = ordersRef.doc();
        batch.set(docRef, {
          'orderGroupId': orderGroupId,
          'retailerId': currentUser.uid,
          'retailerName': retailerName,
          'wholesalerId': item.wholesalerId,
          'productId': item.productId,
          'productName': item.productName,
          'productImage': item.imageUrl,
          'quantity': item.quantity,
          'pricePerUnit': item.price,
          'totalPrice': item.total,
          'status': 'pending',
          'paymentMethod': paymentMethodLabel,
          'paymentStatus': paymentStatus,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Cart only clears after a successful write, so a failed/interrupted
      // checkout doesn't silently lose the user's items.
      CartService.instance.clear();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            orderId: orderGroupId,
            itemCount: widget.items.length,
            totalUnits: widget.items.fold(0, (sum, i) => sum + i.quantity),
            totalPrice: _total,
            paymentMethod: paymentMethodLabel,
            summaryLine: _buildSummaryLine(),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _buildSummaryLine() {
    if (widget.items.length == 1) return widget.items.first.productName;
    final first = widget.items.first.productName;
    final rest = widget.items.length - 1;
    return '$first + $rest more item${rest == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: _isProcessing ? null : () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Payment',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: AbsorbPointer(
              absorbing: _isProcessing,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Summary',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const Divider(height: 20),
                          ...widget.items.map((item) => _summaryRow(
                              '${item.productName} × ${item.quantity}',
                              'KES ${item.total.toStringAsFixed(0)}')),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700)),
                              Text('KES ${_total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: kGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Select Payment Method',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    _paymentOptionTile(
                      method: PaymentMethod.mpesa,
                      icon: Icons.phone_iphone,
                      title: 'M-Pesa',
                      subtitle: 'Pay via M-Pesa STK push',
                    ),
                    const SizedBox(height: 10),
                    _paymentOptionTile(
                      method: PaymentMethod.cash,
                      icon: Icons.payments_outlined,
                      title: 'Cash on Delivery',
                      subtitle: 'Pay when goods arrive',
                    ),
                    const SizedBox(height: 10),
                    _paymentOptionTile(
                      method: PaymentMethod.bank,
                      icon: Icons.account_balance_outlined,
                      title: 'Bank Transfer',
                      subtitle: 'Pay via direct bank transfer',
                    ),

                    if (_selectedMethod == PaymentMethod.mpesa) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'M-Pesa Phone Number',
                          hintText: '07XXXXXXXX',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is a simulated payment for demo purposes. No real transaction occurs.',
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _payNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
                : Text(
              'Pay KES ${_total.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _paymentOptionTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kGreen : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF0FDF4) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? kGreen : Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? kGreen : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
