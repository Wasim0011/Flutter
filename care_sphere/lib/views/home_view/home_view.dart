import 'dart:developer';
import 'package:care_sphere/consts/lists.dart';
import 'package:care_sphere/controllers/home_controller.dart';
import 'package:care_sphere/res/components/custom_textfield.dart';
import 'package:care_sphere/views/category_details_vies/category_details_view.dart';
import 'package:care_sphere/views/doctor_profile_view/doctor_profile_view.dart';
import 'package:care_sphere/views/search_view/search_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../consts/consts.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blueColor,
        elevation: 0.0,
        title: AppStyles.bold(
            title: "${AppStrings.welcome} User",
            color: AppColors.whiteColor,
            size: AppSizes.size18),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              color: AppColors.blueColor,
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextfield(
                      textController: controller.searchQueryController,
                      hint: AppStrings.search,
                      borderColor: AppColors.whiteColor,
                      textColor: AppColors.whiteColor,
                      inputColor: AppColors.whiteColor,
                    ),
                  ),
                  10.widthBox,
                  IconButton(
                      onPressed: () {
                        Get.to(()=>SearchView(searchQuery: controller.searchQueryController.text,));
                      },
                      icon: Icon(
                        Icons.search,
                        color: AppColors.whiteColor,
                      ))
                ],
              ),
            ),
            20.heightBox,
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            Get.to(() => CategoryDetailsView(
                                catName: iconsTitleList[index]));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.blueColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(right: 8),
                            child: Column(
                              children: [
                                Image.asset(
                                  iconsList[index],
                                  width: 30,
                                  color: AppColors.whiteColor,
                                ),
                                5.heightBox,
                                AppStyles.normal(
                                    title: iconsTitleList[index],
                                    color: AppColors.whiteColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  20.heightBox,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppStyles.bold(
                        title: "Popular Doctors",
                        color: AppColors.blueColor,
                        size: AppSizes.size18),
                  ),
                  10.heightBox,
                  FutureBuilder<QuerySnapshot>(
                      future: controller.getDoctorList(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                          var data = snapshot.data?.docs;
                          log(data!.length.toString());
                          return SizedBox(
                            height: 150,
                            child: ListView.builder(
                              physics: BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: data.length,
                              itemBuilder: (BuildContext context, int index) {
                                return GestureDetector(
                                  onTap: () {
                                    Get.to(() =>
                                        DoctorProfileView(doc: data[index]));
                                  },
                                  child: Container(
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                        color: AppColors.bgDarkColor,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    margin: EdgeInsets.only(right: 8),
                                    height: 100,
                                    width: 150,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 150,
                                          alignment: Alignment.center,
                                          color: AppColors.blueColor,
                                          child: Image.asset(
                                            AppAssets.icLogin,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        5.heightBox,
                                        AppStyles.normal(
                                            title: data[index]['docName']),
                                        AppStyles.normal(
                                            title: data[index]['docCategory'],
                                            color: Colors.black54),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      }),
                  5.heightBox,
                  GestureDetector(
                    onTap: () {},
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppStyles.normal(
                          title: "View All", color: AppColors.blueColor),
                    ),
                  ),
                  20.heightBox,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                        4,
                        (index) => Container(
                              decoration: BoxDecoration(
                                  color: AppColors.blueColor,
                                  borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Image.asset(
                                    AppAssets.icBody,
                                    width: 25,
                                    color: AppColors.whiteColor,
                                  ),
                                  5.heightBox,
                                  AppStyles.normal(
                                      title: "Lab Test",
                                      color: AppColors.whiteColor)
                                ],
                              ),
                            )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
