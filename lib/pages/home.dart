import 'package:flutter/material.dart';
import 'package:inventory/category_brand/adidas.dart';
import 'package:inventory/category_brand/converse.dart';
import 'package:inventory/category_brand/nike.dart';
import 'package:inventory/category_brand/puma.dart';
import 'package:inventory/service/product_service.dart';
import 'package:inventory/service/kategori_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> _brands = [
    {"title": "NIKE", "image": 'assets/Brand/001-nike-logos-swoosh-black.jpg'},
    {
      "title": "ADIDAS",
      "image":
          'assets/Brand/vecteezy_adidas-symbol-logo-black-with-name-clothes-design-icon_10994414.jpg',
    },
    {
      "title": "PUMA",
      "image":
          'assets/Brand/vecteezy_puma-logo-black-symbol-with-name-clothes-design-icon_10994431.jpg',
    },
    {
      "title": "CONVERSE",
      "image":
          'assets/Brand/vecteezy_converse-brand-symbol-shoes-logo-with-name-black-design_23599718.jpg',
    },
  ];

  void showFullScreenSplash() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) {
        return Container(
          color: Colors.blueGrey,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, color: Colors.white, size: 80),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Logging out...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    showFullScreenSplash();

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout gagal: $e')));
    }
  }

  void _onSearchPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductSearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Inventory Sepatu",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: _onSearchPressed,
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            tooltip: 'Search Products',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: _brands.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            return _buildBrandCard(_brands[index]);
          },
        ),
      ),
    );
  }

  Widget _buildBrandCard(Map<String, String> brand) {
    return GestureDetector(
      onTap: () {
        Widget page;
        switch (brand['title']) {
          case 'NIKE':
            page = const NikePage();
            break;
          case 'ADIDAS':
            page = const AdidasPage();
            break;
          case 'PUMA':
            page = const PumaPage();
            break;
          case 'CONVERSE':
            page = const ConversePage();
            break;
          default:
            page = Scaffold(
              appBar: AppBar(title: const Text("Unknown Brand")),
              body: const Center(child: Text("Halaman belum tersedia")),
            );
        }
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                      child: Image.asset(brand['image']!,
                      fit: BoxFit.contain,    
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                brand['title']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final products = await getAllProducts();
      final categories = await getAllCategories();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts =
            _allProducts.where((product) {
              final name = product['name']?.toString().toLowerCase() ?? '';
              final brand = product['brand']?.toString().toLowerCase() ?? '';
              final color = product['color']?.toString().toLowerCase() ?? '';
              final categoryName =
                  _getCategoryName(product['category_id']).toLowerCase();
              final searchLower = query.toLowerCase();

              return name.contains(searchLower) ||
                  brand.contains(searchLower) ||
                  color.contains(searchLower) ||
                  categoryName.contains(searchLower);
            }).toList();
      }
    });
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'No Category';
    final category = _categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'name': 'Unknown Category'},
    );
    return category['name'] ?? 'Unknown Category';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Search Products",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
        
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Search by name, brand, color, or category...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),


          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${_filteredProducts.length} product(s)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

        
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.inventory_2_outlined
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No products available'
                                : 'No products found for "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Add some products to get started'
                                : 'Try searching with different keywords',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
         
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child:
                    product['image_url'] != null &&
                            product['image_url'].toString().isNotEmpty
                        ? Image.network(
                          product['image_url'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 16),

            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unnamed Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  if (product['brand']?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.branding_watermark,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product['brand'],
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],

                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryName(product['category_id']),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.green,
                      ),
                      Text(
                        '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      if (product['size'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Size ${product['size']}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      if (product['color']?.isNotEmpty == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product['color'],
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (product['stock'] ?? 0) > 0
                                  ? Colors.green[50]
                                  : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: ${product['stock'] ?? 0}',
                          style: TextStyle(
                            color:
                                (product['stock'] ?? 0) > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
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
}
