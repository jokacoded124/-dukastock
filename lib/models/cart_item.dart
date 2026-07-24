/// A single line item in the shopping cart.
///
/// Mutable `quantity` so CartService can adjust it in place; the list
/// instance itself is always replaced on change so ValueNotifier fires.
class CartItem {
  final String productId;
  final String productName;
  final num price;
  final num stock;
  final String wholesalerId;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.stock,
    required this.wholesalerId,
    required this.quantity,
    this.imageUrl,
  });

  num get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      price: price,
      stock: stock,
      wholesalerId: wholesalerId,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}
