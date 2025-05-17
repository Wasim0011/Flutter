import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart'; //for using alert window
import 'quiz_brain.dart';
import 'package:flutter/services.dart'; //To close the app


QuizBrain quizBrain = QuizBrain();

void main() => runApp(const Quizzler());

class Quizzler extends StatelessWidget {
  const Quizzler({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/sand_black.jpg"),
              fit: BoxFit.cover, // Ensures the background covers the entire screen
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: QuizPage(),
            ),
          ),
        ),
      ),
    );
  }

}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Icon> scoreKeeper=[];
  void checkAnswer(bool userPickedAnswer){
    bool correctAnswer=quizBrain.getCorrectAnswer();

    setState(() {
      if(quizBrain.isFinished()==true){
        Alert(
          context: context,
          title: 'Finished!\n\nYour Scored: ${quizBrain.score} out of 10',
          // desc: 'You\'ve reached the end of the quiz\nYour Scored: ${quizBrain.score} out of 10',
          buttons: [
            DialogButton(
              color: Colors.teal,
              onPressed: () {
                // Add your restart logic here
                Navigator.pop(context); // Dismiss the alert
              },
              width: 140,
              child: const Text(
                "RESTART",
                style: TextStyle(color: Colors.white, fontSize: 28),
              ),
            ),
            DialogButton(
              color: Colors.deepOrangeAccent,
              onPressed: () {
                // Exit the app
                SystemNavigator.pop(); // Close the app
              },
              width: 140,
              child: const Text(
                "CLOSE",
                style: TextStyle(color: Colors.white, fontSize: 28),
              ),
            ),
          ],
        ).show();


        quizBrain.reset();
        scoreKeeper=[];
      }
      else{
        if(userPickedAnswer==correctAnswer){
          quizBrain.score++;
          scoreKeeper.add(const Icon(
            Icons.check,
            color: Colors.green,
          ));
        } else {
          scoreKeeper.add(const Icon(
            Icons.close,
            color: Colors.red,
          ));
        }
        quizBrain.nextQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                quizBrain.getQuestionText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30.0,
                  color: Colors.deepOrangeAccent,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'True',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
              onPressed: () {
                checkAnswer(true);},
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'False',
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                checkAnswer(false);},
            ),
          ),
        ),
        Row(
          children: scoreKeeper,
        )
      ],
    );
  }
}
