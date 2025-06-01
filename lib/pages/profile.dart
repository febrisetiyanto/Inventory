import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    setState(() {
      user = Supabase.instance.client.auth.currentUser;
      isLoading = false;
    });
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada data pengguna', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan avatar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child:
                        user?.userMetadata?['avatar_url'] != null
                            ? ClipOval(
                              child: Image.network(
                                user!.userMetadata!['avatar_url'],
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[600],
                                  );
                                },
                              ),
                            )
                            : Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                  ),
                  SizedBox(height: 16),
                  // Nama
                  Text(
                    user?.userMetadata?['full_name'] ??
                        user?.userMetadata?['name'] ??
                        'Pengguna',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Email
                  Text(
                    user?.email ?? 'Email tidak tersedia',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Informasi detail
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoCard('Informasi Akun', [
                    _buildInfoRow('User ID', user?.id ?? '-'),
                    _buildInfoRow('Email', user?.email ?? '-'),
                    _buildInfoRow(
                      'Provider',
                      user?.appMetadata?['provider'] ?? '-',
                    ),
                    _buildInfoRow(
                      'Terakhir Login',
                      user?.lastSignInAt != null
                          ? _formatDateTime(user!.lastSignInAt!)
                          : '-',
                    ),
                    _buildInfoRow(
                      'Dibuat',
                      user?.createdAt != null
                          ? _formatDateTime(user!.createdAt)
                          : '-',
                    ),
                  ]),

                  SizedBox(height: 20),

                  _buildInfoCard('Data Profil', [
                    _buildInfoRow(
                      'Nama Lengkap',
                      user?.userMetadata?['full_name'] ??
                          user?.userMetadata?['name'] ??
                          '-',
                    ),
                    _buildInfoRow(
                      'Email Terverifikasi',
                      user?.emailConfirmedAt != null ? 'Ya' : 'Tidak',
                    ),
                  ]),

                  SizedBox(height: 30),

                  // Tombol logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(': ', style: TextStyle(color: Colors.grey[700])),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Keluar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
            ),
          ],
        );
      },
    );
  }
}
