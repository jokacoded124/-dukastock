import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/cart_service.dart';
import '../widgets/product_image_widget.dart';
import 'cart_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

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
                  'Favourites',
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
                'You must be logged in to view favourites.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : _FavouritesList(currentUserId: currentUserId),
          ),
        ],
      ),
    );
  }
}

class _FavouritesList extends StatelessWidget {
  final String currentUserId;

  const _FavouritesList({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favourites');

    return StreamBuilder<QuerySnapshot>(
      stream: favRef.orderBy('addedAt', descending: true).snapshots(),
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
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Color(0xFFDC2626),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No favourites yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart on any product\nto save it here.',
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _FavouriteCard(
              productId: doc.id,
              currentUserId: currentUserId,
              data: data,
            );
          },
        );
      },
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  final String productId;
  final String currentUserId;
  final Map<String, dynamic> data;

  const _FavouriteCard({
    required this.productId,
    required this.currentUserId,
    required this.data,
  });

  Future<void> _removeFavourite(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('favourites')
          .doc(productId)
          .delete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove favourite: $e')),
        );
      }
    }
  }

  void _showQuantityDialog(BuildContext context) {
    final name = (data['productName'] ?? 'Unnamed Product').toString();
    final num price = (data['price'] ?? 0) as num;
    final num stock = (data['stock'] ?? 0) as num;
    final String? wholesalerId = data['wholesalerId'] as String?;
    final String? imageUrl = (data['imageUrl'] ?? data['imageBase64']) as String?;

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is out of stock')),
      );
      return;
    }
    if (wholesalerId == null || wholesalerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product has no wholesaler on record')),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(name,
                style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KES ${price.toStringAsFixed(0)} per unit',
                    style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade400)),
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
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.w500)),
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
                child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _addToCart(context, name, price, stock, wholesalerId, imageUrl, quantity);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child:
                const Text('Add to Cart', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Same wholesaler-conflict handling as the catalog screen, kept in sync
  // so a favourite from a different shop doesn't silently mix into a cart.
  void _addToCart(
      BuildContext context,
      String name,
      num price,
      num stock,
      String wholesalerId,
      String? imageUrl,
      int quantity,
      ) {
    void performAdd() {
      CartService.instance.addItem(
        productId: productId,
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

  @override
  Widget build(BuildContext context) {
    final name = data['productName'] ?? 'Unnamed Product';
    final price = data['price'] ?? 0;
    final stock = data['stock'] ?? 0;
    final imageUrl = (data['imageUrl'] ?? data['imageBase64']) as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ProductImage(image: imageUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('KES $price',
                    style: const TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text('Stock: $stock',
                    style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _removeFavourite(context),
                child: const Icon(Icons.favorite, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    color: kGreen, borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showQuantityDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
