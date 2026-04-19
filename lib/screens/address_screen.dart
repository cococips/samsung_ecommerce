import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addressProv = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Alamat")),
      body: addressProv.addresses.isEmpty
          ? const Center(child: Text("Belum ada alamat tersimpan."))
          : ListView.builder(
              itemCount: addressProv.addresses.length,
              itemBuilder: (context, index) {
                final addr = addressProv.addresses[index];
                bool isSelected = addressProv.selectedAddress?['id'] == addr['id'];
                return ListTile(
                  leading: Icon(Icons.location_on, color: isSelected ? Colors.blue[900] : Colors.grey),
                  title: Text("${addr['name']} | ${addr['phone']}"),
                  subtitle: Text(addr['address']),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () => addressProv.selectAddress(addr),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showAddAddressDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tambah Alamat Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Penerima")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Nomor Telepon")),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: "Alamat Lengkap")),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<AddressProvider>().addAddress({
                    'name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                    'address': addrCtrl.text,
                  });
                  Navigator.pop(context);
                },
                child: const Text("Simpan Alamat"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}