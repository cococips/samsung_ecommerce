import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:provider/provider.dart'; 
import '../providers/theme_provider.dart'; 
import 'login_screen.dart';
import 'order_history_screen.dart'; 
import 'address_screen.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "Email tidak ditemukan";
    final bool isAdmin = userEmail == "admin@samsung.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Warna background abu-abu khas aplikasi premium
      appBar: AppBar(title: const Text("Profil Saya"), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER PROFIL ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Colors.black, child: Icon(Icons.person, size: 40, color: Colors.white)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Samsung Member', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        const SizedBox(height: 5),
                        Text(userEmail, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                          child: Text("Gold Tier", style: TextStyle(color: Colors.blue[900], fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // --- MENU DASHBOARD (DENGAN LAYOUT MODERN MENGAMBANG) ---
            _buildMenuGroup([
              _buildMenuItem(Icons.shopping_bag_outlined, "Pesanan Saya", true, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()))),
              _buildMenuItem(Icons.location_on_outlined, "Daftar Alamat", true, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressScreen()))),
              
              // FITUR YANG KINI BISA DI-KLIK!
              _buildMenuItem(Icons.payment_outlined, "Metode Pembayaran", false, () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Dompet / Pembayaran akan segera hadir!")));
              }),
            ]),

            _buildMenuGroup([
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text("Mode Gelap (Dark Mode)", style: TextStyle(fontWeight: FontWeight.w500)),
                value: context.watch<ThemeProvider>().isDarkMode,
                activeThumbColor: Colors.blue[900],
                onChanged: (value) => context.read<ThemeProvider>().toggleTheme(value),
              ),
              const Divider(height: 1, indent: 60),
              _buildMenuItem(Icons.help_outline, "Pusat Bantuan", true, () => _hubungiCS(context)),
              
              // FITUR TENTANG APLIKASI (POPUP INFO)
              _buildMenuItem(Icons.info_outline, "Tentang Aplikasi", false, () {
                showAboutDialog(
                  context: context,
                  applicationName: "Samsung Store",
                  applicationVersion: "v1.0.0 (Premium Edition)",
                  applicationIcon: Image.asset('assets/smsnglogo.png', width: 60),
                  children: [const Text("Aplikasi E-Commerce modern yang dibangun dengan Flutter dan Firebase oleh Developer Hebat.")],
                );
              }),
            ]),    

            if (isAdmin) 
              _buildMenuGroup([
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.blue),
                  title: const Text("Panel Admin (CRUD)", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Kelola Produk & Database"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
                ),
              ]),

            _buildMenuGroup([
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Keluar Akun", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () => _prosesLogout(context),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // WIDGET BANTUAN UNTUK LAYOUT MENU MODERN (MENGAMBANG DENGAN ROUNDED CORNER)
  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Memberikan jarak dari tepi layar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Melengkungkan sudut
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))], // Bayangan tipis
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool showDivider, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap, 
        ),
        if (showDivider) const Divider(height: 1, indent: 60),
      ],
    );
  }

  Future<void> _prosesLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Keluar Akun?"),
        content: const Text("Apakah kamu yakin ingin keluar dari aplikasi Samsung Store?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
            child: const Text("Keluar"),
          )
        ],
      ),
    );
  }

  Future<void> _hubungiCS(BuildContext context) async {
    const String noWA = "628972514000"; 
    const String pesan = "Halo CS Samsung Store, saya butuh bantuan terkait aplikasi/pesanan saya nih.";
    final Uri uri = Uri.parse("https://wa.me/$noWA?text=${Uri.encodeComponent(pesan)}");

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp."), backgroundColor: Colors.red));
    }
  }
}