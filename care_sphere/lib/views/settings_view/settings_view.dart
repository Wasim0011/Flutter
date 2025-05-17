import 'package:care_sphere/consts/lists.dart';
import 'package:care_sphere/controllers/auth_controller.dart';
import 'package:care_sphere/controllers/settings_controller.dart';
import 'package:care_sphere/views/login_view/login_view.dart';
import 'package:get/get.dart';
import '../../consts/consts.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(SettingsController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blueColor,
        elevation: 0.0,
        title: AppStyles.bold(
            title: AppStrings.settings,
            color: AppColors.whiteColor,
            size: AppSizes.size18),
      ),
      body: Obx(()=>
      controller.isLoading.value ? Center(child: CircularProgressIndicator(),):
        Column(
          children: [
            ListTile(
              leading: CircleAvatar(child: Image.asset(AppAssets.imgSignup)),
              title: AppStyles.bold(title: controller.username.value),
              subtitle: AppStyles.normal(title: controller.email.value),
            ),
            const Divider(),
            10.heightBox,
            ListView(
              shrinkWrap: true,
              children: List.generate(
                  settingsList.length,
                  (index) => ListTile(
                    onTap: () async{
                      if(index == 2){
                        AuthController().signout();
                        Get.offAll(()=>LoginView());
                      }
                    },
                    leading: Icon(settingsListIcon[index], color: AppColors.blueColor,),
                        title: AppStyles.bold(title: settingsList[index]),
                      )),
            )
          ],
        ),
      ),
    );
  }
}
