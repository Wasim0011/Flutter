import 'package:care_sphere/consts/consts.dart';
import 'package:care_sphere/firebase_options.dart';
import 'package:care_sphere/res/components/waiting_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        fontFamily: AppFonts.nunito,
        primaryColor: AppColors.blueColor,
        scaffoldBackgroundColor: AppColors.bgColor,
        colorScheme: ColorScheme.light(
          primary: AppColors.blueColor,
          secondary: AppColors.yellowColor,
          background: AppColors.bgColor,
          onBackground: AppColors.textColor,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.blueColor,
          elevation: 0.0,
          iconTheme: IconThemeData(color: AppColors.whiteColor),
          titleTextStyle: TextStyle(
            fontFamily: AppFonts.nunitoBold,
            fontSize: AppSizes.size18,
            color: AppColors.whiteColor,
          ),
        ),

        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontFamily: AppFonts.nunitoBold,
            fontSize: AppSizes.size18,
            color: AppColors.textColor),
          bodyMedium: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: AppSizes.size14,
            color: AppColors.textColor),
          labelLarge: TextStyle(
            fontFamily: AppFonts.nunitoBold,
            fontSize: AppSizes.size16,
            color: AppColors.whiteColor,
          )
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: StadiumBorder(),
            backgroundColor: AppColors.blueColor,
            textStyle: TextStyle(
              color: AppColors.whiteColor, fontFamily: AppFonts.nunitoBold),
            padding: EdgeInsets.symmetric(vertical: 12),
          )
        )
      ),
      debugShowCheckedModeBanner: false,
      home: WaitingScreen(),
    );
  }
}