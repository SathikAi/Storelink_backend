import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../../data/models/customer_model.dart';

class CustomerFormScreen extends StatefulWidget {
  final String? customerUuid;

  const CustomerFormScreen({super.key, this.customerUuid});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _notesController;
  bool _isActive = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customerUuid != null;
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _notesController = TextEditingController();

    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCustomer();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    await provider.loadCustomer(widget.customerUuid!);

    if (provider.currentCustomer != null) {
      final customer = provider.currentCustomer!;
      setState(() {
        _nameController.text = customer.name;
        _phoneController.text = customer.phone;
        _emailController.text = customer.email ?? '';
        _addressController.text = customer.address ?? '';
        _cityController.text = customer.city ?? '';
        _stateController.text = customer.state ?? '';
        _pincodeController.text = customer.pincode ?? '';
        _notesController.text = customer.notes ?? '';
        _isActive = customer.isActive;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<CustomerProvider>(context, listen: false);
    bool success;

    if (_isEditMode) {
      final request = CustomerUpdateRequest(
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        state: _stateController.text.isNotEmpty ? _stateController.text : null,
        pincode:
            _pincodeController.text.isNotEmpty ? _pincodeController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isActive: _isActive,
      );
      success = await provider.updateCustomer(widget.customerUuid!, request);
    } else {
      final request = CustomerCreateRequest(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        state: _stateController.text.isNotEmpty ? _stateController.text : null,
        pincode:
            _pincodeController.text.isNotEmpty ? _pincodeController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isActive: _isActive,
      );
      success = await provider.createCustomer(request);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Customer updated successfully'
                : 'Customer created successfully'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}')),
        );
      }
    }
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone is required';
    }
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Customer' : 'Add Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: provider.isLoading ? null : _saveCustomer,
          ),
        ],
      ),
      body: provider.isLoading && _isEditMode && provider.currentCustomer == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                          ),
                        ),
                      ],
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
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Customer is active'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditMode
                              ? 'Update Customer'
                              : 'Create Customer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
