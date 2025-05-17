import 'package:care_sphere/controllers/appointment_controller.dart';
import 'package:care_sphere/res/components/custom_textfield.dart';
import '../../consts/consts.dart';
import '../../res/components/custom_button.dart';
import 'package:get/get.dart';

class BookAppointmentView extends StatelessWidget {
  final String docId;
  final String docName;
  const BookAppointmentView(
      {super.key, required this.docId, required this.docName});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(AppointmentController());
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.blueColor,
          elevation: 0.0,
          title: AppStyles.bold(
            title: docName,
            size: AppSizes.size18,
            color: AppColors.whiteColor,
          )),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStyles.bold(title: "Select appointment day"),
              5.heightBox,
              CustomTextfield(
                hint: "Select day",
                textController: controller.appDayController,
              ),
              10.heightBox,
              AppStyles.bold(title: "Select appointment time"),
              5.heightBox,
              CustomTextfield(
                hint: "Select time",
                textController: controller.appTimeController,
              ),
              20.heightBox,
              AppStyles.bold(title: "Mobile Number:"),
              5.heightBox,
              CustomTextfield(
                hint: "Enter your mobile number",
                textController: controller.appMobileController,
              ),
              10.heightBox,
              AppStyles.bold(title: "Full Name:"),
              5.heightBox,
              CustomTextfield(
                hint: "Enter your name",
                textController: controller.appNameController,
              ),
              10.heightBox,
              AppStyles.bold(title: "Message:"),
              5.heightBox,
              CustomTextfield(
                hint: "Enter your message",
                textController: controller.appMessageController,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => Padding(
          padding: const EdgeInsets.all(10.0),
          child: controller.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : CustomButton(
                  buttonText: "Book an appointment",
                  onTap: () async {
                    await controller.bookAppointment(docId, docName, context);
                    Get.back();
                  },
                ),
        ),
      ),
    );
  }
}
