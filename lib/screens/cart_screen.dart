import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// --- 1. IMPORT ALAT FORMAT UANG ---
import 'package:intl/intl.dart'; 
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';
import 'package:lottie/lottie.dart'; // <-- ALAT ANIMASI LOTTIE

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: cart.items.isEmpty
          ? _buildEmptyCart() 
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Dismissible(
                        key: Key(item['name'] + index.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) => cart.removeItem(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _buildCartItem(cart, item, index),
                      );
                    },
                  ),
                ),
                _buildOrderSummary(context, cart), 
              ],
            ),
    );
  }

  Widget _buildCartItem(CartProvider cart, Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item['imageUrls'][0].startsWith('http')
                ? Image.network(item['imageUrls'][0], width: 80, height: 80, fit: BoxFit.cover)
                : Image.asset(item['imageUrls'][0], width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(item['price'], style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Row(
            children: [
              _qtyButton(Icons.remove, () => cart.decrementQty(index)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text("${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _qtyButton(Icons.add, () => cart.incrementQty(index)),
            ],
          )
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(5)),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartProvider cart) {
    int total = cart.totalPrice;
    
    // --- 2. KEAJAIBAN INTL: FORMAT RUPIAH OTOMATIS ---
    final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String totalRupiah = formatRupiah.format(total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        children: [
          _summaryRow("Subtotal", totalRupiah), // <-- Jauh lebih bersih kan?
          const SizedBox(height: 10),
          _summaryRow("Pajak (PPN 11%)", "Sudah termasuk"),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(totalRupiah, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen())),
              child: const Text("PROSES CHECKOUT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- ANIMASI KERANJANG KOSONG ---
          Lottie.network(
            'https://lottie.host/6a5fe71c-4f35-4eb7-ae0a-baf2ed2bb352/5a1uTvpgL1.json', 
            width: 250, 
            height: 250,
            // Fallback (Cadangan) jika internet lambat/mati
            errorBuilder: (context, error, stackTrace) => Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          ),
          const SizedBox(height: 10),
          const Text("Keranjangmu masih kosong nih..", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}