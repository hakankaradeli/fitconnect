import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/booking_details_model.dart';
import '../../models/slot_availability_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import 'package:intl/intl.dart';
import '../../utils/image_utils.dart';
import '../../utils/formatters.dart';
import '../../constants/lesson_constants.dart';
import '../../view_models/calendar_view_model.dart';
import '../../view_models/finance_view_model.dart';
import '../../view_models/nutrition_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../widgets/table_time_picker.dart';
import '../widgets/custom_back_button.dart';

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
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: Colors.blue),
                title: const Text("Ders Tarihi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(DateFormat('dd MMMM yyyy, EEEE', 'tr').format(selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedTime = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute);
                    });
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart_rounded, color: Colors.orange),
                title: const Text("Ders Saati (Tablodan Seçin)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(DateFormat('HH:mm').format(selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                trailing: const Icon(Icons.access_time_rounded, size: 20, color: Colors.orange),
                onTap: () async {
                  final themeVM = context.read<ThemeViewModel>();
                  final openHour = int.tryParse(themeVM.openTime.split(':')[0]) ?? 7;
                  final closeHour = int.tryParse(themeVM.closeTime.split(':')[0]) ?? 22;

                  final time = await showTableTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedTime),
                    title: "Ders Saati Seçimi",
                    startHour: openHour,
                    endHour: closeHour > openHour ? (closeHour - 1) : closeHour,
                    isLessonBooking: true,
                  );
                  if (time != null) {
                    setDialogState(() {
                      selectedTime = DateTime(selectedTime.year, selectedTime.month, selectedTime.day, time.hour, 0);
                    });
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
    final trainers = userVM.users.where((u) => u.isTrainerOrCanTeach).toList();

    String? tempLessonType = _currentMember.assignedLessonType;
    if (tempLessonType == "PT_1TO1") tempLessonType = "PT Bireysel";
    if (tempLessonType == "PT_DUO") tempLessonType = "PT Duo";
    if (tempLessonType == "REFORMER_GROUP") tempLessonType = "Reformer Pilates 4 Kişi Grup";

    String tempCategory = tempLessonType != null ? LessonConstants.getCategory(tempLessonType) : LessonConstants.pt;
    if (tempLessonType == null || !LessonConstants.allTypes.contains(tempLessonType)) {
      tempLessonType = LessonConstants.getSubTypes(tempCategory).first;
    }

    int? tempTrainerId = _currentMember.assignedTrainerId != null
        ? int.tryParse(_currentMember.assignedTrainerId!)
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Ders ve Eğitmen Güncelle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempCategory,
                decoration: const InputDecoration(labelText: "Ana Ders Grubu"),
                items: LessonConstants.mainGroups
                    .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      tempCategory = val;
                      tempLessonType = LessonConstants.getSubTypes(val).first;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tempLessonType,
                decoration: InputDecoration(labelText: "$tempCategory - Alt Ders Tipi"),
                items: LessonConstants.getSubTypes(tempCategory)
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

  void _showRecurringBookingDialog() {
    if (_currentMember.assignedTrainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce üyeye bir eğitmen atayın.")),
      );
      return;
    }

    final loginVM = context.read<LoginViewModel>();
    final gymId = loginVM.userData?['gymId'] ?? 1;

    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);
    List<int> selectedWeekdays = [];
    int sessionCount = 12;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final weekdays = [
            {'val': 1, 'label': 'Pzt'},
            {'val': 2, 'label': 'Sal'},
            {'val': 3, 'label': 'Çar'},
            {'val': 4, 'label': 'Per'},
            {'val': 5, 'label': 'Cum'},
            {'val': 6, 'label': 'Cmt'},
            {'val': 7, 'label': 'Paz'},
          ];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Sabit Ders Planla", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.purple, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text("Yönetici yetkisi ile 24 saat kuralı ve salon kotaları devre dışı bırakılır.", style: TextStyle(fontSize: 11, color: Colors.purple))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded, color: Colors.blue),
                    title: const Text("Başlangıç Tarihi", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMMM yyyy', 'tr').format(startDate)),
                    onTap: () async {
                      bool isDateSelectable(DateTime val) {
                        final themeVM = context.read<ThemeViewModel>();
                        final workingDays = themeVM.workingDays.split(',').map((e) => int.tryParse(e) ?? 1).toList();
                        return workingDays.contains(val.weekday);
                      }

                      DateTime initial = startDate;
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
                      if (date != null) setDialogState(() => startDate = date);
                    },
                  ),
                  const Divider(),

                  const Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text("Ders Saati (Sabit)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final themeVM = context.read<ThemeViewModel>();
                      final openHour = int.tryParse(themeVM.openTime.split(':')[0]) ?? 7;
                      final closeHour = int.tryParse(themeVM.closeTime.split(':')[0]) ?? 22;
                      final int totalHours = closeHour - openHour;

                      return SizedBox(
                        height: 140,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: totalHours > 0 ? totalHours : 15,
                          itemBuilder: (context, index) {
                            final hour = openHour + index;
                            final isSelected = selectedTime.hour == hour;
                            final timeString = "${hour.toString().padLeft(2, '0')}:00";

                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedTime = TimeOfDay(hour: hour, minute: 0);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? Colors.orange.shade700 : Colors.grey.shade300),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  timeString,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  ),
                  const Divider(),

                  const Text("Ders Günleri", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: weekdays.map((w) {
                      final isSelected = selectedWeekdays.contains(w['val']);
                      return ChoiceChip(
                        label: Text(w['label'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedWeekdays.add(w['val'] as int);
                            } else {
                              selectedWeekdays.remove(w['val'] as int);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 16),

                  Row(
                    children: [
                      const Expanded(child: Text("Toplam Ders Sayısı", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          controller: TextEditingController(text: sessionCount.toString()),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              sessionCount = parsed;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("İptal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                onPressed: () async {
                  if (selectedWeekdays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen en az bir gün seçin.")));
                    return;
                  }

                  List<DateTime> generatedDates = [];
                  DateTime current = DateTime(startDate.year, startDate.month, startDate.day, selectedTime.hour, selectedTime.minute);

                  while (generatedDates.length < sessionCount) {
                    if (selectedWeekdays.contains(current.weekday)) {
                      generatedDates.add(current);
                    }
                    current = current.add(const Duration(days: 1));
                  }

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sabit dersler planlanıyor, lütfen bekleyin...")));

                  final calendarVM = context.read<CalendarViewModel>();
                  final success = await calendarVM.createBulkBookings(
                    memberId: int.parse(_currentMember.id),
                    trainerId: int.parse(_currentMember.assignedTrainerId!),
                    gymId: gymId,
                    startTimes: generatedDates,
                  );

                  if (mounted) {
                    if (success) {
                      context.read<CalendarViewModel>().fetchMemberHistory(int.parse(_currentMember.id));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sabit dersler başarıyla oluşturuldu!")));
                    } else {
                      final error = calendarVM.errorMessage ?? "Oluşturulamadı";
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Text("Planlama Hatası", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          content: Text(error, style: const TextStyle(fontSize: 14)),
                          actions: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Tamam"),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: const Text("PLANLA"),
              ),
            ],
          );
        }
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
                          final themeVM = context.read<ThemeViewModel>();
                          final workingDays = themeVM.workingDays.split(',').map((e) => int.tryParse(e) ?? 1).toList();
                          if (!workingDays.contains(val.weekday)) return false;

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
                  height: 240,
                  child: context.watch<CalendarViewModel>().isSlotsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.8,
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
    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;
    final onPrimary = themeVM.onPrimaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentMember.fullName,
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: primaryColor.computeLuminance() > 0.45
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: CustomBackButton(
          color: onPrimary,
          backgroundColor: onPrimary.withValues(alpha: 0.18),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, color: onPrimary, size: 18),
            ),
            onPressed: _showEditAssignmentDialog,
            tooltip: "Ders/Eğitmen Düzenle",
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildFreezeSection(),
            _buildAssignmentSection(),
            _buildNutritionPlanSection(),
            _buildCreditSection(),
            _buildBookingActionButtons(),
            _buildLessonHistory(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingActionButtons() {
    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _showCreateBookingDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("YENİ DERS", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _showRecurringBookingDialog,
                  icon: const Icon(Icons.event_repeat_rounded, size: 20),
                  label: const Text("SABİT DERS", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
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
    final bool isFrozen = _currentMember.isFrozen;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isFrozen ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(isFrozen ? Icons.ac_unit_rounded : Icons.pause_circle_outline_rounded,
            color: isFrozen ? Colors.blue : Colors.blueGrey),
        title: Text(isFrozen ? "Üyelik Donduruldu" : "Üyeliği Dondur", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isFrozen
            ? Text("Tarih: ${DateFormat('dd/MM/yyyy').format(_currentMember.freezeStart!)} - ${DateFormat('dd/MM/yyyy').format(_currentMember.freezeEnd!)}")
            : const Text("Sağlık, seyahat vb. durumlarda üyeliği geçici dondurabilirsiniz.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: TextButton(
          onPressed: () => isFrozen ? _unfreezeMemberDialog() : _showFreezeDialog(),
          child: Text(isFrozen ? "AKTİF ET" : "DONDUR",
              style: TextStyle(color: isFrozen ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
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
        content: const Text("Bu üyenin dondurulmuş hesabını tekrar aktif hale getirmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await context.read<UserViewModel>().unfreezeMember(int.parse(_currentMember.id));
              if (success && mounted) {
                Navigator.pop(context);
                final userVM = context.read<UserViewModel>();
                await userVM.fetchUsers(int.parse(_currentMember.gymId));
                setState(() {
                  _currentMember = userVM.users.firstWhere((u) => u.id == _currentMember.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dondurma işlemi iptal edildi, üyelik aktif.")));
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
    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: primaryColor.withOpacity(0.2),
            backgroundImage: imageProvider,
            child: imageProvider == null ? Icon(Icons.person, size: 50, color: primaryColor) : null,
          ),
          const SizedBox(height: 10),
          Text(_currentMember.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_currentMember.email, style: const TextStyle(color: Colors.grey)),
          Text(formatPhoneNumber(_currentMember.phone), style: const TextStyle(color: Colors.grey)),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Kredi Durumu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                  tooltip: "Kredileri Düzenle",
                  onPressed: () => _showEditCreditDialog(context, balance.totalCredits, balance.usedCredits),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
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

  void _showEditCreditDialog(BuildContext context, int currentTotal, int currentUsed) {
    final totalController = TextEditingController(text: currentTotal.toString());
    final usedController = TextEditingController(text: currentUsed.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kredi Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Toplam Alınan Kredi",
                prefixIcon: Icon(Icons.star_border_rounded, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Kullanılan Kredi",
                prefixIcon: Icon(Icons.timelapse_rounded, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              final newTotal = int.tryParse(totalController.text.trim());
              final newUsed = int.tryParse(usedController.text.trim());

              if (newTotal != null && newUsed != null) {
                if (newUsed > newTotal) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanılan kredi toplam krediden fazla olamaz.")));
                  return;
                }
                Navigator.pop(ctx);
                final success = await context.read<FinanceViewModel>().updateMemberCredit(
                  memberId: int.parse(_currentMember.id),
                  totalPurchased: newTotal,
                  totalUsed: newUsed,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kredi bilgileri güncellendi.")));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kredi güncellenemedi.")));
                }
              }
            },
            child: const Text("KAYDET"),
          ),
        ],
      ),
    );
  }

  void _showAddCreditDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController totalPaymentController = TextEditingController();
    final TextEditingController upfrontPaymentController = TextEditingController();
    final financeVM = context.read<FinanceViewModel>();

    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final double totalPay = double.tryParse(totalPaymentController.text.trim()) ?? 0.0;
          final double upfrontPay = upfrontPaymentController.text.trim().isEmpty
              ? totalPay
              : (double.tryParse(upfrontPaymentController.text.trim()) ?? totalPay);
          final double remainingPay = (totalPay - upfrontPay) > 0 ? (totalPay - upfrontPay) : 0.0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Kredi & Kısmi Ödeme Tanımla", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Yüklenecek Seans Kredi Sayısı",
                      hintText: "Örn: 10",
                      prefixIcon: Icon(Icons.star_rounded, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalPaymentController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: "Kredinin Toplam Ücreti (TL)",
                      hintText: "Örn: 10000",
                      prefixIcon: Icon(Icons.payments_rounded, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: upfrontPaymentController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: "Peşin Ödenen Kısım (TL)",
                      hintText: "Tamamı peşinse boş bırakın",
                      prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (remainingPay > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Kalan Borç Tutarı:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                          Text("₺${remainingPay.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.orange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Kalan Ödeme Son Tarihi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('dd MMMM yyyy', 'tr').format(selectedDueDate)),
                      trailing: const Icon(Icons.calendar_today_rounded, color: Colors.orange, size: 20),
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
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final amount = int.tryParse(amountController.text.trim());
                  final totalPayInput = double.tryParse(totalPaymentController.text.trim());
                  final upfrontInput = upfrontPaymentController.text.trim().isEmpty
                      ? (totalPayInput ?? 0.0)
                      : (double.tryParse(upfrontPaymentController.text.trim()) ?? (totalPayInput ?? 0.0));

                  if (amount != null && totalPayInput != null) {
                    final isFullPaid = upfrontInput >= totalPayInput;
                    final success = await financeVM.addCredit(
                      memberId: int.parse(_currentMember.id),
                      amount: amount,
                      paymentAmount: totalPayInput,
                      upfrontAmount: upfrontInput,
                      isPaid: isFullPaid,
                      dueDate: isFullPaid ? null : selectedDueDate,
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFullPaid
                              ? "$amount Kredi ve ₺${totalPayInput.toInt()} ödeme başarıyla alındı."
                              : "$amount Kredi eklendi. ₺${upfrontInput.toInt()} peşin alındı, kalan ₺${(totalPayInput - upfrontInput).toInt()} vadeli olarak kaydedildi.",
                          ),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen geçerli seans sayısı ve TL tutarı girin.")),
                    );
                  }
                },
                child: const Text("KAYDET"),
              ),
            ],
          );
        },
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
              final String status = booking.status.toUpperCase();
              final bool isCompleted = status == 'COMPLETED';
              final bool isCancelled = status == 'CANCELLED';
              final bool isNoShow = status == 'NO_SHOW';

              Color statusColor = Colors.orange;
              String displayStatus = booking.statusText;
              if (isCompleted) {
                statusColor = Colors.green;
                displayStatus = "Tamamlandı";
              } else if (isCancelled) {
                statusColor = Colors.grey;
                displayStatus = "İptal Edildi";
              } else if (isNoShow) {
                statusColor = Colors.redAccent;
                displayStatus = "Katılmadı";
              } else if (isPast) {
                statusColor = Colors.deepOrange;
                displayStatus = "Süresi Doldu";
              }

              return ListTile(
                onTap: isCompleted ? () => _showExerciseLogDialog(booking) : null,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child: Icon(
                    isNoShow ? Icons.event_busy_rounded : (isCompleted ? Icons.check_circle_rounded : Icons.fitness_center),
                    color: statusColor,
                    size: 18,
                  ),
                ),
                title: Text("${booking.trainerName} ile Ders", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(booking.startTime), style: const TextStyle(fontSize: 12)),
                    if (booking.performedExercises.isNotEmpty)
                      Text("${booking.performedExercises.length} egzersiz girildi", style: const TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isCancelled) ...[
                      IconButton(
                        icon: const Icon(Icons.replay_rounded, size: 20, color: Colors.purple),
                        tooltip: "Dersi İptal Et ve Kredi İade Et",
                        onPressed: () => _showCancelAndRefundDialog(
                          booking,
                          isNoShow: isNoShow,
                          isCompleted: isCompleted,
                        ),
                      ),
                      if (!isCompleted && !isNoShow) ...[
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 20, color: Colors.blue),
                          tooltip: "Eğitmeni Değiştir",
                          onPressed: () => _showChangeTrainerDialog(booking),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_calendar, size: 20, color: Colors.blueGrey),
                          onPressed: () => _showEditBookingDialog(booking),
                          tooltip: "Dersi Güncelle",
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showCancelAndRefundDialog(BookingDetails booking, {bool isNoShow = false, bool isCompleted = false}) {
    final calendarVM = context.read<CalendarViewModel>();
    final financeVM = context.read<FinanceViewModel>();
    final memberId = int.tryParse(_currentMember.id);

    String message = "Bu dersi iptal edip, üyeye 1 adet ders kredisini geri iade etmek istiyor musunuz?";
    if (isNoShow) {
      message = "Üye bu derse katılım sağlamamıştır. Dersi iptal edip, düşülen 1 seans kredisini üyenin hesabına geri iade etmek istiyor musunuz?";
    } else if (isCompleted) {
      message = "Bu tamamlanmış dersi iptal edip, üyenin 1 seans kredisini geri vermek ve eğitmenin hakedişini silmek istediğinize emin misiniz?";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.replay_circle_filled_rounded, color: Colors.purple),
            SizedBox(width: 8),
            Text("Ders İptali ve Kredi İadesi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await calendarVM.cancelAndRefundBooking(
                booking.id,
                memberId: memberId,
                cancelledById: context.read<LoginViewModel>().userData?['userId'],
                reason: "Üyenin katılamadığı ders yönetici tarafından iptal edildi ve kredi iade edildi.",
              );
              if (success && mounted) {
                if (memberId != null) {
                  await calendarVM.fetchMemberHistory(memberId);
                  await financeVM.fetchBalance(memberId);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ders iptal edildi ve 1 ders kredisi üyeye iade edildi.")),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(calendarVM.errorMessage ?? "İptal ve iade işlemi başarısız")),
                );
              }
            },
            child: const Text("EVET, İPTAL ET VE İADE ET"),
          ),
        ],
      ),
    );
  }

  void _showChangeTrainerDialog(BookingDetails booking) {
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
