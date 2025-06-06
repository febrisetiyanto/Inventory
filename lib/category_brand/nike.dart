import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NikePage extends StatefulWidget {
  const NikePage({Key? key}) : super(key: key);

  @override
  State<NikePage> createState() => _NikePageState();
}

class _NikePageState extends State<NikePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _nikeProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNikeProducts();
  }

  Future<void> _fetchNikeProducts() async {
    try {
      final products = await supabase
          .from('products')
          .select()
          .ilike('brand', 'nike'); // case-insensitive pencocokan

      setState(() {
        _nikeProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching Nike products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk Nike')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _nikeProducts.isEmpty
              ? const Center(child: Text('Tidak ada produk Nike.'))
              : ListView.builder(
                itemCount: _nikeProducts.length,
                itemBuilder: (context, index) {
                  final product = _nikeProducts[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading:
                          product['image_url'] != null
                              ? Image.network(
                                product['image_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                              : const Icon(Icons.image_not_supported),
                      title: Text(product['name'] ?? 'Tanpa Nama'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga: Rp${product['price']}'),
                          Text('Warna: ${product['color']}'),
                          Text('Ukuran: ${product['size']}'),
                          Text('Stok: ${product['stock']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
