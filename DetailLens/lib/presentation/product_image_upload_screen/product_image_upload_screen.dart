import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_loading_indicator.dart';
import 'notifier/product_image_upload_notifier.dart';

class ProductImageUploadScreen extends ConsumerStatefulWidget {
  const ProductImageUploadScreen({Key? key}) : super(key: key);

  @override
  ProductImageUploadScreenState createState() =>
      ProductImageUploadScreenState();
}

class ProductImageUploadScreenState
    extends ConsumerState<ProductImageUploadScreen> {
  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(productImageUploadNotifier);
    final notifier = ref.read(productImageUploadNotifier.notifier);

    ref.listen<ProductImageUploadState>(productImageUploadNotifier,
        (previous, next) {
      if (next.userMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  next.isError
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Text(
                    next.userMessage!,
                    style: TextStyleHelper.instance.body14RegularBeVietnamPro
                        .copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor:
                next.isError ? appTheme.red_600 : appTheme.teal_400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.h),
            ),
            margin: EdgeInsets.all(16.h),
            duration: const Duration(seconds: 1),
          ),
        );
        notifier.clearUserMessage();
      }
    });

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_50_01,
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUploadInfoText(context),
                        _buildImageUploadSection(context, providerState),
                        // Show instruction only when no images are uploaded (imagePaths is empty)
                        if (providerState.productImageUploadModel?.imagePaths
                                ?.isEmpty ??
                            true)
                          _buildWelcomeMessage(context),
                      ],
                    ),
                  ),
                ),
                _buildBottomSection(context, providerState),
              ],
            ),
            // Conditionally display the loading indicator
            if (providerState.isLoading) const CustomLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  // Add this new method to ProductImageUploadScreenState class:
  Widget _buildWelcomeMessage(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 32.h, bottom: 24.h),
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(
          color: appTheme.orange_50,
          width: 1.5.h,
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.pink_800.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.h),
                decoration: BoxDecoration(
                  color: appTheme.deep_orange_50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_reaction_outlined,
                  color: appTheme.pink_800,
                  size: 24.h,
                ),
              ),
              SizedBox(width: 16.h),
              Expanded(
                child: Text(
                  "Understand Every Product with Ease",
                  style:
                      TextStyleHelper.instance.title18BoldBeVietnamPro.copyWith(
                    color: appTheme.gray_900,
                    fontSize: 18.fSize,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Divider(
            color: appTheme.gray_200,
            thickness: 0.9,
            height: 1,
          ),
          SizedBox(height: 10.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style:
                  TextStyleHelper.instance.body14RegularBeVietnamPro.copyWith(
                color: appTheme.gray_600, // single premium color
                height: 1.6,
                fontSize: 15.fSize,
              ),
              children: const [
                TextSpan(
                  text:
                      "Capture photos of the product to see ingredients, nutrition, and expiry details clearly."
                      "You can also tap Read Aloud to hear everything in Hindi—helpful for quick and easy understanding at home.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 60.h,
      title: Text(
        'Product Info Extractor',
        style: TextStyle(
          fontSize: 24.h,
        ),
      ),
      titleTextStyle: TextStyleHelper.instance.title18BoldBeVietnamPro.copyWith(
        color: Colors.white,
      ),
      centerTitle: true,
      elevation: 4, // Set to 0 to match the flat style in your screenshot
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Colors updated to closely match your screenshots app bar
            colors: [Colors.cyanAccent, Colors.orangeAccent.shade200],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadInfoText(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.h),
      // Use one Container to wrap both texts
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: Color(0xFFF8EFE7),
          borderRadius: BorderRadius.circular(16.0),
        ),
        // A Column inside the container holds the texts
        child: Column(
          children: [
            Text(
              'Upload Product Images',
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title18BoldBeVietnamPro,
            ),
            // A smaller SizedBox for spacing between the lines of text
            SizedBox(height: 8.h),
            Text(
              '(Capture photos from every side)',
              textAlign: TextAlign.center,
              style:
                  TextStyleHelper.instance.body14RegularBeVietnamPro.copyWith(
                color: appTheme.gray_600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(
      BuildContext context, ProductImageUploadState state) {
    final imagePaths = state.productImageUploadModel?.imagePaths ?? [];

    if (imagePaths.isEmpty) {
      return _buildLargeImageUploader(
        context: context,
        onTap: () => _showImageSourceDialog(context),
      );
    } else {
      return _buildImageGrid(context, state);
    }
  }

  Widget _buildLargeImageUploader(
      {required BuildContext context, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160.h,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: appTheme.orange_50,
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                color: appTheme.teal_400, size: 48.h),
            SizedBox(height: 12.h),
            Text('Add Image',
                style:
                    TextStyleHelper.instance.bodyTextBoldBeVietnamPro.copyWith(
                  color: appTheme.gray_900,
                  fontSize: 16.fSize,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, ProductImageUploadState state) {
    final imagePaths = state.productImageUploadModel?.imagePaths ?? [];
    final notifier = ref.read(productImageUploadNotifier.notifier);

    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12.h,
          mainAxisSpacing: 12.h,
        ),
        itemCount: imagePaths.length + (imagePaths.length < 5 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < imagePaths.length) {
            return _buildImagePreview(
              imagePath: imagePaths[index],
              onRemove: () => notifier.removeImage(index),
            );
          } else {
            return _buildImageUploader(
              context: context,
              onTap: () => _showImageSourceDialog(context),
            );
          }
        },
      ),
    );
  }

  Widget _buildImageUploader(
      {required BuildContext context, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
              color: appTheme.gray_300, width: 2.h, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: appTheme.pink_800, size: 32.h),
            SizedBox(height: 8.h),
            Text('Add Image',
                style: TextStyleHelper.instance.body14RegularBeVietnamPro),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(
      {required String imagePath, required VoidCallback onRemove}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.h),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 4.h,
            right: 4.h,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(2.h),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 16.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('From Gallery'),
                  onTap: () {
                    ref
                        .read(productImageUploadNotifier.notifier)
                        .pickImages(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  ref
                      .read(productImageUploadNotifier.notifier)
                      .pickImages(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSection(
      BuildContext context, ProductImageUploadState state) {
    final bool canExtract = state.canExtract ?? false;
    final bool isLoading = state.isLoading;

    return Padding(
      padding:
          EdgeInsets.only(left: 24.h, right: 24.h, bottom: 32.h, top: 16.h),
      child: CustomButton(
        width: double.infinity,
        text: isLoading ? 'Extracting...' : 'Extract Details',
        variant: CustomButtonVariant.action,
        isEnabled: canExtract && !isLoading,
        onPressed: () => _onTapExtractDetails(context),
      ),
    );
  }

  void _onTapExtractDetails(BuildContext context) async {
    final notifier = ref.read(productImageUploadNotifier.notifier);
    final Map<String, dynamic>? extractedData = await notifier.extractDetails();
    if (extractedData != null && mounted) {
      await NavigatorService.pushNamed(
        AppRoutes.productDetailScreen,
        arguments: extractedData,
      );
      notifier.resetState();
    }
  }
}
