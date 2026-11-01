import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/finance_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/finance_model.dart';
import '../../utils/currency_utils.dart';
import '../widgets/custom_back_button.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  DateTimeRange? _selectedDateRange;
  String _activePreset = "ALL";
  int? _selectedMonthFilter;

  final Map<int, String> _months = const {
    1: "Ocak", 2: "Şubat", 3: "Mart", 4: "Nisan", 5: "Mayıs", 6: "Haziran",
    7: "Temmuz", 8: "Ağustos", 9: "Eylül", 10: "Ekim", 11: "Kasım", 12: "Aralık"
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<FinanceViewModel>().fetchAllInstallments(userData['gymId']);
      }
    });
  }

  bool _isWithinRange(DateTime date, DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _activePreset = preset;
      if (preset == "ALL") {
        _selectedDateRange = null;
        _selectedMonthFilter = null;
      } else if (preset == "THIS_MONTH") {
        _selectedDateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
        _selectedMonthFilter = null;
      } else if (preset == "LAST_MONTH") {
        _selectedDateRange = DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        );
        _selectedMonthFilter = null;
      } else if (preset == "LAST_30_DAYS") {
        _selectedDateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
        _selectedMonthFilter = null;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      helpText: 'İki Tarih Aralığı Seçin',
      cancelText: 'Vazgeç',
      confirmText: 'Uygula',
      saveText: 'Uygula',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _activePreset = "CUSTOM";
        _selectedMonthFilter = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FinanceViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    final filteredPlans = viewModel.installments.where((p) {
      if (_selectedDateRange != null) {
        return _isWithinRange(p.dueDate, _selectedDateRange!);
      }
      if (_selectedMonthFilter != null) {
        return p.dueDate.month == _selectedMonthFilter;
      }
      return true;
    }).toList();

    final sortedPlans = List<PaymentPlan>.from(filteredPlans)
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    final groupedPlans = _groupPlansByMonth(sortedPlans);
    final totalIncome = filteredPlans.fold(0.0, (sum, p) => sum + (p.status == PaymentStatus.paid ? p.amount : 0));
    final totalPending = filteredPlans.fold(0.0, (sum, p) => sum + (p.status != PaymentStatus.paid ? p.amount : 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Gelir Yönetimi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (userData != null) {
                  await viewModel.fetchAllInstallments(userData['gymId']);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(totalIncome, totalPending),
                    const SizedBox(height: 16),
                    _buildDateFilterSection(),
                    const SizedBox(height: 20),
                    if (groupedPlans.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text("Seçilen tarih aralığında gelir kaydı bulunmamaktadır.", style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ...groupedPlans.entries.map((entry) => _buildMonthGroup(context, entry.key, entry.value, userData?['gymId'])).toList(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Map<String, List<PaymentPlan>> _groupPlansByMonth(List<PaymentPlan> plans) {
    final Map<String, List<PaymentPlan>> grouped = {};
    for (var plan in plans) {
      final key = DateFormat('MMMM yyyy', 'tr').format(plan.dueDate);
      grouped.putIfAbsent(key, () => []).add(plan);
    }
    return grouped;
  }

  Widget _buildSummaryCards(double income, double pending) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text("Tahsil Edilen", style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(formatCurrency(income), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green.shade900)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text("Bekleyen Alacak", style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(formatCurrency(pending), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.orange.shade900)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilterSection() {
    String rangeLabel;
    if (_selectedDateRange != null) {
      final startStr = DateFormat('d MMM yyyy', 'tr').format(_selectedDateRange!.start);
      final endStr = DateFormat('d MMM yyyy', 'tr').format(_selectedDateRange!.end);
      rangeLabel = "$startStr - $endStr";
    } else if (_selectedMonthFilter != null) {
      rangeLabel = "${_months[_selectedMonthFilter]} Ayı";
    } else {
      rangeLabel = "Tüm Tarihler (Filtre Yok)";
    }

    final bool hasActiveFilter = _selectedDateRange != null || _selectedMonthFilter != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasActiveFilter ? Colors.orange.shade300 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _pickCustomDateRange,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasActiveFilter ? Colors.orange.shade50 : const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasActiveFilter ? Colors.orange.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasActiveFilter ? Colors.orange : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasActiveFilter ? "Seçilen Tarih Aralığı" : "Tarih Aralığı Seç",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasActiveFilter ? Colors.orange.shade900 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rangeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasActiveFilter ? Colors.orange.shade900 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasActiveFilter)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.orange, size: 20),
                      tooltip: "Filtreyi Temizle",
                      onPressed: () => _setDatePreset("ALL"),
                    )
                  else
                    const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("Tüm Zamanlar", _activePreset == "ALL", () => _setDatePreset("ALL")),
                const SizedBox(width: 8),
                _buildFilterChip("Bu Ay", _activePreset == "THIS_MONTH", () => _setDatePreset("THIS_MONTH")),
                const SizedBox(width: 8),
                _buildFilterChip("Geçen Ay", _activePreset == "LAST_MONTH", () => _setDatePreset("LAST_MONTH")),
                const SizedBox(width: 8),
                _buildFilterChip("Son 30 Gün", _activePreset == "LAST_30_DAYS", () => _setDatePreset("LAST_30_DAYS")),
                const SizedBox(width: 8),
                _buildFilterChip("İki Tarih Arası 📅", _activePreset == "CUSTOM", _pickCustomDateRange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGroup(BuildContext context, String monthName, List<PaymentPlan> plans, int? gymId) {
    final monthTotal = plans.fold(0.0, (sum, p) => sum + (p.status == PaymentStatus.paid ? p.amount : 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "Tahsilat: ${formatCurrency(monthTotal)}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        ...plans.map((plan) => _buildPaymentCard(context, plan, gymId)).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentPlan plan, int? gymId) {
    final isPaid = plan.status == PaymentStatus.paid;
    final color = isPaid ? Colors.green : (plan.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(isPaid ? Icons.check_rounded : Icons.pending_actions_rounded, color: color),
        ),
        title: Text(plan.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${formatCurrency(plan.amount)} | ${plan.creditsToLoad} Kredi", style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("Vade: ${DateFormat('dd MMMM yyyy', 'tr').format(plan.dueDate)}",
                style: TextStyle(fontSize: 12, color: plan.dueDate.isBefore(DateTime.now()) && !isPaid ? Colors.red : Colors.grey)),
          ],
        ),
        trailing: isPaid
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text("ÖDENDİ", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _confirmPayment(context, plan, gymId),
              child: const Text("ONAYLA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, PaymentPlan plan, int? gymId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ödeme Onayı"),
        content: Text("${plan.memberName} isimli üyeden ${formatCurrency(plan.amount)} tutarındaki ödeme alındı mı?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hayır")),
          TextButton(
            onPressed: () async {
              final success = await context.read<FinanceViewModel>().confirmPayment(plan.id, gymId!);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ödeme başarıyla onaylandı.")));
              }
            },
            child: const Text("Evet, Alındı", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
