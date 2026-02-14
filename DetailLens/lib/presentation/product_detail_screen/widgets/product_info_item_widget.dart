import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/product_info_item_model.dart';

class ProductInfoItemWidget extends StatelessWidget {
  final ProductInfoModel? leftModel;
  final ProductInfoModel? rightModel;

  const ProductInfoItemWidget({
    Key? key,
    this.leftModel,
    this.rightModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: appTheme.gray_200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- MODIFIED SECTION FOR LEFT LABEL ---
                if (leftModel?.label?.isNotEmpty ?? false)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: appTheme
                          .deep_orange_50, // A soft, beautiful background
                      borderRadius:
                          BorderRadius.circular(6.h), // Rounded corners
                    ),
                    child: Text(
                      leftModel!.label!,
                      style: TextStyleHelper.instance.body14RegularBeVietnamPro
                          .copyWith(
                        color: appTheme.pink_800,
                        fontWeight:
                            FontWeight.w600, // Slightly bolder for emphasis
                      ),
                    ),
                  ),
                SizedBox(height: 8.h), // Adjusted spacing
                Container(
                  width: leftModel?.label == 'Nutritional Info'
                      ? double.infinity * 0.86
                      : double.infinity,
                  child: Text(
                    leftModel?.value ?? '',
                    style: TextStyleHelper.instance.body14RegularBeVietnamPro
                        .copyWith(
                      color: appTheme.gray_900,
                      height:
                          leftModel?.label == 'Nutritional Info' ? 1.5 : 1.29,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 8.h, top: 14.h, bottom: 14.h),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: appTheme.gray_200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- MODIFIED SECTION FOR RIGHT LABEL ---
                if (rightModel?.label?.isNotEmpty ?? false)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: appTheme.deep_orange_50,
                      borderRadius: BorderRadius.circular(6.h),
                    ),
                    child: Text(
                      rightModel!.label!,
                      style: TextStyleHelper.instance.body14RegularBeVietnamPro
                          .copyWith(
                        color: appTheme.pink_800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(height: 8.h), // Adjusted spacing
                Container(
                  alignment: rightModel?.label == 'Other Info'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    rightModel?.value ?? '',
                    style: TextStyleHelper.instance.body14RegularBeVietnamPro
                        .copyWith(color: appTheme.gray_900, height: 1.29),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
