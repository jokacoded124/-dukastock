import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../widgets/shared_widgets.dart';
import '../services/connectivity_service.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

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

    // Check connectivity before attempting the network call — fast,
    // local check, avoids a doomed request and gives the user an
    // immediate, clear message instead of a hanging spinner.
    final online = await ConnectivityService.isOnline();
    if (!online) {
      setState(() {
        _isLoading = false;
        _errorMessage =
        'No internet connection. Please reconnect and try again.';
      });
      return;
    }

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
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      // Firebase-specific errors (permission-denied, unavailable, etc.)
      // give a more useful message than a raw exception string.
      setState(() {
        _errorMessage =
        'Failed to save product: ${e.message ?? "Unknown Firebase error"}';
      });
    } catch (e) {
      // Fallback for anything else (timeout, dropped connection mid-write).
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
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
            ],
          ),
        ),
      ),
    );
  }
}
