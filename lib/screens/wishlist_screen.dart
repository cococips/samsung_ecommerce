import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import 'detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: wishlist.items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.items.length,
              itemBuilder: (context, index) {
                final item = wishlist.items[index];
                // Ambil gambar pertama dari list imageUrls
                final String path = item['imageUrls'][0]; 

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  leading: SizedBox(
                    width: 60,
                    // Logika deteksi sumber gambar
                    child: path.startsWith('http')
                        ? Image.network(path, fit: BoxFit.contain)
                        : Image.asset(path, fit: BoxFit.contain),
                  ),
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['price'], style: const TextStyle(color: Colors.blue)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => wishlist.toggleWishlist(item),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailScreen(product: item)),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Belum ada barang favoritmu.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}