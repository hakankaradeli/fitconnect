import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../widgets/custom_back_button.dart';

class AdminQrScannerScreen extends StatefulWidget {
  final String? defaultRole;

  const AdminQrScannerScreen({super.key, this.defaultRole});

  @override
  State<AdminQrScannerScreen> createState() => _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends State<AdminQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _showRoleSelectionDialog(String fullName) {
    final bool isMemberDefault = widget.defaultRole != "TRAINER";

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.person_add_alt_1_rounded, color: Colors.indigo, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: const Text(
          "Bu kullanıcıyı salonunuza hangi rolde kaydetmek istersiniz?",
          style: TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMemberDefault ? Colors.blue : Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context, "MEMBER"),
                icon: const Icon(Icons.fitness_center_rounded),
                label: Text(
                  isMemberDefault ? "✓ SPOR ÜYESİ OLARAK EKLE" : "SPOR ÜYESİ OLARAK EKLE",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isMemberDefault ? Colors.indigo : Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context, "TRAINER"),
                icon: const Icon(Icons.sports_rounded),
                label: Text(
                  !isMemberDefault ? "✓ EĞİTMEN / ANTRENÖR OLARAK EKLE" : "EĞİTMEN / ANTRENÖR OLARAK EKLE",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("İptal"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawCode = barcodes.first.rawValue;
    if (rawCode == null || rawCode.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final loginVM = context.read<LoginViewModel>();
      final adminGymId = loginVM.userData?['gymId'] ?? 0;

      if (rawCode.startsWith("FITCONNECT_USER:")) {
        final parts = rawCode.split(":");
        if (parts.length >= 2) {
          final int userId = int.tryParse(parts[1]) ?? 0;
          final String fullName = parts.length > 2 ? parts[2] : "Kullanıcı";

          final effectiveGymId = adminGymId > 0 ? adminGymId : 1;
          if (userId > 0) {
            final selectedRole = await _showRoleSelectionDialog(fullName);
            if (selectedRole != null) {
              final result = await context.read<UserViewModel>().assignGymByQr(
                userId: userId,
                gymId: effectiveGymId,
                role: selectedRole,
              );

              if (mounted) {
                if (result != null && result.containsKey("message")) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                          SizedBox(width: 10),
                          Text("Kayıt Başarılı", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Text(result['message'] ?? "Kullanıcı salonunuza başarıyla eklendi!"),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("TAMAM"),
                        ),
                      ],
                    ),
                  );
                } else {
                  final errorMsg = context.read<UserViewModel>().errorMessage ?? "Salon kaydı ataması başarısız.";
                  _showErrorDialog(errorMsg);
                }
              }
            } else {
              setState(() => _isProcessing = false);
            }
          } else {
            _showErrorDialog("Geçersiz kullanıcı veya salon bilgisi.");
          }
        } else {
          _showErrorDialog("Geçersiz QR Kod formatı.");
        }
      } else {
        _showErrorDialog("Okutulan QR kod bir FitConnect kullanıcı QR kodu değil.");
      }
    } catch (e) {
      _showErrorDialog("Hata oluştu: $e");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Hata", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text("Yeniden Dene"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.defaultRole == "TRAINER"
            ? "Eğitmen QR Kodunu Tara"
            : widget.defaultRole == "MEMBER"
              ? "Üye QR Kodunu Tara"
              : "Üye / Eğitmen QR Kodunu Tara",
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const CustomBackButton(
          color: Colors.white,
          backgroundColor: Color(0x33FFFFFF),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "Kamera başlatılamadı veya simülatör kullanılıyor.\nLütfen fiziksel bir cihazda deneyin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.defaultRole == "TRAINER"
                  ? "Eğitmenin uygulamasındaki Salon Kaydı QR kodunu taratın."
                  : widget.defaultRole == "MEMBER"
                    ? "Üyenin uygulamasındaki Salon Kaydı QR kodunu taratın."
                    : "Üye veya Eğitmenin uygulamasındaki Salon Kaydı QR kodunu taratın.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
