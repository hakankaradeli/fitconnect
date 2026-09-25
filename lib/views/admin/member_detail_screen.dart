import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/booking_details_model.dart';
import '../../models/slot_availability_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import 'package:intl/intl.dart';
import '../../utils/image_utils.dart';
import '../../constants/lesson_constants.dart';
import '../../view_models/calendar_view_model.dart';
import '../../view_models/finance_view_model.dart';
import '../../view_models/nutrition_view_model.dart';

class MemberDetailScreen extends StatefulWidget {
  final UserModel member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late UserModel _currentMember;

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarViewModel>().fetchMemberHistory(int.parse(_currentMember.id));
      context.read<FinanceViewModel>().fetchBalance(int.parse(_currentMember.id));
    });
  }

  void _showEditBookingDialog(BookingDetails booking) {
    DateTime selectedTime = booking.startTime;
    final calendarVM = context.read<CalendarViewModel>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ders Saatini Değiştir"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Yeni bir tarih ve saat seçin. Değişiklik üyeye onay için gönderilecektir."),
              const SizedBox(height: 16),
              ListTile(
                title: Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(selectedTime)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedTime),
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final success = await calendarVM.proposeBookingChange(booking.id, selectedTime);
                if (success && mounted) {
                  Navigator.pop(context);
                  calendarVM.fetchMemberHistory(int.parse(_currentMember.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Değişiklik teklifi üyeye gönderildi.")),
                  );
                }
              },
              child: const Text("Onaya Gönder"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAssignmentDialog() {
    final userVM = context.read<UserViewModel>();
    final trainers = userVM.users.where((u) => u.role == 'TRAINER').toList();

    String? tempLessonType = _currentMember.assignedLessonType;
    if (tempLessonType == "PT_1TO1") tempLessonType = "PT Bireysel";
    if (tempLessonType == "PT_DUO") tempLessonType = "PT Duo";
    if (tempLessonType == "REFORMER_GROUP") tempLessonType = "Reformer Pilates 4 Kişi Grup";
    
    List<String> getTypesForCategory(String category) {
      if (category == LessonConstants.reformer) return LessonConstants.reformerTypes;
      if (category == LessonConstants.yoga) return LessonConstants.yogaTypes;
      return LessonConstants.ptTypes;
    }

    String tempCategory = tempLessonType != null ? LessonConstants.getCategory(tempLessonType) : LessonConstants.pt;
    if (tempLessonType == null || !LessonConstants.allTypes.contains(tempLessonType)) {
      tempLessonType = getTypesForCategory(tempCategory).first;
    }

    int? tempTrainerId = _currentMember.assignedTrainerId != null 
        ? int.tryParse(_currentMember.assignedTrainerId!) 
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ders ve Eğitmen Güncelle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempCategory,
                decoration: const InputDecoration(labelText: "Ana Ders Grubu"),
                items: const [
                  DropdownMenuItem(value: LessonConstants.pt, child: Text("PT")),
                  DropdownMenuItem(value: LessonConstants.reformer, child: Text("Reformer Pilates")),
                  DropdownMenuItem(value: LessonConstants.yoga, child: Text("Yoga")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      tempCategory = val;
                      tempLessonType = getTypesForCategory(val).first;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tempLessonType,
                decoration: InputDecoration(labelText: "$tempCategory - Alt Ders Tipi"),
                items: getTypesForCategory(tempCategory)
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setDialogState(() => tempLessonType = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: tempTrainerId,
                decoration: const InputDecoration(labelText: "Eğitmen"),
                items: trainers
                    .map((t) => DropdownMenuItem(value: int.parse(t.id), child: Text(t.fullName)))
                    .toList(),
                onChanged: (val) => setDialogState(() => tempTrainerId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final success = await userVM.updateMemberAssignment(
                  memberId: int.parse(_currentMember.id),
                  trainerId: tempTrainerId,
                  lessonType: tempLessonType,
                );
                
                if (success && mounted) {
                  setState(() {
                    _currentMember = userVM.users.firstWhere((u) => u.id == _currentMember.id);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Atama başarıyla güncellendi")),
                  );
                }
              },
              child: const Text("Güncelle"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBookingDialog() {
    final calendarVM = context.read<CalendarViewModel>();
    final loginVM = context.read<LoginViewModel>();
    
    if (_currentMember.assignedTrainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce üyeye bir eğitmen atayın.")),
      );
      return;
    }

    List<DateTime> selectedSlots = [];
    DateTime tempDate = DateTime.now().add(const Duration(days: 1));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calendarVM.fetchAvailableSlots(
        int.parse(_currentMember.assignedTrainerId!),
        loginVM.userData?['gymId'] ?? 1,
        tempDate
      );
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ders Planla (Müsaitlik)"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_currentMember.assignedTrainerName ?? "", style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('dd/MM/yyyy').format(tempDate)),
                      onPressed: () async {
                        DateTime initial = tempDate;

                        bool isDateSelectable(DateTime val) {
                          if (val.weekday == DateTime.sunday) return false;
                          if (_currentMember.assignedTrainerId != null) {
                            try {
                              final userVM = context.read<UserViewModel>();
                              final trainer = userVM.users.firstWhere(
                                (u) => u.id == _currentMember.assignedTrainerId
                               );
                               if (trainer.leaveStart != null && trainer.leaveEnd != null) {
                                 final dayStart = DateTime(val.year, val.month, val.day);
                                 final leaveStartDay = DateTime(trainer.leaveStart!.year, trainer.leaveStart!.month, trainer.leaveStart!.day);
                                 final leaveEndDay = DateTime(trainer.leaveEnd!.year, trainer.leaveEnd!.month, trainer.leaveEnd!.day);
                                 return dayStart.isBefore(leaveStartDay) || dayStart.isAfter(leaveEndDay);
                               }
                            } catch (e) {}
                          }
                          return true;
                        }

                        while (!isDateSelectable(initial)) {
                          initial = initial.add(const Duration(days: 1));
                        }

                        final date = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                          selectableDayPredicate: isDateSelectable,
                        );
                        if (date != null) {
                          setDialogState(() => tempDate = date);
                          calendarVM.fetchAvailableSlots(
                            int.parse(_currentMember.assignedTrainerId!),
                            loginVM.userData?['gymId'] ?? 1,
                            tempDate
                          );
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                
                const Text("Müsait Saatleri Seçin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                
                SizedBox(
                  height: 240, // Yükseklik artırıldı
                  child: context.watch<CalendarViewModel>().isSlotsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.8, // Butonlar biraz daha uzun yapıldı (2.2'den 1.8'e)
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: calendarVM.availableSlots.length,
                        itemBuilder: (context, index) {
                          final slot = calendarVM.availableSlots[index];
                          final isSelected = selectedSlots.contains(slot.startTime);
                          
                          return InkWell(
                            onTap: slot.isAvailable 
                              ? () => setDialogState(() {
                                  if (isSelected) {
                                    selectedSlots.remove(slot.startTime);
                                  } else {
                                    selectedSlots.add(slot.startTime);
                                  }
                                })
                              : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? Colors.green 
                                  : slot.isAvailable ? Colors.white : Colors.grey.shade200,
                                border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(slot.startTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : slot.isAvailable ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                  if (!slot.isAvailable)
                                    Text(slot.reason ?? "Dolu", style: const TextStyle(fontSize: 7, color: Colors.red)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
                
                const Divider(),
                const Text("Seçilen Dersler:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: selectedSlots.isEmpty 
                      ? const Center(child: Text("Saat seçilmedi", style: TextStyle(fontSize: 11, color: Colors.grey)))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: selectedSlots.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text("- ${DateFormat('dd MMMM, HH:mm', 'tr').format(selectedSlots[index])}", 
                              style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: selectedSlots.isEmpty ? null : () async {
                try {
                  final success = await calendarVM.createBulkAppointments(
                    memberId: int.parse(_currentMember.id),
                    trainerId: int.parse(_currentMember.assignedTrainerId!),
                    gymId: loginVM.userData?['gymId'] ?? 1,
                    startTimes: selectedSlots,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                    calendarVM.fetchMemberHistory(int.parse(_currentMember.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${selectedSlots.length} adet ders planlandı.")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentMember.fullName),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditAssignmentDialog,
            tooltip: "Ders/Eğitmen Düzenle",
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBookingDialog,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("YENİ DERS PLANLA", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildFreezeSection(),
            _buildAssignmentSection(),
            _buildNutritionPlanSection(),
            _buildCreditSection(),
            _buildLessonHistory(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.assignment_ind, color: Colors.blue),
        title: const Text("Eğitmen", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentMember.assignedTrainerName ?? "Atanmamış"),
            Text("Ders Tipi: ${_currentMember.assignedLessonType ?? "Belirlenmemiş"}", 
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: TextButton(
          onPressed: _showEditAssignmentDialog,
          child: const Text("DEĞİŞTİR"),
        ),
      ),
    );
  }

  Widget _buildFreezeSection() {
    final bool isFrozen = _currentMember.hasDefinedLeave;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isFrozen ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(isFrozen ? Icons.ac_unit_rounded : Icons.pause_circle_outline_rounded, 
            color: isFrozen ? Colors.blue : Colors.blueGrey),
        title: Text(isFrozen ? "Üyelik Donduruldu" : "Üyeliği Dondur", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isFrozen
            ? Text("Tarih: ${DateFormat('dd/MM/yyyy').format(_currentMember.leaveStart!)} - ${DateFormat('dd/MM/yyyy').format(_currentMember.leaveEnd!)}")
            : const Text("Sağlık, seyahat vb. durumlarda üyeliği geçici dondurabilirsiniz.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: TextButton(
          onPressed: () => isFrozen ? _unfreezeMemberDialog() : _showFreezeDialog(),
          child: Text(isFrozen ? "DONDURMAYI İPTAL ET" : "DONDUR", 
              style: TextStyle(color: isFrozen ? Colors.red : Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildNutritionPlanSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.restaurant_rounded, color: Colors.teal),
        title: const Text("Beslenme Programı", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Üyenin aktif beslenme planını ve öğünlerini inceleyin.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: TextButton(
          onPressed: _showMemberNutritionPlanDialog,
          child: const Text("GÖRÜNTÜLE", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showMemberNutritionPlanDialog() async {
    final nutritionVM = context.read<NutritionViewModel>();
    final plan = await nutritionVM.fetchMemberPlan(int.parse(_currentMember.id));

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("${_currentMember.fullName} - Beslenme Planı", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: plan == null
              ? const Text("Bu üyeye henüz beslenme planı tanımlanmamış.")
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Text("${plan.dailyCalories} kcal / Gün", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text("P: ${plan.protein}g", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("C: ${plan.carbs}g", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("F: ${plan.fat}g", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Öğün Listesi:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...plan.meals.map((meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("• $meal", style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      const SizedBox(height: 12),
                      Text("Son Güncelleme: ${DateFormat('dd/MM/yyyy').format(plan.updatedAt)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text("Yenilenme Tarihi: ${DateFormat('dd/MM/yyyy').format(plan.expiryDate)}", style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
      ),
    );
  }

  void _showFreezeDialog() {
    DateTimeRange? selectedRange;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Üyelik Dondurma"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(selectedRange == null
                    ? "Dondurma Tarih Aralığı Seçin"
                    : "${DateFormat('dd/MM/yyyy').format(selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedRange!.end)}"),
                trailing: const Icon(Icons.calendar_month, color: Colors.blue),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (range != null) setDialogState(() => selectedRange = range);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: "Dondurma Sebebi (Sağlık, Seyahat vb.)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: selectedRange == null ? null : () async {
                final success = await context.read<UserViewModel>().freezeMember(
                  memberId: int.parse(_currentMember.id),
                  start: selectedRange!.start,
                  end: selectedRange!.end,
                  reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  final userVM = context.read<UserViewModel>();
                  await userVM.fetchUsers(int.parse(_currentMember.gymId));
                  setState(() {
                    _currentMember = userVM.users.firstWhere((u) => u.id == _currentMember.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Üyelik başarıyla donduruldu.")));
                }
              },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }

  void _unfreezeMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dondurmayı İptal Et"),
        content: const Text("Üyenin dondurma işlemini sonlandırıp aktif duruma getirmek istiyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await context.read<UserViewModel>().unfreezeMember(int.parse(_currentMember.id));
              if (success && mounted) {
                Navigator.pop(context);
                final userVM = context.read<UserViewModel>();
                await userVM.fetchUsers(int.parse(_currentMember.gymId));
                setState(() {
                  _currentMember = userVM.users.firstWhere((u) => u.id == _currentMember.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dondurma işlemi iptal edildi.")));
              }
            },
            child: const Text("EVET, AKTİFLEŞTİR"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = _currentMember.profileImageUrl;
    final imageProvider = getProfileImageProvider(photoUrl);

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: Colors.redAccent.withOpacity(0.1),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            backgroundImage: imageProvider,
            child: imageProvider == null ? const Icon(Icons.person, size: 50, color: Colors.redAccent) : null,
          ),
          const SizedBox(height: 10),
          Text(_currentMember.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_currentMember.email, style: const TextStyle(color: Colors.grey)),
          Text(_currentMember.phone ?? "Telefon yok", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              if (_currentMember.assignedTrainerName != null)
                Chip(
                  avatar: const Icon(Icons.engineering, size: 16),
                  label: Text("Eğitmen: ${_currentMember.assignedTrainerName}"),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              if (_currentMember.assignedLessonType != null)
                Chip(
                  avatar: const Icon(Icons.fitness_center, size: 16),
                  label: Text("Ders: ${_currentMember.assignedLessonType}"),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                ),
              if (_currentMember.instagram != null && _currentMember.instagram!.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.camera_alt, size: 16, color: Colors.purple),
                  label: Text("@${_currentMember.instagram}"),
                  backgroundColor: Colors.purple.withOpacity(0.1),
                ),
              if (_currentMember.linkedin != null && _currentMember.linkedin!.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.work, size: 16, color: Colors.blue),
                  label: Text(_currentMember.linkedin!),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              if (_currentMember.twitter != null && _currentMember.twitter!.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.alternate_email, size: 16, color: Colors.black),
                  label: Text(_currentMember.twitter!.replaceFirst(RegExp(r'^@+'), '')),
                  backgroundColor: Colors.black.withOpacity(0.1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditSection() {
    final financeVM = context.watch<FinanceViewModel>();
    final balance = financeVM.balance;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _creditItem("Kalan Kredi", "${balance.totalCredits - balance.usedCredits}", Colors.green),
                const VerticalDivider(),
                _creditItem("Harcanan", "${balance.usedCredits}", Colors.orange),
                const VerticalDivider(),
                _creditItem("Toplam", "${balance.totalCredits}", Colors.blue),
              ],
            ),
            const Divider(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddCreditDialog(context),
              icon: const Icon(Icons.add_card),
              label: const Text("KREDİ TANIMLA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCreditDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController paymentController = TextEditingController();
    final financeVM = context.read<FinanceViewModel>();
    
    bool isPaid = true;
    DateTime selectedDueDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Kredi ve Ödeme Tanımla"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Kredi Miktarı (Seans)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paymentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Toplam Tutar (TL)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text("Ödeme Alındı", style: TextStyle(fontSize: 14)),
                  value: isPaid,
                  onChanged: (val) => setDialogState(() => isPaid = val ?? false),
                ),
                if (!isPaid)
                  ListTile(
                    title: const Text("Ödeme Tarihi", style: TextStyle(fontSize: 12)),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDueDate)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setDialogState(() => selectedDueDate = date);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                final payment = double.tryParse(paymentController.text);
                
                if (amount != null && payment != null) {
                  final success = await financeVM.addCredit(
                    memberId: int.parse(_currentMember.id),
                    amount: amount,
                    paymentAmount: payment,
                    isPaid: isPaid,
                    dueDate: isPaid ? null : selectedDueDate,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$amount kredi ve ${isPaid ? 'ödeme' : 'borç kaydı'} oluşturuldu.")),
                    );
                  }
                }
              },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creditItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLessonHistory() {
    final calendarVM = context.watch<CalendarViewModel>();
    final history = calendarVM.memberHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Ders Geçmişi ve Programı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (calendarVM.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Kayıtlı ders bulunmamaktadır.", style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final booking = history[index];
              final bool isPast = booking.startTime.isBefore(DateTime.now());
              final bool isCompleted = booking.status == 'COMPLETED' || (booking.status == 'ACTIVE' && isPast);

              return ListTile(
                onTap: isCompleted ? () => _showExerciseLogDialog(booking) : null,
                leading: const Icon(Icons.fitness_center, color: Colors.redAccent),
                title: Text("${booking.trainerName} ile Ders"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(booking.startTime)),
                    if (booking.performedExercises.isNotEmpty)
                      Text("${booking.performedExercises.length} egzersiz girildi", style: const TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCompleted ? "Tamamlandı" : booking.statusText,
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCompleted && booking.status != 'CANCELLED')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, size: 20, color: Colors.blue),
                            tooltip: "Eğitmeni Değiştir",
                            onPressed: () => _showChangeTrainerDialog(booking),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_calendar, size: 20),
                            onPressed: () => _showEditBookingDialog(booking),
                            tooltip: "Dersi Güncelle",
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showChangeTrainerDialog(BookingDetails booking) {
    // ... (existing code)
  }

  void _showExerciseLogDialog(BookingDetails booking) {
    final List<PerformedExercise> tempExercises = List.from(booking.performedExercises);
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("${_currentMember.fullName} - Antrenman Özeti"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tempExercises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Henüz çalışma girilmemiş.", style: TextStyle(color: Colors.grey)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tempExercises.length,
                      itemBuilder: (context, idx) => ListTile(
                        dense: true,
                        title: Text(tempExercises[idx].exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${tempExercises[idx].sets ?? '-'} Set x ${tempExercises[idx].reps ?? '-'} Tekrar | ${tempExercises[idx].weight ?? '-'}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => setDialogState(() => tempExercises.removeAt(idx)),
                        ),
                      ),
                    ),
                  ),
                const Divider(),
                const Text("Yeni Çalışma Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Egzersiz Adı", isDense: true)),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightController, decoration: const InputDecoration(labelText: "Ağırlık", hintText: "29 KG", isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Set", isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Tekrar", isDense: true))),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setDialogState(() {
                        tempExercises.add(PerformedExercise(
                          exerciseName: nameController.text,
                          weight: weightController.text,
                          sets: int.tryParse(setsController.text),
                          reps: int.tryParse(repsController.text),
                        ));
                        nameController.clear();
                        weightController.clear();
                        setsController.clear();
                        repsController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Listeye Ekle"),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final vm = context.read<CalendarViewModel>();
                final success = await vm.addPerformedExercises(booking.id, tempExercises);
                if (success && mounted) {
                  Navigator.pop(context);
                  vm.fetchMemberHistory(int.parse(_currentMember.id));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Antrenman özeti güncellendi.")));
                }
              },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }
}
