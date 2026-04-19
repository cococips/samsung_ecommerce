import 'package:flutter/material.dart';
import 'catalog_screen.dart'; 
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart'; // Untuk menggunakan fungsi .watch
import '../providers/cart_provider.dart'; // Agar kenal dengan kelas CartProvider
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 1. Tambahkan variabel pengontrol teks di sini
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 2. Ubah _pages menjadi 'get' agar bisa memperbarui CatalogScreen saat kita mengetik
  List<Widget> get _pages => [
    CatalogScreen(searchQuery: _searchQuery), // Mengirim teks ke layar Katalog
    const CartScreen(),
    const WishlistScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Samsung Store',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, 
        elevation: 0, // Menghilangkan bayangan agar terlihat lebih datar dan modern
        
        // --- FITUR BARU: Menambahkan Search Bar di bawah judul ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            // --- INI DIA TEXTFIELD YANG HILANG ---
            child: TextField(
              controller: _searchController, 
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari produk Galaxy favoritmu...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            // --------------------------------------
          ), // Padding
        ),
        // ---------------------------------------------------------
      ),
      body: _pages[_selectedIndex], 
      
      // Bagian Navigasi Bawah yang Diperbaiki
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Mencegah ikon hilang saat ada 4 item
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[900], // Biru khas Samsung
        unselectedItemColor: Colors.grey[600], // Abu-abu tegas agar kelihatan
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), 
            activeIcon: Icon(Icons.home), 
            label: 'Home'
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text("${context.watch<CartProvider>().items.length}"),
              isLabelVisible: context.watch<CartProvider>().items.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: const Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline), 
            activeIcon: Icon(Icons.favorite), 
            label: 'Wishlist'
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            activeIcon: Icon(Icons.person), 
            label: 'Profil'
          ),
        ],
      ), // Penutup BottomNavigationBar
    ); // Penutup Scaffold (WAJIB ADA)
  }
}