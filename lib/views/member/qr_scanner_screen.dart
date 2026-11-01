import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../view_models/member_scanner_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/calendar_view_model.dart';
import '../../view_models/finance_view_model.dart';
import '../widgets/custom_back_button.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemberScannerViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dersi Onayla (QR)", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const CustomBackButton(),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) async {
              if (_hasScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  setState(() => _hasScanned = true);

                  final userData = context.read<LoginViewModel>().userData;
                  final rawUserId = userData?['userId'] ?? userData?['id'];
                  final int? memberId = rawUserId is int ? rawUserId : int.tryParse(rawUserId?.toString() ?? '');
                  final calendarVM = context.read<CalendarViewModel>();
                  final financeVM = context.read<FinanceViewModel>();

                  try {
                    await _scannerController.stop();
                  } catch (e) {
                    debugPrint("Scanner stop error: $e");
                  }

                  bool success = await viewModel.validateAndStartSession(code, memberId: memberId);

                  if (!mounted) return;

                  if (success) {
                    if (memberId != null) {
                      calendarVM.fetchMemberHistory(memberId);
                      financeVM.fetchBalance(memberId);
                    }
                    _showSuccessDialog(context);
                  } else {
                    _showErrorDialog(context, viewModel.statusMessage ?? "Doğrulama başarısız.");
                  }
                  break;
                }
              }
            },
          ),

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

          if (viewModel.isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Ders başlatılıyor...",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() => _hasScanned = false);
                _scannerController.start();
              }
            },
            child: const Text("Tekrar Dene", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
}
