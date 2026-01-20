import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/business_provider.dart';
import '../../../data/models/business_model.dart';

class BusinessEditScreen extends StatefulWidget {
  const BusinessEditScreen({super.key});

  @override
  State<BusinessEditScreen> createState() => _BusinessEditScreenState();
}

class _BusinessEditScreenState extends State<BusinessEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessTypeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _gstinController;

  Uint8List? _selectedImage;
  String? _selectedImageName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final business = Provider.of<BusinessProvider>(context, listen: false).business;
    _businessTypeController = TextEditingController(text: business?.businessType);
    _phoneController = TextEditingController(text: business?.phone);
    _emailController = TextEditingController(text: business?.email);
    _addressController = TextEditingController(text: business?.address);
    _cityController = TextEditingController(text: business?.city);
    _stateController = TextEditingController(text: business?.state);
    _pincodeController = TextEditingController(text: business?.pincode);
    _gstinController = TextEditingController(text: business?.gstin);
  }

  @override
  void dispose() {
    _businessTypeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _selectedImageName = image.name;
      });
    }
  }

  Future<void> _uploadLogo() async {
    if (_selectedImage == null || _selectedImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    final provider = Provider.of<BusinessProvider>(context, listen: false);
    final success = await provider.uploadLogo(_selectedImage!, _selectedImageName!);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully')),
        );
        setState(() {
          _selectedImage = null;
          _selectedImageName = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = BusinessUpdateRequest(
      businessType: _businessTypeController.text.isNotEmpty ? _businessTypeController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      city: _cityController.text.isNotEmpty ? _cityController.text : null,
      state: _stateController.text.isNotEmpty ? _stateController.text : null,
      pincode: _pincodeController.text.isNotEmpty ? _pincodeController.text : null,
      gstin: _gstinController.text.isNotEmpty ? _gstinController.text : null,
    );

    final provider = Provider.of<BusinessProvider>(context, listen: false);
    final success = await provider.updateProfile(request);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}')),
        );
      }
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 10) {
      return 'Phone must be at least 10 digits';
    }
    final lastTenDigits = cleaned.substring(cleaned.length - 10);
    if (!RegExp(r'^[6-9]').hasMatch(lastTenDigits)) {
      return 'Indian phone numbers start with 6, 7, 8, or 9';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Pincode must be 6 digits';
    }
    return null;
  }

  String? _validateGSTIN(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(value)) {
      return 'Enter a valid GSTIN';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessProvider>(context);
    final business = provider.business;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: provider.isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: _selectedImage != null
                          ? MemoryImage(_selectedImage!)
                          : (business?.logoUrl != null
                              ? NetworkImage(business!.logoUrl!)
                              : null) as ImageProvider?,
                      child: _selectedImage == null && business?.logoUrl == null
                          ? Text(
                              business?.businessName[0].toUpperCase() ?? 'B',
                              style: const TextStyle(fontSize: 48),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Choose Logo'),
                        ),
                        if (_selectedImage != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: provider.isLoading ? null : _uploadLogo,
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _businessTypeController,
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+91 XXXXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin_drop),
                  hintText: '6 digits',
                ),
                keyboardType: TextInputType.number,
                validator: _validatePincode,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstinController,
                decoration: const InputDecoration(
                  labelText: 'GSTIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                  hintText: '15 characters',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: _validateGSTIN,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
