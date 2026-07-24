import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/product_image_widget.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
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
                  'Cart',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<CartItem>>(
              valueListenable: CartService.instance.itemsNotifier,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDEECFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Color(0xFF2563EB),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Your cart is empty',
                          style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add products from the catalog\nto see them here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text('Browse Products',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _CartTile(item: items[index]),
                      ),
                    ),
                    _CheckoutBar(items: items),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ProductImage(image: item.imageUrl, size: 56, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'KES ${item.price.toStringAsFixed(0)} × ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _qtyButton(
                      icon: Icons.remove,
                      onTap: () => CartService.instance
                          .updateQuantity(item.productId, item.quantity - 1),
                    ),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text('${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    _qtyButton(
                      icon: Icons.add,
                      onTap: item.quantity < item.stock
                          ? () => CartService.instance.updateQuantity(
                          item.productId, item.quantity + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => CartService.instance.removeItem(item.productId),
                child: Icon(Icons.delete_outline,
                    color: Colors.grey.shade400, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'KES ${item.total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: kGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF0FDF4) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16, color: enabled ? kGreen : Colors.grey.shade400),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final List<CartItem> items;
  const _CheckoutBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<num>(0, (sum, i) => sum + i.total);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  Text(
                    'KES ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: kGreen),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(items: items),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Checkout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
