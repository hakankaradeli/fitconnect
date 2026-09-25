import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/expense_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/expense_model.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  String _selectedCategoryFilter = "ALL";
  int? _selectedMonthFilter; // null = Tüm Aylar

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
        context.read<ExpenseViewModel>().fetchExpenses(userData['gymId']);
        context.read<UserViewModel>().fetchUsers(userData['gymId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    // Filtreleme: Kategori & Ay
    final filteredExpenses = expenseVM.expenses.where((e) {
      final matchesCategory = _selectedCategoryFilter == "ALL" || e.category == _selectedCategoryFilter;
      final matchesMonth = _selectedMonthFilter == null || e.expenseDate.month == _selectedMonthFilter;
      return matchesCategory && matchesMonth;
    }).toList();

    // Yeni tarihten eski tarihe doğru sıralama
    final sortedExpenses = List<ExpenseModel>.from(filteredExpenses)
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    final groupedExpenses = _groupExpensesByMonth(sortedExpenses);
    final totalFiltered = filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Gider Yönetimi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        onPressed: () => _showAddExpenseSheet(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("YENİ GİDER EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: expenseVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (userData != null) {
                  await expenseVM.fetchExpenses(userData['gymId']);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalExpenseCard(totalFiltered),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildMonthFilterDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCategoryFilterDropdown()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (groupedExpenses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text("Seçilen dönemde gider kaydı bulunmamaktadır.", style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ...groupedExpenses.entries.map((entry) => _buildMonthExpenseGroup(context, entry.key, entry.value, userData?['gymId'])).toList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Map<String, List<ExpenseModel>> _groupExpensesByMonth(List<ExpenseModel> expenses) {
    final Map<String, List<ExpenseModel>> grouped = {};
    for (var expense in expenses) {
      final key = DateFormat('MMMM yyyy', 'tr').format(expense.expenseDate);
      grouped.putIfAbsent(key, () => []).add(expense);
    }
    return grouped;
  }

  Widget _buildTotalExpenseCard(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF1744)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Toplam Gider", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                Text("${total.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedMonthFilter,
          isExpanded: true,
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.blueGrey, size: 20),
          hint: const Text("Tüm Aylar", style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text("Tüm Aylar", style: TextStyle(fontSize: 13))),
            ..._months.entries.map((e) => DropdownMenuItem<int?>(
              value: e.key,
              child: Text(e.value, style: const TextStyle(fontSize: 13)),
            )).toList(),
          ],
          onChanged: (val) => setState(() => _selectedMonthFilter = val),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryFilter,
          isExpanded: true,
          icon: const Icon(Icons.filter_list_rounded, color: Colors.blueGrey, size: 20),
          items: const [
            DropdownMenuItem(value: "ALL", child: Text("Tüm Türler", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "TRAINER_EARNINGS", child: Text("Hakediş Ödemesi", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "TRAINER_INSURANCE", child: Text("Sigorta Primi", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "TAX", child: Text("Vergiler", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "ELECTRICITY", child: Text("Elektrik", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "WATER", child: Text("Su", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "NATURAL_GAS", child: Text("Doğalgaz", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "RENT", child: Text("Kira", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "ACCOUNTANT", child: Text("Muhasebeci", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "BAGKUR", child: Text("Bağkur", style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: "OTHER", child: Text("Diğer", style: TextStyle(fontSize: 13))),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategoryFilter = val);
          },
        ),
      ),
    );
  }

  Widget _buildMonthExpenseGroup(BuildContext context, String monthName, List<ExpenseModel> expenses, int? gymId) {
    final monthTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

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
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "Gider: ${monthTotal.toStringAsFixed(0)} TL",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
        ...expenses.map((expense) => _buildExpenseTile(context, expense, gymId)).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildExpenseTile(BuildContext context, ExpenseModel expense, int? gymId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getCategoryColor(expense.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category)),
        ),
        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.categoryText, style: TextStyle(fontSize: 12, color: _getCategoryColor(expense.category), fontWeight: FontWeight.w600)),
            if (expense.trainerName != null)
              Text("Eğitmen: ${expense.trainerName}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
            Text(DateFormat('dd MMMM yyyy', 'tr').format(expense.expenseDate), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              Text("Not: ${expense.notes}", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${expense.amount.toStringAsFixed(0)} TL", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
              onPressed: () => _confirmDeleteExpense(context, expense, gymId),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, ExpenseModel expense, int? gymId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Gider Kaydını Sil"),
        content: Text("${expense.title} kaydını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await context.read<ExpenseViewModel>().deleteExpense(expense.id, gymId!);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gider kaydı silindi.")));
              }
            },
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    
    String selectedCategory = "ELECTRICITY";
    int? selectedTrainerId;
    DateTime selectedDate = DateTime.now();

    final userVM = context.read<UserViewModel>();
    final trainers = userVM.users.where((u) => u.role == 'TRAINER' && u.isActive).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Yeni Gider Ekle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Gider Türü",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: "ELECTRICITY", child: Text("Elektrik Faturası")),
                    DropdownMenuItem(value: "WATER", child: Text("Su Faturası")),
                    DropdownMenuItem(value: "NATURAL_GAS", child: Text("Doğalgaz Faturası")),
                    DropdownMenuItem(value: "RENT", child: Text("Kira")),
                    DropdownMenuItem(value: "TAX", child: Text("Vergiler")),
                    DropdownMenuItem(value: "ACCOUNTANT", child: Text("Muhasebeci Ücreti")),
                    DropdownMenuItem(value: "BAGKUR", child: Text("Bağkur Primi")),
                    DropdownMenuItem(value: "TRAINER_INSURANCE", child: Text("Eğitmen Sigorta Primi")),
                    DropdownMenuItem(value: "TRAINER_EARNINGS", child: Text("Eğitmen Hakediş Ödemesi")),
                    DropdownMenuItem(value: "OTHER", child: Text("Diğer Giderler")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() {
                        selectedCategory = val;
                        if (titleController.text.isEmpty) {
                          switch (val) {
                            case 'ELECTRICITY': titleController.text = "Elektrik Faturası"; break;
                            case 'WATER': titleController.text = "Su Faturası"; break;
                            case 'NATURAL_GAS': titleController.text = "Doğalgaz Faturası"; break;
                            case 'RENT': titleController.text = "Kira Ödemesi"; break;
                            case 'TAX': titleController.text = "Vergi Ödemesi"; break;
                            case 'ACCOUNTANT': titleController.text = "Muhasebeci Ücreti"; break;
                            case 'BAGKUR': titleController.text = "Bağkur Primi"; break;
                            case 'TRAINER_INSURANCE': titleController.text = "Eğitmen Sigorta Primi"; break;
                            case 'TRAINER_EARNINGS': titleController.text = "Eğitmen Hakediş Ödemesi"; break;
                            default: break;
                          }
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (selectedCategory == 'TRAINER_INSURANCE' || selectedCategory == 'TRAINER_EARNINGS') ...[
                  DropdownButtonFormField<int>(
                    value: selectedTrainerId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "İlgili Eğitmen",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: trainers.map((t) => DropdownMenuItem(value: int.parse(t.id), child: Text(t.fullName))).toList(),
                    onChanged: (val) => setSheetState(() => selectedTrainerId = val),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Açıklama / Başlık",
                    hintText: "Örn: Ocak Ayı Kirası",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Tutar (TL)",
                    hintText: "Örn: 2500",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade400)),
                  title: const Text("Gider Tarihi", style: TextStyle(fontSize: 12)),
                  subtitle: Text(DateFormat('dd MMMM yyyy', 'tr').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setSheetState(() => selectedDate = date);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: "Ek Notlar (Opsiyonel)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      final title = titleController.text.trim();
                      if (amount != null && amount > 0 && title.isNotEmpty) {
                        final loginVM = context.read<LoginViewModel>();
                        final success = await context.read<ExpenseViewModel>().addExpense(
                          gymId: loginVM.userData?['gymId'],
                          category: selectedCategory,
                          title: title,
                          amount: amount,
                          expenseDate: selectedDate,
                          trainerId: selectedTrainerId,
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        );

                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gider kaydı eklendi.")));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen geçerli bir tutar ve başlık girin.")));
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text("GİDERİ KAYDET"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'ELECTRICITY': return Icons.bolt_rounded;
      case 'WATER': return Icons.water_drop_rounded;
      case 'NATURAL_GAS': return Icons.local_fire_department_rounded;
      case 'RENT': return Icons.home_rounded;
      case 'TAX': return Icons.receipt_long_rounded;
      case 'ACCOUNTANT': return Icons.calculate_rounded;
      case 'BAGKUR': return Icons.security_rounded;
      case 'TRAINER_INSURANCE': return Icons.health_and_safety_rounded;
      case 'TRAINER_EARNINGS': return Icons.payments_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'ELECTRICITY': return Colors.amber.shade700;
      case 'WATER': return Colors.blue;
      case 'NATURAL_GAS': return Colors.orange;
      case 'RENT': return Colors.purple;
      case 'TAX': return Colors.redAccent;
      case 'ACCOUNTANT': return Colors.teal;
      case 'BAGKUR': return Colors.indigo;
      case 'TRAINER_INSURANCE': return Colors.deepOrange;
      case 'TRAINER_EARNINGS': return Colors.green;
      default: return Colors.blueGrey;
    }
  }
}
