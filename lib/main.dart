import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:your_ai_friend/chat_page/chat_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  await dotenv.load(fileName: 'api_key.env');
  Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');
  //Gemini.init(apiKey: GEMINI_API_KEY);
  WidgetsFlutterBinding.ensureInitialized();


  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Widget initialPage;

  runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.orange,
        ),
        navigatorKey: navigatorKey,
        home: ChatAI(),
      ),
  );
}