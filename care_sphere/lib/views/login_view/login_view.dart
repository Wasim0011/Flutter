import 'package:care_sphere/consts/consts.dart';
import 'package:care_sphere/controllers/auth_controller.dart';
import 'package:care_sphere/res/components/custom_button.dart';
import 'package:care_sphere/res/components/custom_textfield.dart';
import 'package:care_sphere/views/appointment_view/appointment_view.dart';
import 'package:care_sphere/views/signup_view/signup_view.dart';
import 'package:get/get.dart';
import '../home_view/home.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  var isDoctor = false;

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(AuthController());

    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.icLogin,
                    width: 200.0,
                  ),
                  10.heightBox,
                  AppStyles.bold(
                      title: AppStrings.welcomeBack, size: AppSizes.size18),
                  AppStyles.bold(title: AppStrings.weAreExcited),
                ],
              ),
            ),
            Expanded(
              child: Form(
                child: Column(
                  children: [
                    CustomTextfield(
                      hint: AppStrings.emailHint,
                      textController: controller.emailController,
                    ),
                    10.heightBox,
                    CustomTextfield(
                      hint: AppStrings.passwordHint,
                      textController: controller.passwordController,
                    ),
                    10.heightBox,
                    SwitchListTile(
                      value: isDoctor,
                      onChanged: (newValue) {
                        setState(() {
                          isDoctor = newValue;
                        });
                      },
                      title: "Sign in as a doctor".text.make(),
                    ),
                    // 20.heightBox,
                    Align(
                        alignment: Alignment.centerRight,
                        child:
                        AppStyles.normal(title: AppStrings.forgetPassword)),
                    20.heightBox,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          buttonText: AppStrings.login,
                          onTap: () async {
                            await controller.loginUser();
                            if (controller.userCredential != null) {
                              if (isDoctor) {
                                // Signing in as a doctor
                                Get.to(() => const AppointmentView());
                              } else {
                                // Signing in as a user
                                Get.to(() => const Home());
                              }
                            }
                          },
                        ),
                        20.heightBox,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppStyles.normal(title: AppStrings.dontHaveAccount),
                            8.widthBox,
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const SignupView());
                              },
                              child: AppStyles.bold(title: AppStrings.signup),
                            ),
                          ],
                        ),
                      ],
                    ),



                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}