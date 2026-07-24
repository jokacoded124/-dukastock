import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/product_image_widget.dart';
import 'cart_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  /// When provided, only products from this wholesaler are shown and the
  /// header displays their name. When null, all products are shown (the
  /// original all-shops catalog view) — kept for backward compatibility
  /// with any existing navigation straight into the full catalog.
  final String? wholesalerId;
  final String? wholesalerName;

  const ProductCatalogScreen({
    super.key,
    this.wholesalerId,
    this.wholesalerName,
  });

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All'];

  bool get _isFiltered => widget.wholesalerId != null;

  // ─── Gesture Handler: Long Press ──────────────────────────────────────────
  void _onProductLongPress(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? data['Name'] ?? 'Unnamed Product';
    final price = data['price'] ?? data['Price'] ?? 0;
    final category = data['category'] ?? 'Uncategorised';
    final stock = data['stock'] ?? data['Stock'] ?? 0;
    final description = data['description'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ProductDetailsSheet(
        name: name, price: price, category: category,
        stock: stock, description: description,
        onAddToCart: () {
          Navigator.pop(context);
          _showQuantityDialog(docId, data);
        },
      ),
    );
  }

  // ─── Quantity dialog → add to cart ────────────────────────────────────────
  void _showQuantityDialog(String docId, Map<String, dynamic> data) {
    final name = (data['name'] ?? data['Name'] ?? 'Unnamed Product').toString();
    final num price = (data['price'] ?? data['Price'] ?? 0) as num;
    final num stock = (data['stock'] ?? data['Stock'] ?? 0) as num;

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is out of stock')),
      );
      return;
    }

    int quantity = 1;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final total = price * quantity;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KES ${price.toStringAsFixed(0)} per unit',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantity > 1
                          ? () => setDialogState(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: kGreen,
                    ),
                    Container(
                      width: 56,
                      alignment: Alignment.center,
                      child: Text('$quantity',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: quantity < stock
                          ? () => setDialogState(() => quantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: kGreen,
                    ),
                  ],
                ),
                Center(
                  child: Text('$stock units available',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('KES ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: kGreen,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _addToCart(docId, data, quantity);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add to Cart', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Add to cart, handling cross-wholesaler conflicts ─────────────────────
  void _addToCart(String docId, Map<String, dynamic> data, int quantity) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to order')),
      );
      return;
    }

    final name = (data['name'] ?? data['Name'] ?? 'Unnamed Product').toString();
    final num price = (data['price'] ?? data['Price'] ?? 0) as num;
    final num stock = (data['stock'] ?? data['Stock'] ?? 0) as num;
    final String? wholesalerId = data['wholesalerId'] as String?;
    final String? imageUrl = (data['imageUrl'] ?? data['imageBase64']) as String?;

    if (wholesalerId == null || wholesalerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product has no wholesaler on record')),
      );
      return;
    }

    void performAdd() {
      CartService.instance.addItem(
        productId: docId,
        productName: name,
        price: price,
        stock: stock,
        wholesalerId: wholesalerId,
        quantity: quantity,
        imageUrl: imageUrl,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $name to cart'),
          backgroundColor: kGreen,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
    }

    if (CartService.instance.hasConflict(wholesalerId)) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Different shop'),
          content: const Text(
            'Your cart has items from another wholesaler. Adding this product '
                'will clear your current cart and start a new one.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                CartService.instance.clear();
                performAdd();
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen),
              child: const Text('Clear & Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      performAdd();
    }
  }

  // ─── Favourites: toggle on/off via users/{uid}/favourites/{productId} ────
  Future<void> _toggleFavourite(String docId, Map<String, dynamic> data, bool isFavourited) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('favourites')
        .doc(docId);

    try {
      if (isFavourited) {
        await favRef.delete();
      } else {
        await favRef.set({
          'productName': data['name'] ?? data['Name'] ?? 'Unnamed Product',
          'price': data['price'] ?? data['Price'] ?? 0,
          'stock': data['stock'] ?? data['Stock'] ?? 0,
          'wholesalerId': data['wholesalerId'],
          'imageUrl': data['imageUrl'] ?? data['imageBase64'],
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favourites: $e')),
        );
      }
    }
  }

  void _buildCategories(List<QueryDocumentSnapshot> docs) {
    final cats = <String>{'All'};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cat = (data['category'] ?? '').toString().trim();
      if (cat.isNotEmpty) cats.add(cat);
    }
    if (cats.length != _categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _categories
            ..clear()
            ..addAll(cats);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
                    Expanded(
                      child: Text(
                        _isFiltered
                            ? (widget.wholesalerName ?? 'Products')
                            : 'Products',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22,
                            fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    _CartIconWithBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar — filters by name AND category
                Container(
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: _isFiltered
                          ? 'Search this shop\'s products...'
                          : 'Search by name or category...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Category filter chips ────────────────────────────────────────
          if (_categories.length > 1)
            Container(
              height: 48,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? kGreen : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade700)),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Product list ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _isFiltered
                  ? FirebaseFirestore.instance
                  .collection('products')
                  .where('wholesalerId', isEqualTo: widget.wholesalerId)
                  .snapshots()
                  : FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _shimmerList();
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
                _buildCategories(docs);

                // Filter by search query (name OR category) AND selected chip
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? data['Name'] ?? '')
                      .toString().toLowerCase();
                  final cat = (data['category'] ?? '')
                      .toString().toLowerCase();
                  final matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      cat.contains(_searchQuery);
                  final matchesCategory = _selectedCategory == 'All' ||
                      (data['category'] ?? '') == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          docs.isEmpty && _isFiltered
                              ? 'This wholesaler has no products yet'
                              : 'No products found',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'All')
                          TextButton(
                            onPressed: () => setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                            }),
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: kGreen,
                  onRefresh: () async =>
                      Future.delayed(const Duration(milliseconds: 500)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _productCard(doc.id, data);
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

  // ── Shimmer loading placeholder ──────────────────────────────────────────
  Widget _shimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            _shimmerBox(64, 64, radius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(16, 140),
                  const SizedBox(height: 8),
                  _shimmerBox(12, 80),
                  const SizedBox(height: 8),
                  _shimmerBox(15, 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 6}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          height: height, width: width,
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(radius)),
        ),
      ),
    );
  }

  Widget _productCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? data['Name'] ?? 'Unnamed Product';
    final price = data['price'] ?? data['Price'] ?? 0;
    final category = data['category'] ?? '';
    final stock = data['stock'] ?? data['Stock'] ?? 0;
    final imageUrl = (data['imageUrl'] ?? data['imageBase64']) as String?;

    return GestureDetector(
      onLongPress: () => _onProductLongPress(docId, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade200,
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ProductImage(image: imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEECFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(category,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500)),
                    ),
                  const SizedBox(height: 4),
                  Text('KES $price',
                      style: const TextStyle(color: kGreen,
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('Stock: $stock',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FavouriteButton(docId: docId, data: data, onToggle: _toggleFavourite),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: kGreen, borderRadius: BorderRadius.circular(10)),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _showQuantityDialog(docId, data),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cart icon with live badge count, shown in the catalog header ────────────
class _CartIconWithBadge extends StatelessWidget {
  const _CartIconWithBadge();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartService.instance.itemsNotifier,
      builder: (context, items, _) {
        final count = CartService.instance.totalItems;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Favourite heart toggle, live-synced to Firestore ────────────────────────
class _FavouriteButton extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Future<void> Function(String, Map<String, dynamic>, bool) onToggle;

  const _FavouriteButton({
    required this.docId,
    required this.data,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox(width: 24, height: 24);

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('favourites')
        .doc(docId);

    return StreamBuilder<DocumentSnapshot>(
      stream: favRef.snapshots(),
      builder: (context, snapshot) {
        final isFavourited = snapshot.data?.exists ?? false;
        return GestureDetector(
          onTap: () => onToggle(docId, data, isFavourited),
          child: Icon(
            isFavourited ? Icons.favorite : Icons.favorite_border,
            color: isFavourited ? const Color(0xFFDC2626) : Colors.grey.shade400,
            size: 22,
          ),
        );
      },
    );
  }
}

// ── Product Details Bottom Sheet ─────────────────────────────────────────────
class _ProductDetailsSheet extends StatelessWidget {
  final String name;
  final dynamic price, stock;
  final String category, description;
  final VoidCallback onAddToCart;

  const _ProductDetailsSheet({required this.name, required this.price,
    required this.category, required this.stock,
    required this.description, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: const Color(0xFFDEECFF),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF2563EB), size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Text(name, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 20),
          _row(Icons.category_outlined, 'Category',
              category.isEmpty ? 'Uncategorised' : category),
          _row(Icons.attach_money, 'Price', 'KES $price'),
          _row(Icons.numbers, 'Stock', '$stock units available'),
          if (description.isNotEmpty)
            _row(Icons.description_outlined, 'Description', description),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kGreen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Close', style: TextStyle(color: kGreen)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
                onPressed: onAddToCart,
                style: ElevatedButton.styleFrom(backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Add to Cart',
                    style: TextStyle(color: Colors.white)))),
          ]),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(fontSize: 13,
            color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
