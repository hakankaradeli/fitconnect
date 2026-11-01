import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../view_models/trainer_qr_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../widgets/custom_back_button.dart';

class QrGeneratorScreen extends StatefulWidget {
  final int? bookingId;
  const QrGeneratorScreen({super.key, this.bookingId});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  bool _showingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<TrainerQrViewModel>().startQrGenerator(
          userData['userId'].toString(),
          userData['gymId'].toString(),
          bookingId: widget.bookingId,
        );
      }
    });
  }

  void _showTrainerSuccessDialog(BuildContext context, TrainerQrViewModel viewModel) {
    if (_showingDialog) return;
    _showingDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: Text(
          viewModel.completedMemberName != null
              ? "${viewModel.completedMemberName} ile ders başlamıştır, iyi dersler! 🏋️‍♂️"
              : "Ders başlamıştır, iyi dersler! 🏋️‍♂️",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              viewModel.resetSessionStarted();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TrainerQrViewModel>();

    if (viewModel.isSessionStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrainerSuccessDialog(context, viewModel);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Ders Başlat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Dersi Başlatmak İçin Üyeye Okutun",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: QrImageView(
                data: viewModel.qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: viewModel.secondsRemaining / 20,
                    strokeWidth: 6,
                    color: Colors.green,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                Text(
                  "${viewModel.secondsRemaining}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text("QR Kod 20 saniyede bir yenilenir.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
