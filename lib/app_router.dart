import 'package:anket/screens/admin/addsurvey_screen.dart';
import 'package:anket/screens/admin/resultslist_screen.dart';
import 'package:anket/screens/admin/survey_edit_screen.dart';
import 'package:anket/screens/group/creategroup_screen.dart';
import 'package:anket/screens/group/group_detail.dart';
import 'package:anket/screens/group/groupedit_screen.dart';
import 'package:anket/screens/group/grouplist_screen.dart';
import 'package:anket/screens/survey/survey_graph_screen.dart';
import 'package:anket/screens/survey/survey_unanswer_screen.dart';
import 'package:anket/screens/users_screen.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/survey/survey_list_screen.dart';
import 'screens/survey/survey_detail_screen.dart';
import 'screens/survey/thankyou_screen.dart';
import 'screens/admin/results_screen.dart';
import 'screens/profile_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/splash':
        page = const SplashScreen();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/register':
        page = RegisterScreen();
        break;
      case '/home':
        page = const HomeScreen();
        break;
      case '/surveys':
        page = const SurveyListScreen();
        break;
      case '/surveyAdd':
        page = const AddSurveyScreen();
      case '/surveyDetail':
        final args = settings.arguments as Map<String, dynamic>?;
        page = SurveyDetailScreen(surveyId: args?['surveyId'] ?? '');
        break;
      case '/thankyou':
        page = const ThankYouScreen();
        break;
      case '/results':
        final args = settings.arguments as Map<String, dynamic>?;
        page = ResultsScreen(surveyId: args?['surveyId'] ?? '');
        break;
      case '/profile':
        page = const ProfileScreen();
        break;
      case '/users':
        page = const UsersScreen();
        break;
      case '/resultList':
        page = const ResultsListScreen();
        break;
      case '/resultsScreen':
        final args = settings.arguments as Map<String, dynamic>?;
        page = ResultsScreen(surveyId: args?['surveyId'] ?? '');
        break;
      case '/groupList':
        page = const GroupListScreen();
        break;
      case '/createGroup':
        page = const CreateGroupScreen();
        break;
      case '/groupDetail':
        final args = settings.arguments as Map<String, dynamic>?;
        page = GroupDetailScreen(groupId: args?['groupId'] ?? '');
        break;
      case '/editGroup':
        final args = settings.arguments as Map<String, dynamic>?;
        page = EditGroupScreen(groupId: args?["groupId"] ?? '');
        break;
      case '/surveyUnanswer':
        final args = settings.arguments as Map<String, dynamic>?;
        page = SurveyUnanswerScreen(survey: args?['survey'] ?? '');
        break;
      case '/graph':
        page = const SurveyGraphScreen();
        break;
      case '/surveyEdit':
        final args = settings.arguments as Map<String, dynamic>?;
        page = SurveyEditScreen(surveyId: args?['surveyId'] ?? '');
        break;
      default:
        page = const SplashScreen();
        break;
    }

    return _slideRoute(page);
  }

  static PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // sağdan gelme
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
