import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:shimmer/shimmer.dart'; 
import 'detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
// --- 1. IMPORT ALAT CAROUSEL SLIDER ---
import 'package:carousel_slider/carousel_slider.dart'; 

class CatalogScreen extends StatefulWidget {
  final String searchQuery;
  const CatalogScreen({super.key, this.searchQuery = ""});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String selectedCategory = "Rekomendasi";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // KATEGORI MENU
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['Rekomendasi', 'Smartphone', 'Laptop', 'Tablet', 'Watch'].map((cat) {
              bool isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1D1D1F),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  onSelected: (_) => setState(() => selectedCategory = cat),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),

        // PRODUK DARI FIREBASE
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading(); 
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Terjadi kesalahan jaringan."));
              }

              final firestoreProducts = snapshot.data!.docs;
              List<Map<String, dynamic>> allProducts = firestoreProducts.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['docId'] = doc.id; // <-- TANGKAP ID RAHASIA UNTUK UPDATE STOK NANTI
                return data;
              }).toList();

              List<Map<String, dynamic>> filteredProducts = allProducts.where((p) {
                bool matchSearch = p['name'].toString().toLowerCase().contains(widget.searchQuery.toLowerCase());
                bool matchCategory = selectedCategory == "Rekomendasi" ? p['isRecommended'] : p['category'] == selectedCategory;
                return matchCategory && matchSearch;
              }).toList();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // TAMPILKAN BANNER JIKA DI KATEGORI REKOMENDASI DAN TIDAK SEDANG MENCARI BARANG
                    if (selectedCategory == "Rekomendasi" && widget.searchQuery.isEmpty)
                      _buildBanner(),

                    if (filteredProducts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Text("Tidak ada produk di kategori ini.", style: TextStyle(color: Colors.grey)),
                      )
                    else
                      GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(context, filteredProducts[index]);
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 2. FUNGSI BANNER YANG SUDAH JADI CAROUSEL ---
  Widget _buildBanner() {
    // Daftar link gambar promo kita
    final List<String> promoImages = [
      'https://placehold.co/800x400/0b3b82/FFFFFF/png?text=SAMSUNG+WEEK\nUP+TO+20%25+OFF',
      'https://placehold.co/800x400/000000/FFFFFF/png?text=GALAXY+AI\nIS+HERE',
      'https://placehold.co/800x400/512da8/FFFFFF/png?text=TRADE+IN\nSAVE+MORE',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 140.0,
          autoPlay: true, // Otomatis bergeser!
          autoPlayInterval: const Duration(seconds: 3), // Bergeser tiap 3 detik
          enlargeCenterPage: true, // Efek membesar di tengah (Sultan banget!)
          viewportFraction: 0.9, // Ukuran banner agar ujung banner lain sedikit terlihat
        ),
        items: promoImages.map((imageLink) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(imageLink),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: 4, 
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final List images = product['imageUrls'] ?? [];
    final String imagePath = images.isNotEmpty ? images[0] : 'https://placehold.co/600x600/eeeeee/000000/png?text=No+Image';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), 
                child: _displayImage(imagePath), 
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 12),
                      const SizedBox(width: 4),
                      Text("${product['rating'] ?? 5.0}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(product['price'] ?? '-', style: const TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.contain,
        width: double.infinity,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20, height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)
          ),
        ),
        errorWidget: (context, url, error) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
            const SizedBox(height: 8),
            const Text("Gambar Gagal", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      );
    } else {
      return Image.asset(path, fit: BoxFit.contain, width: double.infinity);
    }
  }
}