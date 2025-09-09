import 'package:anket/screens/accountEdits/mail_change_screen.dart';
import 'package:anket/screens/accountEdits/password_change_screen.dart';
import 'package:anket/screens/accountEdits/user_info_change_screen.dart';
import 'package:anket/screens/admin/department_management_screen.dart';
import 'package:anket/screens/admin/survey/addsurvey_screen.dart';
import 'package:anket/screens/admin/survey/respondents_list_screen.dart';
import 'package:anket/screens/admin/survey/survey_edit_screen.dart';
import 'package:anket/screens/admin/group/creategroup_screen.dart';
import 'package:anket/screens/admin/group/group_detail.dart';
import 'package:anket/screens/admin/group/groupedit_screen.dart';
import 'package:anket/screens/admin/group/grouplist_screen.dart';
import 'package:anket/screens/admin/survey/survey_results_screen.dart';
import 'package:anket/screens/admin/survey/target_audience_selection_screen.dart';
import 'package:anket/screens/admin/survey/target_update_screen.dart';
import 'package:anket/screens/admin/survey/user_responses_screen.dart';
import 'package:anket/screens/admin/unanswers_list_screen.dart';
import 'package:anket/screens/auth/first_page.dart';
import 'package:anket/screens/auth/register_screen.dart';
import 'package:anket/screens/notifications_Screen.dart';
import 'package:flutter/cupertino.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/survey/surveys_list.dart';
import '../screens/survey/survey_questions_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/splash':
        page = const SplashScreen();
        break;
      case '/firstPage':
        page = const FirstPage();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/register':
        page = const RegisterScreen();
        break;
      case '/home':
        page = const HomeScreen();
        break;
      case '/notifications':
        page = const NotificationsScreen();
        break;
      case '/surveys':
        final args = settings.arguments as Map<String, dynamic>?;
        page = SurveysList(pageName: args?['pageName'] ?? '');
        break;
      case '/surveyAdd':
        page = const AddSurveyScreen();
        break;
      case '/audienceScreen':
        final args = settings.arguments as Map<String, dynamic>?;
        page = AudienceScreen(
          surveyTitle: args?['surveyTitle'] ?? '',
          surveyDescription: args?['surveyDescription'] ?? '',
          questions: args?['questions'] ?? [],
        );
        break;
      case '/targetUpdateScreen':
        final args = settings.arguments as Map<String, dynamic>?;
        page = TargetUpdateScreen(
          surveyId: args?['surveyId'] ?? '',
          surveyTitle: args?['surveyTitle'] ?? '',
          surveyDescription: args?['surveyDescription'] ?? '',
          questions: List<Map<String, dynamic>>.from(args?['questions'] ?? []),
          selectedGroups: List<String>.from(args?['selectedGroups'] ?? []),
          selectedUsers: List<String>.from(args?['selectedUsers'] ?? []),
          selectedDepartments: List<String>.from(
            args?['selectedDepartments'] ?? [],
          ),
        );
        break;
      case '/surveyQuestions':
        final args = settings.arguments as Map<String, dynamic>?;
        page = SurveyQuestionsScreen(surveyId: args?['surveyId'] ?? '');
        break;
      case '/resultsScreen':
        page = SurveyResultsScreen();
        break;
      case '/respondentsList':
        final args = settings.arguments as Map<String, dynamic>?;
        page = RespondentsListScreen(survey: args?['survey'] ?? '');
        break;
      case '/userResponses':
        final args = settings.arguments as Map<String, dynamic>?;
        page = UserResponsesScreen(
          survey: args?['survey'] ?? '',
          responseData: args?['responseData'] ?? '',
          userName: args?['userName'] ?? '',
        );
        break;
      case '/groupList':
        final args = settings.arguments as Map<String, dynamic>?;
        page = GroupListScreen(pageName: args?['pageName'] ?? '');
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
        page = UnanswersListScreen(survey: args?['survey'] ?? '');
        break;
      case '/surveyEdit':
        final args = settings.arguments as Map<String, dynamic>?;
        page = SurveyEditScreen(surveyId: args?['surveyId'] ?? '');
        break;
      case '/passwordChange':
        page = const PasswordChangeScreen();
        break;
      case '/mailChange':
        page = const MailChangeScreen();
        break;
      case '/userInfoChange':
        page = const UserInfoChangeScreen();
        break;
      case '/departmentManagement':
        page = const DepartmentManagementScreen();
        break;
      default:
        page = const SplashScreen();
        break;
    }

    return CupertinoPageRoute(builder: (_) => page);
  }
}
