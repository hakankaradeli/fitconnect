import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'admin/admin_dashboard.dart';
import 'trainer/trainer_dashboard.dart';
import 'member/member_dashboard.dart';

class DashboardRouter extends StatelessWidget {
  final String role; // 'ADMIN', 'TRAINER', 'MEMBER'

  const DashboardRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // Role göre hangi dashboard'un açılacağına karar veriyoruz
    switch (role) {
      case 'ADMIN':
        return const AdminDashboard();
      case 'TRAINER':
        return const TrainerDashboard();
      case 'MEMBER':
        return const MemberDashboard();
      default:
        return const Scaffold(body: Center(child: Text("Yetkisiz Rol!")));
    }
  }
}
