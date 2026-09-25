import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../utils/formatters.dart';
import '../../constants/lesson_constants.dart';
import 'package:flutter/services.dart';

class CreateMemberScreen extends StatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedCategory = LessonConstants.pt;
  String? _selectedLessonType;
  int? _selectedTrainerId;

  @override
  void initState() {
    super.initState();
    _selectedLessonType = LessonConstants.ptTypes.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<UserViewModel>().fetchUsers(userData['gymId']);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  List<String> _getTypesForCategory(String category) {
    if (category == LessonConstants.reformer) return LessonConstants.reformerTypes;
    if (category == LessonConstants.yoga) return LessonConstants.yogaTypes;
    return LessonConstants.ptTypes;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final trainers = viewModel.users.where((u) => u.role == 'TRAINER').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Üye Oluştur"),
        backgroundColor: Colors.redAccent,
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
                  prefixText: "+90 ",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Lütfen telefon girin";
                  if (value.replaceAll(' ', '').length != 10) return "Telefon numarası eksik";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 1. Ana Ders Grubu (PT / Reformer Pilates / Yoga)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: "Ana Ders Grubu", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: LessonConstants.pt, child: Text("PT")),
                  DropdownMenuItem(value: LessonConstants.reformer, child: Text("Reformer Pilates")),
                  DropdownMenuItem(value: LessonConstants.yoga, child: Text("Yoga")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                      _selectedLessonType = _getTypesForCategory(val).first;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. Alt Ders Tipi
              DropdownButtonFormField<String>(
                value: _selectedLessonType,
                decoration: InputDecoration(
                  labelText: "$_selectedCategory - Alt Ders Tipi", 
                  border: const OutlineInputBorder(),
                ),
                items: _getTypesForCategory(_selectedCategory)
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedLessonType = val),
                validator: (value) => value == null ? "Lütfen ders tipi seçin" : null,
              ),
              const SizedBox(height: 16),

              // Eğitmen Seçimi
              DropdownButtonFormField<int>(
                value: _selectedTrainerId,
                decoration: const InputDecoration(labelText: "Eğitmen Ata", border: OutlineInputBorder()),
                items: trainers.map((t) => DropdownMenuItem(value: int.parse(t.id), child: Text(t.fullName))).toList(),
                onChanged: (val) => setState(() => _selectedTrainerId = val),
                validator: (value) => value == null ? "Lütfen eğitmen seçin" : null,
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
                            phone: "+90 ${_phoneController.text.trim()}",
                            password: _passwordController.text.trim(),
                            role: "MEMBER",
                            gymId: userData?['gymId'] ?? 1,
                            trainerId: _selectedTrainerId,
                            lessonType: _selectedLessonType,
                          );

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Üye başarıyla oluşturuldu")),
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
