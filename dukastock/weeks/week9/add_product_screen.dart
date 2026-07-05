import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import '../widgets/shared_widgets.dart';

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
  String _errorMessage = '';

  // ── Device Feature State ────────────────────────────────────────────────────
  File? _productImage;          // captured photo from camera
  String? _imageBase64;         // base64-encoded photo for Firestore
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
  // Requests camera permission via image_picker and captures a photo.
  // The image is encoded as base64 and stored in Firestore so no separate
  // Firebase Storage setup is required.
  Future<void> _capturePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,   // compress to reduce Firestore document size
        maxWidth: 800,
      );

      if (photo == null) return; // user cancelled

      final file = File(photo.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() {
        _productImage = file;
        _imageBase64 = base64Str;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera unavailable. Please check permissions.';
      });
    }
  }

  // ── GPS Integration ─────────────────────────────────────────────────────────
  // Checks and requests location permission, then retrieves the current
  // GPS coordinates using Geolocator's Fused Location Provider equivalent.
  Future<void> _getLocation() async {
    setState(() {
      _fetchingLocation = true;
      _errorMessage = '';
    });

    try {
      // 1. Check if location services are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
          'Location services are disabled. Please enable GPS in Settings.';
          _fetchingLocation = false;
        });
        return;
      }

      // 2. Check / request location permission
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

      // 3. Retrieve current position
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

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'price': price,
        'stock': stock,
        'category': _categoryController.text.trim().isEmpty
            ? 'General'
            : _categoryController.text.trim(),
        'description': _descController.text.trim(),
        'wholesalerId': user?.uid ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
        // Device feature data — null if not captured
        'imageBase64': _imageBase64,
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
                onTap: _capturePhoto,
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
              if (_productImage != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: kGreen, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Photo captured',
                      style: TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() {
                            _productImage = null;
                            _imageBase64 = null;
                          }),
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
