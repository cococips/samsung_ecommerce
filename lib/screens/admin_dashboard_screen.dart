import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_form_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String kategoriTerpilih = 'Semua';
  final List<String> kategoriList = ['Semua', 'Smartphone', 'Tablet', 'Laptop', 'Watch' ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background bersih
      appBar: AppBar(
        title: const Text("Manajemen Produk", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- BARIS KATEGORI (SIMPEL) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              children: kategoriList.map((kat) {
                bool isSelected = kategoriTerpilih == kat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(kat),
                    selected: isSelected,
                    onSelected: (val) => setState(() => kategoriTerpilih = kat),
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // --- DAFTAR PRODUK DENGAN GAMBAR ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: kategoriTerpilih == 'Semua'
                  ? FirebaseFirestore.instance.collection('products').snapshots()
                  : FirebaseFirestore.instance.collection('products').where('category', isEqualTo: kategoriTerpilih).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    // Logika mengambil gambar (Thumbnail)
                    String imgUrl = "";
                    if (data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty) {
                      imgUrl = data['imageUrls'][0];
                    } else {
                      imgUrl = data['imageUrl'] ?? "";
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imgUrl.isNotEmpty 
                            ? Image.network(imgUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 60))
                            : const Icon(Icons.image, size: 60),
                      ),
                      title: Text(data['name'] ?? 'Produk Samsung', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Stok: ${data['stock'] ?? 0} | ${data['category'] ?? '-'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_box_outlined, color: Colors.green),
                            onPressed: () => _showUpdateStockDialog(context, doc.id, data['stock'] ?? 0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminFormScreen(docId: doc.id))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteProduct(context, doc.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminFormScreen())),
      ),
    );
  }

  void _deleteProduct(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(productId).delete();
              Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, String docId, int currentStock) {
    TextEditingController stockController = TextEditingController(text: currentStock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Stok"),
        content: TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Jumlah Stok Baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(docId).update({'stock': int.parse(stockController.text)});
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}