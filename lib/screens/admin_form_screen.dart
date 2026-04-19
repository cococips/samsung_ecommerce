import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFormScreen extends StatefulWidget {
  // Jika docId null = Tambah Produk Baru. Jika ada = Edit Produk.
  final String? docId; 
  final Map<String, dynamic>? initialData;

  const AdminFormScreen({super.key, this.docId, this.initialData});

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _stockCtrl;
  String _selectedCategory = 'Smartphone';
  bool _isRecommended = false;

  final List<String> _categories = ['Smartphone', 'Laptop', 'Tablet', 'Watch'];

  @override
  void initState() {
    super.initState();
    // Isi otomatis form jika sedang mode "Edit"
    _nameCtrl = TextEditingController(text: widget.initialData?['name'] ?? '');
    _priceCtrl = TextEditingController(text: widget.initialData?['price'] ?? 'Rp ');
    _stockCtrl = TextEditingController(text: widget.initialData?['stock']?.toString() ?? '10'); // Default stok 10
    
    // Ambil gambar pertama dari list imageUrls jika ada
    String imgUrl = '';
    if (widget.initialData != null && widget.initialData!['imageUrls'] != null) {
      List imgs = widget.initialData!['imageUrls'];
      if (imgs.isNotEmpty) imgUrl = imgs[0];
    }
    _imageCtrl = TextEditingController(text: imgUrl);

    if (widget.initialData != null) {
      _selectedCategory = widget.initialData!['category'] ?? 'Smartphone';
      _isRecommended = widget.initialData!['isRecommended'] ?? false;
    }
  }

  Future<void> _simpanProduk() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productData = {
        'name': _nameCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'category': _selectedCategory,
        'imageUrls': [_imageCtrl.text.trim()], // Dibungkus List agar sesuai dengan DetailScreen
        'isRecommended': _isRecommended,
        'rating': widget.initialData?['rating'] ?? 5.0, // Default rating
        'reviews': widget.initialData?['reviews'] ?? 0, // Default ulasan
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
      };

      if (widget.docId == null) {
        // CREATE: Tambah Produk Baru
        await FirebaseFirestore.instance.collection('products').add(productData);
      } else {
        // UPDATE: Edit Produk Lama
        await FirebaseFirestore.instance.collection('products').doc(widget.docId).update(productData);
      }

      if (mounted) {
        Navigator.pop(context); // Kembali ke Dashboard setelah sukses
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil menyimpan produk!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? "Tambah Produk" : "Edit Produk"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("Nama Produk", _nameCtrl, Icons.shopping_bag_outlined),
              const SizedBox(height: 16),
              
              _buildTextField("Harga (Cth: Rp 15.000.000)", _priceCtrl, Icons.payments_outlined),
              const SizedBox(height: 16),

              _buildTextField("Jumlah Stok (Cth: 50)", _stockCtrl, Icons.inventory_2_outlined),
              const SizedBox(height: 16),

              // Dropdown Kategori
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Kategori", prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              _buildTextField("Link URL Gambar", _imageCtrl, Icons.image_outlined),
              const SizedBox(height: 16),

              // Switch Rekomendasi
              SwitchListTile(
                title: const Text("Jadikan Produk Rekomendasi", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Akan muncul di halaman depan"),
                value: _isRecommended,
                activeThumbColor: Colors.blue[900],
                onChanged: (val) => setState(() => _isRecommended = val),
              ),
              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanProduk,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SIMPAN PRODUK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon) {
    return TextFormField(
      controller: ctrl,
      validator: (val) => val!.isEmpty ? "Tidak boleh kosong" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}