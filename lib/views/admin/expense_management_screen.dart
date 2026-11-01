import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/expense_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/expense_model.dart';
import '../../utils/currency_utils.dart';
import '../widgets/custom_back_button.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  String _selectedCategoryFilter = "ALL";
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
        context.read<ExpenseViewModel>().fetchExpenses(userData['gymId']);
        context.read<UserViewModel>().fetchUsers(userData['gymId']);
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
              primary: Colors.redAccent,
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
    final expenseVM = context.watch<ExpenseViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    final filteredExpenses = expenseVM.expenses.where((e) {
      final matchesCategory = _selectedCategoryFilter == "ALL" || e.category == _selectedCategoryFilter;
      bool matchesDate = true;
      if (_selectedDateRange != null) {
        matchesDate = _isWithinRange(e.expenseDate, _selectedDateRange!);
      } else if (_selectedMonthFilter != null) {
        matchesDate = e.expenseDate.month == _selectedMonthFilter;
      }
      return matchesCategory && matchesDate;
    }).toList();

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
        leading: const CustomBackButton(),
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
                    const SizedBox(height: 16),
                    _buildDateFilterSection(),
                    const SizedBox(height: 12),
                    _buildCategoryFilterDropdown(),
                    const SizedBox(height: 20),
                    if (groupedExpenses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text("Seçilen tarih aralığında gider kaydı bulunmamaktadır.", style: TextStyle(color: Colors.grey)),
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
                Text(formatCurrency(total), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
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
        border: Border.all(color: hasActiveFilter ? Colors.redAccent.shade100 : Colors.grey.shade200),
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
                color: hasActiveFilter ? Colors.red.shade50 : const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasActiveFilter ? Colors.redAccent.shade100 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasActiveFilter ? Colors.redAccent : Colors.grey.shade400,
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
                            color: hasActiveFilter ? Colors.red.shade900 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rangeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasActiveFilter ? Colors.red.shade900 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasActiveFilter)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
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
          color: isSelected ? Colors.redAccent : Colors.grey.shade100,
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

  Widget _buildCategoryFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategoryFilter,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.blueGrey),
                items: const [
                  DropdownMenuItem(value: "ALL", child: Text("Tüm Gider Türleri", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: "TRAINER_EARNINGS", child: Text("Hakediş Ödemesi", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "TRAINER_INSURANCE", child: Text("Sigorta Primi", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "TAX", child: Text("Vergiler", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "ELECTRICITY", child: Text("Elektrik", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "WATER", child: Text("Su", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "NATURAL_GAS", child: Text("Doğalgaz", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "RENT", child: Text("Kira", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "ACCOUNTANT", child: Text("Muhasebeci", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "BAGKUR", child: Text("Bağkur", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "OTHER", child: Text("Diğer Giderler", style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategoryFilter = val);
                },
              ),
            ),
          ),
        ],
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
                  "Gider: ${formatCurrency(monthTotal)}",
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
            Text(formatCurrency(expense.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.redAccent)),
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
    final trainers = userVM.users.where((u) => u.isTrainerOrCanTeach && u.isActive).toList();

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
