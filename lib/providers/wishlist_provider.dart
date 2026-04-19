import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WishlistProvider with ChangeNotifier {
  List<Map<String, dynamic>> _wishlistItems = [];

  List<Map<String, dynamic>> get items => _wishlistItems;

  // 1. Konstruktor untuk memuat data otomatis
  WishlistProvider() {
    _loadWishlist();
  }

  // --- FUNGSI BARU: Simpan data ---
  Future<void> _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    String wishlistData = jsonEncode(_wishlistItems);
    await prefs.setString('wishlist_data', wishlistData);
  }

  // --- FUNGSI BARU: Muat data ---
  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    String? wishlistData = prefs.getString('wishlist_data');

    if (wishlistData != null) {
      List<dynamic> decodedData = jsonDecode(wishlistData);
      _wishlistItems = decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
      notifyListeners();
    }
  }

  // Fungsi tambah atau hapus dari favorit (Toggle)
  void toggleWishlist(Map<String, dynamic> product) {
    final index = _wishlistItems.indexWhere((item) => item['name'] == product['name']);
    if (index >= 0) {
      _wishlistItems.removeAt(index); // Jika sudah ada, hapus
    } else {
      _wishlistItems.add(product); // Jika belum ada, tambahkan
    }
    _saveWishlist(); // Simpan perubahan ke memori HP
    notifyListeners(); // Beritahu semua layar untuk update tampilan
  }

  // Fungsi cek apakah barang sudah ada di favorit
  bool isExist(Map<String, dynamic> product) {
    return _wishlistItems.any((item) => item['name'] == product['name']);
  }
}