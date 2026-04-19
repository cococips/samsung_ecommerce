import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'admin_form_screen.dart'; // Import Form yang baru kita buat

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Fungsi Hapus Produk (DELETE)
  Future<void> _hapusProduk(BuildContext context, String docId, String name) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk?"),
        content: Text("Yakin ingin menghapus $name selamanya?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk dihapus!")));
              }
            },
            child: const Text("Hapus"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Admin (CRUD)")),
      
      // Tombol Mengambang (CREATE)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[900],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Produk", style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFormScreen())),
      ),

      // Daftar Produk (READ)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada produk di gudang."));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              
              // Ambil gambar pertama untuk thumbnail
              List imgs = data['imageUrls'] ?? [];
              String imgPath = imgs.isNotEmpty ? imgs[0] : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60, height: 60,
                      child: imgPath.startsWith('http') 
                          ? CachedNetworkImage(imageUrl: imgPath, fit: BoxFit.cover, errorWidget: (c,u,e) => const Icon(Icons.broken_image))
                          : const Icon(Icons.image, size: 40),
                    ),
                  ),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("${data['price']} | Kategori: ${data['category']}", style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        "Sisa Stok: ${data['stock'] ?? 10}", 
                        style: TextStyle(
                          color: (data['stock'] ?? 10) > 0 ? Colors.green[700] : Colors.red, 
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                        )
                      ),
                    ],
                  ),
                  isThreeLine: false, // Karena kita pakai Column, matikan isThreeLine
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Edit (UPDATE)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFormScreen(docId: docId, initialData: data))),
                      ),
                      // Tombol Hapus (DELETE)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _hapusProduk(context, docId, data['name'] ?? ''),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}