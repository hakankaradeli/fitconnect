import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../view_models/login_view_model.dart';
import '../view_models/theme_view_model.dart';
import 'widgets/custom_back_button.dart';

class UserQrScreen extends StatelessWidget {
  const UserQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginVM = context.watch<LoginViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final userData = loginVM.userData;

    final int userId = userData?['userId'] ?? 0;
    final String fullName = userData?['fullName'] ?? "Kullanıcı";
    final String role = userData?['role'] ?? "MEMBER";
    final int gymId = userData?['gymId'] ?? 0;
    final String rawGymName = userData?['gymName'] ?? "";
    final bool hasGym = gymId > 0 &&
        rawGymName.isNotEmpty &&
        rawGymName != "Salon Kaydı Bekleniyor" &&
        rawGymName != "Ana Sistem Salonu";
    final String displayGymName = hasGym ? rawGymName : "";
    final primaryColor = themeVM.primaryColor;
    final onPrimary = themeVM.onPrimaryColor;

    final String qrData = "FITCONNECT_USER:$userId:$fullName:$role";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Salon Kaydı QR Kodu",
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: primaryColor.computeLuminance() > 0.45 
            ? SystemUiOverlayStyle.dark 
            : SystemUiOverlayStyle.light,
        leading: CustomBackButton(
          color: onPrimary,
          backgroundColor: onPrimary.withValues(alpha: 0.18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(
                          role == "TRAINER" ? Icons.sports_rounded : Icons.person_rounded,
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role == "TRAINER" ? "Eğitmen / Antrenör" : "Spor Salonu Üyesi",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Salon: $displayGymName",
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 24),
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 220.0,
                        foregroundColor: Colors.black87,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Salon Yöneticisine (Admin) bu QR kodu okutarak kayıt veya salon atama işleminizi gerçekleştirebilirsiniz.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
