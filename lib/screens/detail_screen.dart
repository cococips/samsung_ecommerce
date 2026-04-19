import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cart_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String selectedColor = "Titanium Black";
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // --- FUNGSI BARU: POP-UP SULTAN SAAT MASUK KERANJANG ---
  void _showSuccessAddToCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Agar ukurannya bisa menyesuaikan
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // Menyesuaikan dengan Dark Mode
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Garis kecil di atas pop-up
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            
            // Ikon Sukses yang besar
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 15),
            
            // Teks Konfirmasi
            const Text("Berhasil Masuk Keranjang!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.product['name'], style: const TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            
            // 2 Tombol Aksi (Lanjut / Cek Keranjang)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () => Navigator.pop(context), // Tutup pop-up saja
                    child: const Text("Lanjut Belanja", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900], 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Tutup pop-up
                      Navigator.pop(context); // Tutup halaman detail produk (kembali ke Home)
                      // Catatan: Ini akan mengembalikan user ke katalog, lalu user bisa manual ke tab Keranjang.
                    },
                    child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Jarak ekstra untuk area bawah HP
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logika cerdas untuk mendeteksi list gambar
    List<dynamic> images = widget.product['imageUrls'] ?? [widget.product['imageUrl']];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.product['name'], style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link berhasil disalin!"), behavior: SnackBarBehavior.floating),
              );
            }, 
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () {
              context.read<WishlistProvider>().toggleWishlist(widget.product);
            },
            icon: Icon(
              context.watch<WishlistProvider>().isExist(widget.product) 
                  ? Icons.favorite 
                  : Icons.favorite_border,
              color: context.watch<WishlistProvider>().isExist(widget.product) 
                  ? Colors.red 
                  : Colors.black,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE CAROUSEL
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  height: 400,
                  color: const Color(0xFFF8F9FA),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final String path = images[index];
                      return Hero(
                        tag: index == 0 ? widget.product['name'] : 'img_$index',
                        child: path.startsWith('http') 
                            ? CachedNetworkImage(
                                imageUrl: path, 
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.black)),
                                errorWidget: (context, url, error) => const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.wifi_off, color: Colors.grey, size: 50),
                                      SizedBox(height: 10),
                                      Text("Tidak dapat memuat gambar", style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ) 
                            : Image.asset(path, fit: BoxFit.contain),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.black : Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product['name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Text("${widget.product['rating'] ?? 5.0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("  •  ${widget.product['reviews'] ?? 0} Ulasan", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.product['price'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  // --- LENCANA STOK ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: (widget.product['stock'] ?? 10) > 0 ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      (widget.product['stock'] ?? 10) > 0 ? "Stok Tersedia: ${widget.product['stock'] ?? 10}" : "Stok Habis!",
                      style: TextStyle(color: (widget.product['stock'] ?? 10) > 0 ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 40),
                  const Text("Pilihan Warna", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["Titanium Black", "Titanium Gray", "Violet"].map((color) {
                        bool isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(25),
                              color: isSelected ? Colors.black : Colors.transparent,
                            ),
                            child: Text(color, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text("Tentang Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text(
                    "Ditenagai oleh AI tercanggih, Galaxy ini menghadirkan pengalaman visual premium dengan material Titanium yang tangguh.",
                    style: TextStyle(color: Colors.black54, height: 1.6, fontSize: 15),
                  ),
                  const Divider(height: 60),

                  // --- SEKSI BARU: ULASAN PEMBELI (REAL-TIME DARI FIREBASE) ---
                  const Text("Ulasan Pembeli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  
                  StreamBuilder<QuerySnapshot>(
                    // Pasang CCTV khusus untuk produk yang sedang dilihat saja
                    stream: FirebaseFirestore.instance.collection('reviews').where('productName', isEqualTo: widget.product['name']).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                          child: const Center(child: Text("Belum ada ulasan. Jadilah yang pertama!", style: TextStyle(color: Colors.grey))),
                        );
                      }

                      // Olah data ulasan dan urutkan dari yang paling baru
                      final docs = snapshot.data!.docs;
                      List<Map<String, dynamic>> reviews = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                      reviews.sort((a, b) {
                        final timeA = a['timestamp'] as Timestamp?;
                        final timeB = b['timestamp'] as Timestamp?;
                        if (timeA == null || timeB == null) return 0;
                        return timeB.compareTo(timeA); // Terkini di atas
                      });

                      // Tampilkan daftar ulasan
                      return ListView.builder(
                        shrinkWrap: true, // Wajib agar tidak error di dalam ScrollView
                        physics: const NeverScrollableScrollPhysics(), // Scroll diurus oleh layar utama
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final rev = reviews[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(15)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(radius: 16, backgroundColor: Colors.blue[100], child: Text(rev['userEmail'][0].toUpperCase(), style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(rev['userEmail'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    // Cetak bintang sesuai rating
                                    Row(
                                      children: List.generate(5, (starIndex) => Icon(
                                        starIndex < (rev['rating'] ?? 5) ? Icons.star : Icons.star_border,
                                        color: Colors.orange, size: 16,
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(rev['comment'] ?? '', style: const TextStyle(color: Colors.black87, height: 1.4)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 120), // Jarak ruang kosong untuk tombol bawah
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    // --- LOGIKA CERDAS: CEK STOK ---
    int currentStock = widget.product['stock'] ?? 10;
    bool isOutOfStock = currentStock <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, 
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          const SizedBox(width: 12),
          
          // --- TOMBOL 1: TAMBAH KERANJANG ---
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                // Jika habis, garisnya jadi abu-abu
                side: BorderSide(color: isOutOfStock ? Colors.grey : Colors.blue[900]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isOutOfStock 
                ? () {
                    // Beri peringatan jika maksa klik saat stok habis
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maaf, stok produk sedang kosong!"), backgroundColor: Colors.red));
                  }
                : () {
                    context.read<CartProvider>().addToCart(widget.product);
                    _showSuccessAddToCart(); 
                  },
              child: Icon(Icons.add_shopping_cart, color: isOutOfStock ? Colors.grey : Colors.blue[900]),
            ),
          ),
          const SizedBox(width: 12),

          // --- TOMBOL 2: BELI LANGSUNG ---
          Expanded(
            flex: 2, 
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Jika habis, tombolnya jadi abu-abu statis
                backgroundColor: isOutOfStock ? Colors.grey[400] : Colors.blue[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isOutOfStock 
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maaf, stok produk sedang kosong!"), backgroundColor: Colors.red));
                  }
                : () {
                    context.read<CartProvider>().addToCart(widget.product);
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                  },
              // Teks tombol berubah otomatis jika habis
              child: Text(isOutOfStock ? "STOK HABIS" : "Beli Langsung", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}