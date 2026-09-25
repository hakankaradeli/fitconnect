import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/report_view_model.dart';

class CancellationReportsScreen extends StatefulWidget {
  const CancellationReportsScreen({super.key});

  @override
  State<CancellationReportsScreen> createState() => _CancellationReportsScreenState();
}

class _CancellationReportsScreenState extends State<CancellationReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().fetchCancellationReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReportViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("İptal Raporları"),
        backgroundColor: Colors.redAccent,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("En Çok Ders İptal Eden Üyeler"),
                  _buildReportList(viewModel.topCancelledMembers, "İptal"),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle("En Çok Dersi İptal Olan Hocalar"),
                  _buildReportList(viewModel.topCancelledTrainersByOthers, "İptal"),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle("En Çok Kendi Dersini İptal Eden Hocalar"),
                  _buildReportList(viewModel.topCancellingTrainers, "İptal"),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildReportList(List<dynamic> data, String label) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Veri bulunamadı.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: data.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(item['name'] ?? "Bilinmiyor", style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${item['count']} $label",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
