import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/product_image_widget.dart';
import '../services/cloudinary_upload_service.dart';

/// Edit an existing product. Pre-fills all fields from the current
/// Firestore doc. Only writes the fields the user can actually change here
/// (name/price/stock/category/description/image) — leaves wholesalerId,
/// createdAt, latitude/longitude untouched so it doesn't clobber data this
/// screen doesn't manage.
class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> initialData;

  const EditProductScreen({
    super.key,
    required this.productId,
    required this.initialData,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _errorMessage = '';

  // If the user picks a new photo, it's held here and only uploaded on
  // save — same pattern as AddProductScreen, so retaking multiple times
  // before saving doesn't waste uploads.
  File? _newImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameController =
        TextEditingController(text: (data['name'] ?? '').toString());
    _priceController =
        TextEditingController(text: (data['price'] ?? '').toString());
    _stockController =
        TextEditingController(text: (data['stock'] ?? '').toString());
    _categoryController =
        TextEditingController(text: (data['category'] ?? '').toString());
    _descController =
        TextEditingController(text: (data['description'] ?? '').toString());
    _existingImageUrl =
    (data['imageUrl'] ?? data['imageBase64']) as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (photo == null) return;
      setState(() {
        _newImage = File(photo.path);
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera unavailable. Please check permissions.';
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill in name, price and stock.');
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (price == null || stock == null) {
      setState(() => _errorMessage = 'Price and stock must be numbers.');
      return;
    }
    if (price <= 0) {
      setState(() => _errorMessage = 'Price must be greater than zero.');
      return;
    }
    if (stock < 0) {
      setState(() => _errorMessage = 'Stock cannot be negative.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String? imageUrl = _existingImageUrl;

      if (_newImage != null) {
        setState(() => _isUploadingImage = true);
        try {
          imageUrl =
          await CloudinaryUploadService.uploadProductImage(_newImage!);
        } catch (e) {
          setState(() {
            _isLoading = false;
            _isUploadingImage = false;
            _errorMessage = 'Failed to upload photo: $e';
          });
          return;
        }
        setState(() => _isUploadingImage = false);
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'name': _nameController.text.trim(),
        'price': price,
        'stock': stock,
        'category': _categoryController.text.trim().isEmpty
            ? 'General'
            : _categoryController.text.trim(),
        'description': _descController.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update product: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        title: const Text('Edit Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Product Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Changes apply immediately once saved',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Product Photo ────────────────────────────────────────────
              const Text(
                'Product Photo',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isUploadingImage ? null : _capturePhoto,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (_newImage != null || _existingImageUrl != null)
                          ? kGreen
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _newImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_newImage!, fit: BoxFit.cover),
                  )
                      : _existingImageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ProductImage(
                      image: _existingImageUrl,
                      size: 180,
                      borderRadius: 14,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to capture product photo',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isUploadingImage)
                Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kGreen),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Uploading photo...',
                      style: TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              else if (_newImage != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: kGreen, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'New photo ready',
                      style: TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _newImage = null),
                      child: const Text('Undo',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                )
              else if (_existingImageUrl != null)
                  Text(
                    'Tap the photo to replace it',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              const SizedBox(height: 20),

              // ── Product Fields ────────────────────────────────────────────
              buildTextField(
                controller: _nameController,
                hint: 'Product Name',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: _priceController,
                hint: 'Price (KES)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: _stockController,
                hint: 'Stock Quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: _categoryController,
                hint: 'Category (e.g. Flour, Sugar)',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: _descController,
                hint: 'Description',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),

              if (_errorMessage.isNotEmpty) buildError(_errorMessage),
              const SizedBox(height: 24),

              buildButton(
                label: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _saveChanges,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}