import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../widgets/custom_back_button.dart';

enum SortOption {
  oldestFirst,
  newestFirst,
  nameAsc,
  nameDesc,
  birthDateAsc,
}

enum RoleFilter {
  all,
  member,
  trainer,
}

enum FreezeFilter {
  all,
  activeOnly,
  frozenOnly,
}

class UserRegistryReportScreen extends StatefulWidget {
  final bool isEmbeddedTab;

  const UserRegistryReportScreen({super.key, this.isEmbeddedTab = false});

  @override
  State<UserRegistryReportScreen> createState() => _UserRegistryReportScreenState();
}

class _UserRegistryReportScreenState extends State<UserRegistryReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final DateFormat _registrationDateFormat = DateFormat('dd/MM/yyyy - HH:mm');

  String _formatRegistrationDate(DateTime? date) {
    if (date == null) return "-";
    return _registrationDateFormat.format(date);
  }

  SortOption _selectedSort = SortOption.oldestFirst;
  RoleFilter _selectedRole = RoleFilter.all;
  FreezeFilter _selectedFreeze = FreezeFilter.all;
  String _searchQuery = '';
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null && userData['gymId'] != null) {
        final gymId = int.tryParse(userData['gymId'].toString()) ?? 0;
        if (gymId > 0) {
          context.read<UserViewModel>().fetchUsers(gymId);
        }
      }
    });
  }

  List<UserModel> _getFilteredAndSortedUsers(List<UserModel> sourceUsers) {
    var list = sourceUsers.where((u) => !u.isDeleted).toList();

    // 1. Role Filter
    if (_selectedRole == RoleFilter.member) {
      list = list.where((u) => u.role == 'MEMBER').toList();
    } else if (_selectedRole == RoleFilter.trainer) {
      list = list.where((u) => u.role == 'TRAINER').toList();
    }

    // 2. Freeze Filter
    if (_selectedFreeze == FreezeFilter.frozenOnly) {
      list = list.where((u) => u.isCurrentlyFrozen || u.isFrozen).toList();
    } else if (_selectedFreeze == FreezeFilter.activeOnly) {
      list = list.where((u) => !u.isCurrentlyFrozen && !u.isFrozen).toList();
    }

    // 3. Search Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((u) {
        final name = u.fullName.toLowerCase();
        final email = u.email.toLowerCase();
        final phone = (u.phone ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();
    }

    // 4. Sorting
    list.sort((a, b) {
      switch (_selectedSort) {
        case SortOption.oldestFirst:
          // En eski kayıttan en yeniye doğru (Salona kayıt tarihi veya ID sırası)
          final dateA = a.effectiveGymRegistrationDate;
          final dateB = b.effectiveGymRegistrationDate;
          if (dateA != null && dateB != null) {
            final cmp = dateA.compareTo(dateB);
            if (cmp != 0) return cmp;
          } else if (dateA != null) {
            return -1;
          } else if (dateB != null) {
            return 1;
          }
          final idA = int.tryParse(a.id) ?? 0;
          final idB = int.tryParse(b.id) ?? 0;
          return idA.compareTo(idB);

        case SortOption.newestFirst:
          // En yeni kayıttan en eskiye doğru (Salona kayıt tarihi)
          final dateA = a.effectiveGymRegistrationDate;
          final dateB = b.effectiveGymRegistrationDate;
          if (dateA != null && dateB != null) {
            final cmp = dateB.compareTo(dateA);
            if (cmp != 0) return cmp;
          } else if (dateA != null) {
            return -1;
          } else if (dateB != null) {
            return 1;
          }
          final idA = int.tryParse(a.id) ?? 0;
          final idB = int.tryParse(b.id) ?? 0;
          return idB.compareTo(idA);

        case SortOption.nameAsc:
          // Üye ad soyadına göre A-Z
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());

        case SortOption.nameDesc:
          // Üye ad soyadına göre Z-A
          return b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase());

        case SortOption.birthDateAsc:
          // Doğum gününe göre
          if (a.birthDate != null && b.birthDate != null) {
            return a.birthDate!.compareTo(b.birthDate!);
          } else if (a.birthDate != null) {
            return -1;
          } else if (b.birthDate != null) {
            return 1;
          }
          return a.fullName.compareTo(b.fullName);
      }
    });

    return list;
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool _isBirthdayThisMonth(DateTime? birthDate) {
    if (birthDate == null) return false;
    return birthDate.month == DateTime.now().month;
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label panoya kopyalandı: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _printReport(List<UserModel> users) async {
    setState(() => _isPrinting = true);
    try {
      final themeVM = context.read<ThemeViewModel>();
      final gymName = themeVM.gymName.isNotEmpty ? themeVM.gymName : "FitConnect Salonu";
      final now = DateTime.now();
      final reportDateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);

      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      final pdf = pw.Document();

      // Chunk users for clean multi-page tabular layout
      const int itemsPerPage = 16;
      final int totalPages = (users.isEmpty) ? 1 : ((users.length + itemsPerPage - 1) ~/ itemsPerPage);

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * itemsPerPage;
        final endIndex = (startIndex + itemsPerPage < users.length) ? (startIndex + itemsPerPage) : users.length;
        final pageUsers = users.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            gymName,
                            style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blueGrey800),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Üye & Eğitmen Kayıt ve Bilgi Raporu",
                            style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.indigo900),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Rapor Tarihi: $reportDateStr", style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                          pw.Text(
                            "Filtre: ${_getRoleFilterLabel()} | ${_getFreezeFilterLabel()} | Sıralama: ${_getSortLabel()}",
                            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700),
                          ),
                          pw.Text("Sayfa ${pageIndex + 1} / $totalPages", style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 6),

                  // Table
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      columnWidths: const {
                        0: pw.FixedColumnWidth(26),  // No
                        1: pw.FlexColumnWidth(2.3), // Ad Soyad
                        2: pw.FlexColumnWidth(1.1), // Rol
                        3: pw.FlexColumnWidth(1.6), // Telefon
                        4: pw.FlexColumnWidth(2.4), // E-posta
                        5: pw.FlexColumnWidth(1.5), // Doğum Günü
                        6: pw.FlexColumnWidth(1.5), // Salona Kayıt
                        7: pw.FlexColumnWidth(1.5), // Uygulama Kayıt
                        8: pw.FlexColumnWidth(2.1), // Durum / Dondurma
                      },
                      children: [
                        // Header Row
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _buildPdfHeaderCell("#", fontBold),
                            _buildPdfHeaderCell("Ad Soyad", fontBold),
                            _buildPdfHeaderCell("Rol", fontBold),
                            _buildPdfHeaderCell("Telefon", fontBold),
                            _buildPdfHeaderCell("E-posta", fontBold),
                            _buildPdfHeaderCell("Doğum Günü", fontBold),
                            _buildPdfHeaderCell("Salona Kayıt", fontBold),
                            _buildPdfHeaderCell("Uygulama Kayıt", fontBold),
                            _buildPdfHeaderCell("Durum / Dondurma", fontBold),
                          ],
                        ),
                        // Data Rows
                        ...pageUsers.asMap().entries.map((entry) {
                          final idx = startIndex + entry.key + 1;
                          final u = entry.value;

                          final isFrozen = u.isCurrentlyFrozen || u.isFrozen;
                          String statusStr = "Aktif";
                          if (isFrozen) {
                            final start = u.freezeStart != null ? _dateFormat.format(u.freezeStart!) : '';
                            final end = u.freezeEnd != null ? _dateFormat.format(u.freezeEnd!) : '';
                            statusStr = "Donduruldu ($start - $end)";
                            if (u.freezeReason != null && u.freezeReason!.isNotEmpty) {
                              statusStr += "\nSebep: ${u.freezeReason}";
                            }
                          } else if (!u.isActive) {
                            statusStr = "Pasif";
                          }

                          final bdayStr = u.birthDate != null
                              ? "${_dateFormat.format(u.birthDate!)} (${_calculateAge(u.birthDate!)} yaş)"
                              : "-";

                          final gymRegDate = u.effectiveGymRegistrationDate;
                          final appRegDate = u.effectiveAppRegistrationDate;

                          final gymRegStr = gymRegDate != null
                              ? _registrationDateFormat.format(gymRegDate)
                              : "-";

                          final appRegStr = appRegDate != null
                              ? _registrationDateFormat.format(appRegDate)
                              : "-";

                          final roleStr = u.role == 'TRAINER'
                              ? "Eğitmen"
                              : (u.role == 'ADMIN' ? "Yönetici" : "Üye");

                          final isEven = entry.key % 2 == 0;

                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: isFrozen ? PdfColors.amber50 : (isEven ? PdfColors.white : PdfColors.grey50),
                            ),
                            children: [
                              _buildPdfDataCell(idx.toString(), fontRegular, alignCenter: true),
                              _buildPdfDataCell(u.fullName, fontBold),
                              _buildPdfDataCell(roleStr, fontRegular),
                              _buildPdfDataCell(u.phone ?? "-", fontRegular),
                              _buildPdfDataCell(u.email, fontRegular),
                              _buildPdfDataCell(bdayStr, fontRegular),
                              _buildPdfDataCell(gymRegStr, fontRegular),
                              _buildPdfDataCell(appRegStr, fontRegular),
                              _buildPdfDataCell(
                                statusStr,
                                isFrozen ? fontBold : fontRegular,
                                textColor: isFrozen ? PdfColors.orange900 : (u.isActive ? PdfColors.green900 : PdfColors.red900),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Toplam ${users.length} kişi listelendi (Bu sayfada: ${pageUsers.length})",
                        style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        "FitConnect ERP & Raporlama Modülü",
                        style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'FitConnect_Uye_Egitmen_Raporu_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yazdırma hatası: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  pw.Widget _buildPdfHeaderCell(String text, pw.Font font, {bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.black),
      ),
    );
  }

  pw.Widget _buildPdfDataCell(String text, pw.Font font, {bool alignCenter = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(font: font, fontSize: 8.5, color: textColor ?? PdfColors.black),
      ),
    );
  }

  String _getRoleFilterLabel() {
    switch (_selectedRole) {
      case RoleFilter.member:
        return "Sadece Üyeler";
      case RoleFilter.trainer:
        return "Sadece Eğitmenler";
      case RoleFilter.all:
        return "Tüm Roller";
    }
  }

  String _getFreezeFilterLabel() {
    switch (_selectedFreeze) {
      case FreezeFilter.frozenOnly:
        return "Dondurulanlar";
      case FreezeFilter.activeOnly:
        return "Aktifler";
      case FreezeFilter.all:
        return "Tüm Durumlar";
    }
  }

  String _getSortLabel() {
    switch (_selectedSort) {
      case SortOption.oldestFirst:
        return "Kayıt: En Eski ➔ En Yeni";
      case SortOption.newestFirst:
        return "Kayıt: En Yeni ➔ En Eski";
      case SortOption.nameAsc:
        return "Ad Soyad: A ➔ Z";
      case SortOption.nameDesc:
        return "Ad Soyad: Z ➔ A";
      case SortOption.birthDateAsc:
        return "Doğum Tarihi";
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final allUsers = userVM.users;
    final filteredUsers = _getFilteredAndSortedUsers(allUsers);

    final content = userVM.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (widget.isEmbeddedTab)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Üye & Eğitmen Kayıt Listesi",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isPrinting || filteredUsers.isEmpty ? null : () => _printReport(filteredUsers),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isPrinting
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.print_rounded, size: 16),
                        label: const Text("Yazdır / PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              // Statistics Top Bar
              _buildKpiSummaryBar(allUsers),

              // Filter & Search Header
              _buildFilterControlBar(filteredUsers),

              // List of Users
              Expanded(
                child: filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserRegistryCard(user, index + 1);
                        },
                      ),
              ),
            ],
          );

    if (widget.isEmbeddedTab) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Üye & Eğitmen Raporu",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            tooltip: "Yenile",
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _loadUsers,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isPrinting || filteredUsers.isEmpty ? null : () => _printReport(filteredUsers),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isPrinting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_rounded, size: 18),
              label: const Text("Yazdır / PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildKpiSummaryBar(List<UserModel> allUsers) {
    final activeUsers = allUsers.where((u) => !u.isDeleted).toList();
    final memberCount = activeUsers.where((u) => u.role == 'MEMBER').length;
    final trainerCount = activeUsers.where((u) => u.role == 'TRAINER').length;
    final frozenCount = activeUsers.where((u) => u.isCurrentlyFrozen || u.isFrozen).length;
    final bdayThisMonth = activeUsers.where((u) => _isBirthdayThisMonth(u.birthDate)).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          return Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceAround,
            children: [
              _buildMiniKpi(Icons.people_alt_rounded, "Toplam Kayıt", "${activeUsers.length}", Colors.blueGrey, isSmall),
              _buildMiniKpi(Icons.person_rounded, "Üyeler", "$memberCount", Colors.indigo, isSmall),
              _buildMiniKpi(Icons.fitness_center_rounded, "Eğitmenler", "$trainerCount", Colors.teal, isSmall),
              _buildMiniKpi(Icons.ac_unit_rounded, "Dondurulmuş", "$frozenCount", Colors.amber.shade800, isSmall),
              _buildMiniKpi(Icons.cake_rounded, "Bu Ay Doğanlar", "$bdayThisMonth", Colors.pinkAccent, isSmall),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniKpi(IconData icon, String label, String value, Color color, bool isSmall) {
    return Container(
      constraints: BoxConstraints(minWidth: isSmall ? 100 : 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControlBar(List<UserModel> filteredUsers) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Box & Sort Dropdown Row
          Row(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "İsim, e-posta veya telefon ile ara...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 10),

              // Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SortOption>(
                    value: _selectedSort,
                    icon: const Icon(Icons.sort_rounded, size: 18, color: Colors.indigo),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    items: const [
                      DropdownMenuItem(
                        value: SortOption.oldestFirst,
                        child: Text("Kayıt: En Eski ➔ En Yeni (Öneri)"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.newestFirst,
                        child: Text("Kayıt: En Yeni ➔ En Eski"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.nameAsc,
                        child: Text("Ad Soyad: A ➔ Z"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.nameDesc,
                        child: Text("Ad Soyad: Z ➔ A"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.birthDateAsc,
                        child: Text("Doğum Tarihi"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSort = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter Chips (Role & Freeze)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Role Filters
                _buildFilterChip("Tüm Roller", _selectedRole == RoleFilter.all, () {
                  setState(() => _selectedRole = RoleFilter.all);
                }),
                const SizedBox(width: 6),
                _buildFilterChip("Sadece Üyeler", _selectedRole == RoleFilter.member, () {
                  setState(() => _selectedRole = RoleFilter.member);
                }),
                const SizedBox(width: 6),
                _buildFilterChip("Sadece Eğitmenler", _selectedRole == RoleFilter.trainer, () {
                  setState(() => _selectedRole = RoleFilter.trainer);
                }),
                const SizedBox(width: 12),
                Container(height: 20, width: 1, color: Colors.grey.shade300),
                const SizedBox(width: 12),

                // Freeze Filters
                _buildFilterChip("Tüm Durumlar", _selectedFreeze == FreezeFilter.all, () {
                  setState(() => _selectedFreeze = FreezeFilter.all);
                }),
                const SizedBox(width: 6),
                _buildFilterChip("Aktifler", _selectedFreeze == FreezeFilter.activeOnly, () {
                  setState(() => _selectedFreeze = FreezeFilter.activeOnly);
                }),
                const SizedBox(width: 6),
                _buildFilterChip("❄️ Dondurulanlar", _selectedFreeze == FreezeFilter.frozenOnly, () {
                  setState(() => _selectedFreeze = FreezeFilter.frozenOnly);
                }, activeColor: Colors.amber.shade800),

                const SizedBox(width: 12),
                Text(
                  "(${filteredUsers.length} kişi)",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final effectiveActiveColor = activeColor ?? Colors.indigo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? effectiveActiveColor : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveActiveColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildUserRegistryCard(UserModel user, int indexNumber) {
    final isTrainer = user.role == 'TRAINER';
    final isAdmin = user.role == 'ADMIN' || user.role == 'SUPER_ADMIN';
    final isFrozen = user.isCurrentlyFrozen || user.isFrozen;
    final isBdayThisMonth = _isBirthdayThisMonth(user.birthDate);

    final roleColor = isTrainer
        ? Colors.teal
        : (isAdmin ? Colors.deepPurple : Colors.indigo);
    final roleText = isTrainer
        ? "Eğitmen"
        : (isAdmin ? "Yönetici" : "Üye");

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFrozen ? Colors.amber.shade300 : Colors.grey.shade200,
          width: isFrozen ? 1.5 : 1,
        ),
      ),
      color: isFrozen ? const Color(0xFFFFFDF5) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Number, Avatar, Name, Role badge, Freeze Badge
            Row(
              children: [
                // Sequence Number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "$indexNumber",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 10),

                // Initials / Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : "?",
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBdayThisMonth) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: "Bu ay doğum günü!",
                              child: Icon(Icons.cake_rounded, size: 16, color: Colors.pinkAccent),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleText,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Active/Freeze Badge
                          if (isFrozen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.ac_unit_rounded, size: 11, color: Colors.amber.shade900),
                                  const SizedBox(width: 2),
                                  Text(
                                    "Dondurulmuş",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            )
                          else if (!user.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Pasif",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Details Grid
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // 1. Phone
                _buildInfoTile(
                  icon: Icons.phone_rounded,
                  label: "Telefon",
                  value: user.phone != null && user.phone!.isNotEmpty ? user.phone! : "-",
                  color: Colors.green.shade700,
                  onTap: user.phone != null && user.phone!.isNotEmpty ? () => _makePhoneCall(user.phone!) : null,
                  onLongPress: user.phone != null && user.phone!.isNotEmpty ? () => _copyToClipboard(user.phone!, "Telefon") : null,
                ),

                // 2. Email
                _buildInfoTile(
                  icon: Icons.email_rounded,
                  label: "E-posta",
                  value: user.email,
                  color: Colors.blue.shade700,
                  onTap: () => _sendEmail(user.email),
                  onLongPress: () => _copyToClipboard(user.email, "E-posta"),
                ),

                // 3. Birth Date
                _buildInfoTile(
                  icon: Icons.cake_outlined,
                  label: "Doğum Günü",
                  value: user.birthDate != null
                      ? "${_dateFormat.format(user.birthDate!)} (${_calculateAge(user.birthDate!)} yaş)"
                      : "Belirtilmemiş",
                  color: Colors.purple.shade700,
                  badge: isBdayThisMonth ? "Bu Ay" : null,
                  badgeColor: Colors.pinkAccent,
                ),

                // 4. Salona Kayıt Tarihi
                _buildInfoTile(
                  icon: Icons.fitness_center_rounded,
                  label: "Salona Kayıt Tarihi",
                  value: _formatRegistrationDate(user.effectiveGymRegistrationDate),
                  color: Colors.indigo.shade700,
                ),

                // 5. Uygulamaya Kayıt Tarihi
                _buildInfoTile(
                  icon: Icons.app_registration_rounded,
                  label: "Uygulamaya Kayıt",
                  value: _formatRegistrationDate(user.effectiveAppRegistrationDate),
                  color: Colors.teal.shade700,
                ),
              ],
            ),

            // Freeze Details (If frozen)
            if (isFrozen) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Dondurma: ${user.freezeStart != null ? _dateFormat.format(user.freezeStart!) : '-'} ➔ ${user.freezeEnd != null ? _dateFormat.format(user.freezeEnd!) : '-'}"
                        "${user.freezeReason != null && user.freezeReason!.isNotEmpty ? ' (${user.freezeReason})' : ''}",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    String? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              "$label: ",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: onTap != null ? color : Colors.black87,
                decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.blue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor ?? Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              "Filtreye uygun kayıt bulunamadı",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              "Arama kriterlerini veya filtreleri değiştirerek tekrar deneyebilirsiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
