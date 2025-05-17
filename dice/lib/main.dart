import 'package:flutter/material.dart';
import 'dart:math'; //for using random number

void main() {
  return runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blue,
        appBar: AppBar(
          title: const Text('Dicee'),
          backgroundColor: Colors.tealAccent,
        ),
        body: const DicePage(),
      ),
    ),
  );
}



class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  int leftDiceNum = 1;
  int rightDiceNum = 1;
  void buttonPressed(){
    setState(() {  //to update the state of image
      leftDiceNum=(Random().nextInt(100)%6)+1; //1, 2, 3, 4, 5, 6
      rightDiceNum=(Random().nextInt(100)%6)+1; //1, 2, 3, 4, 5, 6
    });
  }
  @override
  Widget build(BuildContext context){
    return Center(
      child: Row(
        children: <Widget> [
          Expanded(
              child: TextButton(
                  onPressed: () {
                    buttonPressed();
                  },
                  child: Image.asset('images/dice$leftDiceNum.png')
              )
          ),
          Expanded(
              child: TextButton(
                  onPressed: () {
                    buttonPressed();
                  },
                  child: Image.asset('images/dice$rightDiceNum.png')
              )
          ),
        ],
      ),
    );
  }
}