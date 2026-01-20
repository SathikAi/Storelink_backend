import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../../data/models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productUuid;

  const ProductFormScreen({super.key, this.productUuid});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _unitController;
  int? _selectedCategoryId;
  bool _isActive = true;
  bool _isEditMode = false;

  Uint8List? _selectedImage;
  String? _selectedImageName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.productUuid != null;
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _skuController = TextEditingController();
    _priceController = TextEditingController();
    _costPriceController = TextEditingController();
    _stockQuantityController = TextEditingController(text: '0');
    _unitController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories(refresh: true);
      if (_isEditMode) {
        _loadProduct();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockQuantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.loadProduct(widget.productUuid!);

    if (provider.currentProduct != null) {
      final product = provider.currentProduct!;
      setState(() {
        _nameController.text = product.name;
        _descriptionController.text = product.description ?? '';
        _skuController.text = product.sku ?? '';
        _priceController.text = product.price.toString();
        _costPriceController.text = product.costPrice?.toString() ?? '';
        _stockQuantityController.text = product.stockQuantity.toString();
        _unitController.text = product.unit ?? '';
        _selectedCategoryId = product.categoryId;
        _isActive = product.isActive;
      });
    }
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

  Future<void> _uploadImage() async {
    if (_selectedImage == null || _selectedImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (!_isEditMode || widget.productUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please save the product first before uploading image')),
      );
      return;
    }

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final success = await provider.uploadProductImage(
      widget.productUuid!,
      _selectedImage!,
      _selectedImageName!,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<ProductProvider>(context, listen: false);
    bool success;

    if (_isEditMode) {
      final request = ProductUpdateRequest(
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        sku: _skuController.text.isNotEmpty ? _skuController.text : null,
        price: _priceController.text.isNotEmpty
            ? double.parse(_priceController.text)
            : null,
        costPrice: _costPriceController.text.isNotEmpty
            ? double.parse(_costPriceController.text)
            : null,
        stockQuantity: _stockQuantityController.text.isNotEmpty
            ? int.parse(_stockQuantityController.text)
            : null,
        unit: _unitController.text.isNotEmpty ? _unitController.text : null,
        categoryId: _selectedCategoryId,
        isActive: _isActive,
      );
      success = await provider.updateProduct(widget.productUuid!, request);
    } else {
      final request = ProductCreateRequest(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        sku: _skuController.text.isNotEmpty ? _skuController.text : null,
        price: double.parse(_priceController.text),
        costPrice: _costPriceController.text.isNotEmpty
            ? double.parse(_costPriceController.text)
            : null,
        stockQuantity: int.parse(_stockQuantityController.text),
        unit: _unitController.text.isNotEmpty ? _unitController.text : null,
        categoryId: _selectedCategoryId,
        isActive: _isActive,
      );
      success = await provider.createProduct(request);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Product updated successfully'
                : 'Product created successfully'),
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

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Enter a valid price greater than 0';
    }
    return null;
  }

  String? _validateCostPrice(String? value) {
    if (value == null || value.isEmpty) return null;
    final costPrice = double.tryParse(value);
    if (costPrice == null || costPrice < 0) {
      return 'Enter a valid cost price';
    }
    return null;
  }

  String? _validateStockQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock quantity is required';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock < 0) {
      return 'Enter a valid stock quantity';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: provider.isLoading ? null : _saveProduct,
          ),
        ],
      ),
      body: provider.isLoading && _isEditMode && provider.currentProduct == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isEditMode) ...[
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : provider.currentProduct?.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            provider.currentProduct!.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.image_not_supported,
                                                    size: 48),
                                          ),
                                        )
                                      : const Icon(Icons.shopping_bag,
                                          size: 48),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed:
                                      provider.isLoading ? null : _pickImage,
                                  icon: const Icon(Icons.image),
                                  label: const Text('Choose Image'),
                                ),
                                if (_selectedImage != null) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: provider.isLoading
                                        ? null
                                        : _uploadImage,
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
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, _) {
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('No Category'),
                            ),
                            ...categoryProvider.categories
                                .where((c) => c.isActive)
                                .map((c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.name),
                                    )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                        hintText: 'Stock Keeping Unit',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: _validatePrice,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Cost Price',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.price_change),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: _validateCostPrice,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockQuantityController,
                            decoration: const InputDecoration(
                              labelText: 'Stock Quantity *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                            validator: _validateStockQuantity,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.straighten),
                              hintText: 'pcs, kg, L, etc.',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Product is available for sale'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveProduct,
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
                              ? 'Update Product'
                              : 'Create Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
