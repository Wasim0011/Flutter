import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_product_app_bar.dart';
import './widgets/product_info_item_widget.dart';
import 'notifier/product_detail_notifier.dart';
import '../../widgets/custom_translation_loader.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? productData;

  const ProductDetailScreen({Key? key, this.productData}) : super(key: key);

  @override
  ProductDetailScreenState createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productData != null) {
        ref
            .read(productDetailNotifier.notifier)
            .initializeFromData(widget.productData!);
      }
    });
  }

  @override
  void dispose() {
    ref.read(productDetailNotifier.notifier).stopReadingAloud();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailNotifier);
    Widget scaffoldContent = Scaffold(
      backgroundColor: appTheme.gray_50_01,
      appBar: _buildAppBar(context),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text("Error: ${state.error}"))
              : Container(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.h, vertical: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductTitle(context),
                        SizedBox(height: 16.h),
                        _buildBrandName(context),
                        SizedBox(height: 32.h),
                        _buildDetailsHeader(context),
                        _buildProductInfoList(context),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildActionBottomBar(context),
    );

    return SafeArea(
      top: false,
      bottom: false,
      child: Stack(
        children: [
          scaffoldContent,
          if (state.isTranslating) const CustomTranslationLoader(),
        ],
      ),
    );
  }

  /// Section Widget - AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomProductAppBar(
      leadingImagePath: ImageConstant.imgDepth3Frame0,
      title: 'Product Details',
      backgroundColor: appTheme.gray_50_01,
      titleColor: appTheme.gray_900,
      onLeadingPressed: () {
        NavigatorService.goBack();
      },
    );
  }

  /// Section Widget - Product Title
  Widget _buildProductTitle(BuildContext context) {
    final model = ref.watch(productDetailNotifier).productDetailModel;
    return Text(
      model?.productTitle ?? 'Not Available', // Default text
      style: TextStyleHelper.instance.title22BoldBeVietnamPro
          .copyWith(height: 1.27),
    );
  }

  /// Section Widget - Brand Name
  Widget _buildBrandName(BuildContext context) {
    final model = ref.watch(productDetailNotifier).productDetailModel;
    return Text(
      model?.brandName ?? "Not Available", // Default text
      style: TextStyleHelper.instance.body14RegularBeVietnamPro
          .copyWith(color: appTheme.pink_800, height: 1.29),
    );
  }

  /// Section Widget - Details Header
  Widget _buildDetailsHeader(BuildContext context) {
    return Text(
      'Details',
      style: TextStyleHelper.instance.title22BoldBeVietnamPro
          .copyWith(height: 1.27),
    );
  }

  /// Section Widget - Product Info List
  Widget _buildProductInfoList(BuildContext context) {
    final state = ref.watch(productDetailNotifier);
    if (state.productInfoItems?.isEmpty ?? true) {
      return Center(child: Text("No details available."));
    }
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (context, index) {
        return SizedBox(height: 1.h);
      },
      itemCount: state.productInfoItems!.length,
      itemBuilder: (context, index) {
        final item = state.productInfoItems![index];
        return ProductInfoItemWidget(
          leftModel: item.leftModel,
          rightModel: item.rightModel,
        );
      },
    );
  }

  /// Section Widget - Bottom Action Bar (Updated)
  Widget _buildActionBottomBar(BuildContext context) {
    final state = ref.watch(productDetailNotifier);
    final notifier = ref.read(productDetailNotifier.notifier);
    final bool isBusy = state.isTranslating;
    final String buttonText = state.isReadingAloud ? 'Stop' : 'Read Aloud';
    final IconData buttonIcon = state.isReadingAloud
        ? Icons.stop_circle_outlined
        : Icons.volume_up_outlined;

    return Container(
      padding: EdgeInsets.only(
        left: 16.h,
        right: 16.h,
        top: 12.h,
        bottom: MediaQuery.of(context).padding.bottom + 1.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000), // Black with 6% opacity
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isBusy ? null : () => notifier.readAloud(),
        icon: Icon(
          buttonIcon,
          size: 24.h,
          color: Colors.white,
        ),
        label: Text(
          buttonText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.pink_800,
          disabledBackgroundColor: appTheme.pink_800.withValues(alpha: 0.5),
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}
