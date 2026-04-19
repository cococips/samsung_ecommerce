import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk memori HP
import 'dart:convert'; // Untuk sihir jsonEncode dan jsonDecode

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  // 1. Konstruktor: Otomatis memanggil data saat aplikasi pertama kali dibuka
  CartProvider() {
    _loadCart();
  }

  // --- FUNGSI BARU: Menyimpan data ke memori ---
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List menjadi Teks (JSON) lalu simpan
    String cartData = jsonEncode(_items);
    await prefs.setString('cart_data', cartData);
  }

  // --- FUNGSI BARU: Membaca data dari memori ---
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString('cart_data');

    if (cartData != null) {
      // Ubah kembali Teks (JSON) menjadi List
      List<dynamic> decodedData = jsonDecode(cartData);
      _items = decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
      notifyListeners(); // Perbarui tampilan
    }
  }

  void addToCart(Map<String, dynamic> product) {
    int index = _items.indexWhere((item) => item['name'] == product['name']);
    if (index >= 0) {
      _items[index]['qty']++;
    } else {
      _items.add({...product, 'qty': 1});
    }
    _saveCart(); // Simpan setiap kali ada perubahan
    notifyListeners();
  }

  void incrementQty(int index) {
    _items[index]['qty']++;
    _saveCart(); // Simpan
    notifyListeners();
  }

  void decrementQty(int index) {
    if (_items[index]['qty'] > 1) {
      _items[index]['qty']--;
    } else {
      _items.removeAt(index);
    }
    _saveCart(); // Simpan
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    _saveCart(); // Simpan
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCart(); // Simpan agar memori ikut kosong
    notifyListeners();
  }

  int get totalPrice {
    int total = 0;
    for (var item in _items) {
      String priceString = item['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      total += int.parse(priceString) * (item['qty'] as int);
    }
    return total;
  }
}