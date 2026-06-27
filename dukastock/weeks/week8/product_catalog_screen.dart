import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

/// Handles all touch gesture interactions on the product catalog screen.
/// Tap        → triggers the add-to-cart action on the + button.
/// Long Press → opens a bottom sheet showing full product details and options.
/// Pull down  → triggers a manual refresh of the product list.
class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  String _searchQuery = '';

  // ─── Gesture Handler: Long Press ────────────────────────────────────────────
  void _onProductLongPress(Map<String, dynamic> data) {
    final name = data['name'] ?? data['Name'] ?? 'Unnamed Product';
    final price = data['price'] ?? data['Price'] ?? 0;
    final category = data['category'] ?? 'Uncategorised';
    final stock = data['stock'] ?? data['Stock'] ?? 0;
    final description = data['description'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ProductDetailsSheet(
        name: name,
        price: price,
        category: category,
        stock: stock,
        description: description,
        onAddToCart: () {
          Navigator.pop(context);
          _onAddToCart(name);
        },
      ),
    );
  }

  // ─── Gesture Handler: Tap (+ button) with undo snackbar ─────────────────────
  void _onAddToCart(String name) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name removed from cart')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          Container(
            color: kGreen,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text('Products',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kGreen));
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Network error. Check your connection.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? data['Name'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No products found',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: kGreen,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data =
                      filtered[index].data() as Map<String, dynamic>;
                      return _productCard(data);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> data) {
    final name = data['name'] ?? data['Name'] ?? 'Unnamed Product';
    final price = data['price'] ?? data['Price'] ?? 0;
    final category = data['category'] ?? '';
    final stock = data['stock'] ?? data['Stock'] ?? 0;

    return GestureDetector(
      onLongPress: () => _onProductLongPress(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2_outlined,
                  color: Colors.grey, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(category,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('KES $price',
                      style: const TextStyle(
                          color: kGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text('Stock: $stock',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: kGreen, borderRadius: BorderRadius.circular(10)),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _onAddToCart(name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Details Bottom Sheet ─────────────────────────────────────────────
class _ProductDetailsSheet extends StatelessWidget {
  final String name;
  final dynamic price;
  final String category;
  final dynamic stock;
  final String description;
  final VoidCallback onAddToCart;

  const _ProductDetailsSheet({
    required this.name,
    required this.price,
    required this.category,
    required this.stock,
    required this.description,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: const Color(0xFFDEECFF),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF2563EB), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow(Icons.category_outlined, 'Category',
              category.isEmpty ? 'Uncategorised' : category),
          _detailRow(Icons.attach_money, 'Price', 'KES $price'),
          _detailRow(Icons.numbers, 'Stock', '$stock units available'),
          if (description.isNotEmpty)
            _detailRow(Icons.description_outlined, 'Description', description),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kGreen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                  const Text('Close', style: TextStyle(color: kGreen)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add to Cart',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
