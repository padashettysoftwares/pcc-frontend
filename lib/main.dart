import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'providers/student_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/test_provider.dart';
import 'providers/fee_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/question_paper_provider.dart';
import 'providers/mcq_test_provider.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';
import 'services/notification_service.dart';

import 'services/api_service.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/parent/parent_shell.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await ApiService().init();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => FeeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => QuestionPaperProvider()),
        ChangeNotifierProvider(create: (_) => McqTestProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return MaterialApp(
            title: 'PCC Admin',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProv.mode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    if (api.role == 'super_admin' || api.role == 'teacher' || api.role == 'front_desk') {
      return AdminShell(role: api.role!, staffName: api.name ?? 'Admin');
    } else if (api.role == 'parent' && api.studentId != null) {
      return ParentShell(studentId: api.studentId!);
    } else {
      return const LoginScreen();
    }
  }
}
