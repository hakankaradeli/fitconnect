import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'views/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => TrainerQrViewModel()),
        ChangeNotifierProvider(create: (_) => MemberScannerViewModel()),
        ChangeNotifierProvider(create: (_) => SurveyViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
        ChangeNotifierProvider(create: (_) => AccrualViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => TrainerScheduleViewModel()),
        ChangeNotifierProvider(create: (_) => TrainerRateViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => DelegationViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),
        ChangeNotifierProvider(create: (_) => NutritionViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();

    return MaterialApp(
      title: themeVM.gymName,
      debugShowCheckedModeBanner: false,
      theme: themeVM.currentTheme,
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
    );
  }
}
