import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inventory/service/product_service.dart';

class NikePage extends StatefulWidget {
  const NikePage({Key? key}) : super(key: key);

  @override
  State<NikePage> createState() => _NikePageState();
}

class _NikePageState extends State<NikePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _nikeProducts = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productName = TextEditingController();
  final TextEditingController _productBrand = TextEditingController();
  final TextEditingController _productSize = TextEditingController();
  final TextEditingController _productColor = TextEditingController();
  final TextEditingController _productPrice = TextEditingController();
  final TextEditingController _productStock = TextEditingController();
  final TextEditingController _productImageUrl = TextEditingController();

  String? _editingProductId;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchNikeProducts();
  }

  Future<void> _fetchNikeProducts() async {
    setState(() {
      _isLoading = true;
    });

    final response = await supabase
        .from('products')
        .select()
        .ilike('brand', 'Nike');

    setState(() {
      _nikeProducts = response;
      _isLoading = false;
    });
  }

  void _showEditDialog(Map<String, dynamic> product) {
    _productName.text = product['name'] ?? '';
    _productBrand.text = product['brand'] ?? '';
    _productSize.text = product['size']?.toString() ?? '';
    _productColor.text = product['color'] ?? '';
    _productPrice.text = product['price']?.toString() ?? '';
    _productStock.text = product['stock']?.toString() ?? '';
    _productImageUrl.text = product['image_url'] ?? '';
    _editingProductId = product['id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_productImageUrl.text.isNotEmpty)
                          Container(
                            height: 100,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _productImageUrl.text,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 48,
                                  );
                                },
                              ),
                            ),
                          ),

                        TextFormField(
                          controller: _productName,
                          decoration: const InputDecoration(
                            labelText: 'Product Name *',
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          validator:
                              (val) => val?.isEmpty == true ? 'Required' : null,
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
                                  if (val?.isEmpty == true) return 'Required';
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
                                  if (val?.isEmpty == true) return 'Required';
                                  if (int.tryParse(val!) == null)
                                    return 'Invalid stock';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _productImageUrl,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            prefixIcon: Icon(Icons.link),
                          ),
                          onChanged: (value) => setDialogState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearForm();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      _isUpdating ? null : () => _updateProduct(setDialogState),
                  child:
                      _isUpdating
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProduct(StateSetter setDialogState) async {
    if (_formKey.currentState!.validate()) {
      setDialogState(() {
        _isUpdating = true;
      });

      try {
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
          categoryId: null,
          imageUrl:
              _productImageUrl.text.isEmpty ? null : _productImageUrl.text,
        );

        _showSuccessSnackBar('Product updated successfully!');
        Navigator.pop(context);
        _clearForm();
        _fetchNikeProducts();
      } catch (e) {
        _showErrorSnackBar('Error updating product: $e');
      } finally {
        setDialogState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Are you sure you want to delete "$productName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
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
        await deleteProduct(productId);
        _showSuccessSnackBar('Product deleted successfully!');
        _fetchNikeProducts();
      } catch (e) {
        _showErrorSnackBar('Error deleting product: $e');
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
    _editingProductId = null;
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

  @override
  void dispose() {
    _productName.dispose();
    _productBrand.dispose();
    _productSize.dispose();
    _productColor.dispose();
    _productPrice.dispose();
    _productStock.dispose();
    _productImageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Nike'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNikeProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _nikeProducts.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada produk Nike.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _nikeProducts.length,
                itemBuilder: (context, index) {
                  final product = _nikeProducts[index];
                  return Card(
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
                              product['image_url'] != null &&
                                      product['image_url'].toString().isNotEmpty
                                  ? Image.network(
                                    product['image_url'],
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
                                        (context, error, stackTrace) =>
                                            Container(
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
                        product['name'] ?? 'Tanpa Nama',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product['brand']?.isNotEmpty == true)
                            Text('Brand: ${product['brand']}'),
                          Text(
                            'Harga: Rp${product['price']?.toStringAsFixed(0) ?? '0'}',
                          ),
                          if (product['color']?.isNotEmpty == true)
                            Text('Warna: ${product['color']}'),
                          if (product['size'] != null)
                            Text('Ukuran: ${product['size']}'),
                          Text(
                            'Stok: ${product['stock'] ?? 0}',
                            style: TextStyle(
                              color:
                                  (product['stock'] ?? 0) > 0
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
                            onPressed: () => _showEditDialog(product),
                            tooltip: 'Edit Product',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed:
                                () => _deleteProduct(
                                  product['id'],
                                  product['name'] ?? 'Unnamed Product',
                                ),
                            tooltip: 'Delete Product',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
