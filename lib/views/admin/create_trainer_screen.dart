import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../utils/formatters.dart';
import '../../constants/lesson_constants.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_back_button.dart';

class CreateTrainerScreen extends StatefulWidget {
  const CreateTrainerScreen({super.key});

  @override
  State<CreateTrainerScreen> createState() => _CreateTrainerScreenState();
}

class _CreateTrainerScreenState extends State<CreateTrainerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _selectedLessonTypes = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSelectCanTeachDialog() {
    final List<String> tempSelected = List<String>.from(_selectedLessonTypes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Verebildiği Ders Türleri"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: LessonConstants.mainGroups.map((group) {
                final subTypes = LessonConstants.getSubTypes(group);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$group Ders Türleri:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: subTypes.map((type) => FilterChip(
                        label: Text(type, style: const TextStyle(fontSize: 12)),
                        selected: tempSelected.contains(type),
                        selectedColor: Colors.indigo.shade100,
                        onSelected: (val) => setDialogState(() {
                          if (val) tempSelected.add(type); else tempSelected.remove(type);
                        }),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedLessonTypes.clear();
                  _selectedLessonTypes.addAll(tempSelected);
                });
                Navigator.pop(context);
              },
              child: const Text("TAMAM"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Eğitmen Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: const CustomBackButton(
          color: Colors.white,
          backgroundColor: Color(0x33FFFFFF),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Lütfen ad soyad girin" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Lütfen e-posta girin" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                decoration: const InputDecoration(
                  labelText: "Telefon", 
                  border: OutlineInputBorder(),
                  hintText: "+90 5XX XXX XX XX",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Lütfen telefon girin";
                  if (value.replaceAll(' ', '').length != 10) return "Telefon numarası eksik";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.tune_rounded, color: Colors.teal),
                  title: const Text("Verebildiği Ders Türleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: _selectedLessonTypes.isEmpty
                      ? const Text("Henüz ders türü seçilmedi", style: TextStyle(color: Colors.grey, fontSize: 12))
                      : Text(
                          _selectedLessonTypes.join(", "),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                        ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showSelectCanTeachDialog,
                    child: const Text("SEÇ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()),
                validator: (value) => value!.length < 6 ? "Şifre en az 6 karakter olmalı" : null,
              ),
              const SizedBox(height: 8),
              if (viewModel.errorMessage != null)
                Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final userData = context.read<LoginViewModel>().userData;
                          bool success = await viewModel.createUser(
                            fullName: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            phone: formatPhoneNumber(_phoneController.text),
                            password: _passwordController.text.trim(),
                            role: "TRAINER",
                            gymId: userData?['gymId'] ?? 1,
                            canTeach: _selectedLessonTypes,
                          );

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Eğitmen başarıyla eklendi")),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("KAYDET", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
