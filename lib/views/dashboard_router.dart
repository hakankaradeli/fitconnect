import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/login_view_model.dart';
import 'admin/admin_dashboard.dart';
import 'trainer/trainer_dashboard.dart';
import 'member/member_dashboard.dart';
import 'super_admin/super_admin_dashboard.dart';

class DashboardRouter extends StatelessWidget {
  final String role;

  const DashboardRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<LoginViewModel>().userData;
    final gymId = userData?['gymId'] ?? 0;

    if (role != 'SUPER_ADMIN' && (gymId == 0 || userData?['gymName'] == null || userData!['gymName'].toString().isEmpty)) {
      return const MemberDashboard();
    }

    switch (role) {
      case 'SUPER_ADMIN':
        return const SuperAdminDashboard();
      case 'ADMIN':
        return const AdminDashboard();
      case 'TRAINER':
        return const TrainerDashboard();
      case 'MEMBER':
        return const MemberDashboard();
      default:
        return const MemberDashboard();
    }
  }
}
