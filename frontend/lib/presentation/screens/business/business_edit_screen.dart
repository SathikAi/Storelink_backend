import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/business_provider.dart';
import '../../../data/models/business_model.dart';
import '../../widgets/image_delete_button.dart';

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
  late TextEditingController _upiIdController;

  final List<Uint8List> _selectedImages = [];
  final List<String> _selectedImageNames = [];
  Uint8List? _selectedBanner;
  String? _selectedBannerName;
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
    _upiIdController = TextEditingController(text: business?.upiId);
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
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 images allowed')),
      );
      return;
    }
    
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var image in images) {
        if (_selectedImages.length < 10) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImages.add(bytes);
            _selectedImageNames.add(image.name);
          });
        }
      }
    }
  }

  Future<void> _pickBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedBanner = bytes;
        _selectedBannerName = image.name;
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select images first')),
      );
      return;
    }

    final provider = Provider.of<BusinessProvider>(context, listen: false);
    final success = await provider.uploadImages(_selectedImages, _selectedImageNames);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images uploaded successfully')),
        );
        setState(() {
          _selectedImages.clear();
          _selectedImageNames.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}')),
        );
      }
    }
  }

  Future<void> _uploadBanner() async {
    if (_selectedBanner == null || _selectedBannerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a banner first')),
      );
      return;
    }

    final provider = Provider.of<BusinessProvider>(context, listen: false);
    final success = await provider.uploadBanner(_selectedBanner!, _selectedBannerName!);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner uploaded successfully')),
        );
        setState(() {
          _selectedBanner = null;
          _selectedBannerName = null;
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
      upiId: _upiIdController.text.isNotEmpty ? _upiIdController.text : null,
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
        .hasMatch(value.toUpperCase())) {
      return 'Enter a valid GSTIN (e.g. 29ABCDE1234F1Z5)';
    }
    return null;
  }

  String? _validateUpiId(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w.\-_+]+@[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return 'Enter a valid UPI ID (e.g. 9876543210@paytm)';
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
                    const Text('Business Profile Images (Max 10)', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Existing Images
                          if (business?.profileImageUrls != null)
                            ...business!.profileImageUrls!.map((url) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                                  ),
                                  PositionImageDeleteButton(onDelete: () {
                                    final newList = List<String>.from(business.profileImageUrls!);
                                    newList.remove(url);
                                    provider.updateProfile(BusinessUpdateRequest(profileImageUrls: newList));
                                  }),
                                ],
                              ),
                            )),
                          // Newly Selected Images
                          ..._selectedImages.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(entry.value, width: 100, height: 100, fit: BoxFit.cover),
                                ),
                                PositionImageDeleteButton(onDelete: () {
                                  setState(() {
                                    _selectedImages.removeAt(entry.key);
                                    _selectedImageNames.removeAt(entry.key);
                                  });
                                }),
                              ],
                            ),
                          )),
                          // Add Button
                          if ((business?.profileImageUrls?.length ?? 0) + _selectedImages.length < 10)
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                                ),
                                child: const Icon(Icons.add_a_photo, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _uploadImages,
                        icon: const Icon(Icons.upload),
                        label: Text('Upload ${_selectedImages.length} Images'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Banner Image (1)', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickBanner,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    image: _selectedBanner != null 
                        ? DecorationImage(image: MemoryImage(_selectedBanner!), fit: BoxFit.cover)
                        : (business?.bannerUrl != null 
                            ? DecorationImage(image: NetworkImage(business!.bannerUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_selectedBanner == null && business?.bannerUrl == null)
                      ? const Center(child: Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey))
                      : null,
                ),
              ),
              if (_selectedBanner != null) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: provider.isLoading ? null : _uploadBanner,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Banner'),
                ),
              ],
              const SizedBox(height: 32),
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
              const SizedBox(height: 24),
              // ── Payment & Tax Section ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Payment & Tax',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _upiIdController,
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                  hintText: 'e.g. 9876543210@paytm',
                  helperText: 'Customers can pay via GPay, PhonePe, Paytm etc.',
                  helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  suffixIcon: _upiIdController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateUpiId,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstinController,
                decoration: const InputDecoration(
                  labelText: 'GSTIN (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long_rounded),
                  hintText: 'e.g. 29ABCDE1234F1Z5',
                  helperText: 'Leave blank if not GST registered',
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

