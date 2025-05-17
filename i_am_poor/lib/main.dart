import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blueGrey,
        appBar: AppBar(
          title: const Center(
            child: Text("I am Poor",
                style: TextStyle(color: Colors.amberAccent, fontSize: 30)),
          ),
          backgroundColor: Colors.teal.shade500,
        ),
        body: const Center(
          child: Image(
              image: AssetImage(
                  'images/vecteezy_character-boy-cartoon_10864772.png')),
        ),
      ),
    ),
  );
}
