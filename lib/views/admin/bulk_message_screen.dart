import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/announcement_view_model.dart';
import '../../view_models/login_view_model.dart';

class BulkMessageScreen extends StatefulWidget {
  const BulkMessageScreen({super.key});

  @override
  State<BulkMessageScreen> createState() => _BulkMessageScreenState();
}

class _BulkMessageScreenState extends State<BulkMessageScreen> {
  final TextEditingController _titleController = TextEditingController(text: "Salon Duyurusu");
  final TextEditingController _messageController = TextEditingController();
  String _selectedTarget = "ALL"; // ALL, MEMBER, TRAINER
  bool _publishToBoard = true;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginVM = context.read<LoginViewModel>();
    final notificationVM = context.read<NotificationViewModel>();
    final announcementVM = context.read<AnnouncementViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Duyuru & Mesaj Gönder", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hedef Kitle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTarget,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: "ALL", child: Text("Tüm Kullanıcılar (Üye & Eğitmen)")),
                    DropdownMenuItem(value: "MEMBER", child: Text("Sadece Üyeler")),
                    DropdownMenuItem(value: "TRAINER", child: Text("Sadece Eğitmenler")),
                  ],
                  onChanged: (val) => setState(() => _selectedTarget = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Duyuru / Etkinlik Başlığı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Örn: Yaz Kampanyası & Turnuva Duyurusu",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Açıklama / Mesaj Metni", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Duyuru veya etkinlik detaylarını buraya yazın...",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: const Text("Duyuru Panosunda İlan Et", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("Ana ekrandaki vitrin panosunda kart olarak yayınlanır.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _publishToBoard,
                activeColor: Colors.orange,
                onChanged: (val) => setState(() => _publishToBoard = val),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSending ? null : () async {
                  if (_messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir mesaj yazın")));
                    return;
                  }

                  setState(() => _isSending = true);
                  final gymId = loginVM.userData?['gymId'];

                  if (_publishToBoard && gymId != null) {
                    await announcementVM.createAnnouncement(
                      gymId: gymId,
                      title: _titleController.text.trim().isEmpty ? "Salon Duyurusu" : _titleController.text.trim(),
                      content: _messageController.text.trim(),
                      targetRole: _selectedTarget,
                    );
                  }

                  final success = await notificationVM.sendBulkNotification(
                    gymId: gymId,
                    message: "${_titleController.text.trim()}: ${_messageController.text.trim()}",
                    role: _selectedTarget == "ALL" ? null : _selectedTarget,
                  );

                  if (mounted) {
                    setState(() => _isSending = false);
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duyuru ve bildirim başarıyla yayınlandı.")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gönderim sırasında hata oluştu.")));
                    }
                  }
                },
                icon: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.campaign_rounded),
                label: Text(_isSending ? "Yayınlanıyor..." : "YAYINLA VE GÖNDER"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
