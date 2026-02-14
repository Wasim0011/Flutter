import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/app_bar.dart';
import '../components/custom_text_field.dart';
import '../consts/fonts.dart';
import '../controllers/auth_controller.dart';
import '../consts/images.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create an Account',
        subtitle: 'Enjoy seamless experience',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Field
            CustomTextField(
              label: 'Name',
              hintText: 'Siri',
              controller: authController.nameController,
              suffixIcon: const Icon(Icons.person),
            ),

            //Email Field
            CustomTextField(
              label: 'Email Address',
              hintText: 'hello@example.com',
              controller: authController.emailController,
            ),

            //Password Field with Toggle
            Obx(
              () => CustomTextField(
                label: 'Password',
                hintText: '••••••••••••',
                controller: authController.passwordController,
                obscureText: !authController.isPasswordVisible.value,
                suffixIcon: Obx(
                  () => IconButton(
                    icon: Icon(
                      authController.isPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      authController.isPasswordVisible.value =
                          !authController.isPasswordVisible.value;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            //Sign Up Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      authController.isLoading.value
                          ? null
                          : () => authController.signupUser(),
                  child:
                      authController.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Sign up',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w500,
                              fontSize: AppSizes.size16,
                            ),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ✅ Divider with Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'or sign in with',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontWeight: FontWeight.w400,
                        fontSize: AppSizes.size14,
                        color: Color(0xFF999DA3),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            //Google Sign-in Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: Image.asset(AppAssets.imgGoogle, height: 24, width: 24),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: AppSizes.size16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4B5768),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Handle Google Sign-In
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE4E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Terms & Privacy
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By clicking continue, you agree to our ',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: AppSizes.size12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1C262F),
                    ),
                    children: const [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: '\nPrivacy Policy',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
