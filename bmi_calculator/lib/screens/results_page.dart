import 'dart:io';

import 'package:bmi_calculator/components/reusable_card.dart';
import 'package:flutter/material.dart';
import 'package:bmi_calculator/constants.dart';
import 'package:bmi_calculator/components/bottom_button.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage(
      {super.key, required this.bmiResult,
      required this.resultText,
      required this.interpretation});

  final String bmiResult;
  final String resultText;
  final String interpretation;

  @override
  Widget build(BuildContext context) {
    // Determine the text style based on the resultText value
    TextStyle resultTextStyle = kResultTextStyle; // Default style

    if (resultText == 'Overweight') {
      resultTextStyle = kResultTextStyle.copyWith(color: Colors.red);
    } else if (resultText == 'Normal') {
      resultTextStyle = kResultTextStyle;
    } else if (resultText == 'Underweight') {
      resultTextStyle = kResultTextStyle.copyWith(color: Colors.yellow);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BMI CALCULATOR',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, //color of background key
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15.0),
              alignment: Alignment.bottomLeft,
              child: const Text(
                'Your Result',
                style: kTitleTextStyle,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: ReusableCard(
              colour: kActiveCardColour,
              cardChild: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    resultText.toUpperCase(),
                    style: resultTextStyle,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'BMI:',
                        style: kBMITextStyle,
                      ),
                      Text(
                        bmiResult,
                        style: kBMITextStyle,
                      ),
                    ],
                  ),
                  const Column(
                    children: [
                      Text(
                        'Normal BMI range:',
                        style: kLabelTextStyle,
                      ),
                      Text(
                        '18.5-24.9 kg/m2',
                        style: kBodyTextStyle,
                      ),
                    ],
                  ),
                  Text(
                    textAlign: TextAlign.center,
                    interpretation,
                    style: kBodyTextStyle,
                  )
                ],
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: BottomButton(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  buttonTitle: 'RE-CALCULATE',
                  buttonColor: const Color(0xFFd3a13d),
                ),
              ),
              const SizedBox(width: 5.0),
              Expanded(
                child: BottomButton(
                    onTap: () {
                      exit(0);
                    },
                    buttonTitle: 'EXIT'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
