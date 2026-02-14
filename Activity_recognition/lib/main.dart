import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(CsiActivityApp());
}

class CsiActivityApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSI Human Activity',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF3F829B)),
      ),
      home: ActivityHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ActivityHomePage extends StatefulWidget {
  @override
  _ActivityHomePageState createState() => _ActivityHomePageState();
}

class _ActivityHomePageState extends State<ActivityHomePage> {
  String _activity = 'No Prediction Yet';
  String _predictionTime = '';   // NEW: Time of prediction
  bool _isLoading = false;
  bool _predictionRequested = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _listenPrediction();
  }

  void _requestPrediction() async {
    setState(() {
      _isLoading = true;
      _predictionRequested = true;
    });

    // Clear previous prediction before requesting
    await _db.collection('activity').doc('current').set({
      'prediction': null,
      'request_prediction': true,
    }, SetOptions(merge: true));
  }

  void _listenPrediction() {
    _db.collection('activity').doc('current').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final prediction = data['prediction'];
          final requestPending = data['request_prediction'] ?? false;

          if (prediction != null && _predictionRequested) {
            String currentTime = TimeOfDay.now().format(context);
            setState(() {
              _activity = prediction;
              _predictionTime = currentTime;  // Save the time
              _isLoading = false;
              _predictionRequested = false;
            });
            _showPredictionAlert(prediction, currentTime);
          }

          if (!requestPending && _isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  void _showPredictionAlert(String prediction, String time) {
    Alert(
      context: context,
      title: "Activity Prediction",
      desc: "${prediction.toUpperCase()}\n$time",
      style: AlertStyle(
        titleStyle: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.greenAccent,
        ),
        descStyle: TextStyle(
          fontSize: 30,
          color: Colors.limeAccent,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Color(0xFF010923),
        animationType: AnimationType.grow,
      ),
      buttons: [
        DialogButton(
          width: MediaQuery.of(context).size.width - 136,
          color: Color(0xFF3F829B),
          onPressed: () => Navigator.pop(context),
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF010923),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'CSI Human Activity Detection',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  "images/2.jpg",
                  width: 350.0,
                  height: 350.0,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Predicted Activity',
                style: TextStyle(fontSize: 40, color: Colors.greenAccent),
              ),
              SizedBox(height: 10),
              Text(
                _activity.toUpperCase(),
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.limeAccent,
                ),
              ),
              SizedBox(height: 10),
              if (_predictionTime.isNotEmpty)
                Text(
                  _predictionTime,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.cyanAccent,    // Different color
                    fontStyle: FontStyle.italic, // Different style
                  ),
                ),
              SizedBox(height: 30),
              _isLoading
                  ? SpinKitFadingCircle(
                color: Colors.white,
                size: 90.0,
              )
                  : ElevatedButton.icon(
                icon: Icon(Icons.sensors, size: 25.0),
                label: Text('Predict Activity'),
                onPressed: _requestPrediction,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}