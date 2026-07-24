import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import '../widgets/shared_widgets.dart';
import '../services/cloudinary_upload_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _errorMessage = '';

  // ── Device Feature State ────────────────────────────────────────────────────
  File? _productImage;          // captured photo from camera, held locally
  double? _latitude;            // GPS latitude
  double? _longitude;           // GPS longitude
  bool _fetchingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Camera Integration ──────────────────────────────────────────────────────
  // Captures a photo and holds the local File. The actual upload to
  // Cloudinary happens at save-time in _saveProduct, so retaking the photo
  // multiple times before saving doesn't waste uploads.
  Future<void> _capturePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1200,
      );

      if (photo == null) return; // user cancelled

      setState(() {
        _productImage = File(photo.path);
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera unavailable. Please check permissions.';
      });
    }
  }

  // ── GPS Integration ─────────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() {
      _fetchingLocation = true;
      _errorMessage = '';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
          'Location services are disabled. Please enable GPS in Settings.';
          _fetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage =
            'Location permission denied. Please allow location access.';
            _fetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
          'Location permission permanently denied. Enable it in App Settings.';
          _fetchingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _fetchingLocation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not retrieve location. Please try again.';
        _fetchingLocation = false;
      });
    }
  }

  // ── Save Product ─────────────────────────────────────────────────────────────
  Future<void> _saveProduct() async {
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'You must be logged in to add a product.';
      });
      return;
    }

    try {
      // ── Upload image to Cloudinary first (if one was captured) ──
      String? imageUrl;
      if (_productImage != null) {
        setState(() => _isUploadingImage = true);
        try {
          imageUrl = await CloudinaryUploadService.uploadProductImage(_productImage!);
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

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'price': price,
        'stock': stock,
        'category': _categoryController.text.trim().isEmpty
            ? 'General'
            : _categoryController.text.trim(),
        'description': _descController.text.trim(),
        'wholesalerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        // Device feature data — null if not captured
        'imageUrl': imageUrl,
        'latitude': _latitude,
        'longitude': _longitude,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save product: $e');
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
        title: const Text('Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add a new item to your stock',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Product Photo (Camera) ──────────────────────────────────────
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
                      color: _productImage != null
                          ? kGreen
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _productImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _productImage!,
                      fit: BoxFit.cover,
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
                            color: Colors.grey.shade500, fontSize: 13),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: kGreen),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Uploading photo...',
                      style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              else if (_productImage != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: kGreen, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Photo ready',
                      style: TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _productImage = null),
                      child: const Text('Remove',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // ── GPS Location ──────────────────────────────────────────────
              const Text(
                'Product Location',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _latitude != null
                        ? kGreen
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_latitude != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: kGreen, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Location captured',
                            style: TextStyle(
                                color: kGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _coordRow('Latitude', _latitude!.toStringAsFixed(6)),
                      const SizedBox(height: 4),
                      _coordRow('Longitude', _longitude!.toStringAsFixed(6)),
                    ] else
                      Row(
                        children: [
                          Icon(Icons.location_off_outlined,
                              color: Colors.grey.shade400, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'No location captured yet',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _fetchingLocation ? null : _getLocation,
                        icon: _fetchingLocation
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kGreen),
                        )
                            : const Icon(Icons.gps_fixed,
                            color: kGreen, size: 18),
                        label: Text(
                          _fetchingLocation
                              ? 'Getting location...'
                              : _latitude != null
                              ? 'Update Location'
                              : 'Get Current Location',
                          style: const TextStyle(color: kGreen),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kGreen),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                          const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                label: 'Save Product',
                isLoading: _isLoading,
                onPressed: _saveProduct,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coordRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
