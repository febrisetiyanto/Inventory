import 'package:flutter/material.dart';
import 'package:inventory/service/kategori_service.dart';
import 'package:inventory/service/product_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _productName = TextEditingController();
  final TextEditingController _productBrand = TextEditingController();
  final TextEditingController _productSize = TextEditingController();
  final TextEditingController _productColor = TextEditingController();
  final TextEditingController _productPrice = TextEditingController();
  final TextEditingController _productStock = TextEditingController();
  final TextEditingController _categoryName = TextEditingController();
  final TextEditingController _productImageUrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedCategoryId;
  String? _editingProductId;
  File? _selectedImage;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final categories = await getAllCategories();
      final products = await getAllProducts();
      setState(() {
        _categories = categories;
        _products = products;
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching data: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _productImageUrl
              .clear(); // Clear URL field when local image is selected
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _productImageUrl
              .clear(); // Clear URL field when local image is selected
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Use URL'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        String? imageUrl;

        // Upload image if selected
        if (_selectedImage != null) {
          print('Uploading selected image...');
          imageUrl = await uploadProductImage(_selectedImage!);
          print('Image uploaded successfully: $imageUrl');
        } else if (_productImageUrl.text.isNotEmpty) {
          imageUrl = _productImageUrl.text;
          print('Using URL image: $imageUrl');
        }

        if (_editingProductId == null) {
          await createProduct(
            name: _productName.text,
            brand: _productBrand.text,
            size: double.parse(
              _productSize.text.isEmpty ? '0' : _productSize.text,
            ),
            color: _productColor.text,
            price: double.parse(_productPrice.text),
            stock: int.parse(_productStock.text),
            categoryId: _selectedCategoryId,
            imageUrl: imageUrl,
          );
          _showSuccessSnackBar('Product added successfully!');
        } else {
          await updateProduct(
            id: _editingProductId!,
            name: _productName.text,
            brand: _productBrand.text,
            size: double.parse(
              _productSize.text.isEmpty ? '0' : _productSize.text,
            ),
            color: _productColor.text,
            price: double.parse(_productPrice.text),
            stock: int.parse(_productStock.text),
            categoryId: _selectedCategoryId,
            imageUrl: imageUrl,
          );
          _showSuccessSnackBar('Product updated successfully!');
        }

        _clearForm();
        _fetchData();
      } catch (e) {
        print('Error in _submitProduct: $e');
        _showErrorSnackBar('Error saving product: $e');
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  
  Future<void> _submitCategory() async {
    if (_categoryName.text.isNotEmpty) {
      try {
        await createCategory(_categoryName.text);
        _categoryName.clear();
        _fetchData();
        _showSuccessSnackBar('Category added successfully!');
      } catch (e) {
        _showErrorSnackBar('Error adding category: $e');
      }
    }
  }

  void _clearForm() {
    _productName.clear();
    _productBrand.clear();
    _productSize.clear();
    _productColor.clear();
    _productPrice.clear();
    _productStock.clear();
    _productImageUrl.clear();
    _selectedCategoryId = null;
    _editingProductId = null;
    _selectedImage = null;
  }

  void _populateForm(Map<String, dynamic> product) {
    _productName.text = product['name'] ?? '';
    _productBrand.text = product['brand'] ?? '';
    _productSize.text = product['size'].toString();
    _productColor.text = product['color'] ?? '';
    _productPrice.text = product['price'].toString();
    _productStock.text = product['stock'].toString();
    _productImageUrl.text = product['image_url'] ?? '';
    _selectedCategoryId = product['category_id'];
    _editingProductId = product['id'];
    _selectedImage = null; // Clear selected image when editing
    setState(() {});
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        ),
      );
    } else if (_productImageUrl.text.isNotEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _productImageUrl.text,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              // Enhanced error handling
              print('Image loading error: $error');
              print('Failed URL: ${_productImageUrl.text}');
              return Container(
                color: Colors.red.shade50,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Check URL or try re-uploading',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
        color: Colors.grey.shade50,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey),
          Text('No image selected', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Enhanced image display for product list
  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'No Category';
    final category = _categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'name': 'Unknown Category'},
    );
    return category['name'] ?? 'Unknown Category';
  }

  @override
  void dispose() {
    _productName.dispose();
    _productBrand.dispose();
    _productSize.dispose();
    _productColor.dispose();
    _productPrice.dispose();
    _productStock.dispose();
    _categoryName.dispose();
    _productImageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Management"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingProductId == null
                            ? "Add New Product"
                            : "Edit Product",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image Section
                      const Text(
                        "Product Image",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _buildImagePreview(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showImagePickerDialog,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text("Select Image"),
                            ),
                          ),
                          if (_selectedImage != null ||
                              _productImageUrl.text.isNotEmpty)
                            const SizedBox(width: 8),
                          if (_selectedImage != null ||
                              _productImageUrl.text.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _productImageUrl.clear();
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text("Remove"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade700,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // URL Input (alternative to image selection)
                      if (_selectedImage == null)
                        TextFormField(
                          controller: _productImageUrl,
                          decoration: const InputDecoration(
                            labelText: 'Or enter Image URL',
                            hintText: 'https://example.com/image.jpg',
                            prefixIcon: Icon(Icons.link),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),

                      const SizedBox(height: 16),

                      // Product Details
                      TextFormField(
                        controller: _productName,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator:
                            (val) =>
                                val?.isEmpty == true
                                    ? 'Product name is required'
                                    : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _productBrand,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          prefixIcon: Icon(Icons.branding_watermark),
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        items:
                            _categories
                                .map(
                                  (cat) => DropdownMenuItem<String>(
                                    value: cat['id'] as String,
                                    child: Text(cat['name'] as String),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedCategoryId = val),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _productSize,
                              decoration: const InputDecoration(
                                labelText: 'Size',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (val) {
                                if (val?.isEmpty == true) return null;
                                if (double.tryParse(val!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _productColor,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                                prefixIcon: Icon(Icons.color_lens),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _productPrice,
                              decoration: const InputDecoration(
                                labelText: 'Price *',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (val) {
                                if (val?.isEmpty == true)
                                  return 'Price is required';
                                if (double.tryParse(val!) == null)
                                  return 'Invalid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _productStock,
                              decoration: const InputDecoration(
                                labelText: 'Stock *',
                                prefixIcon: Icon(Icons.inventory_2),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val?.isEmpty == true)
                                  return 'Stock is required';
                                if (int.tryParse(val!) == null)
                                  return 'Invalid stock';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _submitProduct,
                          icon:
                              _isUploading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    _editingProductId == null
                                        ? Icons.add
                                        : Icons.update,
                                  ),
                          label: Text(
                            _isUploading
                                ? "Processing..."
                                : _editingProductId == null
                                ? "Add Product"
                                : "Update Product",
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      if (_editingProductId != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _clearForm,
                            icon: const Icon(Icons.clear),
                            label: const Text("Cancel Edit"),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Category Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add New Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _categoryName,
                            decoration: const InputDecoration(
                              labelText: 'Category Name',
                              prefixIcon: Icon(Icons.category),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _submitCategory,
                          icon: const Icon(Icons.add),
                          label: const Text("Add"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Products List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Products List",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                TextButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (_products.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Add your first product above',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._products.map(
                (p) => Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child:
                            p['image_url'] != null &&
                                    p['image_url'].toString().isNotEmpty
                                ? Image.network(
                                  p['image_url'],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                                : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),
                    ),
                    title: Text(
                      p['name'] ?? 'Unnamed Product',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p['brand']?.isNotEmpty == true)
                          Text("Brand: ${p['brand']}"),
                        Text("Category: ${_getCategoryName(p['category_id'])}"),
                        Text(
                          "Price: \$${p['price']?.toStringAsFixed(2) ?? '0.00'}",
                        ),
                        if (p['size'] != null) Text("Size: ${p['size']}"),
                        if (p['color']?.isNotEmpty == true)
                          Text("Color: ${p['color']}"),
                        Text(
                          "Stock: ${p['stock'] ?? 0}",
                          style: TextStyle(
                            color:
                                (p['stock'] ?? 0) > 0
                                    ? Colors.green
                                    : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _populateForm(p),
                          tooltip: 'Edit Product',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Delete Product'),
                                    content: Text(
                                      'Are you sure you want to delete "${p['name']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              try {
                                await deleteProduct(p['id']);
                                _fetchData();
                                _showSuccessSnackBar(
                                  'Product deleted successfully!',
                                );
                              } catch (e) {
                                _showErrorSnackBar(
                                  'Error deleting product: $e',
                                );
                              }
                            }
                          },
                          tooltip: 'Delete Product',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
