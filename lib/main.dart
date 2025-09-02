import 'package:anket/services/firebase_options.dart';
import 'package:anket/utils/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'utils/app_router.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SurveyApp());
}

class SurveyApp extends StatelessWidget {
  const SurveyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            title: 'Survey App',
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: '/splash',
            theme: const CupertinoThemeData(
              primaryColor: AppColors.primaryColor,
              barBackgroundColor: AppColors.backgroundColor,
              scaffoldBackgroundColor: AppColors.backgroundColor,
              textTheme: CupertinoTextThemeData(
                textStyle: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
