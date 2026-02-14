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

    // Function to handle date picking
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        controller.appDayController.text = "${picked.toLocal()}".split(' ')[0];
      }
    }

    // Function to handle time picking
    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (picked != null) {
        controller.appTimeController.text = picked.format(context);
      }
    }

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
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer( // Makes the text field not focusable
                  child: CustomTextfield(
                    hint: "Select day",
                    textController: controller.appDayController,
                  ),
                ),
              ),
              10.heightBox,
              AppStyles.bold(title: "Select appointment time"),
              5.heightBox,
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: CustomTextfield(
                    hint: "Select time",
                    textController: controller.appTimeController,
                  ),
                ),
              ),
              20.heightBox,
              AppStyles.bold(title: "Mobile Number:"),
              5.heightBox,
              CustomTextfield(
                hint: "Enter your mobile number",
                textController: controller.appMobileController,
                keyboardType: TextInputType.phone,
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
                maxLines: 3,
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
                    if (controller.appDayController.text.isNotEmpty &&
                        controller.appTimeController.text.isNotEmpty &&
                        controller.appMobileController.text.isNotEmpty &&
                        controller.appNameController.text.isNotEmpty) {
                      await controller.bookAppointment(docId, docName, context);
                      Get.back();
                    } else {
                      VxToast.show(context, msg: "Please fill all fields");
                    }
                  },
                ),
        ),
      ),
    );
  }
}
