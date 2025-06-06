import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PumaPage extends StatefulWidget {
  const PumaPage({Key? key}) : super(key: key);

  @override
  State<PumaPage> createState() => _PumaPageState();
}

class _PumaPageState extends State<PumaPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _PumaProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPumaProducts();
  }

  Future<void> _fetchPumaProducts() async {
    final response = await supabase
        .from('products')
        .select()
        .ilike(
          'brand',
          'Puma',
        ); // Ambil brand "Puma" (tidak case sensitive)

    setState(() {
      _PumaProducts = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk Puma')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _PumaProducts.isEmpty
              ? const Center(child: Text('Tidak ada produk Puma.'))
              : ListView.builder(
                itemCount: _PumaProducts.length,
                itemBuilder: (context, index) {
                  final product = _PumaProducts[index];
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
