import 'package:flutter/material.dart';
import 'package:inventory/category_brand/adidas.dart';
import 'package:inventory/category_brand/converse.dart';
import 'package:inventory/category_brand/nike.dart';
import 'package:inventory/category_brand/puma.dart';
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

  void _onMenuSelected(String value) {
    if (value == 'logout') {
      _logout();
    }
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
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            icon: const Icon(Icons.more_vert, color: Colors.black),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text("Logout"),
                      ],
                    ),
                  ),
                ],
          ),
        ],
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
            page = const Puma();
            break;
          case 'CONVERSE':
            page = const Converse();
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
                  color: Colors.white,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(brand['image']!),
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
