import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- 1. IMPORT ALAT KEAMANAN FIREBASE ---
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Pengendali teks untuk mengambil ketikan user
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- FUNGSI PINTAR: LOGIN & DAFTAR OTOMATIS ---
  Future<void> _loginAtauDaftar() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email dan Password harus diisi!")));
      return;
    }

    setState(() => _isLoading = true); // Munculkan loading muter
    
    try {
      // 1. Coba masuk (Login) ke Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _masukKeHome(); // Kalau berhasil, arahkan ke Beranda
      
    } on FirebaseAuthException catch (e) {
      // 2. Kalau gagal karena akun belum ada, kita DAFTARKAN otomatis!
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Akun baru berhasil dibuat!"), backgroundColor: Colors.green)
            );
          }
          _masukKeHome(); // Arahkan ke Beranda
        } catch (registerError) {
          _tampilkanError("Gagal mendaftar: ${registerError.toString()}");
        }
      } else {
        // Gagal karena alasan lain (misal: password salah, email format salah)
        _tampilkanError("Gagal: ${e.message}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // Matikan loading
    }
  }

  // Fungsi menyimpan ingatan memori (sama seperti sebelumnya)
  Future<void> _masukKeHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }

  void _tampilkanError(String pesan) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/smsnglogo.png', width: 200),
              const SizedBox(height: 50),
              
              // Kolom Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              
              // Kolom Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password (Minimal 6 Huruf)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              
              // Tombol Login/Daftar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginAtauDaftar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                  ),
                  // Jika sedang loading, tampilkan indikator. Jika tidak, tampilkan teks.
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Masuk / Daftar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}