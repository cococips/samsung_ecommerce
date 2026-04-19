import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressProvider with ChangeNotifier {
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;

  List<Map<String, dynamic>> get addresses => _addresses;
  Map<String, dynamic>? get selectedAddress => _selectedAddress;

  // 1. Ambil alamat dari Firebase berdasarkan User yang login
  Future<void> fetchAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    _addresses = snapshot.docs.map((doc) {
      return {...doc.data(), 'id': doc.id};
    }).toList();

    // Set default ke alamat pertama jika ada dan belum ada yang dipilih
    if (_addresses.isNotEmpty && _selectedAddress == null) {
      _selectedAddress = _addresses[0];
    }
    notifyListeners();
  }

  // 2. Tambah Alamat Baru
  Future<void> addAddress(Map<String, dynamic> newAddress) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add(newAddress);
    
    _addresses.add({...newAddress, 'id': docRef.id});
    _selectedAddress ??= _addresses.last;
    notifyListeners();
  }

  // 3. Pilih Alamat untuk Checkout
  void selectAddress(Map<String, dynamic> address) {
    _selectedAddress = address;
    notifyListeners();
  }
}