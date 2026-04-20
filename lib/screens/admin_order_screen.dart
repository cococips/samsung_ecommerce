import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrderScreen extends StatelessWidget {
  const AdminOrderScreen({super.key});

  // Fungsi untuk memunculkan pilihan status dari bawah (Bottom Sheet)
  void _tampilkanUpdateStatus(BuildContext context, String docId, String statusSaatIni) {
    final List<String> daftarStatus = ['Sedang Diproses', 'Sedang Packing', 'Dikirim', 'Selesai'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Update Status Pengiriman", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...daftarStatus.map((status) {
              bool isSelected = status == statusSaatIni;
              return ListTile(
                title: Text(status, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                onTap: () async {
                  // Update ke Firebase!
                  await FirebaseFirestore.instance.collection('orders').doc(docId).update({
                    'statusPesanan': status,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status diubah ke $status"), backgroundColor: Colors.green));
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // Desain warna label (Badge) agar admin gampang lihat
  Color _warnaStatus(String status) {
    if (status == 'Sedang Diproses') return Colors.orange;
    if (status == 'Sedang Packing') return Colors.purple;
    if (status == 'Dikirim') return Colors.blue;
    if (status == 'Selesai') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Kelola Pesanan Masuk", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('waktuPemesanan', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada pesanan masuk."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              String status = data['statusPesanan'] ?? 'Sedang Diproses';
              List items = data['barangBawaan'] ?? [];
              String email = data['emailPemesan'] ?? 'Tanpa Email';

              String tanggal = "Waktu tidak diketahui";
              if (data['waktuPemesanan'] != null) {
                tanggal = DateFormat('dd MMM yyyy, HH:mm').format((data['waktuPemesanan'] as Timestamp).toDate());
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Tanggal & Badge Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tanggal, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _warnaStatus(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(status, style: TextStyle(color: _warnaStatus(status), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 25),
                      // Detail Pembeli
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("Total Item: ${items.length} Barang | Bayar via: ${data['metodePembayaran']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 15),
                      // Harga dan Tombol Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatRupiah.format(data['totalTagihan'] ?? 0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blue)),
                          OutlinedButton.icon(
                            onPressed: () => _tampilkanUpdateStatus(context, doc.id, status),
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text("Ubah Status"),
                            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          )
                        ],
                      )
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