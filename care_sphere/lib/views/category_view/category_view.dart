import 'package:care_sphere/consts/lists.dart';
import 'package:care_sphere/views/category_details_vies/category_details_view.dart';
import 'package:get/get.dart';
import '../../consts/consts.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: AppStyles.bold(
          title: AppStrings.category,
          size: AppSizes.size18,
          color: AppColors.whiteColor,
        ),
        backgroundColor: AppColors.blueColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 170,
            ),
            itemCount: iconsList.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  Get.to(() => CategoryDetailsView(
                        catName: iconsTitleList[index],
                      ));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blueColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          iconsList[index],
                          width: 50,
                          color: AppColors.whiteColor,
                        ),
                      ),
                      30.heightBox,
                      AppStyles.bold(
                        title: iconsTitleList[index],
                        color: AppColors.whiteColor,
                        size: AppSizes.size16,
                      ),
                      10.heightBox,
                      AppStyles.normal(
                        title: "13 Specialists",
                        color:
                            AppColors.whiteColor.withAlpha((0.5 * 255).toInt()),
                        size: AppSizes.size12,
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
