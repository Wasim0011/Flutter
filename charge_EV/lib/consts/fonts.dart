import 'package:charge_ev/consts/consts.dart';

class AppFonts{
  static String nunito = "nunito", nunitoBold = "nunito_bold",
  inter="inter", interBold="inter_bold", nunitoMedium="nunito_medium";
}

class AppSizes{
  static const size12=12.0, size14=14.0, size16 = 16.0, size30 = 30.0;
}

class AppStyles{
  static normal({String? title, Color? color=Colors.black, double? size, TextAlign alignment=TextAlign.left}){
    return title!.text.size(size).color(color).align(alignment).make();
  }

  static bold({String? title, Color? color=Colors.black, double? size, TextAlign alignment=TextAlign.left}){
    return title!.text.size(size).color(color).fontFamily(AppFonts.nunitoBold).align(alignment).make();
  }
}