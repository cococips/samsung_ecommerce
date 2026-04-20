import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  // --- FUNGSI BARU: MENGUBAH STATUS PESANAN JADI SELESAI ---
  Future<void> _tampilkanDialogUlasan(BuildContext context, String orderId, String productName) async {
    int rating = 5; // Default bintang 5
    final TextEditingController reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Pesanan Diterima!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Bagaimana kualitas $productName?", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                
                // --- BARISAN BINTANG 1-5 ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 36,
                      ),
                      onPressed: () => setState(() => rating = index + 1), // Mengubah jumlah bintang
                    );
                  }),
                ),
                
                const SizedBox(height: 15),
                // --- KOLOM KOMENTAR ---
                TextField(
                  controller: reviewCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Tulis pengalaman belanjamu di sini...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            actions: [
              // Tombol Kirim Ulasan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    try {
                      // 1. Simpan ulasan ke gudang baru bernama 'reviews'
                      final user = FirebaseAuth.instance.currentUser;
                      await FirebaseFirestore.instance.collection('reviews').add({
                        'productName': productName,
                        'rating': rating,
                        'comment': reviewCtrl.text.isEmpty ? "Pembeli tidak meninggalkan komentar." : reviewCtrl.text,
                        'userEmail': user?.email ?? 'Member Rahasia',
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      // 2. Ubah status pesanan menjadi Selesai
                      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                        'statusPesanan': 'Selesai',
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // Tutup dialog
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terima kasih atas ulasanmu! ⭐"), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text("Kirim Ulasan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pesanan Saya", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('emailPemesan', isEqualTo: user?.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text("Kamu belum pernah berbelanja nih.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          // PERBAIKAN: Kita ambil 'id' dokumen agar bisa diedit nanti
          List<Map<String, dynamic>> orders = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id; // Simpan ID Rahasia
            return data;
          }).toList();

          orders.sort((a, b) {
            final timeA = a['waktuPemesanan'] as Timestamp?;
            final timeB = b['waktuPemesanan'] as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA); 
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = order['barangBawaan'] as List<dynamic>? ?? [];
              final String firstItemName = items.isNotEmpty ? items[0]['name'] : 'Produk Galaxy';
              final int totalItems = items.length;
              final String status = order['statusPesanan'] ?? 'Sedang Diproses';

              String tanggalPesanan = "Sedang diproses...";
              if (order['waktuPemesanan'] != null) {
                final dt = (order['waktuPemesanan'] as Timestamp).toDate();
                tanggalPesanan = DateFormat('dd MMM yyyy, HH:mm').format(dt);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tanggalPesanan, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 20),
                    
                    // --- FITUR BARU: VISUAL TRACKER (GARIS WAKTU) ---
                    _buildVisualTracker(status),
                    
                    const Divider(height: 30),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.black54),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(firstItemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              if (totalItems > 1)
                                Text("+ ${totalItems - 1} produk lainnya", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Belanja", style: TextStyle(color: Colors.grey)),
                        Text(
                          formatRupiah.format(order['totalTagihan'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    
                    // --- TOMBOL INTERAKTIF: PESANAN DITERIMA ---
if (status == 'Dikirim') ...[
  const SizedBox(height: 15),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _tampilkanDialogUlasan(context, order['docId'], firstItemName),
      child: const Text("Pesanan Diterima", style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  ),
] else if (status == 'Sedang Diproses' || status == 'Diproses' || status == 'Sedang Packing') ...[
  const SizedBox(height: 15),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      "Menunggu pengiriman dari toko",
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
    ),
  ),
]
// Jika status == 'Selesai', tidak perlu menampilkan tombol apa-apa karena sudah selesai.
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // WIDGET BANTUAN UNTUK MENGGAMBAR TIMELINE TRACKER
  // =========================================================
  Widget _buildVisualTracker(String status) {
    int step = 0;
    if (status == 'Sedang Diproses' || status == 'Diproses') {
      step = 0;
    } else if (status == 'Dikirim') {
      step = 1;
    } else if (status == 'Selesai') {
      step = 2;
    }

    return Row(
      children: [
        _buildStep("Diproses", Icons.inventory_2_outlined, step >= 0),
        _buildLine(step >= 1),
        _buildStep("Dikirim", Icons.local_shipping_outlined, step >= 1),
        _buildLine(step >= 2),
        _buildStep("Selesai", Icons.check_circle_outline, step >= 2),
      ],
    );
  }

  Widget _buildStep(String title, IconData icon, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isActive ? Colors.blue[900] : Colors.grey[200],
          child: Icon(icon, size: 18, color: isActive ? Colors.white : Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: 11, color: isActive ? Colors.blue[900] : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20), // Mengangkat garis agar pas di tengah lingkaran
        height: 3,
        color: isActive ? Colors.blue[900] : Colors.grey[200],
      ),
    );
  }
}