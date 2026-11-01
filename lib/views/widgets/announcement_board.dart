import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/announcement_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/announcement_model.dart';

class AnnouncementBoard extends StatefulWidget {
  const AnnouncementBoard({super.key});

  @override
  State<AnnouncementBoard> createState() => _AnnouncementBoardState();
}

class _AnnouncementBoardState extends State<AnnouncementBoard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<AnnouncementViewModel>().fetchAnnouncements(userData['gymId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final announcementVM = context.watch<AnnouncementViewModel>();
    final announcements = announcementVM.announcements;

    if (announcementVM.isLoading) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }

    if (announcements.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.campaign_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text("Duyurular & Etkinlikler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];
              return _buildAnnouncementCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, AnnouncementModel item) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.stars_rounded, color: Colors.orange, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              InkWell(
                onTap: () {
                  final userData = context.read<LoginViewModel>().userData;
                  final role = userData?['role'];

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(role == 'ADMIN' || role == 'SUPER_ADMIN' ? "Duyuruyu Sil" : "Duyuruyu Gizle"),
                      content: Text(role == 'ADMIN' || role == 'SUPER_ADMIN'
                          ? "Bu duyuruyu silmek istediğinize emin misiniz? (Tüm herkesten silinir)"
                          : "Bu duyuruyu ekranınızdan gizlemek istiyor musunuz?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                        TextButton(
                          onPressed: () {
                            if (role == 'ADMIN' || role == 'SUPER_ADMIN') {
                              final gymId = userData?['gymId'];
                              if (gymId != null) {
                                final int parsedGymId = gymId is int ? gymId : (int.tryParse(gymId.toString()) ?? 0);
                                context.read<AnnouncementViewModel>().deleteAnnouncement(item.id, parsedGymId);
                              }
                            } else {
                              context.read<AnnouncementViewModel>().hideAnnouncementLocally(item.id);
                            }
                            Navigator.pop(ctx);
                          },
                          child: Text(role == 'ADMIN' || role == 'SUPER_ADMIN' ? "SİL" : "GİZLE", style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              item.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy', 'tr').format(item.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showAnnouncementDetail(context, item),
                child: const Text("Detay", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDetail(BuildContext context, AnnouncementModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(item.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              Text(item.content, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
        ],
      ),
    );
  }
}
