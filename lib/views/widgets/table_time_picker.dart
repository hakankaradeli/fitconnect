import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/theme_view_model.dart';

Future<TimeOfDay?> showTableTimePicker({
  required BuildContext context,
  TimeOfDay? initialTime,
  String title = "Saat Seçimi",
  Color? primaryColor,
  int? startHour,
  int? endHour,
  bool isLessonBooking = true,
}) async {
  final themeVM = context.read<ThemeViewModel>();
  final activeColor = primaryColor ?? themeVM.primaryColor;

  int gymOpenHour = 7;
  int gymCloseHour = 22;

  try {
    gymOpenHour = int.parse(themeVM.openTime.split(':')[0]);
  } catch (_) {}

  try {
    gymCloseHour = int.parse(themeVM.closeTime.split(':')[0]);
  } catch (_) {}

  final effectiveStart = startHour ?? gymOpenHour;
  final effectiveEnd = endHour ?? (isLessonBooking && gymCloseHour > gymOpenHour ? (gymCloseHour - 1) : gymCloseHour);

  final workingHoursText = "${themeVM.openTime} - ${themeVM.closeTime}";

  return showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) => TableTimePickerDialog(
      initialTime: initialTime ?? TimeOfDay(hour: effectiveStart, minute: 0),
      title: title,
      primaryColor: activeColor,
      startHour: effectiveStart,
      endHour: effectiveEnd,
      workingHoursText: workingHoursText,
    ),
  );
}

class TableTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;
  final Color primaryColor;
  final int startHour;
  final int endHour;
  final String workingHoursText;

  const TableTimePickerDialog({
    super.key,
    required this.initialTime,
    this.title = "Saat Seçimi",
    required this.primaryColor,
    required this.startHour,
    required this.endHour,
    required this.workingHoursText,
  });

  @override
  State<TableTimePickerDialog> createState() => _TableTimePickerDialogState();
}

class _TableTimePickerDialogState extends State<TableTimePickerDialog> {
  late int _selectedHour;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour.clamp(widget.startHour, widget.endHour);

    final totalHours = (widget.endHour - widget.startHour + 1).clamp(1, 24);
    final totalRows = (totalHours / 4).ceil();

    final initialOffset = totalRows <= 4
        ? 0.0
        : (((_selectedHour - widget.startHour) ~/ 4) * 46.0);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = (widget.endHour - widget.startHour + 1).clamp(1, 24);
    final hoursList = List.generate(totalHours, (i) => widget.startHour + i);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.table_chart_rounded, color: widget.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E282A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Salon Çalışma Saatleri: ${widget.workingHoursText}",
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    "${_selectedHour.toString().padLeft(2, '0')}:00",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: widget.primaryColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text(
                    "Müsait Saat Tablosu",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const Spacer(),
                  Text(
                    "Seçilen: ${_selectedHour.toString().padLeft(2, '0')}:00",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: hoursList.length,
                    itemBuilder: (context, index) {
                      final hour = hoursList[index];
                      final isSelected = _selectedHour == hour;
                      final hourStr = "${hour.toString().padLeft(2, '0')}:00";

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedHour = hour;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: isSelected ? widget.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? widget.primaryColor : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: widget.primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hourStr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("İptal", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final result = TimeOfDay(hour: _selectedHour, minute: 0);
                        Navigator.pop(context, result);
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text("SAATİ UYGULA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
