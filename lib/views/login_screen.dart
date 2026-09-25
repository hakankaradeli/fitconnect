import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/login_view_model.dart';
import '../view_models/theme_view_model.dart';
import '../models/gym_branding_model.dart';
import 'dashboard_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Alanı (PRD'deki çoklu tesis vurgusu için)
            context.watch<ThemeViewModel>().gymLogo != null
              ? (context.watch<ThemeViewModel>().gymLogo!.startsWith('http') 
                  ? Image.network(
                      context.watch<ThemeViewModel>().gymLogo!,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
                    )
                  : Image.asset(
                      context.watch<ThemeViewModel>().gymLogo!,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
                    ))
              : const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(
              context.watch<ThemeViewModel>().gymName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),

            // E-posta Alanı
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-posta",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            // Şifre Alanı
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 8),

            // Hata Mesajı
            if (viewModel.errorMessage != null)
              Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 24),

            // Giriş Butonu
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: viewModel.isLoading
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();

                      bool success = await viewModel.login(email, password);
                      if (success && mounted) {
                        final data = viewModel.userData;
                        if (data != null) {
                          // Backend'den gelen salon bilgilerini kullan
                          final branding = GymBrandingModel(
                            gymId: data['gymId'].toString(),
                            gymName: data['gymName'],
                            logoUrl: data['logoUrl'] ?? "",
                            primaryColorHex: data['primaryColor'],
                            secondaryColorHex: data['primaryColor'], // Şimdilik aynı
                          );

                          // Temayı güncelle
                          context.read<ThemeViewModel>().updateBranding(branding);

                          // Rolü al ve yönlendir
                          String userRole = data['role']; // 'ADMIN', 'TRAINER', 'MEMBER'

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (context) =>
                                    DashboardRouter(role: userRole)),
                          );
                        }
                      }
                    },
              child: viewModel.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Giriş Yap"),
            ),
          ],
        ),
      ),
    );
  }
}
