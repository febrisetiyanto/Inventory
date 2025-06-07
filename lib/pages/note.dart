import 'package:flutter/material.dart';
import 'package:inventory/service/kategori_service.dart';
import 'package:inventory/service/product_service.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String? _selectedCategoryFilter;
  String _searchQuery = '';
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Helper method untuk mengkonversi ke int dengan aman
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method untuk mengkonversi ke double dengan aman
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await getAllCategories();
      final products = await getAllProducts();
      setState(() {
        _categories = categories;
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error fetching data: $e');
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts =
          _products.where((product) {
            bool matchesSearch = true;
            bool matchesCategory = true;

            // Search filter
            if (_searchQuery.isNotEmpty) {
              matchesSearch =
                  product['name']?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false ||
                      product['brand']?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                  false;
            }

            // Category filter
            if (_selectedCategoryFilter != null) {
              matchesCategory =
                  product['category_id'] == _selectedCategoryFilter;
            }

            return matchesSearch && matchesCategory;
          }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _onCategoryFilterChanged(String? categoryId) {
    setState(() {
      _selectedCategoryFilter = categoryId;
    });
    _filterProducts();
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'No Category';
    final category = _categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'name': 'Unknown Category'},
    );
    return category['name'] ?? 'Unknown Category';
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

  Widget _buildSearchAndFilter() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search Products',
                hintText: 'Search by name or brand...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Category Filter
            DropdownButtonFormField<String>(
              value: _selectedCategoryFilter,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._categories.map(
                  (cat) => DropdownMenuItem<String>(
                    value: cat['id'] as String,
                    child: Text(cat['name'] as String),
                  ),
                ),
              ],
              onChanged: _onCategoryFilterChanged,
              decoration: InputDecoration(
                labelText: 'Filter by Category',
                prefixIcon: const Icon(Icons.filter_list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStats() {
    int totalProducts = _products.length;

    // Fixed: Menggunakan helper method untuk parsing yang aman
    int totalStock = _products.fold<int>(
      0,
      (sum, product) => sum + _safeParseInt(product['stock']),
    );

    int lowStockProducts =
        _products
            .where((product) => _safeParseInt(product['stock']) < 10)
            .length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.inventory,
              label: 'Total Products',
              value: totalProducts.toString(),
              color: Colors.blue,
            ),
            _buildStatItem(
              icon: Icons.storage,
              label: 'Total Stock',
              value: totalStock.toString(),
              color: Colors.green,
            ),
            _buildStatItem(
              icon: Icons.warning,
              label: 'Low Stock',
              value: lowStockProducts.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stockValue = _safeParseInt(product['stock']);

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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
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
          product['name'] ?? 'Unnamed Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['brand']?.isNotEmpty == true)
              Text("Brand: ${product['brand']}"),
            Text("Category: ${_getCategoryName(product['category_id'])}"),
            // Fixed: Menggunakan _safeParseDouble untuk price
            Text(
              "Price: \$${_safeParseDouble(product['price']).toStringAsFixed(2)}",
            ),
            // Fixed: Menggunakan _safeParseDouble untuk size
            if (product['size'] != null)
              Text("Size: ${_safeParseDouble(product['size']).toString()}"),
            if (product['color']?.isNotEmpty == true)
              Text("Color: ${product['color']}"),
            Row(
              children: [
                const Text("Stock: "),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        stockValue > 10
                            ? Colors.green.shade100
                            : stockValue > 0
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stockValue.toString(),
                    style: TextStyle(
                      color:
                          stockValue > 10
                              ? Colors.green.shade700
                              : stockValue > 0
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          onSelected: (value) async {
            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Product'),
                      content: Text(
                        'Are you sure you want to delete "${product['name']}"?',
                      ),
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
                  await deleteProduct(product['id']);
                  _fetchData();
                  _showSuccessSnackBar('Product deleted successfully!');
                } catch (e) {
                  _showErrorSnackBar('Error deleting product: $e');
                }
              }
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product List"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/inventory');
            },
            tooltip: 'Add Product',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Section
                    _buildProductStats(),

                    const SizedBox(height: 16),

                    // Search and Filter Section
                    _buildSearchAndFilter(),

                    const SizedBox(height: 16),

                    // Products List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Products (${_filteredProducts.length})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategoryFilter != null)
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              _onCategoryFilterChanged(null);
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text("Clear Filters"),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Products List
                    if (_filteredProducts.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  _products.isEmpty
                                      ? Icons.inventory
                                      : Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _products.isEmpty
                                      ? 'No products found'
                                      : 'No products match your search',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _products.isEmpty
                                      ? 'Add your first product'
                                      : 'Try adjusting your search or filters',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                if (_products.isEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/inventory',
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Product'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children:
                            _filteredProducts
                                .map((product) => _buildProductCard(product))
                                .toList(),
                      ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/inventory');
        },
        tooltip: 'Add New Product',
        child: const Icon(Icons.add),
      ),
    );
  }
}
