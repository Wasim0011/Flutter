import 'package:care_sphere/consts/consts.dart';
import 'package:care_sphere/views/appointment_view/appointment_view.dart';
import 'package:care_sphere/views/home_view/home.dart';
import 'package:care_sphere/views/login_view/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController extends GetxController {
  var fullnameController = TextEditingController();
  var passwordController = TextEditingController();
  var emailController = TextEditingController();

  //doctor editing controller
  var aboutController = TextEditingController();
  var addressController = TextEditingController();
  var servicesController = TextEditingController();
  var timingController = TextEditingController();
  var phoneController = TextEditingController();
  var categoryController = TextEditingController();

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
          Get.offAll(() => AppointmentView());
        }else {
          Get.offAll(() => Home());
        }
      } else {
        Get.offAll(() => LoginView());
      }
    });
  }

  loginUser() async {
    userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text, password: passwordController.text);
  }

  signupUser(bool isDoctor) async {
    userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text, password: passwordController.text);
    await storeUserData(userCredential!.user!.uid, fullnameController.text,
        emailController.text, isDoctor);
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
