import 'package:care_sphere/controllers/appointment_controller.dart';
import 'package:care_sphere/controllers/auth_controller.dart';
import 'package:care_sphere/views/appointment_details_view/appointment_details_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../consts/consts.dart';

class AppointmentView extends StatelessWidget {
  final bool isDoctor;
  const AppointmentView({super.key, this.isDoctor = false});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(AppointmentController());

    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.blueColor,
          elevation: 0.0,
          title: AppStyles.bold(
            title: "Appointments",
            size: AppSizes.size18,
            color: AppColors.whiteColor,
          ),
          actions: [
            IconButton(
                onPressed: () {
                  AuthController().signout();
                },
                icon: Icon(Icons.power_settings_new_outlined, color: AppColors.whiteColor,)),

          ],
        ),
        body: FutureBuilder<QuerySnapshot>(
            future: controller.getAppointments(isDoctor),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                var data = snapshot.data?.docs;
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListView.builder(
                      itemCount: data?.length ?? 0,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          onTap: () {
                            Get.to(() => AppointmentDetailsView(
                                  doc: data[index],
                                ));
                          },
                          leading: CircleAvatar(
                            child: Image.asset(AppAssets.icLogin),
                          ),
                          title: AppStyles.bold(
                              title: data![index]
                                  [!isDoctor ? 'appWithName' : 'appName']),
                          subtitle: AppStyles.normal(
                              title:
                                  "${data[index]['appDay']} - ${data[index]['appTime']}",
                              color: AppColors.textColor
                                  .withAlpha((0.5 * 255).toInt())),
                        );
                      }),
                );
              }
            }));
  }
}
