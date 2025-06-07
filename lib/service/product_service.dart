import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

final supabase = Supabase.instance.client;


Future<String> uploadProductImage(File imageFile) async {
  try {
  
    final String fileExtension = path.extension(imageFile.path).toLowerCase();

  
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final String filePath = 'products/$fileName'; 

    print('Uploading file: $fileName to path: $filePath');

  
    final Uint8List fileBytes = await imageFile.readAsBytes();

  
    final String uploadPath = await supabase.storage
        .from('product-images') 
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: null, 
          ),
        );

    print('Upload successful. Path: $uploadPath');

    
    final String publicUrl = supabase.storage
        .from('product-images')
        .getPublicUrl(filePath);

    print('Public URL generated: $publicUrl');

    
    final cleanUrl = publicUrl.replaceAll('//', '/').replaceFirst(':/', '://');

    return cleanUrl;
  } catch (e) {
    print('Upload error details: $e');
    throw Exception('Failed to upload image: $e');
  }
}


Future<void> deleteProductImage(String imageUrl) async {
  try {
 
    final Uri uri = Uri.parse(imageUrl);

  
    final pathSegments = uri.pathSegments;
    final productImagesIndex = pathSegments.indexOf('product-images');

    if (productImagesIndex != -1 &&
        productImagesIndex < pathSegments.length - 1) {
      
      final filePath = pathSegments.sublist(productImagesIndex + 1).join('/');

      print('Attempting to delete file at path: $filePath');

      await supabase.storage.from('product-images').remove([filePath]);

      print('File deleted successfully');
    } else {
      print('Could not extract file path from URL: $imageUrl');
    }
  } catch (e) {
    
    print('Warning: Failed to delete image: $e');
  }
}

Future<void> createProduct({
  required String name,
  required String brand,
  String? categoryId,
  required double size,
  required String color,
  required double price,
  required int stock,
  String? imageUrl,
}) async {
  await supabase.from('products').insert({
    'name': name,
    'brand': brand,
    'category_id': categoryId,
    'size': size,
    'color': color,
    'price': price,
    'stock': stock,
    'image_url': imageUrl,
  });
}

Future<List<Map<String, dynamic>>> getAllProducts() async {
  final response = await supabase
      .from('products')
      .select('*, categories(name)')
      .order('created_at');
  return response;
}

Future<void> updateProduct({
  required String id,
  required String name,
  required String brand,
  String? categoryId,
  required double size,
  required String color,
  required double price,
  required int stock,
  String? imageUrl,
}) async {
 
  final currentProduct =
      await supabase.from('products').select('image_url').eq('id', id).single();

  final String? oldImageUrl = currentProduct['image_url'];


  await supabase
      .from('products')
      .update({
        'name': name,
        'brand': brand,
        'category_id': categoryId,
        'size': size,
        'color': color,
        'price': price,
        'stock': stock,
        'image_url': imageUrl,
      })
      .eq('id', id);


  if (oldImageUrl != null &&
      oldImageUrl.isNotEmpty &&
      oldImageUrl != imageUrl &&
      oldImageUrl.contains('product-images')) {
    await deleteProductImage(oldImageUrl);
  }
}

Future<void> deleteProduct(String id) async {

  final product =
      await supabase.from('products').select('image_url').eq('id', id).single();


  await supabase.from('products').delete().eq('id', id);


  final String? imageUrl = product['image_url'];
  if (imageUrl != null &&
      imageUrl.isNotEmpty &&
      imageUrl.contains('product-images')) {
    await deleteProductImage(imageUrl);
  }
}


Future<List<Map<String, dynamic>>> getProductsByCategory(
  String categoryId,
) async {
  final response = await supabase
      .from('products')
      .select('*, categories(name)')
      .eq('category_id', categoryId)
      .order('created_at');
  return response;
}


Future<List<Map<String, dynamic>>> searchProducts(String query) async {
  final response = await supabase
      .from('products')
      .select('*, categories(name)')
      .ilike('name', '%$query%')
      .order('created_at');
  return response;
}


Future<List<Map<String, dynamic>>> getLowStockProducts({
  int threshold = 10,
}) async {
  final response = await supabase
      .from('products')
      .select('*, categories(name)')
      .lte('stock', threshold)
      .order('stock');
  return response;
}
