import 'dart:io';

import 'package:care_sphere/consts/consts.dart';
import 'package:care_sphere/views/appointment_view/appointment_view.dart';
import 'package:care_sphere/views/home_view/home.dart';
import 'package:care_sphere/views/login_view/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class AuthController extends GetxController {
  var fullnameController = TextEditingController();
  var passwordController = TextEditingController();
  var emailController = TextEditingController();

  var isLoading = false.obs;

  //doctor editing controller
  var aboutController = TextEditingController();
  var addressController = TextEditingController();
  var servicesController = TextEditingController();
  var timingController = TextEditingController();
  var phoneController = TextEditingController();
  var categoryController = TextEditingController();

  var imagePath = ''.obs;
  String? imageLink; // To store the download URL

  UserCredential? userCredential;

  isUserAlreadyLoggedIn() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        var data = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .get();
        var isDoc = data.data()?.containsKey('docName') ?? false;
        if(isDoc){
          Get.offAll(() => AppointmentView(isDoctor: true,));
        }else {
          Get.offAll(() => Home());
        }
      } else {
        Get.offAll(() => LoginView());
      }
    });
  }

  loginUser() async {
    isLoading(true); // Set loading to true
    try {
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);
    } on FirebaseAuthException catch (e) {
      VxToast.show(Get.context!, msg: e.toString());
    } finally {
      isLoading(false); // Set loading to false
    }
  }

  signupUser(bool isDoctor) async {
    isLoading(true); // Set loading to true
    try {
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);

      // --- START: Image Upload Logic ---
      if (isDoctor && imagePath.value.isNotEmpty) {
        var filename = basename(imagePath.value);
        var destination =
            'doctors/${userCredential!.user!.uid}/profile_pic/$filename';
        storage.Reference ref =
        storage.FirebaseStorage.instance.ref().child(destination);
        await ref.putFile(File(imagePath.value));
        imageLink = await ref.getDownloadURL();
      }
      // --- END: Image Upload Logic ---
      await storeUserData(userCredential!.user!.uid, fullnameController.text,
          emailController.text, isDoctor);
    } on FirebaseAuthException catch (e) {
      // If user creation fails, delete the user to avoid orphan accounts
      if(userCredential != null){
        await userCredential!.user!.delete();
      }
      VxToast.show(Get.context!, msg: e.toString());
    } finally {
      isLoading(false); // Set loading to false
    }
  }

  storeUserData(String uid, String fullname, String email, bool isDoctor) async {
    var store = FirebaseFirestore.instance.collection(isDoctor ? 'doctors' : 'user').doc(uid);
    if(isDoctor){
      await store.set({
         'docAbout': aboutController.text,
        'docAddress': addressController.text,
        'docCategory': categoryController.text,
        'docName': fullname,
        'docPhone': phoneController.text,
        'docService': servicesController.text,
        'docTiming': timingController.text,
        'docId': FirebaseAuth.instance.currentUser?.uid,
        'docRating': 1,
        'docEmail': email
      });
    }else{
      await store.set({'fullname': fullname, 'email': email});
    }
  }

  signout() async {
    await FirebaseAuth.instance.signOut();
  }
}
