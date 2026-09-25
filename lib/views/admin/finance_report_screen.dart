import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/report_view_model.dart';
import '../../view_models/login_view_model.dart';

class FinanceReportScreen extends StatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  State<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> {
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDailyDate = DateTime.now();
  String _selectedUnperformedPeriod = "DAILY"; // DAILY, WEEKLY, MONTHLY, QUARTERLY, SEMI_ANNUALLY, YEARLY

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  void _loadAllReports() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        final gymId = userData['gymId'];
        final reportVM = context.read<ReportViewModel>();
        reportVM.fetchMonthlyReport(gymId, _selectedMonth);
        _loadUnperformedReport();
        reportVM.fetchTrainerComplaints(gymId);
      }
    });
  }

  void _loadUnperformedReport() {
    final userData = context.read<LoginViewModel>().userData;
    if (userData == null) return;
    final gymId = userData['gymId'];
    final now = DateTime.now();

    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedUnperformedPeriod) {
      case 'DAILY':
        start = DateTime(_selectedDailyDate.year, _selectedDailyDate.month, _selectedDailyDate.day, 0, 0, 0);
        end = DateTime(_selectedDailyDate.year, _selectedDailyDate.month, _selectedDailyDate.day, 23, 59, 59);
        break;
      case 'WEEKLY':
        final monday = _selectedDailyDate.subtract(Duration(days: _selectedDailyDate.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        break;
      case 'MONTHLY':
        start = DateTime(_selectedDailyDate.year, _selectedDailyDate.month, 1, 0, 0, 0);
        end = DateTime(_selectedDailyDate.year, _selectedDailyDate.month + 1, 1).subtract(const Duration(seconds: 1));
        break;
      case 'QUARTERLY':
        start = DateTime(now.year, now.month - 3, now.day, 0, 0, 0);
        break;
      case 'SEMI_ANNUALLY':
        start = DateTime(now.year, now.month - 6, now.day, 0, 0, 0);
        break;
      case 'YEARLY':
        start = DateTime(now.year - 1, now.month, now.day, 0, 0, 0);
        break;
      default:
        start = DateTime(_selectedDailyDate.year, _selectedDailyDate.month, _selectedDailyDate.day, 0, 0, 0);
    }

    context.read<ReportViewModel>().fetchUnperformedRangeReport(gymId, start, end);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReportViewModel>();
    final report = viewModel.monthlyReport;
    final userData = context.read<LoginViewModel>().userData;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text("ERP & Raporlama Modülü", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Finansal P&L"),
              Tab(text: "Şikayet Raporu"),
              Tab(text: "Yapılmayan Dersler"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFinanceTab(viewModel, report, userData),
            _buildComplaintsTab(viewModel),
            _buildDailyUnperformedTab(viewModel, userData),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: FINANSAL P&L TABLOSU ---
  Widget _buildFinanceTab(ReportViewModel viewModel, Map<String, dynamic>? report, Map<String, dynamic>? userData) {
    if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
    if (report == null) return const Center(child: Text("Rapor yüklenemedi."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dönemsel P&L Tablosu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: _selectedMonth,
                items: List.generate(12, (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text("${index + 1}. Ay"),
                )),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMonth = val);
                    viewModel.fetchMonthlyReport(userData?['gymId'], _selectedMonth);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryGrid(report['financeSummary']),
          const SizedBox(height: 24),
          const Text("Eğitmen Performans Karnesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ... (report['trainerPerformance'] as List).map((t) => _buildTrainerCard(t)).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard("Brüt Gelir", "${summary['totalRevenue']} TL", Colors.green),
        _buildStatCard("Bekleyen Tahsilat", "${summary['totalPending']} TL", Colors.orange),
        _buildStatCard("Toplam Giderler", "${summary['trainerCosts']} TL", Colors.redAccent),
        _buildStatCard("Net Kar/Zarar", "${summary['netProfit']} TL", Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(Map<String, dynamic> trainer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.engineering_rounded, color: Colors.blue)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trainer['trainerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${trainer['lessonCount']} Ders | Memnuniyet: ${trainer['averageRating']} / 5.0", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text("${trainer['totalEarning']} Puan", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 15)),
        ],
      ),
    );
  }

  // --- TAB 2: GİZLİ YÖNETİCİ ŞİKAYET VE ANKET RAPORU ---
  Widget _buildComplaintsTab(ReportViewModel viewModel) {
    final complaints = viewModel.trainerComplaints;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.security_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Gizli Yönetici Şikayet Raporu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                      Text("1-2 yıldız alan veya yazılı geri bildirim bırakılan dersler eğitmene gizli, sadece yöneticiye raporlanır.", style: TextStyle(fontSize: 11, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Şikayet & Düşük Puanlı Dersler (${complaints.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (complaints.isEmpty)
            _buildEmptyReport("Kayıtlı herhangi bir şikayet veya olumsuz değerlendirme bulunmamaktadır.")
          else
            ...complaints.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Eğitmen: ${item['trainerName']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(" ${item['rating']} / 5", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("Üye: ${item['memberName']}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  if (item['comment'] != null && item['comment'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text("Şikayet / Not: \"${item['comment']}\"", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                  ],
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  // --- TAB 3: DÖNEMSEL YAPILMAYAN DERSLER RAPORU ---
  Widget _buildDailyUnperformedTab(ReportViewModel viewModel, Map<String, dynamic>? userData) {
    final list = viewModel.dailyUnperformedReport;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Yapılmayan Dersler Raporu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_selectedUnperformedPeriod == 'DAILY' || _selectedUnperformedPeriod == 'WEEKLY' || _selectedUnperformedPeriod == 'MONTHLY')
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDailyDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && mounted) {
                      setState(() => _selectedDailyDate = date);
                      _loadUnperformedReport();
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(DateFormat('dd MMMM yyyy', 'tr').format(_selectedDailyDate)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Periyot Seçici
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUnperformedPeriod,
                isExpanded: true,
                icon: const Icon(Icons.tune_rounded, color: Colors.purple),
                items: const [
                  DropdownMenuItem(value: "DAILY", child: Text("Günlük Rapor")),
                  DropdownMenuItem(value: "WEEKLY", child: Text("Haftalık Rapor")),
                  DropdownMenuItem(value: "MONTHLY", child: Text("Aylık Rapor")),
                  DropdownMenuItem(value: "QUARTERLY", child: Text("3 Aylık Rapor (Çeyreklik)")),
                  DropdownMenuItem(value: "SEMI_ANNUALLY", child: Text("6 Aylık Rapor")),
                  DropdownMenuItem(value: "YEARLY", child: Text("Yıllık Rapor")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedUnperformedPeriod = val);
                    _loadUnperformedReport();
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
          if (list.isEmpty)
            _buildEmptyReport("Seçilen dönemde iptal edilen, no-show olan veya itiraz edilen ders bulunmuyor.")
          else
            ...list.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${item['memberName']} - ${item['trainerName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Tarih/Saat: ${item['time']} | Nedeni: ${item['reason']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_getStatusText(item['status']), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'NO_SHOW':
        return "Üye Derse Katılmadı";
      case 'CANCELLED':
        return "İptal Edildi";
      case 'PENDING_ADMIN_APPROVAL':
        return "Yönetici Onayı Bekliyor";
      case 'PENDING':
        return "Onay Bekliyor";
      case 'ACTIVE':
        return "Aktif";
      default:
        return status;
    }
  }

  Widget _buildEmptyReport(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center)),
    );
  }
}
