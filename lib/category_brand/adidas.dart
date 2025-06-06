import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdidasPage extends StatefulWidget {
  const AdidasPage({Key? key}) : super(key: key);

  @override
  State<AdidasPage> createState() => _AdidasPageState();
}

class _AdidasPageState extends State<AdidasPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _adidasProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdidasProducts();
  }

  Future<void> _fetchAdidasProducts() async {
    final response = await supabase
        .from('products')
        .select()
        .ilike(
          'brand',
          'Adidas',
        ); // Ambil brand "Adidas" (tidak case sensitive)

    setState(() {
      _adidasProducts = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk Adidas')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _adidasProducts.isEmpty
              ? const Center(child: Text('Tidak ada produk Adidas.'))
              : ListView.builder(
                itemCount: _adidasProducts.length,
                itemBuilder: (context, index) {
                  final product = _adidasProducts[index];
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
