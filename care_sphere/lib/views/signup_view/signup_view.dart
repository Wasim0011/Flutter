import 'package:care_sphere/consts/consts.dart';
import 'package:care_sphere/controllers/auth_controller.dart';
import 'package:care_sphere/res/components/custom_button.dart';
import 'package:care_sphere/res/components/custom_textfield.dart';
import 'package:care_sphere/views/home_view/home.dart';
import 'package:get/get.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  var isDoctor = false;

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(AuthController());
    controller.imagePath.value = '';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppAssets.imgSignup,
                      width: 200.0,
                    ),
                    10.heightBox,
                    AppStyles.bold(
                        title: AppStrings.signupNow,
                        size: AppSizes.size18,
                        alignment: TextAlign.center),
                  ],
                ),
                30.heightBox,
                Form(
                  child: Column(
                    children: [
                      CustomTextfield(
                        hint: AppStrings.fullname,
                        textController: controller.fullnameController,
                      ),
                      10.heightBox,
                      CustomTextfield(
                        hint: AppStrings.email,
                        textController: controller.emailController,
                      ),
                      10.heightBox,
                      CustomTextfield(
                        hint: AppStrings.password,
                        textController: controller.passwordController,
                        isPassword: true,
                      ),
                      10.heightBox,
                      SwitchListTile(
                        title: "Sign up as a doctor".text.make(),
                        value: isDoctor,
                        onChanged: (newValue) {
                          setState(() {
                            isDoctor = newValue;
                          });
                        },
                      ),
                      Visibility(
                        visible: isDoctor,
                        child: Column(
                          children: [
                            // --- START: Image Picker UI ---
                            10.heightBox,
                            Obx(
                                  () => GestureDetector(
                                onTap: () {
                                  controller.pickImage();
                                },
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: controller
                                      .imagePath.value.isNotEmpty
                                      ? FileImage(
                                      File(controller.imagePath.value))
                                  as ImageProvider
                                      : AssetImage(AppAssets.icLogin),
                                  child: controller.imagePath.value.isEmpty
                                      ? Icon(Icons.camera_alt,
                                      color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                            10.heightBox,
                            AppStyles.normal(title: "Add profile picture"),
                            10.heightBox,
                            // --- END: Image Picker UI ---
                            CustomTextfield(
                              hint: 'About',
                              textController: controller.aboutController,
                              maxLines: 3,
                            ),
                            10.heightBox,
                            CustomTextfield(
                              hint: 'Category',
                              textController: controller.categoryController,
                            ),
                            10.heightBox,
                            CustomTextfield(
                              hint: 'Service',
                              textController: controller.servicesController,
                            ),
                            10.heightBox,
                            CustomTextfield(
                              hint: 'Address',
                              textController: controller.addressController,
                            ),
                            10.heightBox,
                            CustomTextfield(
                              hint: 'Phone Number',
                              textController: controller.phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            10.heightBox,
                            CustomTextfield(
                              hint: 'Timing',
                              textController: controller.timingController,
                            ),
                            10.heightBox,
                          ],
                        ),
                      ),
                      20.heightBox,
                      // --- START: Obx Loading Indicator ---
                      Obx(
                            () => controller.isLoading.value
                            ? Center(child: CircularProgressIndicator())
                            : Column(
                          children: [
                            CustomButton(
                              buttonText: AppStrings.signup,
                              onTap: () async {
                                await controller.signupUser(isDoctor);
                                if (controller.userCredential != null) {
                                  Get.offAll(() => Home());
                                }
                              },
                            ),
                            20.heightBox,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppStyles.normal(
                                    title: AppStrings.alreadyHaveAccount),
                                8.widthBox,
                                GestureDetector(
                                  onTap: () {
                                    Get.back();
                                  },
                                  child: AppStyles.bold(
                                      title: AppStrings.login),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // --- END: Obx Loading Indicator ---
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
