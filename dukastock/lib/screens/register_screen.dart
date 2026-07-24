import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../widgets/shared_widgets.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'retailer';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() =>
      _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => DashboardScreen(role: _selectedRole)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Registration failed.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: kGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child:
                const Icon(Icons.store, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create Account',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Join DukaStock today',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Full name
              buildTextField(
                controller: _nameController,
                hint: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Email
              buildTextField(
                controller: _emailController,
                hint: 'Email Address',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              buildTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 20),

              // Role selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'I am a:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _roleCard(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Retailer',
                        subtitle: 'I buy stock',
                        isSelected: _selectedRole == 'retailer',
                        onTap: () =>
                            setState(() => _selectedRole = 'retailer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _roleCard(
                        icon: Icons.store_outlined,
                        label: 'Wholesaler',
                        subtitle: 'I sell stock',
                        isSelected: _selectedRole == 'wholesaler',
                        onTap: () =>
                            setState(() => _selectedRole = 'wholesaler'),
                      ),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 12),

              if (_errorMessage.isNotEmpty) buildError(_errorMessage),
              const SizedBox(height: 16),

              buildButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? kGreen : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kGreen : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(children: [
          Icon(icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white70 : Colors.grey,
            ),
          ),
        ]),
      ),
    );
  }
}
