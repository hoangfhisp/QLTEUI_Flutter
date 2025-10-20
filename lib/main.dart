import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_qlte/screens/admin/admin_user_screen.dart';
import 'package:frontend_qlte/screens/auth/login_screen.dart';
import 'package:frontend_qlte/screens/auth/registration_screen.dart';
import 'package:frontend_qlte/screens/client/chat_message_list_screen.dart';
import 'package:frontend_qlte/screens/client/home_screen.dart';
import 'package:frontend_qlte/screens/admin/admin_screen.dart';
import 'package:frontend_qlte/screens/client/user_infor_screen.dart';
import 'package:frontend_qlte/utils/notification_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // await NotificationHelper.init(); (thông báo)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng nhận nuôi thú cưng',
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
      },
    );
  }
}
