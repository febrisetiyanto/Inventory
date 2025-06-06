import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConversePage extends StatefulWidget {
  const ConversePage({Key? key}) : super(key: key);

  @override
  State<ConversePage> createState() => _ConversePageState();
}

class _ConversePageState extends State<ConversePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _ConverseProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConverseProducts();
  }

  Future<void> _fetchConverseProducts() async {
    try {
      final products = await supabase
          .from('products')
          .select()
          .ilike('brand', 'Converse'); // case-insensitive pencocokan

      setState(() {
        _ConverseProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching Converse products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk Converse')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ConverseProducts.isEmpty
              ? const Center(child: Text('Tidak ada produk Converse.'))
              : ListView.builder(
                itemCount: _ConverseProducts.length,
                itemBuilder: (context, index) {
                  final product = _ConverseProducts[index];
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
