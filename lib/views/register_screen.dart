import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/login_view_model.dart';
import '../view_models/theme_view_model.dart';
import '../models/gym_branding_model.dart';
import '../constants/legal_constants.dart';
import '../utils/image_utils.dart';
import '../utils/formatters.dart';
import 'dashboard_router.dart';
import 'widgets/custom_back_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isTermsOfServiceRead = false;
  bool _isPrivacyPolicyRead = false;
  bool _isHealthDataConsentAccepted = false;
  bool _isMarketingConsentAccepted = false;

  bool get _isTermsAccepted => _isTermsOfServiceRead && _isPrivacyPolicyRead;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showLegalModal(
    BuildContext context,
    String title,
    String content,
    {VoidCallback? onAccepted}
  ) {
    final themeVM = context.read<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () {
                  if (onAccepted != null) {
                    onAccepted();
                  }
                  Navigator.pop(modalContext);
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Okudum Anladım Kabul Ediyorum",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTermsSequence() {
    if (!_isTermsOfServiceRead) {
      _showLegalModal(
        context,
        "PTFitConnect Kullanım Koşulları (Hizmet Şartları)",
        LegalConstants.termsOfService,
        onAccepted: () {
          setState(() => _isTermsOfServiceRead = true);
          if (!_isPrivacyPolicyRead) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showLegalModal(
                  context,
                  "PTFitConnect Gizlilik Politikası ve KVKK Aydınlatma Metni",
                  LegalConstants.privacyPolicy,
                  onAccepted: () {
                    setState(() => _isPrivacyPolicyRead = true);
                  },
                );
              }
            });
          }
        },
      );
    } else if (!_isPrivacyPolicyRead) {
      _showLegalModal(
        context,
        "PTFitConnect Gizlilik Politikası ve KVKK Aydınlatma Metni",
        LegalConstants.privacyPolicy,
        onAccepted: () {
          setState(() => _isPrivacyPolicyRead = true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CustomBackButton(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: getGymLogoWidget(
                    themeVM.gymLogo,
                    height: 80,
                    width: 80,
                    fallbackColor: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "Hesap Oluştur",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "PtFitConnect dünyasına hemen katılın",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: "Ad Soyad",
                    hintText: "Örn: Ahmet Yılmaz",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.person_outline_rounded, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-posta Adresi",
                    hintText: "ornek@domain.com",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  decoration: InputDecoration(
                    labelText: "Telefon Numarası",
                    hintText: "+90 555 123 45 67",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Parola",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Parola Tekrar",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.lock_reset_rounded, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isTermsAccepted,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) {
                          if (val == true) {
                            _openTermsSequence();
                          } else {
                            setState(() {
                              _isTermsOfServiceRead = false;
                              _isPrivacyPolicyRead = false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _showLegalModal(
                              context,
                              "PTFitConnect Kullanım Koşulları (Hizmet Şartları)",
                              LegalConstants.termsOfService,
                              onAccepted: () {
                                setState(() => _isTermsOfServiceRead = true);
                                if (!_isPrivacyPolicyRead) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Kullanım Koşulları kabul edildi. Lütfen Gizlilik Politikası ile KVKK Aydınlatma Metni'ni de onaylayınız."),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                            child: Text(
                              "Kullanım Koşulları",
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(" ve ", style: TextStyle(fontSize: 12, color: Colors.black87)),
                          GestureDetector(
                            onTap: () => _showLegalModal(
                              context,
                              "PTFitConnect Gizlilik Politikası ve KVKK Aydınlatma Metni",
                              LegalConstants.privacyPolicy,
                              onAccepted: () {
                                setState(() => _isPrivacyPolicyRead = true);
                                if (!_isTermsOfServiceRead) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Gizlilik Politikası kabul edildi. Lütfen Kullanım Koşulları'nı da onaylayınız."),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                            child: Text(
                              "Gizlilik Politikası ile KVKK Aydınlatma Metni",
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isHealthDataConsentAccepted,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) {
                          if (val == true) {
                            _showLegalModal(
                              context,
                              "PTFitConnect Özel Nitelikli Kişisel Verilerin İşlenmesine İlişkin Açık Rıza Metni",
                              LegalConstants.explicitConsent,
                              onAccepted: () => setState(() => _isHealthDataConsentAccepted = true),
                            );
                          } else {
                            setState(() => _isHealthDataConsentAccepted = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Boy, kilo, antrenman performansı ve fiziksel aktivite verilerimin kişiselleştirilmiş fitness planı ve antrenör takibi amacıyla işlenmesine ilişkin ",
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                          GestureDetector(
                            onTap: () => _showLegalModal(
                              context,
                              "PTFitConnect Özel Nitelikli Kişisel Verilerin İşlenmesine İlişkin Açık Rıza Metni",
                              LegalConstants.explicitConsent,
                              onAccepted: () => setState(() => _isHealthDataConsentAccepted = true),
                            ),
                            child: Text(
                              "Özel Nitelikli Kişisel Veri Açık Rıza Metni",
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isMarketingConsentAccepted,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) => setState(() => _isMarketingConsentAccepted = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "ptfitconnect tarafından sunulan yeni özellikler, kampanyalar ve antrenman hatırlatmaları hakkında tarafıma ticari elektronik ileti (SMS, e-posta, push bildirim) gönderilmesini kabul ediyorum.",
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (viewModel.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: viewModel.isLoading
                        ? null
                        : () async {
                            final fullName = _fullNameController.text.trim();
                            final email = _emailController.text.trim().toLowerCase();
                            final rawPhone = _phoneController.text.trim();
                            final password = _passwordController.text.trim();
                            final confirmPassword = _confirmPasswordController.text.trim();

                            if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm zorunlu alanları doldurun.")));
                              return;
                            }

                            if (password != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Girdiğiniz parolalar eşleşmiyor.")));
                              return;
                            }

                            if (!_isTermsAccepted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.orange,
                                  content: Text("Lütfen hem Kullanım Koşulları hem de Gizlilik Politikası alanlarını okuyup kabul edin."),
                                ),
                              );
                              return;
                            }

                            if (!_isHealthDataConsentAccepted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.orange,
                                  content: Text("Lütfen Özel Nitelikli Kişisel Veri Açık Rıza Metni'ni kabul edin."),
                                ),
                              );
                              return;
                            }

                            final String formattedPhone = formatPhoneNumber(rawPhone);

                            bool success = await viewModel.register(
                              fullName: fullName,
                              email: email,
                              phone: formattedPhone,
                              password: password,
                              role: "MEMBER",
                              gymId: null,
                              termsAccepted: true,
                              healthDataConsentAccepted: true,
                              marketingConsentAccepted: _isMarketingConsentAccepted,
                            );

                            if (success && mounted) {
                              final data = viewModel.userData;
                              if (data != null) {
                                final branding = GymBrandingModel(
                                  gymId: data['gymId'].toString(),
                                  gymName: data['gymName'] ?? "PtFitConnect",
                                  logoUrl: data['logoUrl'] ?? "",
                                  primaryColorHex: data['primaryColor'] ?? "#3F51B5",
                                  secondaryColorHex: data['primaryColor'] ?? "#3F51B5",
                                );

                                context.read<ThemeViewModel>().updateBranding(branding);

                                String userRole = data['role'];

                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => DashboardRouter(role: userRole),
                                  ),
                                );
                              }
                            }
                          },
                    child: viewModel.isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("HESAP OLUŞTUR VE GİRİŞ YAP", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
