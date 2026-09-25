import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../view_models/member_scanner_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/calendar_view_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _hasScanned = false; // Aynı kodu üst üste okumasını engellemek için

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemberScannerViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Dersi Onayla (QR)")),
      body: Stack(
        children: [
          // Kamera Tarayıcı
          MobileScanner(
            onDetect: (capture) async {
              if (_hasScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  setState(() => _hasScanned = true);
                  
                  bool success = await viewModel.validateAndStartSession(code);
                  
                  if (success && mounted) {
                    final userData = context.read<LoginViewModel>().userData;
                    if (userData != null) {
                      context.read<CalendarViewModel>().fetchMemberHistory(userData['userId']);
                    }
                    _showSuccessDialog(context);
                  }
 else {
                    setState(() => _hasScanned = false); // Hata olursa tekrar taramaya izin ver
                  }
                }
              }
            },
          ),
          
          // Kamera Üzerindeki Çerçeve Tasarımı
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // İşlem Yapılırken Çıkan Loading
          if (viewModel.isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: const Text(
          "Ders başlamıştır, iyi dersler! 🏋️‍♂️",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialogu kapat
              Navigator.pop(context); // Scanner'ı kapat ve Dashboard'a dön
            },
            child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
}
