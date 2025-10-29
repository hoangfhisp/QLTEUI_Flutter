import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_qlte/models/device_info_model.dart';
import 'package:frontend_qlte/screens/auth/login_screen.dart';
import 'package:frontend_qlte/screens/auth/registration_screen.dart';
import 'package:frontend_qlte/screens/client/chat_message_list_screen.dart';
import 'package:frontend_qlte/screens/client/child/exam_schedule_children_screen.dart';
import 'package:frontend_qlte/screens/client/child/home_children_screen.dart';
import 'package:frontend_qlte/screens/client/child/schedule_children_screen.dart';
import 'package:frontend_qlte/screens/client/child/sos_request_children_screen.dart';
import 'package:frontend_qlte/screens/client/device_info_child_screen.dart';
import 'package:frontend_qlte/screens/client/device_detail_child_screen.dart';
import 'package:frontend_qlte/screens/client/home_screen.dart';
import 'package:frontend_qlte/screens/admin/admin_screen.dart';
import 'package:frontend_qlte/screens/client/sos_request_parent_screen.dart';
import 'package:frontend_qlte/screens/common/navigation_bar_child_screen.dart';
import 'package:frontend_qlte/screens/common/navigation_bar_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ứng dụng quản lý trẻ em',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/chatmassagelist': (context) => const ChatMessageListScreen(),
        '/navigationbar': (context) => const NavigationBarScreen(),
        '/navigationbarchild': (context) => const NavigationBarChildScreen(),
        '/child': (context) => const HomeChildrenScreen(),
        '/schedule_children': (context) => const ScheduleChildrenScreen(),
        '/exam_schedule_children': (context) => const ExamScheduleChildrenScreen(),
        '/sos_request_children': (context) => const SOSRequestChildrenScreen(),
        '/sos_request_parent': (context) => const SOSRequestParentScreen(sosData: {},),
        '/device_info_child': (context) => const DeviceInfoChildScreen(),
        '/device_detail_child': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as DeviceInfoModel;
          return DeviceDetailChildScreen(device: args);
         },
      },
    );
  }
}
