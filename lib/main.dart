import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/gym_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/finance_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/nutrition_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/announcement_repository.dart';
import 'repositories/trainer_rate_repository.dart';
import 'repositories/delegation_repository.dart';
import 'repositories/super_admin_repository.dart';
import 'repositories/accrual_repository.dart';
import 'repositories/survey_repository.dart';
import 'view_models/login_view_model.dart';
import 'view_models/trainer_qr_view_model.dart';
import 'view_models/member_scanner_view_model.dart';
import 'view_models/survey_view_model.dart';
import 'view_models/theme_view_model.dart';
import 'view_models/calendar_view_model.dart';
import 'view_models/accrual_view_model.dart';
import 'view_models/user_view_model.dart';
import 'view_models/trainer_schedule_view_model.dart';
import 'view_models/trainer_rate_view_model.dart';
import 'view_models/notification_view_model.dart';
import 'view_models/report_view_model.dart';
import 'view_models/delegation_view_model.dart';
import 'view_models/finance_view_model.dart';
import 'view_models/expense_view_model.dart';
import 'view_models/announcement_view_model.dart';
import 'view_models/nutrition_view_model.dart';
import 'view_models/super_admin_view_model.dart';
import 'views/login_screen.dart';
import 'views/dashboard_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('tr', null);
    await initializeDateFormatting('tr_TR', null);
  } catch (e) {
    debugPrint("Locale initialization warning: $e");
  }

  final apiService = ApiService(customUrl: ApiService.defaultCustomUrl);
  final authRepository = AuthRepository(apiService: apiService);
  final userRepository = UserRepository(apiService: apiService);
  final bookingRepository = BookingRepository(apiService: apiService);
  final gymRepository = GymRepository(apiService: apiService);
  final reportRepository = ReportRepository(apiService: apiService);
  final financeRepository = FinanceRepository(apiService: apiService);
  final expenseRepository = ExpenseRepository(apiService: apiService);
  final nutritionRepository = NutritionRepository(apiService: apiService);
  final notificationRepository = NotificationRepository(apiService: apiService);
  final announcementRepository = AnnouncementRepository(apiService: apiService);
  final trainerRateRepository = TrainerRateRepository(apiService: apiService);
  final delegationRepository = DelegationRepository(apiService: apiService);
  final superAdminRepository = SuperAdminRepository(apiService: apiService);
  final accrualRepository = AccrualRepository(apiService: apiService);
  final surveyRepository = SurveyRepository(apiService: apiService);

  final loginViewModel = LoginViewModel(
    authRepository: authRepository,
  );
  final bool hasToken = await loginViewModel.loadToken();

  // Eğer token varsa, access token süresi dolmuş olabilir.
  // Refresh token ile otomatik yenilemeye çalış.
  bool tokenValid = hasToken;
  if (hasToken) {
    final refreshed = await loginViewModel.tryRefreshToken();
    if (!refreshed) {
      // Refresh başarısız — token'lar tamamen geçersiz, kullanıcı login ekranında kalsın
      tokenValid = false;
    }
  }

  final String? savedRole = loginViewModel.userRole;

  final homeWidget = tokenValid && savedRole != null
      ? DashboardRouter(role: savedRole)
      : const LoginScreen();

  final themeViewModel = ThemeViewModel(gymRepository: gymRepository);
  if (tokenValid && loginViewModel.userData != null) {
    final gymId = loginViewModel.userData!['gymId'];
    if (gymId != null) {
      final parsedGymId = int.tryParse(gymId.toString());
      if (parsedGymId != null) {
        themeViewModel.syncGymBranding(parsedGymId);
      }
    }
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),

        Provider<AuthRepository>.value(value: authRepository),
        Provider<UserRepository>.value(value: userRepository),
        Provider<BookingRepository>.value(value: bookingRepository),
        Provider<GymRepository>.value(value: gymRepository),
        Provider<ReportRepository>.value(value: reportRepository),
        Provider<FinanceRepository>.value(value: financeRepository),
        Provider<ExpenseRepository>.value(value: expenseRepository),
        Provider<NutritionRepository>.value(value: nutritionRepository),
        Provider<NotificationRepository>.value(value: notificationRepository),
        Provider<AnnouncementRepository>.value(value: announcementRepository),
        Provider<TrainerRateRepository>.value(value: trainerRateRepository),
        Provider<DelegationRepository>.value(value: delegationRepository),
        Provider<SuperAdminRepository>.value(value: superAdminRepository),
        Provider<AccrualRepository>.value(value: accrualRepository),
        Provider<SurveyRepository>.value(value: surveyRepository),

        ChangeNotifierProvider.value(value: loginViewModel),
        ChangeNotifierProvider(create: (ctx) => TrainerQrViewModel(bookingRepository: ctx.read<BookingRepository>())),
        ChangeNotifierProvider(create: (ctx) => MemberScannerViewModel(bookingRepository: ctx.read<BookingRepository>())),
        ChangeNotifierProvider(create: (ctx) => SurveyViewModel(repository: ctx.read<SurveyRepository>())),
        ChangeNotifierProvider.value(value: themeViewModel),
        ChangeNotifierProvider(create: (ctx) => CalendarViewModel(
          bookingRepository: ctx.read<BookingRepository>(),
          financeRepository: ctx.read<FinanceRepository>(),
        )),
        ChangeNotifierProvider(create: (ctx) => AccrualViewModel(repository: ctx.read<AccrualRepository>())),
        ChangeNotifierProvider(create: (ctx) => UserViewModel(userRepository: ctx.read<UserRepository>())),
        ChangeNotifierProvider(create: (ctx) => TrainerScheduleViewModel(bookingRepository: ctx.read<BookingRepository>())),
        ChangeNotifierProvider(create: (ctx) => TrainerRateViewModel(repository: ctx.read<TrainerRateRepository>())),
        ChangeNotifierProvider(create: (ctx) => NotificationViewModel(repository: ctx.read<NotificationRepository>())),
        ChangeNotifierProvider(create: (ctx) => ReportViewModel(repository: ctx.read<ReportRepository>())),
        ChangeNotifierProvider(create: (ctx) => DelegationViewModel(repository: ctx.read<DelegationRepository>())),
        ChangeNotifierProvider(create: (ctx) => FinanceViewModel(repository: ctx.read<FinanceRepository>())),
        ChangeNotifierProvider(create: (ctx) => ExpenseViewModel(repository: ctx.read<ExpenseRepository>())),
        ChangeNotifierProvider(create: (ctx) => AnnouncementViewModel(repository: ctx.read<AnnouncementRepository>())),
        ChangeNotifierProvider(create: (ctx) => NutritionViewModel(repository: ctx.read<NutritionRepository>())),
        ChangeNotifierProvider(create: (ctx) => SuperAdminViewModel(repository: ctx.read<SuperAdminRepository>())),
      ],
      child: MyApp(home: homeWidget),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();

    return MaterialApp(
      title: themeVM.gymName,
      debugShowCheckedModeBanner: false,
      theme: themeVM.currentTheme,
      themeMode: ThemeMode.light,
      home: home,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('tr'),
      ],
    );
  }
}
