import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;




Future<void> createCategory(String name) async {
  await supabase.from('categories').insert({'name': name});
}

Future<List<Map<String, dynamic>>> getAllCategories() async {
  final response = await supabase
      .from('categories')
      .select()
      .order('created_at');
  return response;
}

Future<void> updateCategory(String id, String newName) async {
  await supabase.from('categories').update({'name': newName}).eq('id', id);
}

Future<void> deleteCategory(String id) async {
  await supabase.from('categories').delete().eq('id', id);
}
