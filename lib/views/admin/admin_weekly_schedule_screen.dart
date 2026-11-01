import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../view_models/trainer_schedule_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../view_models/calendar_view_model.dart';
import '../../models/booking_details_model.dart';
import '../../models/user_model.dart';
import '../widgets/table_time_picker.dart';
import '../widgets/custom_back_button.dart';

class AdminWeeklyScheduleScreen extends StatefulWidget {
  const AdminWeeklyScheduleScreen({super.key});

  @override
  State<AdminWeeklyScheduleScreen> createState() => _AdminWeeklyScheduleScreenState();
}

class _AdminWeeklyScheduleScreenState extends State<AdminWeeklyScheduleScreen> with SingleTickerProviderStateMixin {
  late DateTime _currentWeekMonday;
  late int _selectedDayIndex;
  int? _selectedTrainerId;
  String _selectedStatus = "ALL";
  String _searchQuery = "";
  String _viewMode = "Timeline";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);

    _currentWeekMonday = todayNormalized.subtract(Duration(days: todayNormalized.weekday - 1));
    _selectedDayIndex = (todayNormalized.weekday - 1).clamp(0, 6);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final userData = context.read<LoginViewModel>().userData;
    final gymId = userData?['gymId'];
    if (gymId != null && gymId > 0) {
      final weekStart = _currentWeekMonday;
      final weekEnd = _currentWeekMonday.add(const Duration(days: 7, seconds: -1));

      context.read<UserViewModel>().fetchUsers(gymId);
      context.read<TrainerScheduleViewModel>().fetchGymSchedule(gymId, weekStart, weekEnd);
    }
  }

  void _changeWeek(int deltaWeeks) {
    setState(() {
      _currentWeekMonday = _currentWeekMonday.add(Duration(days: deltaWeeks * 7));
    });
    _loadData();
  }

  void _goToCurrentWeek() {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    setState(() {
      _currentWeekMonday = todayNormalized.subtract(Duration(days: todayNormalized.weekday - 1));
      _selectedDayIndex = (todayNormalized.weekday - 1).clamp(0, 6);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVM = context.watch<TrainerScheduleViewModel>();
    final userVM = context.watch<UserViewModel>();
    final themeVM = context.watch<ThemeViewModel>();

    final trainers = userVM.users.where((u) {
      return u.role == 'TRAINER' || (u.canTeach != null && u.canTeach!.isNotEmpty);
    }).toList();

    final allBookings = scheduleVM.gymWeeklyBookings;
    final filteredBookings = allBookings.where((b) {
      if (_selectedTrainerId != null && b.trainerId != null && b.trainerId != _selectedTrainerId) {
        return false;
      }

      if (_selectedStatus != "ALL") {
        if (_selectedStatus == "ACTIVE" && b.status.toUpperCase() != "ACTIVE") return false;
        if (_selectedStatus == "COMPLETED" && b.status.toUpperCase() != "COMPLETED") return false;
        if (_selectedStatus == "PENDING" && !b.status.toUpperCase().contains("PENDING") && b.status.toUpperCase() != "PROPOSED") return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesMember = b.memberName.toLowerCase().contains(query);
        final matchesTrainer = b.trainerName.toLowerCase().contains(query);
        if (!matchesMember && !matchesTrainer) return false;
      }
      return true;
    }).toList();

    final primary = themeVM.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Haftalık Program",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: const CustomBackButton(),
        actions: [
          TextButton.icon(
            onPressed: _goToCurrentWeek,
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text("Bu Hafta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Yenile",
            onPressed: _loadData,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: scheduleVM.isLoading && allBookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _loadData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildWeekHeader(primary),
                        const SizedBox(height: 12),
                        _buildKpiSummaryBar(allBookings, primary),
                        const SizedBox(height: 14),

                        _buildFilterAndModeBar(trainers, allBookings, primary),
                        const SizedBox(height: 12),

                        _buildSearchBar(),
                        const SizedBox(height: 14),

                        if (_viewMode == "Timeline")
                          _buildTimelineView(filteredBookings, themeVM, primary)
                        else
                          _buildMatrixView(filteredBookings, trainers, primary),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWeekHeader(Color primary) {
    final weekEnd = _currentWeekMonday.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            onPressed: () => _changeWeek(-1),
            tooltip: "Önceki Hafta",
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _currentWeekMonday,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                  locale: const Locale('tr', 'TR'),
                );
                if (picked != null) {
                  final normalized = DateTime(picked.year, picked.month, picked.day);
                  setState(() {
                    _currentWeekMonday = normalized.subtract(Duration(days: normalized.weekday - 1));
                  });
                  _loadData();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month_rounded, color: primary, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "${DateFormat('d MMMM', 'tr_TR').format(_currentWeekMonday)} - ${DateFormat('d MMMM yyyy', 'tr_TR').format(weekEnd)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onPressed: () => _changeWeek(1),
            tooltip: "Sonraki Hafta",
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSummaryBar(List<BookingDetails> bookings, Color primary) {
    final int total = bookings.length;
    final int active = bookings.where((b) => b.status.toUpperCase() == 'ACTIVE').length;
    final int completed = bookings.where((b) => b.status.toUpperCase() == 'COMPLETED').length;
    final int pending = bookings.where((b) => b.status.toUpperCase().contains('PENDING') || b.status.toUpperCase() == 'PROPOSED').length;

    return Row(
      children: [
        Expanded(child: _buildKpiCard("Toplam", "$total Ders", Colors.blueGrey, Icons.event_note_rounded)),
        const SizedBox(width: 6),
        Expanded(child: _buildKpiCard("Aktif", "$active Ders", Colors.teal, Icons.check_circle_outline_rounded)),
        const SizedBox(width: 6),
        Expanded(child: _buildKpiCard("Biten", "$completed Ders", Colors.indigo, Icons.task_alt_rounded)),
        const SizedBox(width: 6),
        Expanded(child: _buildKpiCard("Bekleyen", "$pending", Colors.orange, Icons.hourglass_top_rounded)),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndModeBar(List<UserModel> trainers, List<BookingDetails> allBookings, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                "Eğitmen Filtresi",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  _buildViewModeButton("Timeline", Icons.view_day_rounded, "Günlük Akış"),
                  _buildViewModeButton("Matrix", Icons.grid_view_rounded, "Haftalık Tablo"),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ChoiceChip(
                label: Text("Tümü (${allBookings.length})"),
                selected: _selectedTrainerId == null,
                selectedColor: primary.withValues(alpha: 0.18),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _selectedTrainerId == null ? primary : Colors.black87,
                ),
                onSelected: (val) {
                  setState(() => _selectedTrainerId = null);
                },
              ),
              const SizedBox(width: 8),
              ...trainers.map((t) {
                final trainerId = int.tryParse(t.id);
                final trainerLessonCount = allBookings.where((b) => b.trainerId == trainerId).length;
                final isSelected = _selectedTrainerId == trainerId;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: isSelected ? primary : Colors.grey.shade300,
                      radius: 11,
                      child: Text(
                        t.fullName.isNotEmpty ? t.fullName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    label: Text("${t.fullName} ($trainerLessonCount)"),
                    selected: isSelected,
                    selectedColor: primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                      color: isSelected ? primary : Colors.black87,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedTrainerId = val ? trainerId : null;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeButton(String mode, IconData icon, String label) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _viewMode = mode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.black87 : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Üye veya Eğitmen ara...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
              items: const [
                DropdownMenuItem(value: "ALL", child: Text("Tüm Durumlar")),
                DropdownMenuItem(value: "ACTIVE", child: Text("Sadece Aktif")),
                DropdownMenuItem(value: "COMPLETED", child: Text("Tamamlanan")),
                DropdownMenuItem(value: "PENDING", child: Text("Onay Bekleyen")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineView(List<BookingDetails> bookings, ThemeViewModel themeVM, Color primary) {
    final selectedDate = _currentWeekMonday.add(Duration(days: _selectedDayIndex));

    final dayBookings = bookings.where((b) {
      return b.startTime.year == selectedDate.year &&
          b.startTime.month == selectedDate.month &&
          b.startTime.day == selectedDate.day;
    }).toList();

    final openHour = int.tryParse(themeVM.openTime.split(':')[0]) ?? 7;
    final closeHour = int.tryParse(themeVM.closeTime.split(':')[0]) ?? 22;
    final totalHours = (closeHour - openHour).clamp(1, 24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDaySelectorTabs(bookings, primary),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Text(
                "${DateFormat('EEEE, d MMMM yyyy', 'tr_TR').format(selectedDate)} Programı",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E282A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: dayBookings.isNotEmpty ? primary.withValues(alpha: 0.12) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${dayBookings.length} Ders",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: dayBookings.isNotEmpty ? primary : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalHours,
          itemBuilder: (context, index) {
            final hour = openHour + index;
            final hourBookings = dayBookings.where((b) => b.startTime.hour == hour).toList();
            return _buildHourSlotRow(hour, hourBookings, primary);
          },
        ),
      ],
    );
  }

  Widget _buildDaySelectorTabs(List<BookingDetails> allWeekBookings, Color primary) {
    final weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
    final now = DateTime.now();

    return Row(
      children: List.generate(7, (i) {
        final dayDate = _currentWeekMonday.add(Duration(days: i));
        final isSelected = _selectedDayIndex == i;
        final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;

        final count = allWeekBookings.where((b) =>
            b.startTime.year == dayDate.year &&
            b.startTime.month == dayDate.month &&
            b.startTime.day == dayDate.day).length;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
            child: InkWell(
              onTap: () {
                setState(() => _selectedDayIndex = i);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : (isToday ? primary.withValues(alpha: 0.5) : Colors.grey.shade200),
                    width: isToday && !isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      weekdays[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${dayDate.day}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (count > 0 ? primary.withValues(alpha: 0.12) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (count > 0 ? primary : Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHourSlotRow(int hour, List<BookingDetails> bookings, Color primary) {
    final hourLabel = "${hour.toString().padLeft(2, '0')}:00";

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              hourLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: bookings.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: bookings.isEmpty
                ? Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Müsait / Ders Yok",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                    ),
                  )
                : Column(
                    children: bookings.map((b) => _buildLessonItemCard(b, primary)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItemCard(BookingDetails booking, Color primary) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = booking.statusText;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showBookingDetailsSheet(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    booking.trainerName.isNotEmpty ? booking.trainerName[0].toUpperCase() : 'E',
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            booking.trainerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            "Üye: ${booking.memberName}",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixView(List<BookingDetails> bookings, List<UserModel> trainers, Color primary) {
    final weekdays = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];

    final activeTrainers = trainers.where((t) {
      if (_selectedTrainerId != null) {
        return int.tryParse(t.id) == _selectedTrainerId;
      }
      return true;
    }).toList();

    if (activeTrainers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text("Görüntülenecek eğitmen bulunamadı.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 850),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              dataRowMinHeight: 70,
              dataRowMaxHeight: 120,
              horizontalMargin: 12,
              columnSpacing: 14,
              columns: [
                const DataColumn(
                  label: Text("Eğitmen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                ...List.generate(7, (i) {
                  final dayDate = _currentWeekMonday.add(Duration(days: i));
                  return DataColumn(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weekdays[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("${dayDate.day} ${DateFormat('MMM', 'tr_TR').format(dayDate)}",
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  );
                }),
              ],
              rows: activeTrainers.map((t) {
                final trainerId = int.tryParse(t.id);

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: primary.withValues(alpha: 0.15),
                            child: Text(
                              t.fullName.isNotEmpty ? t.fullName[0].toUpperCase() : '?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              t.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    ...List.generate(7, (dayIdx) {
                      final dayDate = _currentWeekMonday.add(Duration(days: dayIdx));
                      final dayTrainerBookings = bookings.where((b) {
                        return b.trainerId == trainerId &&
                            b.startTime.year == dayDate.year &&
                            b.startTime.month == dayDate.month &&
                            b.startTime.day == dayDate.day;
                      }).toList();

                      if (dayTrainerBookings.isEmpty) {
                        return const DataCell(
                          Center(
                            child: Text("-", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ),
                        );
                      }

                      return DataCell(
                        SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: dayTrainerBookings.map((b) {
                              final statusColor = _getStatusColor(b.status);
                              final hourStr = DateFormat('HH:mm').format(b.startTime);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: InkWell(
                                  onTap: () => _showBookingDetailsSheet(b),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          hourStr,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 65),
                                          child: Text(
                                            b.memberName,
                                            style: const TextStyle(fontSize: 10, color: Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingDetailsSheet(BookingDetails booking) {
    final statusColor = _getStatusColor(booking.status);
    final themeVM = context.read<ThemeViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Row(
              children: [
                const Icon(Icons.event_available_rounded, color: Colors.indigo, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Rezervasyon Detayı",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _buildDetailRow(
              Icons.schedule_rounded,
              "Tarih & Saat",
              "${DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(booking.startTime)}  ${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}",
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              Icons.engineering_rounded,
              "Eğitmen",
              booking.trainerName,
              actionWidget: booking.trainerPhone != null && booking.trainerPhone!.isNotEmpty
                  ? _buildContactButtons(booking.trainerPhone!)
                  : null,
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              Icons.person_rounded,
              "Üye",
              booking.memberName,
              actionWidget: booking.memberPhone != null && booking.memberPhone!.isNotEmpty
                  ? _buildContactButtons(booking.memberPhone!)
                  : null,
            ),

            if (booking.performedExercises.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text("İşlenen Egzersizler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: booking.performedExercises.map((e) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.exerciseName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        Text("${e.sets ?? 0} set x ${e.reps ?? 0} tekrar", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.orange),
                      foregroundColor: Colors.orange.shade800,
                    ),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: const Text("Saati Değiştir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      _showRescheduleDialog(booking, themeVM);
                    },
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text("Dersi İptal Et", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      _showCancelDialog(booking);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Widget? actionWidget}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
        if (actionWidget != null) actionWidget,
      ],
    );
  }

  Widget _buildContactButtons(String phone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
          tooltip: "Ara",
          onPressed: () async {
            final uri = Uri.parse("tel:$phone");
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.teal, size: 20),
          tooltip: "WhatsApp",
          onPressed: () async {
            final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
            final uri = Uri.parse("https://wa.me/$cleanPhone");
            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ],
    );
  }

  void _showRescheduleDialog(BookingDetails booking, ThemeViewModel themeVM) async {
    final openHour = int.tryParse(themeVM.openTime.split(':')[0]) ?? 7;
    final closeHour = int.tryParse(themeVM.closeTime.split(':')[0]) ?? 22;

    DateTime selectedDate = booking.startTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(booking.startTime);

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Ders Saati Değiştir", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded, color: Colors.blue),
                title: const Text("Tarih", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  DateFormat('d MMMM yyyy', 'tr_TR').format(selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogCtx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    locale: const Locale('tr', 'TR'),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = DateTime(picked.year, picked.month, picked.day, selectedTime.hour, 0);
                    });
                  }
                },
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart_rounded, color: Colors.orange),
                title: const Text("Ders Saati (Çalışma Saatleri Tablosu)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  "${selectedTime.hour.toString().padLeft(2, '0')}:00",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                ),
                trailing: const Icon(Icons.access_time_rounded, color: Colors.orange),
                onTap: () async {
                  final time = await showTableTimePicker(
                    context: dialogCtx,
                    initialTime: selectedTime,
                    title: "Ders Saati Seçimi",
                    startHour: openHour,
                    endHour: closeHour > openHour ? (closeHour - 1) : closeHour,
                    isLessonBooking: true,
                  );
                  if (time != null) {
                    setDialogState(() {
                      selectedTime = TimeOfDay(hour: time.hour, minute: 0);
                      selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, time.hour, 0);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final success = await context.read<CalendarViewModel>().proposeBookingChange(booking.id, selectedDate);
                if (success && mounted) {
                  Navigator.pop(dialogCtx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ders saati değişikliği başarıyla iletildi.")),
                  );
                }
              },
              child: const Text("ONAYLA & GÖNDER"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BookingDetails booking) {
    final userData = context.read<LoginViewModel>().userData;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Dersi İptal Et", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          "${booking.memberName} ile ${booking.trainerName} arasındaki ${DateFormat('d MMMM HH:mm').format(booking.startTime)} dersini iptal etmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await context.read<CalendarViewModel>().rejectBooking(
                    booking.id,
                    cancelledById: userData?['userId'],
                    reason: "Yönetici tarafından haftalık takvimden iptal edildi",
                  );
              if (success && mounted) {
                Navigator.pop(dialogCtx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ders iptal edildi.")),
                );
              }
            },
            child: const Text("İPTALİ ONAYLA"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.teal;
      case 'COMPLETED':
        return Colors.indigo;
      case 'PENDING':
      case 'PENDING_ADMIN_APPROVAL':
      case 'PROPOSED':
        return Colors.orange;
      case 'CANCELLED':
      case 'NO_SHOW':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
