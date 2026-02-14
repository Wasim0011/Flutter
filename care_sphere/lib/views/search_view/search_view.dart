import 'package:care_sphere/views/doctor_profile_view/doctor_profile_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../consts/consts.dart';

class SearchView extends StatelessWidget {
  final String searchQuery;
  const SearchView({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blueColor,
        elevation: 0.0,
        title: AppStyles.bold(
            title: "Search Results",
            color: AppColors.whiteColor,
            size: AppSizes.size18),
      ),
      body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('doctors')
              .where('docName', isGreaterThanOrEqualTo: searchQuery)
              .where('docName', isLessThanOrEqualTo: searchQuery + '\uf8ff')
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: AppStyles.normal(title: "No results found"),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 170,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      var doc = snapshot.data!.docs[index];

                      return GestureDetector(
                        onTap: () {
                          Get.to(() => DoctorProfileView(doc: doc));
                        },
                        child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                color: AppColors.bgDarkColor,
                                borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.only(right: 8),
                            height: 100,
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  color: AppColors.blueColor,
                                  child: Image.asset(
                                    AppAssets.icLogin,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                5.heightBox,
                                AppStyles.normal(title: doc['docName']),
                                VxRating(
                                  selectionColor: AppColors.yellowColor,
                                  onRatingUpdate: (value) {},
                                  maxRating: 5,
                                  count: 5,
                                  value:
                                      double.parse(doc['docRating'].toString()),
                                  stepInt: true,
                                )
                              ],
                            )),
                      );
                    }),
              );
            }
          }),
    );
  }
}
