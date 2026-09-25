import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/image_utils.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/user_model.dart';
import 'create_member_screen.dart';
import 'member_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final userData = context.read<LoginViewModel>().userData;
    if (userData != null) {
      context.read<UserViewModel>().fetchUsers(userData['gymId']);
      context.read<UserViewModel>().fetchDeletedUsers(userData['gymId']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final members = viewModel.users.where((u) => u.role == 'MEMBER').toList();
    final deletedMembers = viewModel.deletedUsers.where((u) => u.role == 'MEMBER').toList();

    final filteredMembers = members
        .where((u) => u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: _searchQuery.isEmpty 
            ? const Text("Üyeler", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)) 
            : TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Üye ara...",
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            labelColor: Colors.redAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.redAccent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Aktif/Pasif"),
              Tab(text: "Silinmişler"),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_searchQuery.isEmpty ? Icons.search_rounded : Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _searchQuery = "";
                  _searchController.clear();
                });
              },
            )
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.redAccent,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateMemberScreen()),
            );
            _loadUsers();
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("YENİ ÜYE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: TabBarView(
          children: [
            _buildActiveList(viewModel, filteredMembers),
            _buildDeletedList(deletedMembers),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveList(UserViewModel viewModel, List<UserModel> filtered) {
    if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
    if (filtered.isEmpty) return const Center(child: Text("Üye bulunamadı."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        final imageProvider = getProfileImageProvider(user.profileImageUrl);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: (user.isActive ? Colors.blue : Colors.grey).withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person_rounded, color: user.isActive ? Colors.blue : Colors.grey)
                  : null,
            ),
            title: Text(
              user.fullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: user.isActive ? Colors.black87 : Colors.grey,
                decoration: user.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (user.isActive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isActive ? "AKTİF" : "PASİF",
                    style: TextStyle(
                      color: user.isActive ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (val) async {
                if (val == 'status') {
                  await viewModel.toggleUserStatus(int.parse(user.id));
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text("Üyeyi Sil"),
                      content: const Text("Bu üyeyi silmek istediğinize emin misiniz?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SİL", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await viewModel.deleteUser(int.parse(user.id));
                    _loadUsers();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'status', 
                  child: Row(
                    children: [
                      Icon(user.isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(user.isActive ? "Pasife Al" : "Aktifleştir"),
                    ],
                  )
                ),
                const PopupMenuItem(
                  value: 'delete', 
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text("Sil", style: TextStyle(color: Colors.red)),
                    ],
                  )
                ),
              ],
            ),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => MemberDetailScreen(member: user)));
              _loadUsers();
            },
          ),
        );
      },
    );
  }

  Widget _buildDeletedList(List<UserModel> deleted) {
    if (deleted.isEmpty) return const Center(child: Text("Silinmiş üye bulunamadı."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deleted.length,
      itemBuilder: (context, index) {
        final user = deleted[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey, 
              child: Icon(Icons.delete_sweep_rounded, color: Colors.white)
            ),
            title: Text(user.fullName, style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold)),
            subtitle: Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }
}
