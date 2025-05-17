import 'package:flutter/material.dart';
import 'dart:math';  //for using random number

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,  //for removing debug tag
    home: BallPage(),
  )
);
class  BallPage extends StatelessWidget {
  const BallPage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.blue,
        appBar: AppBar(
            title: const Text("Ask Me Anything",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            backgroundColor: Colors.blue.shade900,
          ),
        body: const Ball(),
      );
    }
  }

class Ball extends StatefulWidget {
  const Ball({super.key});

  @override
  State<Ball> createState() => _BallState();
}

class _BallState extends State<Ball> {
  int ballNumber = 1;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: (){
          setState(() { //to update the state of image
            ballNumber=Random().nextInt(100)%5+1; //1, 2, 3, 4, 5
            // print(ballNumber);
          });
        },
        child: Image.asset('images/ball$ballNumber.png'),
          ),
    );
  }
}
