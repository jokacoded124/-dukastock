import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

/// Simple in-memory cart, scoped to a single wholesaler at a time.
///
/// Why single-wholesaler: orders are written with one `wholesalerId` per
/// doc (that's how Incoming Orders / Sales Report query), so mixing
/// products from different shops in one cart would break that. If the user
/// tries to add a product from a different wholesaler while the cart has
/// items, the UI should call `hasConflict` first and prompt them to clear
/// the cart, then call `clear()` + `addItem()`.
///
/// This is a singleton (no Provider/InheritedWidget dependency needed).
/// Screens listen via `CartService.instance.itemsNotifier`.
class CartService {
  CartService._internal();
  static final CartService instance = CartService._internal();

  final ValueNotifier<List<CartItem>> itemsNotifier =
  ValueNotifier<List<CartItem>>([]);

  List<CartItem> get items => itemsNotifier.value;

  bool get isEmpty => items.isEmpty;

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  num get totalPrice => items.fold(0, (sum, i) => sum + i.total);

  /// The wholesaler the current cart belongs to, or null if empty.
  String? get currentWholesalerId =>
      items.isEmpty ? null : items.first.wholesalerId;

  /// True if adding a product from [wholesalerId] would mix shops.
  bool hasConflict(String wholesalerId) {
    final current = currentWholesalerId;
    return current != null && current != wholesalerId;
  }

  /// Adds [quantity] of a product, merging with an existing line if the
  /// product is already in the cart. Clamps to available stock.
  /// Call `hasConflict` first — this does NOT check for cross-wholesaler
  /// conflicts, it assumes the caller already resolved that.
  void addItem({
    required String productId,
    required String productName,
    required num price,
    required num stock,
    required String wholesalerId,
    required int quantity,
    String? imageUrl,
  }) {
    final updated = List<CartItem>.from(items);
    final index = updated.indexWhere((i) => i.productId == productId);

    if (index >= 0) {
      final existing = updated[index];
      final newQty = (existing.quantity + quantity).clamp(1, stock.toInt());
      updated[index] = existing.copyWith(quantity: newQty);
    } else {
      updated.add(CartItem(
        productId: productId,
        productName: productName,
        price: price,
        stock: stock,
        wholesalerId: wholesalerId,
        quantity: quantity.clamp(1, stock.toInt()),
        imageUrl: imageUrl,
      ));
    }

    itemsNotifier.value = updated;
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = items.map((i) {
      if (i.productId == productId) {
        final clamped = quantity.clamp(1, i.stock.toInt());
        return i.copyWith(quantity: clamped);
      }
      return i;
    }).toList();
    itemsNotifier.value = updated;
  }

  void removeItem(String productId) {
    final updated = items.where((i) => i.productId != productId).toList();
    itemsNotifier.value = updated;
  }

  void clear() {
    itemsNotifier.value = [];
  }
}
