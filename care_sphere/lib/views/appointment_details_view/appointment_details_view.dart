import 'package:cloud_firestore/cloud_firestore.dart';

import '../../consts/consts.dart';

class AppointmentDetailsView extends StatelessWidget {
  final DocumentSnapshot doc;

  const AppointmentDetailsView({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blueColor,
          elevation: 0.0,
          title: AppStyles.bold(
            title: "Doctor Name",
            size: AppSizes.size18,
            color: AppColors.whiteColor,
          )),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStyles.bold(title: "Select appointment day"),
            5.heightBox,
            AppStyles.normal(title: doc['appWithName']),
            10.heightBox,
            AppStyles.bold(title: "Select appointment time"),
            5.heightBox,
            AppStyles.normal(title: doc['appTime']),
            20.heightBox,
            AppStyles.bold(title: "Mobile Number:"),
            5.heightBox,
            AppStyles.normal(title: doc['appMobile']),
            10.heightBox,
            AppStyles.bold(title: "Full Name:"),
            5.heightBox,
            AppStyles.normal(title: doc['appName']),
            10.heightBox,
            AppStyles.bold(title: "Message:"),
            5.heightBox,
            AppStyles.normal(title: doc['appMsg']),
          ],
        ),
      ),
    );
  }
}
