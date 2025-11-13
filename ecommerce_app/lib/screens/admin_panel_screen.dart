import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/screens/admin_chat_list_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/admin_order_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/admin_products_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String? _selectedCategory;

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<String> _categories = [
    'Laptops',
    'Motherboard',
    'Processor (CPU)',
    'Graphics Card (GPU)',
    'Memory Sticks (RAM)',
    'Storage Devices',
    'Power Supply Unit (PSU)',
    'Chassis',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final String imageUrl = _imageUrlController.text.trim();
      await _firestore.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'category': _selectedCategory ?? 'Uncategorized',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product uploaded successfully!')),
        );
      }
      _formKey.currentState!.reset();
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      setState(() {
        _selectedCategory = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. Let's change the title to be more general
        title: const Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // 2. Find this Column
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // 2. Your "Manage All Orders" button
              ElevatedButton.icon(
                icon: const Icon(Icons.list_alt),
                label: const Text('Manage All Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo, // A different color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  // 4. Navigate to our new screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminOrderScreen(),
                    ),
                  );
                },
              ),
              // 3. --- ADD THIS NEW BUTTON ---
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('View User Chats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminChatListScreen(),
                    ),
                  );
                },
              ),
              // --- END OF NEW BUTTON ---
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminProductsScreen(),
                    ),
                  );
                },
              ),
              // 5. A divider to separate it
              const Divider(height: 30, thickness: 1),
              
              Text(
                'Add New Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDFC5FE),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // 6. The rest of your form (wrapped in its own Form widget)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Color(0xFFDFC5FE)),
                  cursorColor: const Color(0xFFDFC5FE),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an image URL';
                    }
                    if (!value.startsWith('http')) {
                      return 'Please enter a valid URL (e.g., http://...)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  style: const TextStyle(color: Color(0xFFDFC5FE)),
                  cursorColor: const Color(0xFFDFC5FE),
                  validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFFDFC5FE)),
                  cursorColor: const Color(0xFFDFC5FE),
                  validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFFDFC5FE)),
                  cursorColor: const Color(0xFFDFC5FE),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Color(0xFFDFC5FE)),
                  ),
                  dropdownColor: const Color(0xFF1E1B52),
                  style: const TextStyle(color: Color(0xFFDFC5FE)),
                  iconEnabledColor: const Color(0xFFDFC5FE),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: const Color(0xFF3E424B),
                  ),
                  onPressed: _isLoading ? null : _uploadProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Upload Product'),
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


