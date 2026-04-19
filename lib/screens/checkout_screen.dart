import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart'; 
import 'address_screen.dart';              
import 'package:lottie/lottie.dart'; 

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPayment = "QRIS / E-Wallet";

  // --- LOGIKA FIREBASE (DIPISAH AGAR LEBIH RAPI) ---
  Future<bool> _simpanKeFirebase(int totalTagihan, List<Map<String, dynamic>> cartItems) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final strukPesanan = {
        'emailPemesan': user?.email ?? 'Tamu',
        'barangBawaan': cartItems,
        'totalTagihan': totalTagihan,
        'metodePembayaran': selectedPayment,
        'statusPesanan': 'Sedang Diproses', 
        'waktuPemesanan': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(strukPesanan);
      
      for (var item in cartItems) {
        if (item['docId'] != null) {
          await FirebaseFirestore.instance.collection('products').doc(item['docId']).update({
            'stock': FieldValue.increment(-(item['qty'] as int)), 
          });
        }
      }

      if (mounted) context.read<CartProvider>().clearCart();
      return true; // Berhasil
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      return false; // Gagal
    }
  }

  // --- FUNGSI PAYMENT GATEWAY YANG SUDAH DINAMIS & BISA LOADING ---
  void _tampilkanPaymentGateway(BuildContext context, int totalAngka, List<Map<String, dynamic>> items) {
    bool isProcessing = false; // Pengontrol loading KHUSUS di dalam popup

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !isProcessing, // Tidak bisa ditutup saat sedang loading
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( // StatefulBuilder agar popup bisa re-render sendiri
        builder: (context, setStatePopup) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text("Selesaikan Pembayaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                const SizedBox(height: 20),
                
                // --- TAMPILAN DINAMIS BERDASARKAN PILIHAN METODE ---
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue[100]!)),
                  child: Column(
                    children: [
                      Text(selectedPayment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 15),
                      
                      // LOGIKA IF-ELSE PEMBAYARAN
                      if (selectedPayment == "QRIS / E-Wallet") ...[
                        Image.network('https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=SAMSUNG_STORE_PAYMENT', width: 160),
                        const SizedBox(height: 10),
                        const Text("Scan QR Code dengan M-Banking / E-Wallet", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ] else if (selectedPayment == "Transfer Bank") ...[
                        const Text("BCA Virtual Account", style: TextStyle(color: Colors.grey)),
                        const Text("8801 2345 6789 0000", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                        const Text("a.n. PT Samsung Store Indonesia", style: TextStyle(fontWeight: FontWeight.w500)),
                      ] else ...[
                        Icon(Icons.credit_card, size: 80, color: Colors.blue[900]),
                        const Text("Kartu Kredit / Debit", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text("Otomatis memotong dari kartu tersimpan.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],

                      const Divider(height: 30),
                      const Text("Total Tagihan:", style: TextStyle(color: Colors.grey)),
                      Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalAngka), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // --- TOMBOL SAYA SUDAH BAYAR DENGAN LOADING ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: isProcessing ? null : () async {
                      // 1. Ubah tombol jadi loading
                      setStatePopup(() => isProcessing = true);
                      
                      // 2. Simpan ke Firebase di latar belakang
                      bool success = await _simpanKeFirebase(totalAngka, items);
                      
                      // 3. Jika berhasil, tutup popup dan munculkan centang sukses
                      if (success && context.mounted) {
                        Navigator.pop(context); // Tutup popup pembayaran
                        _showSuccessDialog(context); // Munculkan dialog sukses lottie
                      } else {
                        // Jika gagal, matikan loading
                        setStatePopup(() => isProcessing = false);
                      }
                    },
                    child: isProcessing 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("SAYA SUDAH BAYAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  // --- KODE SISANYA SAMA SEPERTI SEBELUMNYA ---
  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartProvider>();
    int ongkir = 25000; 
    int totalHapus = cart.totalPrice + ongkir;
    final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final selectedAddr = context.watch<AddressProvider>().selectedAddress;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Checkout", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Alamat Pengiriman"),
             ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: Text(selectedAddr != null ? "${selectedAddr['name']} | ${selectedAddr['phone']}" : "Pilih Alamat"),
              subtitle: Text(selectedAddr != null ? selectedAddr['address'] : "Klik untuk mengatur alamat pengiriman"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressScreen())),
            ),
            const Divider(height: 30),
            _buildSectionTitle("Metode Pembayaran"),
            _paymentOption("QRIS / E-Wallet", Icons.qr_code_scanner),
            _paymentOption("Transfer Bank", Icons.account_balance),
            _paymentOption("Kartu Kredit", Icons.credit_card),
            const Divider(height: 30),
            _buildSectionTitle("Rincian Pembayaran"),
            _priceRow("Subtotal Produk", formatRupiah.format(cart.totalPrice)),
            _priceRow("Biaya Pengiriman", formatRupiah.format(ongkir)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(formatRupiah.format(totalHapus), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: cart.items.isEmpty ? null : () => _tampilkanPaymentGateway(context, totalHapus, cart.items),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text("BAYAR SEKARANG (${formatRupiah.format(totalHapus)})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
  Widget _priceRow(String label, String price) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(price, style: const TextStyle(fontWeight: FontWeight.w500))]));

  Widget _paymentOption(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return ListTile(
      onTap: () => setState(() => selectedPayment = title),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? Colors.blue[900] : Colors.grey),
      title: Text(title),
      trailing: isSelected ? Icon(Icons.check_circle, color: Colors.blue[900]) : const Icon(Icons.circle_outlined),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network('https://lottie.host/76d7e00e-66d4-4639-b9a3-5c8e44ebf2ff/P4rPwtIihw.json', width: 150, height: 150, repeat: false, errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle, color: Colors.green, size: 80)),
            const SizedBox(height: 10),
            const Text("Pembayaran Berhasil!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Pesananmu sudah masuk ke sistem kami dan sedang diproses.", textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Kembali ke Beranda", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}